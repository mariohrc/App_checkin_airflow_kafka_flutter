import json
from kafka import KafkaConsumer
import threading
from django.core.cache import cache

KAFKA_BROKER = 'localhost:9092'
KAFKA_RESPONSE_TOPIC = 'checkdata_response'

def process_response(message):
    data = json.loads(message.value.decode('utf-8'))
    qrcode = data.get('qrcode')
    status = data.get('status')
    message = data.get('message')
    
    cache.set(f'qr_{qrcode}_status', {'status': status, 'message': message}, timeout=300)

def consume_responses():
    consumer = KafkaConsumer(
        KAFKA_RESPONSE_TOPIC,
        bootstrap_servers=KAFKA_BROKER,
        group_id='django-consumer-group',
        value_deserializer=lambda m: json.loads(m.decode('utf-8'))
    )

    for message in consumer:
        process_response(message)

def start_consumer():
    thread = threading.Thread(target=consume_responses)
    thread.daemon = True
    thread.start()