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

class SeguimientoArritmiaModel {
  final String id;
  final String arritmia;
  final String fechaControl;
  final int frecuenciaCardiaca;
  final String nivelRiesgo;
  final String estado;
  final String? observaciones;
  final String? registradoPorNombre;
  final String createdAt;

  SeguimientoArritmiaModel({
    required this.id,
    required this.arritmia,
    required this.fechaControl,
    required this.frecuenciaCardiaca,
    required this.nivelRiesgo,
    required this.estado,
    this.observaciones,
    this.registradoPorNombre,
    required this.createdAt,
  });

  factory SeguimientoArritmiaModel.fromJson(Map<String, dynamic> json) {
    return SeguimientoArritmiaModel(
      id: json['id'] ?? '',
      arritmia: json['arritmia'] ?? '',
      fechaControl: json['fecha_control'] ?? '',
      frecuenciaCardiaca: json['frecuencia_cardiaca'] ?? 0,
      nivelRiesgo: json['nivel_riesgo'] ?? '',
      estado: json['estado'] ?? '',
      observaciones: json['observaciones'],
      registradoPorNombre: json['registrado_por_nombre'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ExamenMedicoModel {
  final String id;
  final int paciente;
  final String? doctor;
  final String tipoExamen;
  final String fechaExamen;
  final String? resultado;
  final String? descripcion;
  final String? archivoAdjunto;
  final String createdAt;
  final String updatedAt;

  ExamenMedicoModel({
    required this.id,
    required this.paciente,
    this.doctor,
    required this.tipoExamen,
    required this.fechaExamen,
    this.resultado,
    this.descripcion,
    this.archivoAdjunto,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExamenMedicoModel.fromJson(Map<String, dynamic> json) {
    return ExamenMedicoModel(
      id: json['id'] ?? '',
      paciente: json['paciente'] ?? 0,
      doctor: json['doctor']?.toString(),
      tipoExamen: json['tipo_examen'] ?? '',
      fechaExamen: json['fecha_examen'] ?? '',
      resultado: json['resultado'],
      descripcion: json['descripcion'],
      archivoAdjunto: json['archivo_adjunto'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class ArritmiaModel {
  final String id;
  final int paciente;
  final String? doctor;
  final String tipoArritmia;
  final String fechaDeteccion;
  final String nivelRiesgo;
  final String estado;
  final String? observaciones;
  final List<SeguimientoArritmiaModel> seguimientos;
  final String createdAt;

  ArritmiaModel({
    required this.id,
    required this.paciente,
    this.doctor,
    required this.tipoArritmia,
    required this.fechaDeteccion,
    required this.nivelRiesgo,
    required this.estado,
    this.observaciones,
    required this.seguimientos,
    required this.createdAt,
  });

  factory ArritmiaModel.fromJson(Map<String, dynamic> json) {
    var listaSeguimientosRaw = json['seguimientos'] as List? ?? [];
    List<SeguimientoArritmiaModel> seguimientosMapeados = listaSeguimientosRaw
        .map((sJson) => SeguimientoArritmiaModel.fromJson(sJson))
        .toList();

    return ArritmiaModel(
      id: json['id'] ?? '',
      paciente: json['paciente'] ?? 0,
      doctor: json['doctor']?.toString(),
      tipoArritmia: json['tipo_arritmia'] ?? '',
      fechaDeteccion: json['fecha_deteccion'] ?? '',
      nivelRiesgo: json['nivel_riesgo'] ?? '',
      estado: json['estado'] ?? '',
      observaciones: json['observaciones'],
      seguimientos: seguimientosMapeados,
      createdAt: json['created_at'] ?? '',
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
  final List<ArritmiaModel> arritmias;
  final List<ExamenMedicoModel> examenesMedicos;

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
    required this.arritmias,
    required this.examenesMedicos,
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

    var listaArritmiasRaw = json['arritmias'] as List? ?? [];
    List<ArritmiaModel> arritmiasMapeadas = listaArritmiasRaw
        .map((aJson) => ArritmiaModel.fromJson(aJson))
        .toList();

    var listaExamenesRaw = json['examenes_medicos'] as List? ?? [];
    List<ExamenMedicoModel> examenesMapeados = listaExamenesRaw
        .map((eJson) => ExamenMedicoModel.fromJson(eJson))
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
      arritmias: arritmiasMapeadas,
      examenesMedicos: examenesMapeados,
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
