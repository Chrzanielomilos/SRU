from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

# Załadowanie modułów
import SRU.core
import SRU.modules.user
import SRU.modules.auth
from SRU.core.registry import all_modules

urlpatterns = [
    # path('admin/', admin.site.urls),

    # Endpoints do uwierzytelniania (JWT)
    # path('api/auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    # path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Endpoint do menu
    path('api/', include('SRU.core.api_urls')),
]

# Dynamiczne podpinanie każdego zarejestrowanego modułu pod /api/<slug>/
for m in all_modules():
    urlpatterns.append(
        path(f'api/{m.slug}/', include((f'{m.app}.api_urls', m.slug), namespace=m.slug))
    )

print("REJESTROWANE MODUŁY:", all_modules())
