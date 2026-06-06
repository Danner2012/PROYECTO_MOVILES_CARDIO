// lib/features/pacientes/data/paciente_model.dart

class ControlCardioModel {
  final int id;
  final String fecha;
  final int presionSistolica;
  final int presionDiastolica;
  final int frecuenciaCardiaca;
  final int saturacionOxigeno;
  final String sintomas;
  final String evolucion;
  final bool dolorPecho;
  final bool disnea;
  final bool mareos;
  final bool edema;
  final String diagnosticoEcg;
  final String planMedicacion;
  final String? proximaCita;
  final String? archivoAdjunto;
  final bool consentimientoFirmado;

  ControlCardioModel({
    required this.id,
    required this.fecha,
    required this.presionSistolica,
    required this.presionDiastolica,
    required this.frecuenciaCardiaca,
    required this.saturacionOxigeno,
    required this.sintomas,
    required this.evolucion,
    required this.dolorPecho,
    required this.disnea,
    required this.mareos,
    required this.edema,
    required this.diagnosticoEcg,
    required this.planMedicacion,
    this.proximaCita,
    this.archivoAdjunto,
    required this.consentimientoFirmado,
  });

  factory ControlCardioModel.fromJson(Map<String, dynamic> json) {
    return ControlCardioModel(
      id: json['id'] ?? 0,
      fecha: json['fecha'] ?? '',
      presionSistolica: json['presion_sistolica'] ?? 0,
      presionDiastolica: json['presion_diastolica'] ?? 0,
      frecuenciaCardiaca: json['frecuencia_cardiaca'] ?? 0,
      saturacionOxigeno: json['saturacion_oxigeno'] ?? 0,
      sintomas: json['sintomas'] ?? 'Ninguno',
      evolucion: json['evolucion'] ?? '',
      dolorPecho: json['dolor_pecho'] ?? false,
      disnea: json['disnea'] ?? false,
      mareos: json['mareos'] ?? false,
      edema: json['edema'] ?? false,
      diagnosticoEcg: json['diagnostico_ecg'] ?? 'Pendiente',
      planMedicacion: json['plan_medicacion'] ?? '',
      proximaCita: json['proxima_cita'],
      archivoAdjunto: json['archivo_adjunto'],
      consentimientoFirmado: json['consentimiento_firmado'] ?? false,
    );
  }
}

class HistorialClinicoModel {
  final String id;
  final int paciente;
  final String? doctor;
  final String fechaRegistro;
  final String motivoConsulta;
  final String? antecedentesCardiacos;
  final String? antecedentesFamiliares;
  final String? enfermedadesPrevias;
  final String? alergias;
  final String? observacionesMedicas;
  final String estadoActual;
  final bool activo;
  final String createdAt;
  final String updatedAt;

  HistorialClinicoModel({
    required this.id,
    required this.paciente,
    this.doctor,
    required this.fechaRegistro,
    required this.motivoConsulta,
    this.antecedentesCardiacos,
    this.antecedentesFamiliares,
    this.enfermedadesPrevias,
    this.alergias,
    this.observacionesMedicas,
    required this.estadoActual,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HistorialClinicoModel.fromJson(Map<String, dynamic> json) {
    return HistorialClinicoModel(
      id: json['id'] ?? '',
      paciente: json['paciente'] ?? 0,
      doctor: json['doctor']?.toString(),
      fechaRegistro: json['fecha_registro'] ?? '',
      motivoConsulta: json['motivo_consulta'] ?? '',
      antecedentesCardiacos: json['antecedentes_cardiacos'],
      antecedentesFamiliares: json['antecedentes_familiares'],
      enfermedadesPrevias: json['enfermedades_previas'],
      alergias: json['alergias'],
      observacionesMedicas: json['observaciones_medicas'],
      estadoActual: json['estado_actual'] ?? '',
      activo: json['activo'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class PacienteModel {
  final int id;
  final String nombre;
  final String email;
  final int edad;
  final String sexo;
  final double pesoInicial;
  final double tallaInicial;
  final String alergias;
  final String antecedentesBase;
  final String? foto;
  final List<ControlCardioModel> historialControles;
  final List<HistorialClinicoModel> historialesClinicos;

  PacienteModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.edad,
    required this.sexo,
    required this.pesoInicial,
    required this.tallaInicial,
    required this.alergias,
    required this.antecedentesBase,
    this.foto,
    required this.historialControles,
    required this.historialesClinicos,
  });

  factory PacienteModel.fromJson(Map<String, dynamic> json) {
    var listaControlesRaw = json['historial_controles'] as List? ?? [];
    List<ControlCardioModel> controlesMapeados = listaControlesRaw
        .map((controlJson) => ControlCardioModel.fromJson(controlJson))
        .toList();

    var listaHistorialesRaw = json['historiales_clinicos'] as List? ?? [];
    List<HistorialClinicoModel> historialesMapeados = listaHistorialesRaw
        .map((hJson) => HistorialClinicoModel.fromJson(hJson))
        .toList();

    return PacienteModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Sin nombre',
      email: json['email'] ?? 'Sin email',
      edad: json['edad'] ?? 0,
      sexo: json['sexo'] ?? 'Masculino',
      pesoInicial: _toDouble(json['peso_inicial']),
      tallaInicial: _toDouble(json['talla_inicial']),
      alergias: json['alergias'] ?? 'Ninguna',
      antecedentesBase: json['antecedentes_base'] ?? 'Ninguno',
      foto: json['foto'],
      historialControles: controlesMapeados,
      historialesClinicos: historialesMapeados,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
