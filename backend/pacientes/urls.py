from django.urls import path
from . import views

urlpatterns = [
    path('', views.listar_pacientes, name='listar_pacientes'),
    path('registrar/', views.registrar_paciente, name='registrar_paciente'),
    path('<int:paciente_id>/controles/', views.agregar_control, name='agregar_control'),
]
