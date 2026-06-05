// lib/features/pacientes/logic/pacientes_provider.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/paciente_model.dart';

class PacientesProvider with ChangeNotifier {
  List<PacienteModel> _pacientes = [];
  bool _isLoading = false;
  String? _ultimoError;

  List<PacienteModel> get pacientes    => _pacientes;
  bool                get isLoading   => _isLoading;
  String?             get ultimoError => _ultimoError;

  final String baseUrl = 'http://localhost:8000/api/pacientes';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── Listar pacientes ──────────────────────────────────────────────────────
  Future<void> cargarPacientes(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _pacientes = data.map((j) => PacienteModel.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('cargarPacientes excepción: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Registrar paciente (usa bytes para la foto) ───────────────────────────
  Future<bool> registrarPaciente({
    required String token,
    required String email,
    required int    edad,
    required String sexo,
    required double peso,
    required double talla,
    String  alergias         = 'Ninguna',
    String  antecedentesBase = 'Ninguno',
    Uint8List? fotoBytes,      // bytes de la imagen
    String?   fotoNombre,      // nombre del archivo (ej: foto.jpg)
    String?   fecha,           // no se envía al backend, se ignora
  }) async {
    try {
      final url = Uri.parse('$baseUrl/registrar/');
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['email'] = email;
      request.fields['edad'] = edad.toString();
      request.fields['sexo'] = sexo;
      request.fields['peso_inicial'] = peso.toString();
      request.fields['talla_inicial'] = talla.toString();
      request.fields['alergias'] = alergias;
      request.fields['antecedentes_base'] = antecedentesBase;

      if (fotoBytes != null && fotoBytes.isNotEmpty && fotoNombre != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'foto',
          fotoBytes,
          filename: fotoNombre,
        ));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        await cargarPacientes(token);
        return true;
      }

      try {
        final decoded = json.decode(response.body);
        _ultimoError = decoded['error'] ?? 'Error desconocido';
      } catch (_) {
        _ultimoError = 'Error ${response.statusCode}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('registrarPaciente excepción: $e');
      _ultimoError = 'Sin conexión con el servidor';
      notifyListeners();
      return false;
    }
  }

  // ── Agregar control cardiológico (usa bytes para el adjunto) ──────────────
  Future<bool> agregarControlCardio({
    required String token,
    required int pacienteId,
    required Map<String, dynamic> datosControl,
    Uint8List? archivoBytes,
    String?   archivoNombre,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$pacienteId/controles/');

      if (archivoBytes != null && archivoBytes.isNotEmpty && archivoNombre != null) {
        final request = http.MultipartRequest('POST', url);
        request.headers['Authorization'] = 'Bearer $token';

        datosControl.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        request.files.add(http.MultipartFile.fromBytes(
          'archivo_adjunto',
          archivoBytes,
          filename: archivoNombre,
        ));

        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);

        if (response.statusCode == 201) {
          await cargarPacientes(token);
          return true;
        }
      } else {
        final response = await http.post(
          url,
          headers: _headers(token),
          body: json.encode(datosControl),
        );
        if (response.statusCode == 201) {
          await cargarPacientes(token);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('agregarControlCardio excepción: $e');
      return false;
    }
  }
}
