from rest_framework import viewsets
from .serializers import BlockSerializer
from .models import Block

class BlockViewSet(viewsets.ModelViewSet):
    queryset = Block.objects.all().order_by('number')
    serializer_class = BlockSerializer

