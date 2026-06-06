from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, ForeignKey, Numeric, Date
from sqlalchemy.orm import relationship
from database import Base
import uuid

class Role(Base):
    __tablename__ = "users_role"
    id = Column(String, primary_key=True)
    nombre = Column(String)

class User(Base):
    __tablename__ = "users_user"
    id = Column(String, primary_key=True)
    email = Column(String, unique=True)
    rol_id = Column(String, ForeignKey("users_role.id"))
    
    perfil = relationship("Perfil", back_populates="usuario", uselist=False)

class Perfil(Base):
    __tablename__ = "users_perfil"
    id = Column(String, primary_key=True)
    usuario_id = Column(String, ForeignKey("users_user.id"))
    nombre = Column(String)
    apellido = Column(String)
    
    usuario = relationship("User", back_populates="perfil")

class Paciente(Base):
    __tablename__ = "pacientes_paciente"
    id = Column(Integer, primary_key=True)
    usuario_id = Column(String, ForeignKey("users_user.id"))
    edad = Column(Integer)
    sexo = Column(String)
    peso_inicial = Column(Numeric)
    talla_inicial = Column(Numeric)
    alergias = Column(Text)
    antecedentes_base = Column(Text)
    
    usuario = relationship("User")

class ControlCardiologico(Base):
    __tablename__ = "pacientes_controlcardiologico"
    id = Column(Integer, primary_key=True)
    paciente_id = Column(Integer, ForeignKey("pacientes_paciente.id"))
    fecha = Column(DateTime)
    presion_sistolica = Column(Integer)
    presion_diastolica = Column(Integer)
    frecuencia_cardiaca = Column(Integer)
    saturacion_oxigeno = Column(Integer)
    sintomas = Column(Text)
    evolucion = Column(Text)
    diagnostico_ecg = Column(String)
    plan_medicacion = Column(Text)

class Arritmia(Base):
    __tablename__ = "pacientes_arritmia"
    id = Column(String, primary_key=True) # UUID
    paciente_id = Column(Integer, ForeignKey("pacientes_paciente.id"))
    tipo_arritmia = Column(String)
    fecha_deteccion = Column(Date)
    nivel_riesgo = Column(String)
    estado = Column(String)
    observaciones = Column(Text)

class Tratamiento(Base):
    __tablename__ = "pacientes_tratamiento"
    id = Column(String, primary_key=True) # UUID
    paciente_id = Column(Integer, ForeignKey("pacientes_paciente.id"))
    fecha_inicio = Column(Date)
    fecha_fin = Column(Date)
    estado = Column(String)
    observaciones = Column(Text)

class MedicamentoTratamiento(Base):
    __tablename__ = "pacientes_medicamentotratamiento"
    id = Column(String, primary_key=True) # UUID
    tratamiento_id = Column(String, ForeignKey("pacientes_tratamiento.id"))
    nombre_medicamento = Column(String)
    dosis = Column(String)
    frecuencia = Column(String)
    duracion = Column(String)

class CardioRecord(Base):
    __tablename__ = "cardio_records"
    id = Column(Integer, primary_key=True, index=True)
    paciente = Column(String, index=True)
    ritmo_cardiaco = Column(Integer)
    tipo_arritmia = Column(String)
    sintomas = Column(String)
    diagnostico = Column(String)
    presion_arterial = Column(String)
    fecha_registro = Column(DateTime)
    observaciones = Column(Text)
