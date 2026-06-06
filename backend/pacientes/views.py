# backend/pacientes/views.py

from rest_framework import status
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db import connections # <--- Importante para la base de datos secundaria
from .models import Paciente
from .serializers import PacienteSerializer, ControlCardiologicoSerializer

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

# =========================================================================
# ENDPOINT ADAPTADO A LAS COLUMNAS REALES DE REGISTROS_ECG
# =========================================================================
@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def obtener_metricas_ecg(request):
    """
    Extrae el historial de telemetría directamente desde las columnas reales
    de 'registros_ecg' en 'ecg_db'.
    """
    try:
        with connections['ecg_db'].cursor() as cursor:
            # Consultamos las columnas reales según tu esquema de pgAdmin
            query = """
                SELECT 
                    id, 
                    bpm, 
                    bpm_average, 
                    hrv, 
                    beat_detected, 
                    electrodes_connected, 
                    created_at 
                FROM registros_ecg 
                ORDER BY id DESC 
                LIMIT 50;
            """
            cursor.execute(query)
            
            columnas = [col[0] for col in cursor.description]
            resultados = [dict(zip(columnas, fila)) for fila in cursor.fetchall()]

        datos_formateados = []
        for registro in resultados:
            dt = registro.get("created_at")
            # Extraemos fecha y hora del timestamp con zona horaria (created_at)
            fecha_str = dt.strftime("%d/%m/%Y") if hasattr(dt, "strftime") else str(dt or "")
            hora_str = dt.strftime("%H:%M:%S") if hasattr(dt, "strftime") else str(dt or "")
            
            datos_formateados.append({
                "id": str(registro.get("id", "")),
                "fecha": fecha_str,
                "hora": hora_str,
                "bpm": str(registro.get("bpm", "0")),
                "bpm_average": str(registro.get("bpm_average", "0")),
                "hrv": str(registro.get("hrv", "0")),
                "beat_detected": "Sí" if registro.get("beat_detected") is True else "No",
                "electrodes_connected": "Conectado" if registro.get("electrodes_connected") is True else "Desconectado",
                "estado": "Normal" if float(registro.get("bpm", 0)) <= 100 else "Taquicardia"
            })

        return Response(datos_formateados, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {"error": f"Error en la consulta de registros_ecg: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )