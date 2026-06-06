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

    # Seguimiento de Arritmias CRUD
    path('<int:paciente_id>/arritmias/', views.gestionar_arritmias_paciente, name='gestionar_arritmias'),
    path('arritmias/<uuid:pk>/', views.detalle_arritmia, name='detalle_arritmia'),
    path('arritmias/<uuid:arritmia_id>/seguimiento/', views.registrar_seguimiento_arritmia, name='registrar_seguimiento'),
    path('seguimiento/<uuid:pk>/', views.eliminar_seguimiento_arritmia, name='eliminar_seguimiento'),

    # Gestión de Exámenes CRUD
    path('<int:paciente_id>/examenes/', views.gestionar_examenes_paciente, name='gestionar_examenes'),
    path('examenes/<uuid:pk>/', views.detalle_examen_medico, name='detalle_examen'),

    # Gestión de Tratamientos CRUD
    path('<int:paciente_id>/tratamientos/', views.gestionar_tratamientos_paciente, name='gestionar_tratamientos'),
    path('tratamientos/<uuid:pk>/', views.detalle_tratamiento, name='detalle_tratamiento'),

    # Reportes PDF
    path('<int:paciente_id>/reporte-pdf/', views.descargar_reporte_paciente, name='descargar_reporte'),
]
