from rest_framework import serializers
from .models import Tcc, Check

class TccSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tcc
        fields = '__all__'

class CheckSerializer(serializers.ModelSerializer):
    class Meta:
        model = Check
        fields = '__all__'