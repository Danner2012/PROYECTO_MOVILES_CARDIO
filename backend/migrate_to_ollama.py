import os
import django
import requests
import sys

# Configurar entorno de Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from pacientes.models import Paciente, ControlCardiologico

def migrate_data():
    print("Iniciando migración de datos a Ollama API...")
    controles = ControlCardiologico.objects.all()
    count = 0
    
    for c in controles:
        paciente = c.paciente
        try:
            perfil = paciente.usuario.perfil
            nombre_paciente = f"{perfil.nombre} {perfil.apellido}".strip()
        except:
            nombre_paciente = paciente.usuario.email
            
        def si_no(val): return "Sí" if val else "No"
        
        payload = {
            "paciente": nombre_paciente,
            "ritmo_cardiaco": c.frecuencia_cardiaca,
            "tipo_arritmia": c.diagnostico_ecg,
            "sintomas": f"{c.sintomas}. Dolor pecho: {si_no(c.dolor_pecho)}, Disnea: {si_no(c.disnea)}, Mareos: {si_no(c.mareos)}, Edema: {si_no(c.edema)}",
            "diagnostico": c.evolucion or "Sin evolución registrada",
            "presion_arterial": f"{c.presion_sistolica}/{c.presion_diastolica} mmHg (SatO2: {c.saturacion_oxigeno}%)",
            "observaciones": f"Plan: {c.plan_medicacion or 'N/A'}. Próxima cita: {c.proxima_cita or 'Sin definir'}"
        }
        
        try:
            r = requests.post("http://localhost:8001/records", json=payload)
            if r.status_code == 200 or r.status_code == 201:
                count += 1
        except Exception as e:
            print(f"Error migrando registro {c.id}: {e}")
            
    print(f"Migración completada. Se sincronizaron {count} registros.")

if __name__ == "__main__":
    migrate_data()
