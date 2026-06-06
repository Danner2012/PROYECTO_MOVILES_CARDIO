from django.urls import path
from . import views

urlpatterns = [
    path('', views.listar_pacientes, name='listar_pacientes'),
    path('registrar/', views.registrar_paciente, name='registrar_paciente'),
    path('<int:paciente_id>/controles/', views.agregar_control, name='agregar_control'),
    # NUEVA RUTA: Endpoint para el historial y métricas del ECG
    path('ecg-metrics/', views.obtener_metricas_ecg, name='obtener_metricas_ecg'),
]
