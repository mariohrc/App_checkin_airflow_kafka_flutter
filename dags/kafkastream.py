from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook

default_args = {
    'owner' : 'mario',
    'start_date': datetime(2024, 7, 2, 10, 00),
    'retries' : 5,
    'retray_delay': timedelta(minutes=2)
    }


def get_data():
    import json
    import requests

    res = requests.get('https://randomuser.me/api/')
    res = res.json()
    res = res['results'][0]

    return res

def format_data(ti):
    data = {}
    res = ti.xcom_pull(task_ids='get_data')
    location = res['location']
    data['id'] = res['login']['uuid']
    data['name'] = res['name']['first']+ ' ' + res['name']['last']
    data['gender'] = res['gender']
    data['address'] = f"{str(location['street']['number'])} {location['street']['name']}, " \
                      f"{location['city']}, {location['state']}, {location['country']}"
    data['post_code'] = location['postcode']
    data['email'] = res['email']
    data['username'] = res['login']['username']
    data['registered_date'] = res['registered']['date']
    data['phone'] = res['phone']

    return data

def insert_data(ti):

    pg_hook = PostgresHook(postgres_conn_id='postgres_localhost')
    insert_cmd = """
                INSERT INTO tcc (Qrcode,Name,Gender,Adress,Postcode,Email,Username,RegisterDate,Phone)
                VALUES(%s,%s,%s,%s,%s,%s,%s,%s,%s);
            """
    res = ti.xcom_pull(task_ids='transform_data')
    Qrcode = res['id']
    Name = res['name']
    Gender = res['gender']
    Adress = res['address']
    Postcode = res['post_code']
    Email = res['email']
    Username = res['username']
    RegisterDate = res['registered_date']
    Phone = res['phone']

    row = (Qrcode,Name,Gender,Adress,Postcode,Email,Username,RegisterDate,Phone)
    pg_hook.run(insert_cmd, parameters=row)
    

with DAG(
    default_args=default_args,
    dag_id='streaming_test',
    schedule_interval='@daily',
    catchup=False,
) as dag:
    
    get_data_task = PythonOperator(
        task_id='get_data',
        python_callable=get_data,
    )
    
    
    transform_data_task = PythonOperator(
        task_id='transform_data',
        python_callable=format_data,
    )

    create_postgres_table_task = SQLExecuteQueryOperator(

        task_id='create_postgres_table',
        conn_id='postgres_localhost',
        sql=""" 
            CREATE TABLE IF NOT EXISTS tcc (
                Qrcode varchar(255),
                Name varchar(255),
                Gender varchar(255),
                Adress varchar(255),
                Postcode varchar(255),
                Email varchar(255),
                Username varchar(255),
                RegisterDate varchar(255),
                Phone varchar(255)
            );
        """
    )

    insert_postgres_data_task = PythonOperator(

        task_id='insert_postgres_data',
        python_callable=insert_data,
        
    )

    get_data_task >> transform_data_task >> create_postgres_table_task >>insert_postgres_data_task



