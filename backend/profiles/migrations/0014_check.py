# Generated by Django 5.0.6 on 2024-07-16 22:31

import django.utils.timezone
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('profiles', '0013_rename_register_date_tcc_registerdate'),
    ]

    operations = [
        migrations.CreateModel(
            name='Check',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('qrcode', models.CharField(max_length=255)),
                ('name', models.CharField(max_length=255)),
                ('check_time', models.DateTimeField(default=django.utils.timezone.now)),
                ('reader_name', models.CharField(max_length=255)),
            ],
            options={
                'db_table': 'check',
            },
        ),
    ]
