from django.apps import AppConfig
from django.core.management import call_command
import threading

class MyappConfig(AppConfig):
    name = 'profiles'

    def ready(self):
        def start_kafka_consumer():
            call_command('consume_kafka')

        thread = threading.Thread(target=start_kafka_consumer)
        thread.daemon = True
        thread.start()