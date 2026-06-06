import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/ollama/data/ollama_client.dart';

class PatientOllamaProvider with ChangeNotifier {
  final OllamaClient _client = OllamaClient();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String? _patientName;

  List<Map<String, String>> get messages => _messages;
  bool get isLoading => _isLoading;

  void setPatientName(String name) {
    _patientName = name;
  }

  Future<void> sendMessage(String text, {VoidCallback? onDone}) async {
    if (text.trim().isEmpty) return;

    // Agregar mensaje del usuario
    _messages.add({"role": "user", "content": text});
    _isLoading = true;
    notifyListeners();
    if (onDone != null) onDone();

    try {
      debugPrint('Enviando mensaje a Ollama para paciente: \$_patientName');
      final response = await _client.chat(_messages, patientName: _patientName);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage = data['answer'];
        _messages.add({"role": "assistant", "content": assistantMessage});
      } else {
        _messages.add({"role": "assistant", "content": "Lo siento, no pude obtener una respuesta en este momento. Intenta de nuevo más tarde."});
      }
    } catch (e) {
      _messages.add({"role": "assistant", "content": "Error de conexión. Asegúrate de que el servicio de IA esté activo."});
    } finally {
      _isLoading = false;
      notifyListeners();
      if (onDone != null) onDone();
    }
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}
