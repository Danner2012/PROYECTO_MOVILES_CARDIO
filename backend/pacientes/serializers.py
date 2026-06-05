# backend/pacientes/serializers.py
from rest_framework import serializers
from .models import Paciente, ControlCardiologico


class ControlCardiologicoSerializer(serializers.ModelSerializer):
    archivo_adjunto = serializers.FileField(
        use_url=True,
        required=False,
        allow_null=True,
    )

    class Meta:
        model  = ControlCardiologico
        fields = [
            'id',
            'fecha',
            'presion_sistolica',
            'presion_diastolica',
            'frecuencia_cardiaca',
            'saturacion_oxigeno',
            'sintomas',
            'evolucion',
            'dolor_pecho',
            'disnea',
            'mareos',
            'edema',
            'diagnostico_ecg',
            'plan_medicacion',
            'proxima_cita',
            'archivo_adjunto',
            'consentimiento_firmado',
        ]


class PacienteSerializer(serializers.ModelSerializer):
    nombre = serializers.SerializerMethodField()
    email  = serializers.CharField(source='usuario.email', read_only=True)
    historial_controles = serializers.SerializerMethodField()

    # NUEVO: campo de foto con URL absoluta
    foto = serializers.ImageField(use_url=True, required=False, allow_null=True)

    class Meta:
        model  = Paciente
        fields = [
            'id',
            'nombre',
            'email',
            'edad',
            'sexo',
            'peso_inicial',
            'talla_inicial',
            'alergias',
            'antecedentes_base',
            'fecha_registro',
            'historial_controles',
            'foto',   # ← nuevo campo
        ]

    def get_nombre(self, obj):
        try:
            p = obj.usuario.perfil
            return f"{p.nombre} {p.apellido}".strip()
        except Exception:
            return obj.usuario.email

    def get_historial_controles(self, obj):
        controles = obj.historial_controles.all()
        return ControlCardiologicoSerializer(
            controles,
            many=True,
            context=self.context,
        ).data
    