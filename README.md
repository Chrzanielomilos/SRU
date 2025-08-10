# SRU

## Rejestracja nowego modułu

### ./SRU/modules/module_name/apps.py 
```
from django.apps import AppConfig

class NameConfig(AppConfig): # Replace Name with Module_name
    name = 'SRU.modules.module_name'
    label = 'module_name'

```

### ./SRU/settings.py
```
INSTALLED_APPS = [
    # ...
    'SRU.modules.module_name',
]
```

### ./SRU/urls.py
```
urlpatterns = [
    # inne moduły
    path('api/module_name/', include('SRU.modules.module_name.api_urls')),
]
```

### Create ./SRU/module_name/api_views.py
```
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticatedOrReadOnly
from rest_framework.response import Response

@api_view(['GET'])
@permission_classes([IsAuthenticatedOrReadOnly])
def index(request):
    return Response({
        'title': 'Module_name',
        'items': [
            {'id': 1, 'title': 'XY 1'},
            {'id': 2, 'title': 'XY 2'},
        ]
    })
```

### Set up routing ./SRU/modules/module_name/api_urls.py
```
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.permissions import AllowAny #TODO: Remove this line
from rest_framework.response import Response
from django.urls import path
from .api_views import index

urlpatterns = [
    path('', index, name='name-index'), # replace name with module_name
]

@api_view(['GET'])
@permission_classes([AllowAny]) # TODO: IsAuthenticated
def index(request):
    return Response({
        'username': 'MICHAŁ',
        'email': 'ORZEŁ@wp.pl',
    })
```

### Create ./SRU/modules/module_name/__init__.py
```
from core.registry import register, ModuleInfo

register(ModuleInfo(
    app='SRU.modules.module_name',
    slug='module_name',
    label='Module_label'
))
```