from kafka import KafkaProducer
import json

def json_serializer(data):
    return json.dumps(data).encode('utf-8')

producer = KafkaProducer(
    bootstrap_servers='localhost:9092',  # Replace with your Kafka broker address
    value_serializer=json_serializer
)

def send_to_kafka(topic, data):
    producer.send(topic, data)
    producer.flush()