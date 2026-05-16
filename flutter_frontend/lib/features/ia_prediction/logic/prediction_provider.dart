import 'package:flutter/material.dart';
import '../data/models/ecg_models.dart';
import 'prediction_service.dart';

class IaPredictionProvider extends ChangeNotifier {
  final PredictionService _service = PredictionService();
  
  EcgPredictionResponse? _predictionResult;
  EcgGraphResponse? _graphResult;
  bool _isLoading = false;
  String? _error;

  EcgPredictionResponse? get predictionResult => _predictionResult;
  EcgGraphResponse? get graphResult => _graphResult;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> performAnalysis(EcgPredictionRequest request, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Realizar predicción
      _predictionResult = await _service.predictECG(request, token);
      
      // Obtener gráfico basado en el BPM del request
      _graphResult = await _service.getECGGraph(request.bpm, token);
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResults() {
    _predictionResult = null;
    _graphResult = null;
    _error = null;
    notifyListeners();
  }
}
