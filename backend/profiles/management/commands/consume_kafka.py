import json
import logging
from kafka import KafkaConsumer, KafkaProducer
from django.core.management.base import BaseCommand
from django.core.cache import cache
import psycopg2
from psycopg2.extras import RealDictCursor

# Configure logging for the application
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Kafka configuration settings
KAFKA_BROKER = 'localhost:9092' # Kafka broker address
KAFKA_CONSUME_TOPIC = 'checkdata' # Kafka topic to consume messages from
KAFKA_PRODUCE_TOPIC = 'checkdata_response' # Kafka topic to produce messages to

# PostgreSQL configuration settings
POSTGRES_DB = 'postgres' # Database name
POSTGRES_USER = 'airflow' # Database user
POSTGRES_PASSWORD = 'airflow' # Database password
POSTGRES_HOST = 'localhost' # Database host
POSTGRES_PORT = '5432' # Database port

def json_serializer(data):
    """
    Serializes a Python object into a JSON formatted string encoded in UTF-8.
    This is used by KafkaProducer to send data in JSON format.
    """
    return json.dumps(data).encode('utf-8')

def connect_to_postgres():
    """
    Establishes a connection to the PostgreSQL database using the provided configuration.
    Returns the connection object if successful, or None if an error occurs.
    """
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
    """
    Processes incoming Kafka messages to handle check-in/out operations.
    
    Parameters:
    - message: The Kafka message containing QR code data.
    - cursor: A cursor object to interact with the PostgreSQL database.
    - producer: A KafkaProducer object to send responses back to Kafka.

    This function checks if the QR code exists in the database, records the
    check-in/out event if valid, and sends a response back to Kafka.
    """
    try:
        data = message.value
        qrcode = data.get('qrcode')
        reader_name = data.get('reader_name')

        if not qrcode or not reader_name:
            logger.error("Invalid message format")
            return
        
        # Check if the QR code exists in the database
        cursor.execute("SELECT * FROM public.tcc WHERE qrcode = %s", (qrcode,))
        tcc_record = cursor.fetchone()

        if tcc_record:
             # Record the check-in/out event in the 'check' table
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

        # Cache the response and send it to the Kafka producer
        cache.set(f'qr_{qrcode}_status', response_data, timeout=60)
        producer.send(KAFKA_PRODUCE_TOPIC, response_data)
    except Exception as e:
        logger.error(f"Error handling message: {e}")

        
def consume_messages():
    """
    Consumes messages from the specified Kafka topic and processes them.
    Establishes a connection to PostgreSQL, consumes messages from Kafka,
    and delegates each message to the handle_message function for processing.
    """
    # Set up Kafka consumer
    consumer = KafkaConsumer(
        KAFKA_CONSUME_TOPIC,
        bootstrap_servers=KAFKA_BROKER,
        value_deserializer=lambda m: json.loads(m.decode('utf-8')),
        group_id='django-consumer-group',
        auto_offset_reset='earliest',
        enable_auto_commit=True,
        auto_commit_interval_ms=100
    )

     # Set up Kafka producer
    producer = KafkaProducer(
        bootstrap_servers=KAFKA_BROKER,
        value_serializer=json_serializer
    )

    # Connect to PostgreSQL
    connection = connect_to_postgres()
    if connection is None:
        return

    cursor = connection.cursor(cursor_factory=RealDictCursor)

    try:
        for message in consumer:
            logger.info(f"Received message: {message.value}")
            handle_message(message, cursor, producer)
            connection.commit() # Commit transaction after handling each message
    except Exception as e:
        logger.error(f"Error processing messages: {e}")
    finally:
        cursor.close() # Close the cursor
        connection.close() # Close the connection to PostgreSQL

class Command(BaseCommand):
    """
    Custom Django management command to start the Kafka consumer.
    The command is executed using Django's management interface.
    """
    help = 'Starts the Kafka consumer to process check-in/out messages'

    def handle(self, *args, **options):
        consume_messages()
