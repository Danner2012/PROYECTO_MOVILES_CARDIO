import 'dart:convert';
import 'package:http/http.dart' as http;

class OllamaClient {
  // Ahora apuntamos a nuestra API de FastAPI que tiene los datos de la BD
  final String baseUrl = "http://127.0.0.1:8001/chat";

  Future<http.Response> chat(List<Map<String, String>> messages) async {
    // Para la API de FastAPI, enviamos solo la última pregunta del usuario
    // ya que la API se encarga de buscar en la BD y hablar con Ollama.
    final lastMessage = messages.lastWhere((m) => m['role'] == 'user')['content'];

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "question": lastMessage,
      }),
    );
    return response;
  }
}
