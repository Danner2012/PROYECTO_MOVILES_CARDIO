# backend/pacientes/models.py
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
    