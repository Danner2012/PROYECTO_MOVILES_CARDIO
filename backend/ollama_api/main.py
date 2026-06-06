from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import httpx
import json
from database import get_db, engine
import models, schemas, crud

# No creamos tablas aquí para no interferir con Django, solo usamos las existentes
# models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Cardio Ollama API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

OLLAMA_URL = "http://127.0.0.1:11434/api/chat"

@app.post("/records", response_model=schemas.CardioResponse)
def create_record(record: schemas.CardioCreate, db: Session = Depends(get_db)):
    return crud.create_cardio_record(db, record)

@app.post("/chat", response_model=schemas.ChatResponse)
async def chat_with_data(request: schemas.ChatRequest, db: Session = Depends(get_db)):
    # Ahora crud.search_cardio_records devuelve un string con todo el contexto real
    db_context = crud.search_cardio_records(db, request.question, request.patient_name)

    print(f"\n--- DEBUG: PREGUNTA RECIBIDA: {request.question} ---")
    if request.patient_name:
        print(f"DEBUG: Identidad Paciente: {request.patient_name}")

    if request.patient_name:
        system_prompt = (
            "Eres el asistente personal de salud experto de Cardio-Project. "
            f"Estás hablando con el paciente {request.patient_name}. "
            "TU MISION es realizar una LECTURA PUNTUAL de sus datos médicos. "
            "REGLAS DE ORO:\n"
            "1. LECTURA PUNTUAL: Extrae valores exactos de la base de datos (presión, frecuencia, dosis). No los resumas si el usuario pide detalle.\n"
            "2. TIPOS DE SOLICITUD:\n"
            "   a) GENERAL: Si el usuario pregunta qué es una enfermedad, usa tu conocimiento médico.\n"
            "   b) PUNTUAL: Si pregunta por sus datos, usa SOLO la información de la sección 'DATOS REALES'.\n"
            "3. HABLA EN SEGUNDA PERSONA: 'Tus resultados', 'Tu médico registró'.\n"
            "4. SEGURIDAD: Nunca recetes, solo informa sobre lo registrado.\n"
            "5. ESTRUCTURA: Usa Markdown (negritas y listas)."
        )
    else:
        system_prompt = (
            "Eres un asistente médico experto en cardiología. "
            "Si el usuario pregunta por datos específicos, realiza una LECTURA PUNTUAL de la base de datos proporcionada. "
            "Sé técnico, preciso y profesional."
        )

    full_prompt_context = f"--- DATOS REALES DEL PACIENTE DESDE LA BASE DE DATOS ---\n{db_context}\n\n"
    full_prompt_context += f"PREGUNTA DEL USUARIO: {request.question}\n"
    
    print("--- CONTEXTO ENVIADO A OLLAMA ---")
    print(db_context)
    print("--- FIN DEBUG ---\n")

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                OLLAMA_URL,
                json={
                    "model": "mistral",
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": full_prompt_context}
                    ],
                    "stream": False
                }
            )
            
            if response.status_code != 200:
                raise HTTPException(status_code=500, detail="Error al conectar con Ollama")
            
            ollama_data = response.json()
            answer = ollama_data['message']['content']
            
            return schemas.ChatResponse(
                answer=answer,
                matched_records=[] # Ya no devolvemos objetos individuales en esta versión simplificada
            )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en el servidor: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
