from django.urls import path
from .api_views import index

urlpatterns = [
    path('', index, name='user'),
]
