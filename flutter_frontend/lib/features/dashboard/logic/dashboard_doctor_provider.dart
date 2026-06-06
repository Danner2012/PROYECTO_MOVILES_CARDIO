import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/network/api_client.dart';
import 'package:flutter_frontend/features/dashboard/data/models/dashboard_doctor_model.dart';

class DashboardDoctorProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  DashboardDoctorModel? _data;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardDoctorModel? get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/pacientes/dashboard-doctor/', token: token);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        _data = DashboardDoctorModel.fromJson(jsonData);
      } else {
        _errorMessage = 'Error al cargar datos: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error de red o servidor: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
