from django.urls import path
from . import views

urlpatterns = [
    path('', views.listar_pacientes, name='listar_pacientes'),
    path('mis-controles/', views.obtener_mis_controles, name='mis_controles'),
    path('registrar/', views.registrar_paciente, name='registrar_paciente'),
    path('<int:paciente_id>/controles/', views.agregar_control, name='agregar_control'),
    path('ecg-metrics/', views.obtener_ecg_metrics, name='ecg_metrics'),
]
