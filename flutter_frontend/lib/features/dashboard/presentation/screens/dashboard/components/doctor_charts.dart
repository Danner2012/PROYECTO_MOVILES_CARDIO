import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_frontend/features/dashboard/logic/dashboard_doctor_provider.dart';
import 'package:flutter_frontend/features/dashboard/data/models/dashboard_doctor_model.dart';
import 'package:provider/provider.dart';
import '../../../constants.dart';

class DoctorCharts extends StatelessWidget {
  const DoctorCharts({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardDoctorProvider>(context);
    final data = dashboardProvider.data;

    if (dashboardProvider.isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (data == null) {
      return const SizedBox.shrink();
    }

    final hasRiesgoData = data.distribucionRiesgo.isNotEmpty;
    final hasTipoData = data.distribucionTipo.isNotEmpty;

    if (!hasRiesgoData && !hasTipoData) {
      return const SizedBox.shrink();
    }

    final Size _size = MediaQuery.of(context).size;
    final bool isMobile = _size.width < 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Análisis de Arritmias y Pacientes",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: defaultPadding),
        if (isMobile)
          Column(
            children: [
              if (hasRiesgoData) ...[
                _buildRiesgoCard(context, data.distribucionRiesgo),
                const SizedBox(height: defaultPadding),
              ],
              if (hasTipoData) _buildTipoCard(context, data.distribucionTipo),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasRiesgoData)
                Expanded(
                  child: _buildRiesgoCard(context, data.distribucionRiesgo),
                ),
              if (hasRiesgoData && hasTipoData)
                const SizedBox(width: defaultPadding),
              if (hasTipoData)
                Expanded(
                  child: _buildTipoCard(context, data.distribucionTipo),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildRiesgoCard(BuildContext context, List<RiesgoStat> stats) {
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
            "Distribución por Nivel de Riesgo",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: stats.map((stat) {
                        final color = _getColorForRiesgo(stat.nivelRiesgo);
                        return PieChartSectionData(
                          color: color,
                          value: stat.cantidad.toDouble(),
                          title: '${stat.cantidad}',
                          radius: 45,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: defaultPadding),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: stats.map((stat) {
                      final color = _getColorForRiesgo(stat.nivelRiesgo);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stat.nivelRiesgo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoCard(BuildContext context, List<TipoArritmiaStat> stats) {
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
            "Tipos de Arritmia más Comunes",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: stats.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stat = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: stat.cantidad.toDouble(),
                        color: Colors.blueAccent,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < stats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _getAbbreviation(stats[index].tipoArritmia),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Glosario para abreviaciones
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: stats.map((stat) {
              return Text(
                '${_getAbbreviation(stat.tipoArritmia)}: ${stat.tipoArritmia}',
                style: const TextStyle(fontSize: 10, color: Colors.white38),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getColorForRiesgo(String riesgo) {
    switch (riesgo.toLowerCase()) {
      case 'crítico':
      case 'critico':
        return Colors.red;
      case 'alto':
        return Colors.orange;
      case 'medio':
        return Colors.yellow;
      case 'bajo':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getAbbreviation(String name) {
    if (name.length <= 4) return name.toUpperCase();
    final words = name.split(' ');
    if (words.length > 1) {
      return words.map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    }
    return name.substring(0, 3).toUpperCase();
  }
}
