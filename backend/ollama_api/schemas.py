from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class CardioBase(BaseModel):
    paciente: Optional[str] = None
    ritmo_cardiaco: Optional[int] = None
    tipo_arritmia: Optional[str] = None
    sintomas: Optional[str] = None
    diagnostico: Optional[str] = None
    presion_arterial: Optional[str] = None
    observaciones: Optional[str] = None

class CardioCreate(CardioBase):
    pass

class CardioUpdate(CardioBase):
    pass

class CardioResponse(CardioBase):
    id: int
    fecha_registro: datetime

    class Config:
        from_attributes = True

class ChatRequest(BaseModel):
    question: str

class ChatResponse(BaseModel):
    answer: str
    matched_records: Optional[List[CardioResponse]] = []
