import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/network/api_client.dart';
import 'package:flutter_frontend/features/auth/data/models/user_model.dart';

class DoctorProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<UserModel> _doctors = [];
  bool _isLoading = false;

  List<UserModel> get doctors => _doctors;
  bool get isLoading => _isLoading;

  Future<void> fetchDoctors(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/users/doctors/', token: token);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _doctors = data.map((json) => UserModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching doctors: \$e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDoctor(String token, String email, String password, String nombre, String apellido) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/users/doctors/', {
        'email': email,
        'password': password,
        'nombre': nombre,
        'apellido': apellido,
      }, token: token);

      if (response.statusCode == 201) {
        await fetchDoctors(token);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating doctor: \$e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
