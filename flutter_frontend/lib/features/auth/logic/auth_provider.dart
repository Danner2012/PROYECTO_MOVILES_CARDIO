import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _token;
  String? get token => _token;

  UserModel? _user;
  UserModel? get user => _user;

  AuthProvider() {
    // loadUser se llamará desde el SplashScreen para mejor control
  }

  // =========================================================================
  // CARGAR SESIÓN (Sincronizada con SharedPreferences)
  // =========================================================================
  Future<void> loadUser() async {
    _token = await _storage.read(key: 'token');
    if (_token != null) {
      try {
        final response = await _apiClient.get('/auth/me/', token: _token);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _user = UserModel.fromJson(data);
          
          // Sincronizamos SharedPreferences por si acaso se borró la caché web
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', _token!);
          
          notifyListeners();
        } else {
          // Token inválido o expirado
          await logout();
        }
      } catch (e) {
        print('Error cargando sesión: $e');
      }
    }
  }

  // =========================================================================
  // INICIAR SESIÓN (Persistencia e inyección de llaves locales)
  // =========================================================================
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/login/', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        _user = UserModel.fromJson(data['user']);
        
        // 1. Guardado en almacenamiento cifrado (Móviles)
        await _storage.write(key: 'token', value: _token);
        await _storage.write(key: 'user_rol', value: _user!.rol);
        await _storage.write(key: 'user_nombre', value: _user!.nombre);
        
        // 2. Guardado en LocalStorage (Para ecg_screen.dart y consultas Web)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        
        print('=== [AUTH_PROVIDER] Token replicado con éxito en SharedPreferences ===');
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error en login: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // =========================================================================
  // REGISTRO DE NUEVOS USUARIOS
  // =========================================================================
  Future<bool> register({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String rol,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/register/', {
        'email': email,
        'password': password,
        'nombre': nombre,
        'apellido': apellido,
        'rol_nombre': rol,
      });

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('Error en registro: ${response.statusCode}');
        print('Cuerpo del error: ${response.body}');
      }
    } catch (e) {
      print('Excepción en registro: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // =========================================================================
  // CERRAR SESIÓN (Limpieza completa de ambos almacenamientos)
  // =========================================================================
  Future<void> logout() async {
    _token = null;
    _user = null;
    
    // 1. Limpieza de Secure Storage
    await _storage.delete(key: 'token');
    
    // 2. Limpieza de SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    
    print('=== [AUTH_PROVIDER] Sesión destruida en todos los almacenamientos ===');
    
    notifyListeners();
  }

  // =========================================================================
  // ACTUALIZACIÓN DE PERFIL CON SOPORTE MULTIPART
  // =========================================================================
  Future<bool> updateProfile(Map<String, String> data, {String? imagePath, List<int>? imageBytes, String? fileName}) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('DEBUG: Iniciando actualización de perfil');

      final response = await _apiClient.multipartPut(
        '/auth/me/', 
        data, 
        filePath: imagePath,
        fileBytes: imageBytes,
        fileName: fileName,
        token: _token
      );

      print('DEBUG: Status Code del servidor: ${response.statusCode}');

      final responseData = await http.Response.fromStream(response);
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(responseData.body);
        _user = UserModel.fromJson(userData);
        notifyListeners();
        _isLoading = false;
        print('DEBUG: Perfil actualizado exitosamente');
        return true;
      } else {
        print('DEBUG: Error del servidor: ${responseData.body}');
      }
    } catch (e) {
      print('DEBUG: Excepción capturada en updateProfile: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}