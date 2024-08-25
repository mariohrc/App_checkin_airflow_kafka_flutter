from django.db import models
from django.utils import timezone

class Tcc(models.Model):
    """
    Represents the 'tcc' table in the PostgreSQL database.
    Stores information related to the QR codes and associated user data.
    """
    qrcode = models.CharField(max_length=255, default='default_qr_code', primary_key=True)
    name = models.CharField(max_length=255, null=True)
    gender = models.CharField(max_length=255, null=True)
    adress = models.CharField(max_length=255, null=True)
    postcode = models.CharField(max_length=255, null=True)
    email = models.CharField(max_length=255, null=True)
    username = models.CharField(max_length=255, null=True)
    registerdate = models.CharField(max_length=255, null=True)
    phone = models.CharField(max_length=255, null=True)

    class Meta:
        db_table = 'tcc'

class Check(models.Model):
    """
    Represents the 'check' table in the PostgreSQL database.
    Stores the check-in/out records associated with QR codes.
    """
    qrcode = models.CharField(max_length=255)
    name = models.CharField(max_length=255)
    check_time = models.DateTimeField(default=timezone.now)
    reader_name = models.CharField(max_length=255)

    class Meta:
        db_table = 'check'

class QrCodeLog(models.Model):
    """
    Represents the log of QR code activities.
    Logs details such as QR code status, messages, and timestamps.
    """
    qrcode = models.CharField(max_length=255)
    status = models.CharField(max_length=50)
    message = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.qrcode} - {self.status}"