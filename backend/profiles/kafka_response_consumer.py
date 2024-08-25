import json
from kafka import KafkaConsumer
import threading
from django.core.cache import cache
from elasticsearch import Elasticsearch
from datetime import datetime
from .models import QrCodeLog
from .documents import QrCodeLogDocument
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Kafka and Elasticsearch configuration
KAFKA_BROKER = 'localhost:9092' # Kafka broker address
KAFKA_RESPONSE_TOPIC = 'checkdata_response' # Kafka topic to consume responses from
es = Elasticsearch([{'host': 'localhost', 'port': 9200}]) # Elasticsearch connection

def process_response(message):
    """
    Processes the response message received from Kafka and performs actions
    such as caching the result and indexing it in Elasticsearch.

    Parameters:
    - message: The Kafka message containing the response data.
    """
    data = json.loads(message.value.decode('utf-8'))
    qrcode = data.get('qrcode')
    status = data.get('status')
    message_text = data.get('message')
    
    cache_key = f'qr_{qrcode}_status'
    cache_value = {'status': status, 'message': message_text}
    
    # Set cache with a detailed log
    cache.set(cache_key, cache_value, timeout=300)
    logger.info(f"Cache set for QR Code: {qrcode}, Key: {cache_key}, Value: {cache_value}")

    # Index the data in Elasticsearch
    qr_code_log = QrCodeLog(
        qrcode=qrcode,
        status=status,
        message=message_text,
        timestamp=datetime.now()
    )
    qr_code_log.save() # Save to Django model
    QrCodeLogDocument().update(qr_code_log) # Index in Elasticsearch

def consume_responses():
    """
    Consumes responses from the Kafka topic and processes each response
    by calling the process_response function.
    """
    consumer = KafkaConsumer(
        KAFKA_RESPONSE_TOPIC,
        bootstrap_servers=KAFKA_BROKER,
        group_id='django-response-consumer-group',
        value_deserializer=lambda m: json.loads(m.decode('utf-8')),
        auto_offset_reset='earliest',
        enable_auto_commit=True,
        auto_commit_interval_ms=100
    )

    for message in consumer:
        process_response(message)

def start_consumer():
    """
    Starts a separate thread to run the Kafka consumer for processing responses.
    This allows the consumer to run concurrently with the main Django application.
    """
    thread = threading.Thread(target=consume_responses)
    thread.daemon = True
    thread.start()
