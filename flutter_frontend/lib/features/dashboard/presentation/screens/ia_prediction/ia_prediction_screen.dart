import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_frontend/features/dashboard/presentation/screens/dashboard/components/header.dart';
import 'package:flutter_frontend/features/dashboard/presentation/constants.dart';
import 'package:flutter_frontend/features/auth/logic/auth_provider.dart';
import 'package:flutter_frontend/features/ia_prediction/logic/prediction_provider.dart';
import 'package:flutter_frontend/features/ia_prediction/data/models/ecg_models.dart';

class IaPredictionScreen extends StatefulWidget {
  const IaPredictionScreen({Key? key}) : super(key: key);

  @override
  State<IaPredictionScreen> createState() => _IaPredictionScreenState();
}

class _IaPredictionScreenState extends State<IaPredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for the 9 fields
  final TextEditingController _bpmController = TextEditingController(text: "72");
  final TextEditingController _bpmAvgController = TextEditingController(text: "74");
  final TextEditingController _rrController = TextEditingController(text: "830");
  final TextEditingController _hrvController = TextEditingController(text: "15");
  final TextEditingController _electrodesController = TextEditingController(text: "1");
  final TextEditingController _qualityController = TextEditingController(text: "85");
  final TextEditingController _amplitudeController = TextEditingController(text: "1400");
  final TextEditingController _loPlusController = TextEditingController(text: "0");
  final TextEditingController _loMinusController = TextEditingController(text: "0");

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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final predictionProvider = Provider.of<IaPredictionProvider>(context, listen: false);
      
      final request = EcgPredictionRequest(
        bpm: double.parse(_bpmController.text),
        bpmAverage: double.parse(_bpmAvgController.text),
        rrInterval: double.parse(_rrController.text),
        hrv: double.parse(_hrvController.text),
        electrodesConnected: int.parse(_electrodesController.text),
        signalQuality: double.parse(_qualityController.text),
        amplitude: double.parse(_amplitudeController.text),
        loPlus: int.parse(_loPlusController.text),
        loMinus: int.parse(_loMinusController.text),
      );

      predictionProvider.performAnalysis(request, authProvider.token ?? "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            const Header(),
            const SizedBox(height: defaultPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildInputForm(),
                ),
                const SizedBox(width: defaultPadding),
                Expanded(
                  flex: 3,
                  child: _buildResultsSection(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Datos del ECG",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: defaultPadding),
            _buildTextField(_bpmController, "BPM", "Ej: 72"),
            _buildTextField(_bpmAvgController, "BPM Promedio", "Ej: 74"),
            _buildTextField(_rrController, "Intervalo RR", "Ej: 830"),
            _buildTextField(_hrvController, "HRV", "Ej: 15"),
            _buildTextField(_electrodesController, "Electrodos (0/1)", "1"),
            _buildTextField(_qualityController, "Calidad Señal (%)", "Ej: 85"),
            _buildTextField(_amplitudeController, "Amplitud", "Ej: 1400"),
            _buildTextField(_loPlusController, "LO Plus", "0"),
            _buildTextField(_loMinusController, "LO Minus", "0"),
            const SizedBox(height: defaultPadding),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onPredict,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                ),
                child: const Text("Analizar con IA"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding / 2),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          fillColor: bgColor,
          filled: true,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Requerido";
          if (double.tryParse(value) == null) return "Inválido";
          return null;
        },
      ),
    );
  }

  Widget _buildResultsSection() {
    return Consumer<IaPredictionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Container(
            padding: const EdgeInsets.all(defaultPadding),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Text("Error: ${provider.error}"),
          );
        }

        if (provider.predictionResult == null) {
          return Container(
            padding: const EdgeInsets.all(defaultPadding),
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.psychology_outlined, size: 80, color: Colors.white24),
                  SizedBox(height: defaultPadding),
                  Text("Ingrese los datos para iniciar el análisis"),
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
            if (provider.graphResult != null)
              _buildGraphCard(provider.graphResult!),
          ],
        );
      },
    );
  }

  Widget _buildPredictionCard(EcgPredictionResponse result) {
    Color statusColor = result.prediction.toLowerCase() == 'normal' ? Colors.green : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Resultado del Análisis", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: defaultPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Predicción", style: TextStyle(color: Colors.white54)),
                  Text(
                    result.prediction.toUpperCase(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Confianza", style: TextStyle(color: Colors.white54)),
                  Text(
                    "${(result.confidence * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
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
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Señal ECG Generada", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: defaultPadding),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: true),
                titlesData: FlTitlesData(show: false),
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
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryColor.withOpacity(0.1),
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
