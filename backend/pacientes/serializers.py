# backend/pacientes/serializers.py
from rest_framework import serializers
from .models import Paciente, ControlCardiologico, HistorialClinico, Arritmia, SeguimientoArritmia, ExamenMedico, Tratamiento, MedicamentoTratamiento, Recomendacion


class MedicamentoTratamientoSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedicamentoTratamiento
        fields = ['id', 'nombre_medicamento', 'dosis', 'frecuencia', 'duracion', 'observaciones']


class RecomendacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recomendacion
        fields = ['id', 'tipo_recomendacion', 'descripcion']


class TratamientoSerializer(serializers.ModelSerializer):
    medicamentos = MedicamentoTratamientoSerializer(many=True)
    recomendaciones = RecomendacionSerializer(many=True)

    class Meta:
        model = Tratamiento
        fields = [
            'id', 'paciente', 'doctor', 'fecha_inicio', 'fecha_fin', 
            'estado', 'observaciones', 'medicamentos', 'recomendaciones',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'paciente', 'doctor', 'created_at', 'updated_at']

    def create(self, validated_data):
        medicamentos_data = validated_data.pop('medicamentos')
        recomendaciones_data = validated_data.pop('recomendaciones')
        
        tratamiento = Tratamiento.objects.create(**validated_data)
        
        for med_data in medicamentos_data:
            MedicamentoTratamiento.objects.create(tratamiento=tratamiento, **med_data)
            
        for rec_data in recomendaciones_data:
            Recomendacion.objects.create(tratamiento=tratamiento, **rec_data)
            
        return tratamiento

    def update(self, instance, validated_data):
        medicamentos_data = validated_data.pop('medicamentos', None)
        recomendaciones_data = validated_data.pop('recomendaciones', None)
        
        # Actualizar campos básicos
        instance.fecha_inicio = validated_data.get('fecha_inicio', instance.fecha_inicio)
        instance.fecha_fin = validated_data.get('fecha_fin', instance.fecha_fin)
        instance.estado = validated_data.get('estado', instance.estado)
        instance.observaciones = validated_data.get('observaciones', instance.observaciones)
        instance.save()
        
        # Si se envían medicamentos/recomendaciones, reemplazamos los existentes (lógica simple)
        if medicamentos_data is not None:
            instance.medicamentos.all().delete()
            for med_data in medicamentos_data:
                MedicamentoTratamiento.objects.create(tratamiento=instance, **med_data)
                
        if recomendaciones_data is not None:
            instance.recomendaciones.all().delete()
            for rec_data in recomendaciones_data:
                Recomendacion.objects.create(tratamiento=instance, **rec_data)
                
        return instance


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
    tratamientos = serializers.SerializerMethodField()

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
            'tratamientos',
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

    def get_tratamientos(self, obj):
        # Usamos el related_name definido en el modelo
        tratamientos = obj.tratamientos.all().order_by('-fecha_inicio')
        return TratamientoSerializer(tratamientos, many=True, context=self.context).data