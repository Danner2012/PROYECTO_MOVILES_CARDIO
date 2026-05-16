import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/ecg_models.dart';

class PredictionService {
  static const String baseUrl = 'http://localhost:8000/api/predictions';

  Future<EcgPredictionResponse> predictECG(EcgPredictionRequest request, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return EcgPredictionResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Fallo al realizar la predicción: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<EcgGraphResponse> getECGGraph(double bpm, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/graph/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"bpm": bpm}),
      );

      if (response.statusCode == 200) {
        return EcgGraphResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Fallo al obtener el gráfico: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
