import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // Para Web/Windows: localhost
  // Para emulador Android: 10.0.2.2
  static const String baseUrl = 'http://localhost:8000/api'; 
  static const String mediaBaseUrl = 'http://localhost:8000';

  final http.Client _client = http.Client();

  Future<http.Response> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> get(String endpoint, {String? token}) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body, {String? token}) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await _client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.StreamedResponse> multipartPut(String endpoint, Map<String, String> body, {String? filePath, List<int>? fileBytes, String? fileName, String? token}) async {
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl$endpoint'));
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.fields.addAll(body);
    
    if (fileBytes != null && fileName != null) {
      request.files.add(http.MultipartFile.fromBytes('foto', fileBytes, filename: fileName));
    } else if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', filePath));
    }
    
    return await request.send();
  }
}
