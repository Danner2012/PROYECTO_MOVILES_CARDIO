# backend/pacientes/views.py
from rest_framework import status
from rest_framework.decorators import api_view, authentication_classes, permission_classes, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from .models import Paciente
from .serializers import PacienteSerializer, ControlCardiologicoSerializer

User = get_user_model()


def es_doctor(usuario):
    try:
        return str(usuario.rol).lower() == 'doctor'
    except Exception:
        return False


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
        respuesta = ControlCardiologicoSerializer(
            instancia,
            context={'request': request},
        )
        return Response(respuesta.data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
