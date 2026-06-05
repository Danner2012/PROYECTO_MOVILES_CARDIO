# backend/pacientes/views.py

from rest_framework import status
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.response import Response
from django.contrib.auth import get_user_model
import asyncio
from .models import Paciente, ControlCardiologico
from .serializers import PacienteSerializer, ControlCardiologicoSerializer
from infrastructure.ollama_client import get_cardio_explanation

User = get_user_model()


def es_doctor(usuario):
    """
    rol es ForeignKey a Role cuyo __str__ devuelve role.nombre.
    Comparamos el nombre del rol en minúsculas.
    """
    try:
        return str(usuario.rol).lower() == 'doctor'
    except Exception:
        return False


def es_paciente(usuario):
    try:
        return str(usuario.rol).lower() == 'paciente'
    except Exception:
        return False


@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def obtener_mis_controles(request):
    if not es_paciente(request.user):
        return Response(
            {"error": "Este endpoint es solo para pacientes."},
            status=status.HTTP_403_FORBIDDEN,
        )

    try:
        paciente = Paciente.objects.get(usuario=request.user)
    except Paciente.DoesNotExist:
        return Response(
            {"error": "No se encontró un perfil de paciente para este usuario."},
            status=status.HTTP_404_NOT_FOUND,
        )

    controles = ControlCardiologico.objects.filter(paciente=paciente).order_by('-fecha')
    serializer = ControlCardiologicoSerializer(controles, many=True)
    data = serializer.data

    # Enriquecer con IA de forma asíncrona (opcionalmente podríamos hacerlo uno por uno o en batch)
    # Por simplicidad y para no bloquear demasiado, lo haremos para todos los controles
    # En un entorno real, esto podría cachearse.
    
    async def enriquecer_controles(controles_data):
        tasks = []
        for c in controles_data:
            sintomas = c.get('sintomas', 'Ninguno')
            diagnostico = c.get('diagnostico_ecg', 'Pendiente')
            tasks.append(get_cardio_explanation(sintomas, diagnostico))
        
        explicaciones = await asyncio.gather(*tasks)
        for i, c in enumerate(controles_data):
            c['explicacion_ia'] = explicaciones[i]

    # Ejecutar la parte asíncrona
    asyncio.run(enriquecer_controles(data))

    return Response(data, status=status.HTTP_200_OK)


@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def listar_pacientes(request):
    if not es_doctor(request.user):
        return Response(
            {"error": "No tienes permisos de Doctor."},
            status=status.HTTP_403_FORBIDDEN,
        )
    pacientes = Paciente.objects.filter(
        doctor=request.user
    ).select_related('usuario', 'usuario__perfil').order_by('-fecha_registro')

    serializer = PacienteSerializer(pacientes, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
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

    # Buscar usuario por email
    try:
        usuario_base = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response(
            {"error": "El correo ingresado no corresponde a ningún usuario registrado."},
            status=status.HTTP_404_NOT_FOUND,
        )

    # Verificar que tenga rol paciente
    if str(usuario_base.rol).lower() != 'paciente':
        return Response(
            {"error": f"El usuario encontrado tiene rol '{usuario_base.rol}', no 'paciente'."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Verificar que no esté ya registrado
    if Paciente.objects.filter(usuario=usuario_base).exists():
        return Response(
            {"error": "Este usuario ya está registrado como paciente."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Validar campos numéricos
    try:
        edad        = int(request.data.get('edad', 0))
        peso        = float(request.data.get('peso_inicial', 0))
        talla       = float(request.data.get('talla_inicial', 0))
    except (ValueError, TypeError):
        return Response(
            {"error": "Edad, peso y talla deben ser valores numéricos."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    paciente = Paciente.objects.create(
        usuario      = usuario_base,
        doctor       = request.user,          # ✅ asigna el doctor logueado
        edad         = edad,
        sexo         = request.data.get('sexo', 'Masculino'),
        peso_inicial = peso,
        talla_inicial= talla,
    )

    serializer = PacienteSerializer(paciente)
    return Response(serializer.data, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
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

    serializer = ControlCardiologicoSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save(paciente=paciente)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
