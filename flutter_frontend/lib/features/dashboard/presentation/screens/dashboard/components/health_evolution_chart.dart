import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/pacientes/logic/pacientes_provider.dart';
import 'package:flutter_frontend/features/pacientes/data/paciente_model.dart';
import '../../../constants.dart';

class HealthEvolutionChart extends StatelessWidget {
  const HealthEvolutionChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pacientesProvider = Provider.of<PacientesProvider>(context);
    final perfil = pacientesProvider.perfilPaciente;

    if (pacientesProvider.isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (perfil == null) {
      return const SizedBox.shrink();
    }

    // Tomamos los controles en orden cronológico (antiguo a nuevo para la gráfica)
    final List<ControlCardioModel> controles = List.from(perfil.historialControles.reversed);

    if (controles.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const Icon(Icons.show_chart, color: Colors.white24, size: 50),
            const SizedBox(height: 10),
            const Text(
              "Evolución de Signos Vitales",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 5),
            Text(
              "Se necesitan al menos 2 controles médicos para graficar la evolución de tus signos vitales. Consulta con tu doctor.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
      );
    }

    // Limitar a los últimos 7 controles para no saturar
    final lasControles = controles.length > 7 ? controles.sublist(controles.length - 7) : controles;

    List<FlSpot> fcSpots = [];
    List<FlSpot> pasSpots = [];

    for (int i = 0; i < lasControles.length; i++) {
      fcSpots.add(FlSpot(i.toDouble(), lasControles[i].frecuenciaCardiaca.toDouble()));
      pasSpots.add(FlSpot(i.toDouble(), lasControles[i].presionSistolica.toDouble()));
    }

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Evolución de Frecuencia Cardíaca y Presión",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Visualiza tus últimos controles cardiológicos",
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 20,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(color: Colors.white10, strokeWidth: 1);
                  },
                  getDrawingVerticalLine: (value) {
                    return const FlLine(color: Colors.white10, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < lasControles.length) {
                          // Mostrar fecha corta
                          final fechaStr = lasControles[index].fecha;
                          final datePart = fechaStr.split(' ')[0]; // YYYY-MM-DD
                          final parts = datePart.split('-');
                          final cleanDate = parts.length >= 3 ? '${parts[2]}/${parts[1]}' : datePart;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              cleanDate,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white10, width: 1),
                ),
                minX: 0,
                maxX: (lasControles.length - 1).toDouble(),
                minY: 40,
                maxY: 180,
                lineBarsData: [
                  // Frecuencia Cardíaca (Rojo)
                  LineChartBarData(
                    spots: fcSpots,
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.redAccent.withOpacity(0.05),
                    ),
                  ),
                  // Presión Sistólica (Azul)
                  LineChartBarData(
                    spots: pasSpots,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blueAccent.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem("Frecuencia Cardíaca (lpm)", Colors.redAccent),
              const SizedBox(width: defaultPadding),
              _buildLegendItem("Presión Sistólica (mmHg)", Colors.blueAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}
