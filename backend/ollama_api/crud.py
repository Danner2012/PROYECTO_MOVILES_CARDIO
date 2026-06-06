from sqlalchemy.orm import Session
import models, schemas

def create_cardio_record(db: Session, record: schemas.CardioCreate):
    db_record = models.CardioRecord(**record.model_dump())
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    return db_record

def get_cardio_records(db: Session, skip: int = 0, limit: int = 200):
    return db.query(models.CardioRecord).offset(skip).limit(limit).all()

def get_cardio_record(db: Session, record_id: int):
    return db.query(models.CardioRecord).filter(models.CardioRecord.id == record_id).first()

def update_cardio_record(db: Session, record_id: int, record_update: schemas.CardioUpdate):
    db_record = get_cardio_record(db, record_id)
    if db_record:
        for key, value in record_update.model_dump(exclude_unset=True).items():
            setattr(db_record, key, value)
        db.commit()
        db.refresh(db_record)
    return db_record

def delete_cardio_record(db: Session, record_id: int):
    db_record = get_cardio_record(db, record_id)
    if db_record:
        db.delete(db_record)
        db.commit()
        return db_record

# Función para buscar registros basados en palabras clave de la pregunta
def search_cardio_records(db: Session, query: str, patient_name: str = None):
    # Limpiar la pregunta: quitar signos de interrogación y pasar a minúsculas
    clean_query = query.replace("?", "").replace("¿", "").lower()
    words = clean_query.split()
    
    # Filtrar palabras comunes que no aportan a la búsqueda
    stop_words = ["quien", "es", "que", "dime", "sobre", "el", "la", "los", "las", "un", "una", "de", "del", "paciente", "diagnostico", "tiene"]
    keywords = [w for w in words if w not in stop_words and len(w) > 2]

    from sqlalchemy import or_, and_, desc

    if patient_name:
        # ESTRATEGIA PARA PACIENTE: Siempre traer sus últimos 3 registros como base
        # más cualquier otro registro que coincida con las palabras clave.
        
        # 1. Obtener los 3 más recientes
        latest_records = db.query(models.CardioRecord).filter(
            models.CardioRecord.paciente.ilike(f"%{patient_name}%")
        ).order_by(desc(models.CardioRecord.fecha_registro)).limit(3).all()
        
        # 2. Si hay palabras clave, buscar coincidencias específicas
        keyword_records = []
        if keywords:
            conditions = []
            for word in keywords:
                search_term = f"%{word}%"
                conditions.append(models.CardioRecord.tipo_arritmia.ilike(search_term))
                conditions.append(models.CardioRecord.diagnostico.ilike(search_term))
                conditions.append(models.CardioRecord.sintomas.ilike(search_term))
                conditions.append(models.CardioRecord.presion_arterial.ilike(search_term))
            
            keyword_records = db.query(models.CardioRecord).filter(
                and_(
                    models.CardioRecord.paciente.ilike(f"%{patient_name}%"),
                    or_(*conditions)
                )
            ).limit(5).all()
        
        # Combinar y eliminar duplicados manteniendo el orden
        seen_ids = set()
        final_records = []
        for r in (latest_records + keyword_records):
            if r.id not in seen_ids:
                final_records.append(r)
                seen_ids.add(r.id)
        
        return final_records[:5]

    # ESTRATEGIA PARA ADMIN: Búsqueda tradicional por palabras clave
    if not keywords:
        keywords = [clean_query]

    conditions = []
    for word in keywords:
        search_term = f"%{word}%"
        conditions.append(models.CardioRecord.paciente.ilike(search_term))
        conditions.append(models.CardioRecord.tipo_arritmia.ilike(search_term))
        conditions.append(models.CardioRecord.diagnostico.ilike(search_term))
        conditions.append(models.CardioRecord.sintomas.ilike(search_term))
        conditions.append(models.CardioRecord.presion_arterial.ilike(search_term))

    return db.query(models.CardioRecord).filter(or_(*conditions)).limit(5).all()
