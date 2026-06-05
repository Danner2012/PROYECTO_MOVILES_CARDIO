// lib/features/pacientes/logic/pacientes_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/paciente_model.dart';

class PacientesProvider with ChangeNotifier {
  List<PacienteModel> _pacientes = [];
  bool _isLoading = false;
  String? _ultimoError;

  List<PacienteModel> get pacientes  => _pacientes;
  bool               get isLoading   => _isLoading;
  String?            get ultimoError => _ultimoError;

  // ✅ localhost — no 127.0.0.1 (Chrome trata las dos como orígenes distintos)
  final String baseUrl = 'http://localhost:8000/api/pacientes';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── Listar pacientes del doctor logueado ──────────────────────────────────
  Future<void> cargarPacientes(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: _headers(token),
      );
      debugPrint('cargarPacientes → ${response.statusCode}: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _pacientes = data.map((j) => PacienteModel.fromJson(j)).toList();
      } else {
        debugPrint('cargarPacientes error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('cargarPacientes excepción: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Registrar nuevo paciente ──────────────────────────────────────────────
  Future<bool> registrarPaciente({
    required String token,
    required String email,
    required int    edad,
    required String sexo,
    required double peso,
    required double talla,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/registrar/');
      final body = json.encode({
        'email':         email,
        'edad':          edad,
        'sexo':          sexo,
        'peso_inicial':  peso,
        'talla_inicial': talla,
      });

      debugPrint('POST → $url');
      debugPrint('Body → $body');

      final response = await http.post(url, headers: _headers(token), body: body);

      debugPrint('registrarPaciente → ${response.statusCode}: ${response.body}');

      if (response.statusCode == 201) {
        await cargarPacientes(token);
        return true;
      }

      // Extrae el mensaje de error del backend para mostrarlo en UI
      try {
        final decoded = json.decode(response.body);
        _ultimoError  = decoded['error'] ?? 'Error desconocido';
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

  // ── Agregar control cardiológico ──────────────────────────────────────────
  Future<bool> agregarControlCardio({
    required String              token,
    required int                 pacienteId,
    required Map<String, dynamic> datosControl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$pacienteId/controles/'),
        headers: _headers(token),
        body: json.encode(datosControl),
      );
      debugPrint('agregarControl → ${response.statusCode}: ${response.body}');
      if (response.statusCode == 201) {
        await cargarPacientes(token);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('agregarControlCardio excepción: $e');
      return false;
    }
  }
}
