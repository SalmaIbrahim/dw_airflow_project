FROM apache/airflow:3.2.1

# USER airflow
# RUN pip install apache-airflow-providers-postgres

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
        apache-airflow-providers-postgres \
        apache-airflow-providers-common-sql \
        "pendulum>=3.0.0"