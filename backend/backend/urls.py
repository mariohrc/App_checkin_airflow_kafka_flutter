from django.urls import include, path
from django.contrib import admin
from profiles.views import CheckCodeView



urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/check-code/', CheckCodeView.as_view(), name='check_code'),
]