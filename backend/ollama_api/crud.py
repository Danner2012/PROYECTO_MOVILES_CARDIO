from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, desc
import models, schemas
from datetime import datetime

def create_cardio_record(db: Session, record: schemas.CardioCreate):
    db_record = models.CardioRecord(**record.model_dump())
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    return db_record

def search_cardio_records(db: Session, query: str, patient_identity: str = None):
    """
    Busca información en todas las tablas reales del sistema basadas en el paciente.
    """
    clean_query = query.replace("?", "").replace("¿", "").lower()
    
    context_parts = []
    
    if patient_identity:
        # 1. Buscar al paciente (por email, nombre o apellido en Perfil)
        paciente = db.query(models.Paciente).join(models.User).outerjoin(models.Perfil).filter(
            or_(
                models.User.email.ilike(f"%{patient_identity}%"),
                models.Perfil.nombre.ilike(f"%{patient_identity}%"),
                models.Perfil.apellido.ilike(f"%{patient_identity}%")
            )
        ).first()

        if paciente:
            nombre_completo = f"{paciente.usuario.perfil.nombre} {paciente.usuario.perfil.apellido}" if paciente.usuario.perfil else paciente.usuario.email
            context_parts.append(f"DATOS GENERALES: Paciente {nombre_completo}, Edad: {paciente.edad}, Sexo: {paciente.sexo}. Alergias: {paciente.alergias}. Antecedentes: {paciente.antecedentes_base}.")

            # 2. Buscar Controles (los últimos 3)
            controles = db.query(models.ControlCardiologico).filter(
                models.ControlCardiologico.paciente_id == paciente.id
            ).order_by(desc(models.ControlCardiologico.fecha)).limit(3).all()
            
            if controles:
                context_parts.append("ÚLTIMOS CONTROLES:")
                for c in controles:
                    fecha_str = c.fecha.strftime('%d/%m/%Y') if c.fecha else "Sin fecha"
                    context_parts.append(f"- Fecha: {fecha_str}, Presión: {c.presion_sistolica}/{c.presion_diastolica}, Frecuencia: {c.frecuencia_cardiaca} BPM, SatO2: {c.saturacion_oxigeno}%, ECG: {c.diagnostico_ecg}, Síntomas: {c.sintomas}")

            # 3. Buscar Arritmias
            arritmias = db.query(models.Arritmia).filter(
                models.Arritmia.paciente_id == paciente.id
            ).order_by(desc(models.Arritmia.fecha_deteccion)).all()
            
            if arritmias:
                context_parts.append("ARRITMIAS DETECTADAS:")
                for a in arritmias:
                    context_parts.append(f"- {a.tipo_arritmia} detectada el {a.fecha_deteccion}, Riesgo: {a.nivel_riesgo}, Estado: {a.estado}")

            # 4. Buscar Tratamientos y Medicamentos
            tratamientos = db.query(models.Tratamiento).filter(
                models.Tratamiento.paciente_id == paciente.id,
                models.Tratamiento.estado == "Activo"
            ).all()
            
            if tratamientos:
                context_parts.append("TRATAMIENTOS ACTIVOS:")
                for t in tratamientos:
                    context_parts.append(f"- Tratamiento iniciado el {t.fecha_inicio}: {t.observaciones}")
                    # Buscar medicamentos de este tratamiento
                    medicamentos = db.query(models.MedicamentoTratamiento).filter(
                        models.MedicamentoTratamiento.tratamiento_id == t.id
                    ).all()
                    for m in medicamentos:
                        context_parts.append(f"  * Medicamento: {m.nombre_medicamento}, Dosis: {m.dosis}, Frecuencia: {m.frecuencia}")

        else:
            # Si no se encuentra paciente específico, buscar en la tabla legacy cardio_records por si acaso
            legacy = db.query(models.CardioRecord).filter(
                models.CardioRecord.paciente.ilike(f"%{patient_identity}%")
            ).limit(5).all()
            if legacy:
                context_parts.append("REGISTROS ENCONTRADOS (Sistema Anterior):")
                for r in legacy:
                    fecha_reg_str = r.fecha_registro.strftime('%d/%m/%Y') if r.fecha_registro else "Sin fecha"
                    context_parts.append(f"- {fecha_reg_str}: {r.diagnostico}, Presión: {r.presion_arterial}")

    # Si no hay paciente o no se encontró nada específico
    if not context_parts:
        context_parts.append("No se encontró información específica para el paciente solicitado. Por favor, responde de forma general sobre cardiología.")
    
    return "\n".join(context_parts)
