from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Role, Perfil

User = get_user_model()

from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # Añadir claims personalizados
        token['email'] = user.email
        token['rol'] = user.rol.nombre
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        # Añadir datos adicionales a la respuesta del login usando el UserSerializer
        user_serializer = UserSerializer(self.user)
        data['user'] = user_serializer.data
        return data

class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Role
        fields = ['id', 'nombre']

class PerfilSerializer(serializers.ModelSerializer):
    class Meta:
        model = Perfil
        fields = ['nombre', 'apellido', 'fecha_nacimiento', 'genero', 'telefono', 'direccion', 'foto']

class UserSerializer(serializers.ModelSerializer):
    perfil = PerfilSerializer()
    rol_nombre = serializers.ReadOnlyField(source='rol.nombre')

    class Meta:
        model = User
        fields = ['id', 'email', 'rol', 'rol_nombre', 'estado', 'perfil']

class RegisterSerializer(serializers.ModelSerializer):
    nombre = serializers.CharField(write_only=True)
    apellido = serializers.CharField(write_only=True)
    rol_nombre = serializers.CharField(write_only=True) # 'doctor' o 'paciente'

    class Meta:
        model = User
        fields = ['email', 'password', 'nombre', 'apellido', 'rol_nombre']
        extra_kwargs = {'password': {'write_only': True}}

    def validate_rol_nombre(self, value):
        if value != 'paciente':
            raise serializers.ValidationError("Actualmente solo se permite el registro de 'paciente'.")
        return value

    def create(self, validated_data):
        nombre = validated_data.pop('nombre')
        apellido = validated_data.pop('apellido')
        rol_nombre = validated_data.pop('rol_nombre')
        
        try:
            role = Role.objects.get(nombre=rol_nombre)
        except Role.DoesNotExist:
            raise serializers.ValidationError({"rol_nombre": "El rol especificado no existe."})

        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            rol=role
        )
        
        Perfil.objects.create(
            usuario=user,
            nombre=nombre,
            apellido=apellido
        )
        
        return user
