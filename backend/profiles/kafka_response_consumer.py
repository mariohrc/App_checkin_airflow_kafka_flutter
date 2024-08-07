import json
from kafka import KafkaConsumer
import threading
from django.core.cache import cache
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

KAFKA_BROKER = 'localhost:9092'
KAFKA_RESPONSE_TOPIC = 'checkdata_response'

def process_response(message):
    data = json.loads(message.value.decode('utf-8'))
    qrcode = data.get('qrcode')
    status = data.get('status')
    message = data.get('message')
    
    cache_key = f'qr_{qrcode}_status'
    cache_value = {'status': status, 'message': message}
    
    # Set cache with a detailed log
    cache.set(cache_key, cache_value, timeout=300)
    logger.info(f"Cache set for QR Code: {qrcode}, Key: {cache_key}, Value: {cache_value}")

def consume_responses():
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
    thread = threading.Thread(target=consume_responses)
    thread.daemon = True
    thread.start()
