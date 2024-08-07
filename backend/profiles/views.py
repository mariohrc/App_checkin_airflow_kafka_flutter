# profiles/views.py

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .kafka_producer import send_to_kafka
from django.core.cache import cache
import time
import threading
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class CheckCodeView(APIView):
    def get(self, request):
        qrcode = request.query_params.get('qrcode', None)
        reader_name = request.query_params.get('reader_name', None)

        if not qrcode or not reader_name:
            return Response({'error': 'QR Code and Reader Name are required.'}, status=status.HTTP_400_BAD_REQUEST)

        check_data = {
            'qrcode': qrcode,
            'reader_name': reader_name,
        }

        # Send data to Kafka
        send_thread = threading.Thread(target=send_to_kafka, args=('checkdata', check_data))
        send_thread.start()

        # Poll the cache for the response within a timeout period
        timeout = 3
        interval = 0.5
        elapsed_time = 0

        while elapsed_time < timeout:
            response_data = cache.get(f'qr_{qrcode}_status')
            logger.info(f"Polling cache for QR Code: {qrcode}, Data: {response_data}")
            if response_data:
                if response_data['status'] == 'success':
                    return Response({'message': response_data['message']}, status=status.HTTP_201_CREATED)
                else:
                    return Response({'error': response_data['message']}, status=status.HTTP_404_NOT_FOUND)
            time.sleep(interval)
            elapsed_time += interval

        # If no response in cache, return 404
        return Response({'error': 'QR Code does not exist.'}, status=status.HTTP_404_NOT_FOUND)
