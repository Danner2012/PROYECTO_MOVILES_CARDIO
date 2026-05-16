import json
import urllib.request
import urllib.error
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Prediction

COLAB_URL = "https://canister-revivable-grandson.ngrok-free.dev"

class PredictView(APIView):
    def post(self, request):
        data = request.data
        
        try:
            # Reenviar a Colab
            req = urllib.request.Request(
                f"{COLAB_URL}/predict",
                data=json.dumps(data).encode('utf-8'),
                headers={'Content-Type': 'application/json'},
                method='POST'
            )
            
            with urllib.request.urlopen(req) as response:
                result = json.loads(response.read().decode('utf-8'))
                
            # Guardar en la BD si la predicción fue exitosa
            if result.get('success'):
                Prediction.objects.create(
                    bpm=data.get('bpm', 0),
                    prediction=result.get('prediction', 'unknown'),
                    confidence=result.get('confidence', 0.0)
                )
                
            return Response(result, status=status.HTTP_200_OK)
            
        except urllib.error.URLError as e:
            return Response(
                {"error": "No se pudo conectar con el predictor de IA", "details": str(e)},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

class GraphView(APIView):
    def post(self, request):
        data = request.data
        
        try:
            req = urllib.request.Request(
                f"{COLAB_URL}/graph",
                data=json.dumps(data).encode('utf-8'),
                headers={'Content-Type': 'application/json'},
                method='POST'
            )
            
            with urllib.request.urlopen(req) as response:
                result = json.loads(response.read().decode('utf-8'))
                
            return Response(result, status=status.HTTP_200_OK)
            
        except urllib.error.URLError as e:
            return Response(
                {"error": "No se pudo conectar con el generador de gráficos", "details": str(e)},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
