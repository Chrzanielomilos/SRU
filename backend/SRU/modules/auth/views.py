from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.contrib.auth import authenticate
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

@api_view(['POST'])
def login_view(request):
    username = request.data.get("email")
    password = request.data.get("password")
    user = authenticate(request, username=username, password=password)

    if not user or not user.is_active:
        return Response({"detail": "Nieprawidłowe dane logowania"}, status=status.HTTP_401_UNAUTHORIZED)

    refresh = RefreshToken.for_user(user)

    response = Response({"message": "Zalogowano"})
    response.set_cookie(
        key="access_token",
        value=str(refresh.access_token),
        httponly=True,
        secure=True,
        samesite="Strict",
        max_age=1800  # 30 min
    )
    return response
