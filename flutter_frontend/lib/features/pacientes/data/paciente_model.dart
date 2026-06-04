// lib/features/pacientes/data/paciente_model.dart

class PacienteModel {
  final int id;
  final String nombre;
  final String email;
  final int edad;
  final String sexo;
  final double pesoInicial;
  final double tallaInicial;
  final List<dynamic> historialControles;

  PacienteModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.edad,
    required this.sexo,
    required this.pesoInicial,
    required this.tallaInicial,
    required this.historialControles,
  });

  factory PacienteModel.fromJson(Map<String, dynamic> json) {
    return PacienteModel(
      id:     json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Sin nombre',
      email:  json['email']  ?? 'Sin email',
      edad:   json['edad']   ?? 0,
      sexo:   json['sexo']   ?? 'Masculino',
      // ✅ Django DecimalField serializa como String "66.00" — doble parse seguro
      pesoInicial:  _toDouble(json['peso_inicial']),
      tallaInicial: _toDouble(json['talla_inicial']),
      historialControles: json['historial_controles'] ?? [],
    );
  }

  /// Convierte num o String a double sin fallar
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
