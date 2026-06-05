# backend/pacientes/serializers.py

from rest_framework import serializers
from .models import Paciente, ControlCardiologico


class ControlCardiologicoSerializer(serializers.ModelSerializer):
    class Meta:
        model = ControlCardiologico
        fields = [
            'id', 'fecha', 'presion_sistolica', 'presion_diastolica',
            'frecuencia_cardiaca', 'saturacion_oxigeno', 'sintomas', 'diagnostico_ecg',
        ]


class PacienteSerializer(serializers.ModelSerializer):
    # ✅ El nombre viene de usuario.perfil.nombre (modelo Perfil separado)
    nombre = serializers.SerializerMethodField()
    email  = serializers.CharField(source='usuario.email', read_only=True)
    historial_controles = ControlCardiologicoSerializer(many=True, read_only=True)

    class Meta:
        model = Paciente
        fields = [
            'id', 'nombre', 'email', 'edad', 'sexo',
            'peso_inicial', 'talla_inicial', 'historial_controles',
        ]

    def get_nombre(self, obj):
        # Intenta obtener el nombre desde el Perfil; si no existe devuelve el email
        try:
            p = obj.usuario.perfil
            return f"{p.nombre} {p.apellido}".strip()
        except Exception:
            return obj.usuario.email
        
        