# backend/pacientes/views.py
from rest_framework import status
from rest_framework.decorators import api_view, authentication_classes, permission_classes, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from .models import Paciente, ControlCardiologico, HistorialClinico, Arritmia, SeguimientoArritmia, ExamenMedico, Tratamiento
from .serializers import (
    PacienteSerializer, 
    ControlCardiologicoSerializer, 
    HistorialClinicoSerializer,
    ArritmiaSerializer,
    SeguimientoArritmiaSerializer,
    ExamenMedicoSerializer,
    TratamientoSerializer
)


User = get_user_model()


def es_doctor(usuario):
    try:
        return str(usuario.rol).lower() == 'doctor'
    except Exception:
        return False


def es_paciente(usuario):
    try:
        return str(usuario.rol).lower() == 'paciente'
    except Exception:
        return False


# --- Gestión de Exámenes Médicos CRUD ---

@api_view(['GET', 'POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def gestionar_examenes_paciente(request, paciente_id):
    if not es_doctor(request.user):
        return Response({"error": "No tienes permisos de Doctor."}, status=status.HTTP_403_FORBIDDEN)

    try:
        paciente = Paciente.objects.get(id=paciente_id, doctor=request.user)
    except Paciente.DoesNotExist:
        return Response({"error": "Paciente no encontrado o no pertenece a tu lista."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        examenes = paciente.examenes_medicos.all()
        serializer = ExamenMedicoSerializer(examenes, many=True, context={'request': request})
        return Response(serializer.data)

    elif request.method == 'POST':
        serializer = ExamenMedicoSerializer(data=request.data)
        if serializer.is_valid():
            instancia = serializer.save(paciente=paciente, doctor=request.user)
            sincronizar_con_ollama(paciente, 'examen', instancia)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT', 'DELETE'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def detalle_examen_medico(request, pk):
    if not es_doctor(request.user):
        return Response({"error": "No tienes permisos de Doctor."}, status=status.HTTP_403_FORBIDDEN)

    try:
        examen = ExamenMedico.objects.get(id=pk, doctor=request.user)
    except ExamenMedico.DoesNotExist:
        return Response({"error": "Examen no encontrado o no tienes permiso."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = ExamenMedicoSerializer(examen, context={'request': request})
        return Response(serializer.data)

    elif request.method == 'PUT':
        serializer = ExamenMedicoSerializer(examen, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        examen.delete()
        return Response({"mensaje": "Examen eliminado."}, status=status.HTTP_200_OK)


# --- Seguimiento de Arritmias CRUD ---

@api_view(['GET', 'POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def gestionar_arritmias_paciente(request, paciente_id):
    if not es_doctor(request.user):
        return Response({"error": "No tienes permisos de Doctor."}, status=status.HTTP_403_FORBIDDEN)

    try:
        paciente = Paciente.objects.get(id=paciente_id, doctor=request.user)
    except Paciente.DoesNotExist:
        return Response({"error": "Paciente no encontrado o no pertenece a tu lista."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        arritmias = paciente.arritmias.all()
        serializer = ArritmiaSerializer(arritmias, many=True, context={'request': request})
        return Response(serializer.data)

    elif request.method == 'POST':
        serializer = ArritmiaSerializer(data=request.data)
        if serializer.is_valid():
            instancia = serializer.save(paciente=paciente, doctor=request.user)
            sincronizar_con_ollama(paciente, 'arritmia', instancia)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT', 'DELETE'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def detalle_arritmia(request, pk):
    if not es_doctor(request.user):
        return Response({"error": "No tienes permisos de Doctor."}, status=status.HTTP_403_FORBIDDEN)

    try:
        arritmia = Arritmia.objects.get(id=pk, doctor=request.user)
    except Arritmia.DoesNotExist:
        return Response({"error": "Arritmia no encontrada o no tienes permiso."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = ArritmiaSerializer(arritmia, context={'request': request})
        return Response(serializer.data)

    elif request.method == 'PUT':
        serializer = ArritmiaSerializer(arritmia, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        arritmia.delete()
        return Response({"mensaje": "Registro eliminado."}, status=status.HTTP_200_OK)


@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def registrar_seguimiento_arritmia(request, arritmia_id):
    if not es_doctor(request.user):
        return Response({"error": "No tienes permisos de Doctor."}, status=status.HTTP_403_FORBIDDEN)

    try:
        arritmia = Arritmia.objects.get(id=arritmia_id, doctor=request.user)
    except Arritmia.DoesNotExist:
        return Response({"error": "Arritmia no encontrada o no tienes permiso."}, status=status.HTTP_404_NOT_FOUND)

    serializer = SeguimientoArritmiaSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save(arritmia=arritmia, registrado_por=request.user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def eliminar_seguimiento_arritmia(request, pk):
    if not es_doctor(request.user):
        return Response({"error": "No tienes permisos de Doctor."}, status=status.HTTP_403_FORBIDDEN)

    try:
        seguimiento = SeguimientoArritmia.objects.get(id=pk, registrado_por=request.user)
    except SeguimientoArritmia.DoesNotExist:
        return Response({"error": "Seguimiento no encontrado o no tienes permiso."}, status=status.HTTP_404_NOT_FOUND)

    seguimiento.delete()
    return Response({"mensaje": "Control eliminado."}, status=status.HTTP_200_OK)


# --- Historial Clínico CRUD ---

@api_view(['GET', 'POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def gestionar_historial_paciente(request, paciente_id):
    if not es_doctor(request.user):
        return Response({"error": "No tienes permisos de Doctor."}, status=status.HTTP_403_FORBIDDEN)

    try:
        paciente = Paciente.objects.get(id=paciente_id, doctor=request.user)
    except Paciente.DoesNotExist:
        return Response({"error": "Paciente no encontrado o no pertenece a tu lista."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        historiales = paciente.historiales_clinicos.filter(activo=True)
        serializer = HistorialClinicoSerializer(historiales, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        serializer = HistorialClinicoSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(paciente=paciente, doctor=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT', 'DELETE'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def detalle_historial_clinico(request, pk):
    if not es_doctor(request.user):
        return Response({"error": "No tienes permisos de Doctor."}, status=status.HTTP_403_FORBIDDEN)

    try:
        historial = HistorialClinico.objects.get(id=pk, doctor=request.user)
    except HistorialClinico.DoesNotExist:
        return Response({"error": "Registro de historial no encontrado o no tienes permiso."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = HistorialClinicoSerializer(historial)
        return Response(serializer.data)

    elif request.method == 'PUT':
        serializer = HistorialClinicoSerializer(historial, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        historial.activo = False
        historial.save()
        return Response({"mensaje": "Registro desactivado correctamente."}, status=status.HTTP_200_OK)


# --- Vistas Existentes ---

@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def obtener_mis_controles(request):
    if not es_paciente(request.user):
        return Response(
            {"error": "Esta vista es solo para pacientes."},
            status=status.HTTP_403_FORBIDDEN,
        )

    try:
        paciente = Paciente.objects.get(usuario=request.user)
    except Paciente.DoesNotExist:
        return Response(
            {"error": "No tienes un perfil de paciente creado todavía."},
            status=status.HTTP_404_NOT_FOUND,
        )

    serializer = PacienteSerializer(paciente, context={'request': request})
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def listar_pacientes(request):
    if not es_doctor(request.user):
        return Response(
            {"error": "No tienes permisos de Doctor."},
            status=status.HTTP_403_FORBIDDEN,
        )

    pacientes = (
        Paciente.objects
        .filter(doctor=request.user)
        .select_related('usuario', 'usuario__perfil')
        .prefetch_related('historial_controles', 'historiales_clinicos', 'arritmias')
        .order_by('-fecha_registro')
    )
    serializer = PacienteSerializer(
        pacientes,
        many=True,
        context={'request': request},
    )
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def registrar_paciente(request):
    if not es_doctor(request.user):
        return Response(
            {"error": "No tienes permisos de Doctor para registrar pacientes."},
            status=status.HTTP_403_FORBIDDEN,
        )

    email = request.data.get('email', '').strip()
    if not email:
        return Response(
            {"error": "El campo email es requerido."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        usuario_base = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response(
            {"error": "El correo ingresado no corresponde a ningún usuario registrado."},
            status=status.HTTP_404_NOT_FOUND,
        )

    if str(usuario_base.rol).lower() != 'paciente':
        return Response(
            {"error": f"El usuario encontrado tiene rol '{usuario_base.rol}', no 'paciente'."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if Paciente.objects.filter(usuario=usuario_base).exists():
        return Response(
            {"error": "Este usuario ya está registrado como paciente."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        edad  = int(request.data.get('edad', 0))
        peso  = float(request.data.get('peso_inicial', 0))
        talla = float(request.data.get('talla_inicial', 0))
    except (ValueError, TypeError):
        return Response(
            {"error": "Edad, peso y talla deben ser valores numéricos."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    paciente = Paciente.objects.create(
        usuario           = usuario_base,
        doctor            = request.user,
        edad              = edad,
        sexo              = request.data.get('sexo', 'Masculino'),
        peso_inicial      = peso,
        talla_inicial     = talla,
        alergias          = request.data.get('alergias', 'Ninguna'),
        antecedentes_base = request.data.get('antecedentes_base', 'Ninguno'),
        foto              = request.FILES.get('foto'),
    )

    serializer = PacienteSerializer(paciente, context={'request': request})
    return Response(serializer.data, status=status.HTTP_201_CREATED)


import requests

def sincronizar_con_ollama(paciente, tipo_evento, objeto):
    """
    Sincroniza eventos médicos con Ollama (Controles, Arritmias, Exámenes, Tratamientos).
    """
    url = "http://localhost:8001/records"
    
    try:
        perfil = paciente.usuario.perfil
        nombre_paciente = f"{perfil.nombre} {perfil.apellido}".strip()
    except Exception:
        nombre_paciente = paciente.usuario.email

    payload = {
        "paciente": nombre_paciente,
        "ritmo_cardiaco": 0,
        "tipo_arritmia": "N/A",
        "sintomas": "N/A",
        "diagnostico": "N/A",
        "presion_arterial": "N/A",
        "observaciones": ""
    }

    if tipo_evento == 'control':
        def si_no(val): return "Sí" if val else "No"
        payload.update({
            "ritmo_cardiaco": objeto.frecuencia_cardiaca,
            "tipo_arritmia": objeto.diagnostico_ecg,
            "sintomas": f"{objeto.sintomas}. Dolor pecho: {si_no(objeto.dolor_pecho)}, Disnea: {si_no(objeto.disnea)}, Mareos: {si_no(objeto.mareos)}, Edema: {si_no(objeto.edema)}",
            "diagnostico": objeto.evolucion or "Sin evolución registrada",
            "presion_arterial": f"{objeto.presion_sistolica}/{objeto.presion_diastolica} mmHg (SatO2: {objeto.saturacion_oxigeno}%)",
            "observaciones": f"Plan: {objeto.plan_medicacion or 'N/A'}. Próxima cita: {objeto.proxima_cita or 'Sin definir'}"
        })
    
    elif tipo_evento == 'arritmia':
        payload.update({
            "tipo_arritmia": objeto.tipo_arritmia,
            "diagnostico": f"Nivel de Riesgo: {objeto.nivel_riesgo}",
            "sintomas": f"Estado: {objeto.estado}",
            "observaciones": f"Detección de Arritmia: {objeto.observaciones or 'Sin notas'}"
        })

    elif tipo_evento == 'examen':
        payload.update({
            "tipo_arritmia": f"Examen: {objeto.tipo_examen}",
            "diagnostico": f"Resultado: {objeto.resultado or 'Pendiente'}",
            "observaciones": f"Descripción del examen: {objeto.descripcion or 'Sin descripción'}"
        })

    elif tipo_evento == 'tratamiento':
        meds = ", ".join([f"{m.nombre_medicamento} ({m.dosis})" for m in objeto.medicamentos.all()])
        recs = ", ".join([f"{r.tipo_recomendacion}: {r.descripcion}" for r in objeto.recomendaciones.all()])
        payload.update({
            "tipo_arritmia": "Inicio de Tratamiento",
            "diagnostico": f"Medicamentos: {meds if meds else 'Ninguno'}",
            "sintomas": f"Estado: {objeto.estado}",
            "observaciones": f"Recomendaciones: {recs if recs else 'Ninguna'}. Notas: {objeto.observaciones or ''}"
        })

    try:
        requests.post(url, json=payload, timeout=5)
    except Exception as e:
        print(f"Error sincronizando {tipo_evento} con Ollama: {e}")


@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def agregar_control(request, paciente_id):
    if not es_doctor(request.user):
        return Response(
            {"error": "No tienes permisos de Doctor para añadir controles clínicos."},
            status=status.HTTP_403_FORBIDDEN,
        )

    try:
        paciente = Paciente.objects.get(id=paciente_id, doctor=request.user)
    except Paciente.DoesNotExist:
        return Response(
            {"error": "Paciente no encontrado o no pertenece a tu lista."},
            status=status.HTTP_404_NOT_FOUND,
        )

    serializer = ControlCardiologicoSerializer(
        data=request.data,
        context={'request': request},
    )
    if serializer.is_valid():
        instancia = serializer.save(paciente=paciente)
        sincronizar_con_ollama(paciente, 'control', instancia)
        respuesta = ControlCardiologicoSerializer(
            instancia,
            context={'request': request},
        )
        return Response(respuesta.data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


from django.http import HttpResponse
from .utils import generar_pdf_paciente


from rest_framework_simplejwt.tokens import AccessToken
from django.contrib.auth import get_user_model

# ... (otras vistas)

from django.utils import timezone
from datetime import timedelta

# ... (vistas anteriores)

@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def obtener_resumen_dashboard(request):
    if not es_doctor(request.user):
        return Response({"error": "No tienes permisos de Doctor."}, status=status.HTTP_403_FORBIDDEN)

    hoy = timezone.now().date()
    
    # Total de pacientes
    total_pacientes = Paciente.objects.filter(doctor=request.user).count()
    
    # Pacientes con arritmias activas (pacientes únicos)
    pacientes_arritmias_activas = (
        Arritmia.objects
        .filter(doctor=request.user, estado='Activa')
        .values('paciente')
        .distinct()
        .count()
    )
    
    # Alertas recientes (Arritmias con riesgo Alto o Crítico en los últimos 7 días)
    hace_una_semana = hoy - timedelta(days=7)
    alertas_recientes_qs = (
        Arritmia.objects
        .filter(
            doctor=request.user, 
            nivel_riesgo__in=['Alto', 'Crítico'],
            fecha_deteccion__gte=hace_una_semana
        )
        .select_related('paciente__usuario__perfil')
        .order_by('-fecha_deteccion')[:5]
    )
    
    alertas_data = []
    for alerta in alertas_recientes_qs:
        try:
            nombre = f"{alerta.paciente.usuario.perfil.nombre} {alerta.paciente.usuario.perfil.apellido}"
        except:
            nombre = alerta.paciente.usuario.email
            
        alertas_data.append({
            "id": alerta.id,
            "paciente_nombre": nombre,
            "tipo_arritmia": alerta.tipo_arritmia,
            "nivel_riesgo": alerta.nivel_riesgo,
            "fecha": alerta.fecha_deteccion,
        })

    # Próximas consultas (Controles con proxima_cita >= hoy)
    proximas_consultas_qs = (
        ControlCardiologico.objects
        .filter(paciente__doctor=request.user, proxima_cita__gte=hoy)
        .select_related('paciente__usuario__perfil')
        .order_by('proxima_cita')[:5]
    )
    
    consultas_data = []
    for control in proximas_consultas_qs:
        try:
            nombre = f"{control.paciente.usuario.perfil.nombre} {control.paciente.usuario.perfil.apellido}"
        except:
            nombre = control.paciente.usuario.email
            
        consultas_data.append({
            "paciente_nombre": nombre,
            "fecha": control.proxima_cita,
            "motivo": control.diagnostico_ecg,
        })

    # Estadísticas adicionales para gráficas
    from django.db.models import Count
    distribucion_riesgo_qs = (
        Arritmia.objects
        .filter(doctor=request.user)
        .values('nivel_riesgo')
        .annotate(cantidad=Count('id'))
    )
    distribucion_riesgo = [
        {"nivel_riesgo": item['nivel_riesgo'], "cantidad": item['cantidad']}
        for item in distribucion_riesgo_qs
    ]

    distribucion_tipo_qs = (
        Arritmia.objects
        .filter(doctor=request.user)
        .values('tipo_arritmia')
        .annotate(cantidad=Count('id'))
        .order_by('-cantidad')[:5]
    )
    distribucion_tipo = [
        {"tipo_arritmia": item['tipo_arritmia'], "cantidad": item['cantidad']}
        for item in distribucion_tipo_qs
    ]

    return Response({
        "total_pacientes": total_pacientes,
        "arritmias_activas": pacientes_arritmias_activas,
        "total_alertas_recientes": len(alertas_data),
        "alertas_recientes": alertas_data,
        "proximas_consultas": consultas_data,
        "distribucion_riesgo": distribucion_riesgo,
        "distribucion_tipo": distribucion_tipo,
    })


@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def obtener_mis_arritmias(request):
    if not es_paciente(request.user):
        return Response({"error": "Solo para pacientes."}, status=status.HTTP_403_FORBIDDEN)

    try:
        paciente = Paciente.objects.get(usuario=request.user)
    except Paciente.DoesNotExist:
        return Response({"error": "Perfil no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    arritmias = paciente.arritmias.all().order_by('-fecha_deteccion')
    serializer = ArritmiaSerializer(arritmias, many=True, context={'request': request})
    return Response(serializer.data)


@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def obtener_mis_examenes(request):
    if not es_paciente(request.user):
        return Response({"error": "Solo para pacientes."}, status=status.HTTP_403_FORBIDDEN)

    try:
        paciente = Paciente.objects.get(usuario=request.user)
    except Paciente.DoesNotExist:
        return Response({"error": "Perfil no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    examenes = paciente.examenes_medicos.all().order_by('-fecha_examen')
    serializer = ExamenMedicoSerializer(examenes, many=True, context={'request': request})
    return Response(serializer.data)


@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def obtener_mis_tratamientos(request):
    if not es_paciente(request.user):
        return Response({"error": "Solo para pacientes."}, status=status.HTTP_403_FORBIDDEN)

    try:
        paciente = Paciente.objects.get(usuario=request.user)
    except Paciente.DoesNotExist:
        return Response({"error": "Perfil no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    # Obtenemos tratamientos con prefetch_related para eficiencia
    tratamientos = (
        paciente.tratamientos.all()
        .prefetch_related('medicamentos', 'recomendaciones')
        .order_by('-fecha_inicio')
    )
    serializer = TratamientoSerializer(tratamientos, many=True, context={'request': request})
    return Response(serializer.data)


# --- Gestión de Reportes PDF ---





@api_view(['GET'])
@permission_classes([]) # Permitimos el acceso para validar el token manualmente
@authentication_classes([])
def descargar_reporte_paciente(request, paciente_id):
    # Intentamos obtener el token del header o de la URL
    token_str = request.query_params.get('token')
    
    if not token_str:
        return Response({"error": "Credenciales no proporcionadas."}, status=status.HTTP_401_UNAUTHORIZED)

    try:
        # Validar el token manualmente
        access_token = AccessToken(token_str)
        user_id = access_token['user_id']
        User = get_user_model()
        user = User.objects.get(id=user_id)
        
        if not es_doctor(user):
            return Response({"error": "No tienes permisos de Doctor."}, status=status.HTTP_403_FORBIDDEN)
            
        paciente = Paciente.objects.get(id=paciente_id, doctor=user)
        
        pdf_content = generar_pdf_paciente(paciente, user)
        
        response = HttpResponse(pdf_content, content_type='application/pdf')
        filename = f"reporte_{paciente.usuario.email}_{datetime.now().strftime('%Y%m%d')}.pdf"
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        
        return response
        
    except Exception as e:
        return Response({"error": f"Token inválido o expirado. {str(e)}"}, status=status.HTTP_401_UNAUTHORIZED)


# --- Gestión de Tratamientos CRUD ---

@api_view(['GET', 'POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def gestionar_tratamientos_paciente(request, paciente_id):
    if not es_doctor(request.user):
        return Response({"error": "No tienes permisos de Doctor."}, status=status.HTTP_403_FORBIDDEN)

    try:
        paciente = Paciente.objects.get(id=paciente_id, doctor=request.user)
    except Paciente.DoesNotExist:
        return Response({"error": "Paciente no encontrado o no pertenece a tu lista."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        tratamientos = paciente.tratamientos.all()
        serializer = TratamientoSerializer(tratamientos, many=True, context={'request': request})
        return Response(serializer.data)

    elif request.method == 'POST':
        serializer = TratamientoSerializer(data=request.data)
        if serializer.is_valid():
            instancia = serializer.save(paciente=paciente, doctor=request.user)
            sincronizar_con_ollama(paciente, 'tratamiento', instancia)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT', 'DELETE'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def detalle_tratamiento(request, pk):
    if not es_doctor(request.user):
        return Response({"error": "No tienes permisos de Doctor."}, status=status.HTTP_403_FORBIDDEN)

    try:
        tratamiento = Tratamiento.objects.get(id=pk, doctor=request.user)
    except Tratamiento.DoesNotExist:
        return Response({"error": "Tratamiento no encontrado o no tienes permiso."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = TratamientoSerializer(tratamiento, context={'request': request})
        return Response(serializer.data)

    elif request.method == 'PUT':
        serializer = TratamientoSerializer(tratamiento, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        tratamiento.delete()
        return Response({"mensaje": "Tratamiento eliminado."}, status=status.HTTP_200_OK)
