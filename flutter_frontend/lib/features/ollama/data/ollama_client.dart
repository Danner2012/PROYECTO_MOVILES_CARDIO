import 'dart:convert';
import 'package:http/http.dart' as http;

class OllamaClient {
  final String baseUrl = "http://127.0.0.1:11434/api/chat";

  Future<http.Response> chat(List<Map<String, String>> messages) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "model": "mistral", // Cambiado de llama3.2 a mistral por petición del usuario
        "messages": messages,
        "stream": false, // Desactivamos stream para simplificar la primera implementación
      }),
    );
    return response;
  }
}
