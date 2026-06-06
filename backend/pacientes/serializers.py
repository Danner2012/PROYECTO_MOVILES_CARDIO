# backend/pacientes/serializers.py
from rest_framework import serializers
from .models import Paciente, ControlCardiologico, HistorialClinico, Arritmia, SeguimientoArritmia, ExamenMedico


class ExamenMedicoSerializer(serializers.ModelSerializer):
    archivo_adjunto = serializers.FileField(use_url=True, required=False, allow_null=True)

    class Meta:
        model = ExamenMedico
        fields = [
            'id',
            'paciente',
            'doctor',
            'tipo_examen',
            'fecha_examen',
            'resultado',
            'descripcion',
            'archivo_adjunto',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'paciente', 'doctor', 'created_at', 'updated_at']


class ControlCardiologicoSerializer(serializers.ModelSerializer):
# ... (sin cambios)
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


class HistorialClinicoSerializer(serializers.ModelSerializer):
# ... (sin cambios)
    class Meta:
        model = HistorialClinico
        fields = [
            'id',
            'paciente',
            'doctor',
            'fecha_registro',
            'motivo_consulta',
            'antecedentes_cardiacos',
            'antecedentes_familiares',
            'enfermedades_previas',
            'alergias',
            'observaciones_medicas',
            'estado_actual',
            'activo',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'paciente', 'doctor', 'activo', 'created_at', 'updated_at']


class SeguimientoArritmiaSerializer(serializers.ModelSerializer):
    registrado_por_nombre = serializers.SerializerMethodField()

    class Meta:
        model = SeguimientoArritmia
        fields = [
            'id',
            'arritmia',
            'fecha_control',
            'frecuencia_cardiaca',
            'nivel_riesgo',
            'estado',
            'observaciones',
            'registrado_por',
            'registrado_por_nombre',
            'created_at',
        ]
        read_only_fields = ['id', 'arritmia', 'registrado_por', 'created_at']

    def get_registrado_por_nombre(self, obj):
        if obj.registrado_por and hasattr(obj.registrado_por, 'perfil'):
            return f"{obj.registrado_por.perfil.nombre} {obj.registrado_por.perfil.apellido}".strip()
        return obj.registrado_por.email if obj.registrado_por else "N/A"


class ArritmiaSerializer(serializers.ModelSerializer):
    seguimientos = SeguimientoArritmiaSerializer(many=True, read_only=True)

    class Meta:
        model = Arritmia
        fields = [
            'id',
            'paciente',
            'doctor',
            'tipo_arritmia',
            'fecha_deteccion',
            'nivel_riesgo',
            'estado',
            'observaciones',
            'seguimientos',
            'created_at',
        ]
        read_only_fields = ['id', 'paciente', 'doctor', 'created_at']


class PacienteSerializer(serializers.ModelSerializer):
    nombre = serializers.SerializerMethodField()
    email  = serializers.CharField(source='usuario.email', read_only=True)
    historial_controles = serializers.SerializerMethodField()
    historiales_clinicos = serializers.SerializerMethodField()
    arritmias = serializers.SerializerMethodField()
    examenes_medicos = serializers.SerializerMethodField()

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
            'historiales_clinicos',
            'arritmias',
            'examenes_medicos',
            'foto',
        ]

    def get_nombre(self, obj):
        try:
            p = obj.usuario.perfil
            return f"{p.nombre} {p.apellido}".strip()
        except Exception:
            return obj.usuario.email

    def get_historial_controles(self, obj):
        # Usamos el related_name definido en el modelo
        controles = obj.historial_controles.all().order_by('-fecha')
        return ControlCardiologicoSerializer(controles, many=True, context=self.context).data

    def get_historiales_clinicos(self, obj):
        # Usamos el related_name definido en el modelo y filtramos activos
        historiales = obj.historiales_clinicos.filter(activo=True).order_by('-fecha_registro')
        return HistorialClinicoSerializer(historiales, many=True, context=self.context).data

    def get_arritmias(self, obj):
        # Usamos el related_name definido en el modelo
        arritmias = obj.arritmias.all().order_by('-fecha_deteccion')
        return ArritmiaSerializer(arritmias, many=True, context=self.context).data

    def get_examenes_medicos(self, obj):
        # Usamos el related_name definido en el modelo
        examenes = obj.examenes_medicos.all().order_by('-fecha_examen')
        return ExamenMedicoSerializer(examenes, many=True, context=self.context).data