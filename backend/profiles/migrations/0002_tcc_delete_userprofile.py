# Generated by Django 5.0.6 on 2024-07-15 23:32

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('profiles', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Tcc',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('code', models.CharField(max_length=100, unique=True)),
            ],
            options={
                'db_table': 'tcc',
            },
        ),
        migrations.DeleteModel(
            name='UserProfile',
        ),
    ]
