from django_elasticsearch_dsl import Document, Index, fields
from django_elasticsearch_dsl.registries import registry
from .models import QrCodeLog  # Assuming you have a QrCodeLog model

# Define the index
qr_code_log_index = Index('qrcode_logs')

@registry.register_document
@qr_code_log_index.document
class QrCodeLogDocument(Document):
    qrcode = fields.TextField()
    status = fields.TextField()
    message = fields.TextField()
    timestamp = fields.DateField()

    class Django:
        model = QrCodeLog  # The model associated with this Document
        fields = [
            'qrcode',
            'status',
            'message',
            'timestamp',
        ]
