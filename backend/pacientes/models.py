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
    fecha_registro= models.DateTimeField(auto_now_add=True)

    def __str__(self):
        # ✅ Usa email — nombre está en Perfil, no en User
        return self.usuario.email


class ControlCardiologico(models.Model):
    paciente          = models.ForeignKey(Paciente, on_delete=models.CASCADE, related_name='historial_controles')
    fecha             = models.DateTimeField(auto_now_add=True)
    presion_sistolica = models.IntegerField()
    presion_diastolica= models.IntegerField()
    frecuencia_cardiaca=models.IntegerField()
    saturacion_oxigeno= models.IntegerField()
    sintomas          = models.TextField(blank=True, default="Ninguno")
    diagnostico_ecg   = models.CharField(max_length=100, default="Pendiente")

    def __str__(self):
        return f"Control de {self.paciente.usuario.email} - {self.fecha.strftime('%d/%m/%Y')}"
    
    