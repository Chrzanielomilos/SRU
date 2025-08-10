from django.urls import path
from .api_views import menu

app_name = 'core'

urlpatterns = [
    path('menu/', menu, name='menu'),
]
