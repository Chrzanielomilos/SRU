from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .navigation import get_menu_items_for

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def menu(request):
    return Response(get_menu_items_for(request.user))
