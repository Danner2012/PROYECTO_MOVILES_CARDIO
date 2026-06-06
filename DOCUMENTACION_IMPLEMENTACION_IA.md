# Documentación de Implementación: Módulo de Controles para Pacientes con IA

Este documento detalla los cambios realizados en el sistema Cardio-Project para permitir a los usuarios con el rol de **Paciente** visualizar sus propios controles cardiológicos enriquecidos con explicaciones educativas generadas por Inteligencia Artificial (Ollama).

## 1. Cambios en el Backend (Django)

### Nueva Carpeta de Infraestructura
- **Ubicación**: `backend/infrastructure/`
- **Archivo**: `ollama_client.py`
- **Propósito**: Cliente centralizado para la comunicación asíncrona con el microservicio de Ollama (FastAPI).
- **Lógica**: Envía los síntomas y el diagnóstico de ECG a la IA y recibe una explicación breve y educativa.

### Endpoints y Vistas
- **Archivo**: `backend/pacientes/views.py`
- **Nuevo Endpoint**: `obtener_mis_controles` (`GET /api/pacientes/mis-controles/`)
  - **Seguridad**: Solo accesible para usuarios autenticados con rol `paciente`.
  - **Integración IA**: Utiliza `asyncio` para procesar las peticiones a la IA sin bloquear el hilo principal.
  - **Respuesta**: Devuelve la lista de controles del paciente logueado, inyectando un nuevo campo `explicacion_ia` en cada registro.

### Rutas
- **Archivo**: `backend/pacientes/urls.py`
- **Cambio**: Se registró la ruta `mis-controles/` para vincularla a la nueva vista.

### Dependencias Instaladas
- **httpx**: Instalado en el entorno virtual (`venv`) para manejar peticiones HTTP asíncronas de manera eficiente.

---

## 2. Cambios en el Frontend (Flutter)

### Lógica de Negocio (Provider)
- **Archivo**: `lib/features/pacientes/logic/pacientes_provider.dart`
- **Cambio**: Se añadió el método `fetchMisControles(token)` que gestiona la petición al nuevo endpoint del backend y almacena los datos en el estado de la aplicación.

### Nueva Interfaz de Usuario
- **Archivo**: `lib/features/pacientes/presentation/screens/mis_controles_screen.dart`
- **Descripción**: Una vista "Read-Only" (solo lectura) que adapta la estética del expediente del doctor para el paciente.
- **Sección IA**: Implementación de un widget visualmente distintivo (color turquesa, estilo "glassmorphism") para mostrar la información generada por Ollama debajo de cada control.

### Integración en el Menú
- **Archivo**: `lib/features/dashboard/presentation/screens/main/components/side_menu.dart`
- **Cambio**: Se añadió el botón **"Mis Controles"** que aparece exclusivamente para usuarios con el rol `paciente`.
- **Archivo**: `lib/features/dashboard/presentation/screens/main/main_screen.dart`
- **Cambio**: Se integró la navegación para que la pantalla de controles sea accesible desde el controlador principal.

---

## 3. Resumen Técnico
| Componente | Acción |
| :--- | :--- |
| **Backend** | Creación de cliente IA, nuevo endpoint seguro y lógica asíncrona. |
| **Frontend** | Pantalla de historial para pacientes y visualización de respuestas IA. |
| **Integración** | Comunicación mediante JSON con el campo dinámico `explicacion_ia`. |
| **IA** | Prompt especializado en educación médica básica sin compromiso de diagnóstico. |

---
*Documento generado automáticamente por Gemini CLI - 2026*
