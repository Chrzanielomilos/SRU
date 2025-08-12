from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.urls import path
from .api_views import index

urlpatterns = [
    path('', index, name='user-index'),
]

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def index(request):
    return Response({
        'username': 'MICHAŁ',
        'email': 'ORZEŁ@wp.pl',
    })
