import httpx
import logging

logger = logging.getLogger(__name__)

OLLAMA_API_URL = "http://127.0.0.1:8001/chat"

async def get_cardio_explanation(sintomas, diagnostico_ecg):
    """
    Consulta a la API de Ollama para obtener una explicación educativa 
    sobre los síntomas y el diagnóstico de ECG.
    """
    if sintomas == "Ninguno" and diagnostico_ecg == "Pendiente":
        return "No hay datos suficientes para generar una explicación detallada."

    question = (
        f"Explica de forma muy breve, profesional y educativa para un paciente "
        f"qué podrían indicar estos síntomas: '{sintomas}' y este resultado de ECG: '{diagnostico_ecg}'. "
        f"No des un diagnóstico médico definitivo, solo información general educativa."
    )

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                OLLAMA_API_URL,
                json={"question": question}
            )
            
            if response.status_code == 200:
                data = response.json()
                return data.get("answer", "No se pudo generar una explicación en este momento.")
            else:
                logger.error(f"Error en Ollama API: {response.status_code}")
                return "El asistente de IA no está disponible actualmente."
    except Exception as e:
        logger.error(f"Error conectando con Ollama: {str(e)}")
        return "Error de conexión con el servicio de IA."
