import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_frontend/features/dashboard/presentation/screens/dashboard/components/header.dart';
import 'package:flutter_frontend/features/dashboard/presentation/constants.dart';
import 'package:flutter_frontend/features/auth/logic/auth_provider.dart';
import 'package:flutter_frontend/features/ia_prediction/logic/prediction_provider.dart';
import 'package:flutter_frontend/features/ia_prediction/data/models/ecg_models.dart';
import 'package:flutter_frontend/features/pacientes/logic/pacientes_provider.dart';
import 'package:flutter_frontend/features/pacientes/data/paciente_model.dart';

class IaPredictionScreen extends StatefulWidget {
  const IaPredictionScreen({Key? key}) : super(key: key);

  @override
  State<IaPredictionScreen> createState() => _IaPredictionScreenState();
}

class _IaPredictionScreenState extends State<IaPredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _bpmController       = TextEditingController(text: "72");
  final TextEditingController _bpmAvgController    = TextEditingController(text: "74");
  final TextEditingController _rrController        = TextEditingController(text: "830");
  final TextEditingController _hrvController       = TextEditingController(text: "15");
  final TextEditingController _electrodesController= TextEditingController(text: "1");
  final TextEditingController _qualityController   = TextEditingController(text: "85");
  final TextEditingController _amplitudeController = TextEditingController(text: "1400");
  final TextEditingController _loPlusController    = TextEditingController(text: "0");
  final TextEditingController _loMinusController   = TextEditingController(text: "0");

  PacienteModel? _selectedPatient;
  String? _lastAnalyzedPatient;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final rol = authProvider.user?.rol.toLowerCase();
      if (rol == 'doctor') {
        Provider.of<PacientesProvider>(context, listen: false)
            .cargarPacientes(authProvider.token ?? '');
      }
    });
  }

  @override
  void dispose() {
    _bpmController.dispose();
    _bpmAvgController.dispose();
    _rrController.dispose();
    _hrvController.dispose();
    _electrodesController.dispose();
    _qualityController.dispose();
    _amplitudeController.dispose();
    _loPlusController.dispose();
    _loMinusController.dispose();
    super.dispose();
  }

  void _onPredict() {
    if (_formKey.currentState!.validate()) {
      final authProvider       = Provider.of<AuthProvider>(context, listen: false);
      final predictionProvider = Provider.of<IaPredictionProvider>(context, listen: false);
      final rol = authProvider.user?.rol.toLowerCase();

      if (rol == 'doctor' && _selectedPatient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Selecciona un paciente antes de analizar"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _lastAnalyzedPatient = _selectedPatient?.nombre;
      });

      final request = EcgPredictionRequest(
        bpm:                 double.parse(_bpmController.text),
        bpmAverage:          double.parse(_bpmAvgController.text),
        rrInterval:          double.parse(_rrController.text),
        hrv:                 double.parse(_hrvController.text),
        electrodesConnected: int.parse(_electrodesController.text),
        signalQuality:       double.parse(_qualityController.text),
        amplitude:           double.parse(_amplitudeController.text),
        loPlus:              int.parse(_loPlusController.text),
        loMinus:             int.parse(_loMinusController.text),
      );

      predictionProvider.performAnalysis(request, authProvider.token ?? "");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final rol = authProvider.user?.rol.toLowerCase();
    final isDoctor = rol == 'doctor';

    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Header(),
            const SizedBox(height: defaultPadding),
            // Banner contextual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.biotech_outlined, color: Colors.blueAccent, size: 28),
                  ),
                  const SizedBox(width: defaultPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDoctor
                              ? "Análisis Cardíaco con IA — Vista Médica"
                              : "Análisis Cardíaco con IA",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDoctor
                              ? "Selecciona un paciente e ingresa los parámetros del ECG para obtener un diagnóstico asistido por inteligencia artificial."
                              : "Ingresa los parámetros del ECG para obtener un diagnóstico preliminar asistido por IA.",
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: defaultPadding),
            // Selector de paciente (solo Doctor)
            if (isDoctor) ...[
              _buildPatientSelector(),
              const SizedBox(height: defaultPadding),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildInputForm()),
                const SizedBox(width: defaultPadding),
                Expanded(flex: 3, child: _buildResultsSection()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelector() {
    return Consumer<PacientesProvider>(
      builder: (context, prov, _) {
        final pacientes = prov.pacientes;
        return Container(
          padding: const EdgeInsets.all(defaultPadding),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Paciente a Analizar",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                "Al seleccionar un paciente, sus últimos datos de frecuencia se autocompletarán.",
                style: TextStyle(fontSize: 11, color: Colors.white38),
              ),
              const SizedBox(height: defaultPadding),
              if (prov.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (pacientes.isEmpty)
                const Text(
                  "No tienes pacientes registrados aún.",
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                )
              else
                DropdownButtonFormField<PacienteModel>(
                  value: _selectedPatient,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    hintText: "Seleccionar paciente...",
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.person_search_outlined, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                  dropdownColor: const Color(0xFF161B22),
                  style: const TextStyle(color: Colors.white),
                  items: pacientes.map((p) {
                    return DropdownMenuItem<PacienteModel>(
                      value: p,
                      child: Text(
                        "${p.nombre} — ${p.email}",
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPatient = value);
                    // Autocompletar BPM desde el último control del paciente
                    if (value != null && value.historialControles.isNotEmpty) {
                      final ultimo = value.historialControles.first;
                      _bpmController.text    = ultimo.frecuenciaCardiaca.toString();
                      _bpmAvgController.text = ultimo.frecuenciaCardiaca.toString();
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.white10),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Parámetros del ECG",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              "Ingresa los valores del sensor de electrocardiograma",
              style: TextStyle(fontSize: 11, color: Colors.white38),
            ),
            const SizedBox(height: defaultPadding),
            _buildTextField(_bpmController,        "BPM",                 "Ej: 72",   "Pulsaciones por minuto actuales"),
            _buildTextField(_bpmAvgController,     "BPM Promedio",        "Ej: 74",   "Promedio de latidos en la sesión"),
            _buildTextField(_rrController,         "Intervalo RR (ms)",   "Ej: 830",  "Tiempo entre latidos sucesivos"),
            _buildTextField(_hrvController,        "HRV",                 "Ej: 15",   "Variabilidad del ritmo cardíaco"),
            _buildTextField(_electrodesController, "Electrodos (0/1)",    "1",        "1=Conectado, 0=Desconectado"),
            _buildTextField(_qualityController,    "Calidad de Señal (%)", "Ej: 85",  "Porcentaje de calidad del ECG"),
            _buildTextField(_amplitudeController,  "Amplitud",            "Ej: 1400", "Amplitud de la onda R en el ECG"),
            _buildTextField(_loPlusController,     "LO Plus",             "0",        "Señal de electrodo positivo perdido"),
            _buildTextField(_loMinusController,    "LO Minus",            "0",        "Señal de electrodo negativo perdido"),
            const SizedBox(height: defaultPadding),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _onPredict,
                icon: const Icon(Icons.psychology_outlined),
                label: const Text("Analizar con IA"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, String helper) {
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding / 2),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          helperStyle: const TextStyle(fontSize: 10, color: Colors.white38),
          fillColor: const Color(0xFF0D1117),
          filled: true,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Colors.white10),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Requerido";
          if (double.tryParse(value) == null) return "Debe ser un número válido";
          return null;
        },
      ),
    );
  }

  Widget _buildResultsSection() {
    return Consumer<IaPredictionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Container(
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Analizando señal ECG con IA...", style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          );
        }

        if (provider.error != null) {
          return Container(
            padding: const EdgeInsets.all(defaultPadding),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
                const SizedBox(height: 12),
                const Text(
                  "Error de Conexión con el Modelo IA",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (provider.predictionResult == null) {
          return Container(
            padding: const EdgeInsets.all(defaultPadding * 2),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.psychology_outlined, size: 80, color: Colors.white24),
                  SizedBox(height: defaultPadding),
                  Text(
                    "Listo para analizar",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Completa los datos del ECG y presiona\n\"Analizar con IA\" para obtener el diagnóstico.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        final result = provider.predictionResult!;
        return Column(
          children: [
            _buildPredictionCard(result),
            const SizedBox(height: defaultPadding),
            if (provider.graphResult != null) _buildGraphCard(provider.graphResult!),
          ],
        );
      },
    );
  }

  Widget _buildPredictionCard(EcgPredictionResponse result) {
    final isNormal    = result.prediction.toLowerCase() == 'normal';
    final statusColor = isNormal ? Colors.greenAccent : Colors.orangeAccent;
    final statusIcon  = isNormal ? Icons.check_circle_outlined : Icons.warning_amber_outlined;

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resultado del Análisis",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          if (_lastAnalyzedPatient != null) ...[
            const SizedBox(height: 4),
            Text(
              "Paciente: $_lastAnalyzedPatient",
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
          const SizedBox(height: defaultPadding),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(defaultPadding),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 40),
                const SizedBox(width: defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.prediction.toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        isNormal
                            ? "El ECG muestra un ritmo cardíaco dentro de parámetros normales."
                            : "Se detectaron anomalías en la señal. Se recomienda revisión médica.",
                        style: const TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Confianza", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text(
                      "${(result.confidence * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphCard(EcgGraphResponse graph) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Señal ECG Simulada por el Modelo",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            "Forma de onda generada por la IA basada en los parámetros ingresados",
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: defaultPadding),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.white10)),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      graph.time.length,
                      (i) => FlSpot(graph.time[i], graph.signal[i]),
                    ),
                    isCurved: true,
                    color: primaryColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryColor.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
