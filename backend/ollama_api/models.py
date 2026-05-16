from sqlalchemy import Column, Integer, String, Text, DateTime
from datetime import datetime
from database import Base

class CardioRecord(Base):
    __tablename__ = "cardio_records"

    id = Column(Integer, primary_key=True, index=True)
    paciente = Column(String, index=True)
    ritmo_cardiaco = Column(Integer)
    tipo_arritmia = Column(String)
    sintomas = Column(String)
    diagnostico = Column(String)
    presion_arterial = Column(String)
    fecha_registro = Column(DateTime, default=datetime.utcnow)
    observaciones = Column(Text)
