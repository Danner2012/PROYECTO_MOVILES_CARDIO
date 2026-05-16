import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/ollama/data/ollama_client.dart';

class OllamaProvider with ChangeNotifier {
  final OllamaClient _client = OllamaClient();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  List<Map<String, String>> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text, {VoidCallback? onDone}) async {
    if (text.trim().isEmpty) return;

    // Agregar mensaje del usuario
    _messages.add({"role": "user", "content": text});
    _isLoading = true;
    notifyListeners();
    if (onDone != null) onDone();

    try {
      debugPrint('Enviando mensaje a Ollama...');
      final response = await _client.chat(_messages);
      debugPrint('Respuesta recibida: \${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('JSON decodificado con éxito');
        final assistantMessage = data['answer']; // Cambiado de 'message' a 'answer'
        _messages.add({"role": "assistant", "content": assistantMessage});
      } else {
        debugPrint('Error en la respuesta: \${response.body}');
        _messages.add({"role": "assistant", "content": "Error: \${response.statusCode}. No se pudo obtener respuesta de Ollama."});
      }
    } catch (e) {
      debugPrint('Excepción capturada en OllamaProvider: \$e');
      _messages.add({"role": "assistant", "content": "Error de conexión: \$e"});
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
