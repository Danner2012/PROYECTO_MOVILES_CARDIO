# backend/pacientes/views.py
from rest_framework import status
from rest_framework.decorators import api_view, authentication_classes, permission_classes, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from .models import Paciente, ControlCardiologico, HistorialClinico
from .serializers import PacienteSerializer, ControlCardiologicoSerializer, HistorialClinicoSerializer

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
        historiales = paciente.historiales_clinicos.all()
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
        historial.delete()
        return Response({"mensaje": "Registro eliminado correctamente."}, status=status.HTTP_204_NO_CONTENT)


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
        .prefetch_related('historial_controles')
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
@parser_classes([MultiPartParser, FormParser, JSONParser])  # ← permite multipart
def registrar_paciente(request):
    if not es_doctor(request.user):
        return Response(
            {"error": "No tienes permisos de Doctor para registrar pacientes."},
            status=status.HTTP_403_FORBIDDEN,
        )

    # Con multipart, los datos vienen en request.data, incluso los archivos
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
        foto              = request.FILES.get('foto'),   # ← guardamos la foto si viene
    )

    serializer = PacienteSerializer(paciente, context={'request': request})
    return Response(serializer.data, status=status.HTTP_201_CREATED)


import requests

def sincronizar_con_ollama(paciente, control):
    """Sincroniza el nuevo control con la base de datos de Ollama incluyendo todos los datos clínicos."""
    url = "http://localhost:8001/records"
    
    # Obtener nombre del perfil
    try:
        perfil = paciente.usuario.perfil
        nombre_paciente = f"{perfil.nombre} {perfil.apellido}".strip()
    except Exception:
        nombre_paciente = paciente.usuario.email

    # Formatear booleanos para que la IA los entienda mejor
    def si_no(val): return "Sí" if val else "No"
    
    payload = {
        "paciente": nombre_paciente,
        "ritmo_cardiaco": control.frecuencia_cardiaca,
        "tipo_arritmia": control.diagnostico_ecg,
        "sintomas": f"{control.sintomas}. Dolor pecho: {si_no(control.dolor_pecho)}, Disnea: {si_no(control.disnea)}, Mareos: {si_no(control.mareos)}, Edema: {si_no(control.edema)}",
        "diagnostico": control.evolucion or "Sin evolución registrada",
        "presion_arterial": f"{control.presion_sistolica}/{control.presion_diastolica} mmHg (SatO2: {control.saturacion_oxigeno}%)",
        "observaciones": f"Plan: {control.plan_medicacion or 'N/A'}. Próxima cita: {control.proxima_cita or 'Sin definir'}"
    }
    try:
        requests.post(url, json=payload, timeout=5)
    except Exception as e:
        print(f"Error sincronizando con Ollama: {e}")


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
        
        # Sincronizar con la IA
        sincronizar_con_ollama(paciente, instancia)

        respuesta = ControlCardiologicoSerializer(
            instancia,
            context={'request': request},
        )
        return Response(respuesta.data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
