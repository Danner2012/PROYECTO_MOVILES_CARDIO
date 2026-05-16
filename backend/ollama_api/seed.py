from sqlalchemy.orm import Session
from database import SessionLocal, engine, Base
import models
import schemas
import crud

# Crear tablas
models.Base.metadata.create_all(bind=engine)

def seed_data():
    db = SessionLocal()
    
    # Datos de ejemplo
    records = [
        {
            "paciente": "Juan Pérez",
            "ritmo_cardiaco": 110,
            "tipo_arritmia": "Taquicardia Sinusal",
            "sintomas": "Palpitaciones, fatiga",
            "diagnostico": "Taquicardia por estrés",
            "presion_arterial": "130/85",
            "observaciones": "Paciente requiere reposo y monitoreo."
        },
        {
            "paciente": "María García",
            "ritmo_cardiaco": 45,
            "tipo_arritmia": "Bradicardia Sinusal",
            "sintomas": "Mareos, desmayos",
            "diagnostico": "Bradicardia severa",
            "presion_arterial": "100/60",
            "observaciones": "Considerar uso de marcapasos."
        },
        {
            "paciente": "Carlos López",
            "ritmo_cardiaco": 160,
            "tipo_arritmia": "Fibrilación Auricular",
            "sintomas": "Dificultad para respirar, dolor de pecho",
            "diagnostico": "FA paroxística",
            "presion_arterial": "140/90",
            "observaciones": "Iniciar tratamiento con anticoagulantes."
        },
        {
            "paciente": "Ana Martínez",
            "ritmo_cardiaco": 72,
            "tipo_arritmia": "Ritmo Sinusal Normal",
            "sintomas": "Ninguno",
            "diagnostico": "Corazón sano",
            "presion_arterial": "120/80",
            "observaciones": "Control rutinario anual."
        },
        {
            "paciente": "Luis Rodríguez",
            "ritmo_cardiaco": 95,
            "tipo_arritmia": "Extrasístoles Ventriculares",
            "sintomas": "Vuelcos en el corazón",
            "diagnostico": "Arritmia benigna",
            "presion_arterial": "125/82",
            "observaciones": "Reducir consumo de cafeína."
        },
        {
            "paciente": "Elena Sánchez",
            "ritmo_cardiaco": 130,
            "tipo_arritmia": "Flutter Auricular",
            "sintomas": "Debilidad extrema",
            "diagnostico": "Flutter auricular tipo I",
            "presion_arterial": "115/75",
            "observaciones": "Programar ablación por radiofrecuencia."
        },
        {
            "paciente": "Pedro Gómez",
            "ritmo_cardiaco": 55,
            "tipo_arritmia": "Bloqueo AV de segundo grado",
            "sintomas": "Síncope ocasional",
            "diagnostico": "Bloqueo Mobitz II",
            "presion_arterial": "110/70",
            "observaciones": "Urgencia para colocación de marcapasos."
        },
        {
            "paciente": "Sofía Torres",
            "ritmo_cardiaco": 180,
            "tipo_arritmia": "Taquicardia Supraventricular",
            "sintomas": "Ahogo agudo",
            "diagnostico": "TSV paroxística",
            "presion_arterial": "150/95",
            "observaciones": "Maniobras vagales fallidas, requiere adenosina."
        },
        {
            "paciente": "Jorge Ramírez",
            "ritmo_cardiaco": 85,
            "tipo_arritmia": "Síndrome de Wolff-Parkinson-White",
            "sintomas": "Mareos repentinos",
            "diagnostico": "WPW confirmado por EKG",
            "presion_arterial": "122/78",
            "observaciones": "Paciente joven, deportista."
        },
        {
            "paciente": "Carmen Ruiz",
            "ritmo_cardiaco": 60,
            "tipo_arritmia": "Bradicardia por medicamentos",
            "sintomas": "Somnolencia",
            "diagnostico": "Efecto secundario de betabloqueantes",
            "presion_arterial": "105/65",
            "observaciones": "Ajustar dosis de Bisoprolol."
        }
    ]

    for r in records:
        crud.create_cardio_record(db, schemas.CardioCreate(**r))
    
    db.close()
    print("Base de datos sembrada con éxito.")

if __name__ == "__main__":
    seed_data()
