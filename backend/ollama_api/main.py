from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import httpx
import json
from database import get_db, engine
import models, schemas, crud

# Crear tablas si no existen
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Cardio Ollama API")

# Configuración de CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permite todos los orígenes
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

OLLAMA_URL = "http://127.0.0.1:11434/api/chat"

@app.post("/chat", response_model=schemas.ChatResponse)
async def chat_with_data(request: schemas.ChatRequest, db: Session = Depends(get_db)):
    # 1. Buscar registros relacionados en la BD
    matched_records = crud.search_cardio_records(db, request.question)

    print(f"\n--- DEBUG: PREGUNTA RECIBIDA: {request.question} ---")
    print(f"DEBUG: Cantidad de registros encontrados: {len(matched_records)}")

    # 2. Construir el contexto para Ollama
    system_prompt = (
        "Eres un asistente médico experto en cardiología del sistema Cardio-Project. "
        "TU TAREA es responder preguntas usando ÚNICAMENTE la información de la BASE DE DATOS que te proporciono. "
        "Si los datos están ahí, úsalos para dar una respuesta detallada del paciente."
    )

    context = "DATOS REALES DE LA BASE DE DATOS:\n"
    if matched_records:
        for r in matched_records:
            record_str = f"- PACIENTE: {r.paciente}, RITMO: {r.ritmo_cardiaco} BPM, ARRITMIA: {r.tipo_arritmia}, DIAGNÓSTICO: {r.diagnostico}, SÍNTOMAS: {r.sintomas}, OBSERVACIONES: {r.observaciones}"
            context += record_str + "\n"
            print(f"DEBUG: Registro enviado a Ollama -> {record_str}")
    else:
        context += "NO SE ENCONTRARON REGISTROS EN LA BASE DE DATOS.\n"
        print("DEBUG: No se enviaron registros médicos.")

    context += f"\nPREGUNTA DEL USUARIO: {request.question}"

    print("--- FIN DEBUG ---\n")

    # 3. Llamar a Ollama
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                OLLAMA_URL,
                json={
                    "model": "mistral",
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": context}
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
                matched_records=[schemas.CardioResponse.model_validate(r) for r in matched_records]
            )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en el servidor: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
