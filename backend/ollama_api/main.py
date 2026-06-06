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
            "Eres un asistente educativo de salud para el sistema Cardio-Project. "
            f"Estás ayudando al paciente {request.patient_name} a entender su salud cardiovascular. "
            "TU TAREA es explicar los resultados médicos de forma sencilla, tranquilizadora y educativa. "
            "REGLAS CRÍTICAS:\n"
            "1. Usa un lenguaje que un paciente sin conocimientos médicos pueda entender.\n"
            "2. Responde basándote exclusivamente en los datos del paciente que te proporciono.\n"
            "3. No des diagnósticos médicos definitivos, siempre sugiere consultar con su doctor.\n"
            "4. Sé muy amable y responde solo sobre cardiología."
        )
    else:
        system_prompt = (
            "Eres un asistente médico experto en cardiología del sistema Cardio-Project. "
            "TU TAREA es responder de forma inteligente basándote en el contexto proporcionado. "
            "REGLAS CRÍTICAS:\n"
            "1. Si el usuario hace una PREGUNTA GENERAL (ej. '¿Qué es la taquicardia?'), responde de forma educativa y profesional SIN mencionar datos de pacientes específicos de la base de datos, a menos que el usuario lo pida.\n"
            "2. Si el usuario pregunta por DATOS REALES o REGISTROS (ej. '¿Qué pacientes tienen arritmia?'), utiliza la información de la BASE DE DATOS que te proporciono.\n"
            "3. Solo puedes responder sobre cardiología o el sistema Cardio-Project. Para otros temas, di: 'Lo siento, solo puedo ayudarte con temas relacionados con el corazón o el sistema Cardio-Project'.\n"
            "4. Sé conciso y preciso."
        )

    context = ""
    if matched_records:
        header = "TUS DATOS MÉDICOS:" if request.patient_name else "DATOS DE LA BASE DE DATOS:"
        context += f"{header}\n"
        for r in matched_records:
            context += f"- FECHA: {r.fecha_registro.strftime('%d/%m/%Y')}, RITMO: {r.ritmo_cardiaco} BPM, ARRITMIA: {r.tipo_arritmia}, DIAGNÓSTICO: {r.diagnostico}, SÍNTOMAS: {r.sintomas}, PRESIÓN: {r.presion_arterial}\n"
    
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
