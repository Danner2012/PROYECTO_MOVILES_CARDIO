class DashboardDoctorModel {
  final int totalPacientes;
  final int arritmiasActivas;
  final int totalAlertasRecientes;
  final List<AlertaReciente> alertasRecientes;
  final List<ProximaConsulta> proximasConsultas;
  final List<RiesgoStat> distribucionRiesgo;
  final List<TipoArritmiaStat> distribucionTipo;

  DashboardDoctorModel({
    required this.totalPacientes,
    required this.arritmiasActivas,
    required this.totalAlertasRecientes,
    required this.alertasRecientes,
    required this.proximasConsultas,
    required this.distribucionRiesgo,
    required this.distribucionTipo,
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
      distribucionRiesgo: (json['distribucion_riesgo'] as List?)
              ?.map((i) => RiesgoStat.fromJson(i))
              .toList() ??
          [],
      distribucionTipo: (json['distribucion_tipo'] as List?)
              ?.map((i) => TipoArritmiaStat.fromJson(i))
              .toList() ??
          [],
    );
  }
}

class RiesgoStat {
  final String nivelRiesgo;
  final int cantidad;

  RiesgoStat({required this.nivelRiesgo, required this.cantidad});

  factory RiesgoStat.fromJson(Map<String, dynamic> json) {
    return RiesgoStat(
      nivelRiesgo: json['nivel_riesgo'] ?? 'Desconocido',
      cantidad: json['cantidad'] ?? 0,
    );
  }
}

class TipoArritmiaStat {
  final String tipoArritmia;
  final int cantidad;

  TipoArritmiaStat({required this.tipoArritmia, required this.cantidad});

  factory TipoArritmiaStat.fromJson(Map<String, dynamic> json) {
    return TipoArritmiaStat(
      tipoArritmia: json['tipo_arritmia'] ?? 'N/A',
      cantidad: json['cantidad'] ?? 0,
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
