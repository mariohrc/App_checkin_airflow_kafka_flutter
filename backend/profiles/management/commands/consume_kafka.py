import json
import logging
from kafka import KafkaConsumer, KafkaProducer
from django.core.management.base import BaseCommand
from django.core.cache import cache
import psycopg2
from psycopg2.extras import RealDictCursor

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Kafka settings
KAFKA_BROKER = 'localhost:9092'
KAFKA_CONSUME_TOPIC = 'checkdata'
KAFKA_PRODUCE_TOPIC = 'checkdata_response'

# PostgreSQL settings
POSTGRES_DB = 'postgres'
POSTGRES_USER = 'airflow'
POSTGRES_PASSWORD = 'airflow'
POSTGRES_HOST = 'localhost'
POSTGRES_PORT = '5432'

def json_serializer(data):
    return json.dumps(data).encode('utf-8')

def connect_to_postgres():
    try:
        connection = psycopg2.connect(
            dbname=POSTGRES_DB,
            user=POSTGRES_USER,
            password=POSTGRES_PASSWORD,
            host=POSTGRES_HOST,
            port=POSTGRES_PORT,
        )
        return connection
    except Exception as e:
        logger.error(f"Error connecting to PostgreSQL: {e}")
        return None

def handle_message(message, cursor, producer):
    try:
        data = message.value
        qrcode = data.get('qrcode')
        reader_name = data.get('reader_name')

        if not qrcode or not reader_name:
            logger.error("Invalid message format")
            return

        cursor.execute("SELECT * FROM public.tcc WHERE qrcode = %s", (qrcode,))
        tcc_record = cursor.fetchone()

        if tcc_record:
            cursor.execute(
                "INSERT INTO public.check (qrcode, name, check_time, reader_name) VALUES (%s, %s, NOW(), %s) ON CONFLICT DO NOTHING",
                (qrcode, tcc_record['name'], reader_name)
            )
            response_data = {
                'qrcode': qrcode,
                'status': 'success',
                'message': 'Check-in/out recorded.'
            }
            logger.info("Check-in/out recorded for QR Code: %s", qrcode)
        else:
            response_data = {
                'qrcode': qrcode,
                'status': 'error',
                'message': 'QR Code does not exist.'
            }
            logger.error("QR Code does not exist: %s", qrcode)

        cache.set(f'qr_{qrcode}_status', response_data, timeout=60)
        producer.send(KAFKA_PRODUCE_TOPIC, response_data)
    except Exception as e:
        logger.error(f"Error handling message: {e}")

        
def consume_messages():
    consumer = KafkaConsumer(
        KAFKA_CONSUME_TOPIC,
        bootstrap_servers=KAFKA_BROKER,
        value_deserializer=lambda m: json.loads(m.decode('utf-8')),
        group_id='django-consumer-group',
        auto_offset_reset='earliest',
        enable_auto_commit=True,
        auto_commit_interval_ms=100
    )

    producer = KafkaProducer(
        bootstrap_servers=KAFKA_BROKER,
        value_serializer=json_serializer
    )

    connection = connect_to_postgres()
    if connection is None:
        return

    cursor = connection.cursor(cursor_factory=RealDictCursor)

    try:
        for message in consumer:
            logger.info(f"Received message: {message.value}")
            handle_message(message, cursor, producer)
            connection.commit()
    except Exception as e:
        logger.error(f"Error processing messages: {e}")
    finally:
        cursor.close()
        connection.close()

class Command(BaseCommand):
    help = 'Starts the Kafka consumer to process check-in/out messages'

    def handle(self, *args, **options):
        consume_messages()
