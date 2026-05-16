from django.urls import path
from .views import PredictView, GraphView

urlpatterns = [
    path('predict/', PredictView.as_view(), name='predict'),
    path('graph/', GraphView.as_view(), name='graph'),
]
