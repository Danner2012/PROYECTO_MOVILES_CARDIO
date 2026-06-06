from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import httpx
import json
from database import get_db, engine
import models, schemas, crud

models.Base.metadata.create_all(bind=engine)

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
    matched_records = crud.search_cardio_records(db, request.question, request.patient_name)

    print(f"\n--- DEBUG: PREGUNTA RECIBIDA: {request.question} ---")
    if request.patient_name:
        print(f"DEBUG: Paciente: {request.patient_name}")
    print(f"DEBUG: Cantidad de registros encontrados: {len(matched_records)}")

    if request.patient_name:
        system_prompt = (
            "Eres el asistente personal de salud de Cardio-Project. "
            f"Estás hablando directamente con el paciente {request.patient_name}. "
            "TU TAREA es explicarle SUS resultados médicos de forma directa, amable y MUY ESTRUCTURADA. "
            "REGLAS CRÍTICAS DE COMUNICACIÓN:\n"
            "1. HABLA EN SEGUNDA PERSONA: Dirígete al usuario como 'tú'. Usa frases como 'Tus registros muestran...', 'Tu presión está...', 'Tus síntomas registrados son...'.\n"
            "2. NUNCA hables en tercera persona (evita decir 'En el caso de...' o 'La paciente tiene...'). Habla como si estuvieras viendo su expediente con él/ella.\n"
            "3. Usa Markdown: Negritas (**), listas (-) y saltos de línea.\n"
            "4. DATOS REALES: Usa los datos de 'TUS DATOS MÉDICOS' con precisión. Si el dato existe, dalo directamente.\n"
            "5. SEGURIDAD: No des diagnósticos definitivos, sugiere siempre hablar con su médico de cabecera.\n"
            "6. Sé muy empático y educado."
        )
    else:
        system_prompt = (
            "Eres un asistente médico experto en cardiología del sistema Cardio-Project. "
            "TU TAREA es responder de forma inteligente basándote en el contexto proporcionado. "
            "REGLAS CRÍTICAS:\n"
            "1. Usa Markdown profesional: Negritas para términos clave y listas para enumerar hallazgos.\n"
            "2. Si el usuario hace una PREGUNTA GENERAL, responde de forma educativa.\n"
            "3. Si el usuario pregunta por DATOS REALES o REGISTROS, utiliza la información de la BASE DE DATOS con precisión.\n"
            "4. Sé conciso y técnico pero accesible."
        )

    context = ""
    if matched_records:
        header = f"--- DATOS REALES DE {request.patient_name.upper()} ---" if request.patient_name else "--- REGISTROS DE LA BASE DE DATOS ---"
        context += f"{header}\n"
        for r in matched_records:
            context += (
                f"- FECHA DEL REGISTRO: {r.fecha_registro.strftime('%d/%m/%Y')}\n"
                f"  * Ritmo Cardíaco: {r.ritmo_cardiaco} pulsaciones por minuto (BPM)\n"
                f"  * Presión Arterial: {r.presion_arterial}\n"
                f"  * Tipo de Arritmia/ECG: {r.tipo_arritmia}\n"
                f"  * Diagnóstico del Doctor: {r.diagnostico}\n"
                f"  * Síntomas Reportados: {r.sintomas}\n"
                f"  * Observaciones/Plan: {r.observaciones}\n"
                "-------------------------------------------\n"
            )
    else:
        if request.patient_name:
            context += f"AVISO: No se encontraron registros específicos para la pregunta de {request.patient_name}. Responde de forma general y educativa.\n"
    
    context += f"\nPREGUNTA DEL USUARIO: {request.question}\n"
    context += "\nResponde siguiendo las reglas del sistema."

    print("--- FIN DEBUG ---\n")

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
