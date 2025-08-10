from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def index(request):
    return Response({
        'title': 'User',
        'items': [
            {'id': 1, 'title': 'XY 1'},
            {'id': 2, 'title': 'XY 2'},
        ]
    })