"""
    Created on 16 May 2026

    Author: Salma Ibrahim Ed-Desouki
"""
##################################

from datetime import datetime, timedelta
import pendulum
import requests
import os
import sys

from airflow.sdk import dag, task
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

@dag (
    dag_id = "bronze_layer"
    , description = "the creation dag of the bronze layer in the data warehouse"
    , start_date = pendulum.datetime(2026, 5, 20, tz="Africa/Cairo")
    , schedule = "@daily"
    , catchup = False
    , dagrun_timeout = timedelta(minutes=30)
    ,
)

def bronze_layer():
                                # ################################################### #
    # the functions Definition
    #  INGESTING CSV FILES INTO THE TEMP TABLES
    def _ingesting_csv(file_name, source_type):
        file_dir = f"/opt/airflow/dags/datasets/source_{source_type}/{file_name}"
        table_name = f"bronze.{source_type}_{file_name.split('.')[0]}_tmp"

        postgres_hook = PostgresHook(postgres_conn_id="dwh_postgres_conn")
        conn = postgres_hook.get_conn()
        cursor = conn.cursor()

        try:
            with open(file_dir, "r") as file:
                file.seek(0)
                col_names = next(file)  # Skip the header row
                file.seek(0)

                print(f"Starting ingestion of {file_name} into {table_name}...")

                cursor.copy_expert(f"""
                    COPY {table_name}
                    ({col_names.strip()})
                    FROM STDIN 
                    WITH CSV HEADER 
                    DELIMITER ','
                    """
                    , file)
                conn.commit()

            print(f"Ingestion of {file_name} into {table_name} completed successfully.")

        except Exception as e:
            conn.rollback()
            raise Exception (f"Error occurred while ingesting {file_name}: {e}")
        
        finally:   
            cursor.close()
            conn.close()
                                # ################################################### #
    # MERGING SOURCES
    def _merge_source(script_path, src_type):
        with open(script_path, "r") as script:
            query = script.read()
            
        postgres_hook = PostgresHook(postgres_conn_id="dwh_postgres_conn")
        conn = postgres_hook.get_conn()
        cursor = conn.cursor()

        try:
            # print (f"Starting merging Stage from {tmp_table_name} into {table_name}...")
            print (f"Starting merging Stage from {src_type} tmp tables into bronze layer tables...")
            cursor.execute(query)
            conn.commit()
            print (f"Merging Stage from {src_type} tmp tables into bronze layer tables completed successfully.")
            
        except Exception as e:
            conn.rollback()
            raise Exception (f"Error occured while merging {src_type}: {e}")

        finally:
            cursor.close()
            conn.close() 

        # ######################################################################################################################## #
    
    # DAG Tasks definition    

    # create the schemas in the data warehouse database
    schemas_creation = SQLExecuteQueryOperator (
            task_id = "schemas_creation"
            , conn_id = "dwh_postgres_conn"
            , sql = "sql/1_db_init/create_schemas.sql"
    )
                                ################################################### #
    # create the tables of the bronze layer
    ddl_bronze_layer = SQLExecuteQueryOperator (
            task_id = "ddl_bronze_layer"
            , conn_id = "dwh_postgres_conn" 
            , sql ="sql/2_bronze/ddl_bronze.sql"
    )
                                # ################################################### #
    # create the temp tables of the bronze layer
    ddl_tmp_bronze_layer = SQLExecuteQueryOperator (
            task_id = "ddl_tmp_bronze_layer"
            , conn_id = "dwh_postgres_conn" 
            , sql ="sql/2_bronze/ddl_tmp_bronze.sql"
    )
                                # ################################################### #
    # ingest the data of the crm_source CSV files on PC in the tmp tables bronze layer
    @task (task_id = "ingestion_crm_source_tmp")
    def ingestion_crm_source(file_name, source_type):
        return _ingesting_csv(file_name, source_type)

                                # ################################################### #
    @task (task_id = "merge_crm_source")
    def merge_crm_source(script_path):
        return _merge_source(script_path, "crm")
        # script_path = "/opt/airflow/dags/sql/2_bronze/merge_crm.sql"
        
                                # ################################################### #

    @task (task_id = "download_csv")
    def download_csv():

        with open("/opt/airflow/dags/datasets/links/get_erp_datasets.txt", "r") as f:
            urls = [line.strip() for line in f.readlines() if line.strip()]
        # print (f"URLs to download: {urls}")

        for url in urls:
            datasets_dir = "/opt/airflow/dags/datasets/source_erp/"        
            file_name = url.split("/")[-1]   
            file_path = os.path.join(datasets_dir, file_name) 

            try:
                response = requests.get(url)
                print(f"Downloading file: {file_name}...")
                
                with open(file_path, "wb") as file:
                    file.write(response.content)  # Save the content as a JSON file
                
                print(f"File '{file_name}' downloaded successfully.")
            
            except Exception as e:
                raise Exception (f"Failed to download file '{file_name}': {e}.")
            

                                # ################################################### #
    @task (task_id = "ingestion_erp_source_tmp")
    def ingestion_erp_source(file_name, source_type):
        return _ingesting_csv(file_name, source_type)

                                # ################################################### #
    @task (task_id = "merge_erp_source")
    def merge_erp_source(script_path):
        return _merge_source(script_path, "erp")      
                                # ################################################### #

            #################################################################################################################### 
    # get files list and create a task for each file to ingest it in the tmp table of the bronze layer
    ingest_crm_files = [
        ingestion_crm_source(file, "crm")
        for file in os.listdir("/opt/airflow/dags/datasets/source_crm/")
        if file.endswith(".csv")
    ]

    ingest_erp_files = [
        ingestion_erp_source(file, "erp")
        for file in os.listdir("/opt/airflow/dags/datasets/source_erp/")
        if file.endswith(".csv")
    ]

    src_crm_merge_dir = "/opt/airflow/dags/sql/2_bronze/merge_crm.sql"
    src_erp_merge_dir = "/opt/airflow/dags/sql/2_bronze/merge_erp.sql"
    
    download_task = download_csv()
    merge_crm_source_task = merge_crm_source(src_crm_merge_dir)
    merge_erp_source_task = merge_erp_source(src_erp_merge_dir)

    # set the dependencies between the tasks
    schemas_creation >> ddl_bronze_layer >> ddl_tmp_bronze_layer 
    ddl_tmp_bronze_layer >> ingest_crm_files >> merge_crm_source_task
    ddl_tmp_bronze_layer >> download_task >> ingest_erp_files >> merge_erp_source_task
     
    
bronze_layer = bronze_layer()

