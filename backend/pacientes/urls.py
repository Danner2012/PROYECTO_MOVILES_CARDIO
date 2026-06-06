from django.urls import path
from . import views

urlpatterns = [
    path('', views.listar_pacientes, name='listar_pacientes'),
    path('mis-controles/', views.obtener_mis_controles, name='mis_controles'),
    path('registrar/', views.registrar_paciente, name='registrar_paciente'),
    path('<int:paciente_id>/controles/', views.agregar_control, name='agregar_control'),
    
    # Historial Clínico CRUD
    path('<int:paciente_id>/historial/', views.gestionar_historial_paciente, name='gestionar_historial'),
    path('historial/<uuid:pk>/', views.detalle_historial_clinico, name='detalle_historial'),
]
