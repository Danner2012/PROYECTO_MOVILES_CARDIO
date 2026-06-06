import uuid
from django.db import models
from django.conf import settings

class Paciente(models.Model):
    SEXO_CHOICES = [
        ('Masculino', 'Masculino'),
        ('Femenino',  'Femenino'),
        ('Otro',      'Otro'),
    ]

    usuario = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='perfil_paciente',
    )
    doctor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='mis_pacientes',
    )
    edad          = models.IntegerField()
    sexo          = models.CharField(max_length=20, choices=SEXO_CHOICES, default='Masculino')
    peso_inicial  = models.DecimalField(max_digits=5, decimal_places=2)
    talla_inicial = models.DecimalField(max_digits=4, decimal_places=2)
    
    alergias = models.TextField(blank=True, default="Ninguna", help_text="Alergias a medicamentos o materiales")
    antecedentes_base = models.TextField(blank=True, default="Ninguno", help_text="Ej: Diabetes, Hipertensión, etc.")
    
    # NUEVO: foto de perfil del paciente
    foto = models.ImageField(upload_to='fotos_pacientes/', null=True, blank=True)

    fecha_registro = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.usuario.email


class ControlCardiologico(models.Model):
    paciente          = models.ForeignKey(Paciente, on_delete=models.CASCADE, related_name='historial_controles')
    fecha             = models.DateTimeField(auto_now_add=True)
    
    presion_sistolica = models.IntegerField()
    presion_diastolica= models.IntegerField()
    frecuencia_cardiaca=models.IntegerField()
    saturacion_oxigeno= models.IntegerField()
    
    sintomas          = models.TextField(blank=True, default="Ninguno")
    evolucion         = models.TextField(blank=True, null=True, help_text="Notas libres de evolución del paciente")
    dolor_pecho       = models.BooleanField(default=False)
    disnea            = models.BooleanField(default=False, help_text="Falta de aire")
    mareos            = models.BooleanField(default=False)
    edema             = models.BooleanField(default=False, help_text="Hinchazón en piernas")
    
    diagnostico_ecg   = models.CharField(max_length=100, default="Pendiente")
    plan_medicacion   = models.TextField(blank=True, null=True, help_text="Fármaco, dosis y frecuencia")
    proxima_cita      = models.DateField(blank=True, null=True)

    archivo_adjunto   = models.FileField(upload_to='adjuntos_medicos/%Y/%m/', blank=True, null=True)
    consentimiento_firmado = models.BooleanField(default=False)

    def __str__(self):
        return f"Control de {self.paciente.usuario.email} - {self.fecha.strftime('%d/%m/%Y')}"


class HistorialClinico(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    paciente = models.ForeignKey(Paciente, on_delete=models.CASCADE, related_name='historiales_clinicos')
    doctor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='historiales_medicos_creados'
    )
    
    fecha_registro = models.DateTimeField()
    motivo_consulta = models.TextField()
    antecedentes_cardiacos = models.TextField(blank=True, null=True)
    antecedentes_familiares = models.TextField(blank=True, null=True)
    enfermedades_previas = models.TextField(blank=True, null=True)
    alergias = models.TextField(blank=True, null=True)
    observaciones_medicas = models.TextField(blank=True, null=True)
    estado_actual = models.CharField(max_length=100)
    activo = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Historial Clínico"
        verbose_name_plural = "Historiales Clínicos"
        ordering = ['-fecha_registro']

    def __str__(self):
        return f"Historial {self.paciente.usuario.email} - {self.fecha_registro.strftime('%d/%m/%Y')}"


class Arritmia(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    paciente = models.ForeignKey(Paciente, on_delete=models.CASCADE, related_name='arritmias')
    doctor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='arritmias_detectadas'
    )
    
    tipo_arritmia = models.CharField(max_length=100)
    fecha_deteccion = models.DateField()
    nivel_riesgo = models.CharField(max_length=50) # Bajo, Medio, Alto, Crítico
    estado = models.CharField(max_length=50) # Activa, En tratamiento, Controlada
    observaciones = models.TextField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Arritmia"
        verbose_name_plural = "Arritmias"
        ordering = ['-fecha_deteccion']

    def __str__(self):
        return f"{self.tipo_arritmia} - {self.paciente.usuario.email}"


class SeguimientoArritmia(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    arritmia = models.ForeignKey(Arritmia, on_delete=models.CASCADE, related_name='seguimientos')
    
    fecha_control = models.DateField()
    frecuencia_cardiaca = models.IntegerField()
    nivel_riesgo = models.CharField(max_length=50)
    estado = models.CharField(max_length=50)
    observaciones = models.TextField(blank=True, null=True)
    
    registrado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='seguimientos_arritmias_realizados'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Seguimiento de Arritmia"
        verbose_name_plural = "Seguimientos de Arritmias"
        ordering = ['-fecha_control']

    def __str__(self):
        return f"Control {self.fecha_control} - {self.arritmia.tipo_arritmia}"
