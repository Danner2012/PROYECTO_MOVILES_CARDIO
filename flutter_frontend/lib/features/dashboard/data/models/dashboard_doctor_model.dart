class DashboardDoctorModel {
  final int totalPacientes;
  final int arritmiasActivas;
  final int totalAlertasRecientes;
  final List<AlertaReciente> alertasRecientes;
  final List<ProximaConsulta> proximasConsultas;

  DashboardDoctorModel({
    required this.totalPacientes,
    required this.arritmiasActivas,
    required this.totalAlertasRecientes,
    required this.alertasRecientes,
    required this.proximasConsultas,
  });

  factory DashboardDoctorModel.fromJson(Map<String, dynamic> json) {
    return DashboardDoctorModel(
      totalPacientes: json['total_pacientes'] ?? 0,
      arritmiasActivas: json['arritmias_activas'] ?? 0,
      totalAlertasRecientes: json['total_alertas_recientes'] ?? 0,
      alertasRecientes: (json['alertas_recientes'] as List?)
              ?.map((i) => AlertaReciente.fromJson(i))
              .toList() ??
          [],
      proximasConsultas: (json['proximas_consultas'] as List?)
              ?.map((i) => ProximaConsulta.fromJson(i))
              .toList() ??
          [],
    );
  }
}

class AlertaReciente {
  final String id;
  final String pacienteNombre;
  final String tipoArritmia;
  final String nivelRiesgo;
  final String fecha;

  AlertaReciente({
    required this.id,
    required this.pacienteNombre,
    required this.tipoArritmia,
    required this.nivelRiesgo,
    required this.fecha,
  });

  factory AlertaReciente.fromJson(Map<String, dynamic> json) {
    return AlertaReciente(
      id: json['id'].toString(),
      pacienteNombre: json['paciente_nombre'] ?? 'Desconocido',
      tipoArritmia: json['tipo_arritmia'] ?? 'N/A',
      nivelRiesgo: json['nivel_riesgo'] ?? 'N/A',
      fecha: json['fecha'] ?? '',
    );
  }
}

class ProximaConsulta {
  final String pacienteNombre;
  final String fecha;
  final String motivo;

  ProximaConsulta({
    required this.pacienteNombre,
    required this.fecha,
    required this.motivo,
  });

  factory ProximaConsulta.fromJson(Map<String, dynamic> json) {
    return ProximaConsulta(
      pacienteNombre: json['paciente_nombre'] ?? 'Desconocido',
      fecha: json['fecha'] ?? '',
      motivo: json['motivo'] ?? 'N/A',
    );
  }
}
