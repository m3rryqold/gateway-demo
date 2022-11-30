from rest_framework import routers
from .views import BlockViewSet

router = routers.DefaultRouter()
router.register('api/blocks', BlockViewSet, 'blocks')

urlpatterns = router.urls
