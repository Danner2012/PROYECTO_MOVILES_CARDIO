// lib/features/dashboard/presentation/screens/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../responsive.dart';
import 'components/header.dart';
import '../../../../pacientes/logic/pacientes_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pacProvider = Provider.of<PacientesProvider>(context);
    final totalPacientes = pacProvider.pacientes.length;

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
                // Panel Principal Izquierdo
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      // ── Tarjetas de Estado Clínico Superior ──
                      GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
                        crossAxisSpacing: defaultPadding,
                        mainAxisSpacing: defaultPadding,
                        // ▼ FIX: Proporción ajustada (1.1 en móviles, 1.3 en escritorio) para dar más altura
                        childAspectRatio: Responsive.isMobile(context) ? 1.1 : 1.3,
                        children: [
                          _MetricSummaryCard(title: "Pacientes", value: "$totalPacientes", sub: "Asignados", icon: Icons.assignment_ind, color: primaryColor),
                          _MetricSummaryCard(title: "Monitoreados", value: "$totalPacientes", sub: "Dispositivos activos", icon: Icons.favorite, color: Colors.green),
                          _MetricSummaryCard(title: "Casos Críticos", value: "0", sub: "Requieren revisión", icon: Icons.gpp_bad_rounded, color: Colors.redAccent),
                          _MetricSummaryCard(title: "Análisis IA Today", value: "0", sub: "Modelos procesados", icon: Icons.psychology_alt_rounded, color: Colors.purpleAccent),
                        ],
                      ),
                      const SizedBox(height: defaultPadding),
                      
                      // ── Tabla Central de Alertas y Evaluaciones Recientes ──
                      const _RecentEvaluationsTable(),
                    ],
                  ),
                ),
                
                // Panel Lateral Derecho: Segmentación de Riesgo General
                if (!Responsive.isMobile(context)) const SizedBox(width: defaultPadding),
                if (!Responsive.isMobile(context))
                  const Expanded(
                    flex: 2,
                    child: _DoctorRiskSummarySidePanel(),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// COMPONENTE: TARJETA DE MÉTRICA SUPERIOR
// ==========================================
class _MetricSummaryCard extends StatelessWidget {
  final String title, value, sub;
  final IconData icon;
  final Color color;

  const _MetricSummaryCard({
    required this.title, 
    required this.value, 
    required this.sub, 
    required this.icon, 
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // ▼ FIX: Reducimos un 15% el padding para evitar el overflow de 2 píxeles
      padding: const EdgeInsets.all(defaultPadding * 0.85),
      decoration: const BoxDecoration(
        color: secondaryColor, 
        borderRadius: BorderRadius.all(Radius.circular(10))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(defaultPadding * 0.4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const Icon(Icons.more_vert, color: Colors.white30, size: 16)
            ],
          ),
          const Spacer(), // ▼ FIX: Empuja el contenido hacia los extremos de forma segura
          Text(
            title, 
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
          const SizedBox(height: 2),
          // ▼ FIX: Si el número crece (ej: "10,000"), se encogerá en vez de desbordar la caja
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 2),
          Text(
            sub, 
            style: const TextStyle(color: Colors.white30, fontSize: 10), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENTE: TABLA DE EVALUACIONES RECIENTES
// ==========================================
class _RecentEvaluationsTable extends StatelessWidget {
  const _RecentEvaluationsTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pacProvider = Provider.of<PacientesProvider>(context);

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: const BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.all(Radius.circular(10))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Últimas Alertas Clínicas", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: defaultPadding / 2),
          SizedBox(
            width: double.infinity,
            child: pacProvider.pacientes.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: defaultPadding * 2),
                    child: Center(child: Text("No hay registros médicos cargados aún.", style: TextStyle(color: Colors.white38))),
                  )
                : DataTable(
                    columnSpacing: defaultPadding,
                    horizontalMargin: 0,
                    columns: const [
                      DataColumn(label: Text("Paciente")),
                      DataColumn(label: Text("Sexo")),
                      DataColumn(label: Text("Último Estado")),
                      DataColumn(label: Text("Diagnóstico IA")),
                    ],
                    rows: pacProvider.pacientes.take(5).map((paciente) {
                      // Sacamos el último control registrado si existe
                      final tieneControles = paciente.historialControles != null && paciente.historialControles!.isNotEmpty;
                      final ultimoDiag = tieneControles ? paciente.historialControles!.last['diagnostico_ecg'] ?? 'Normal' : 'Sin Controles';
                      
                      return DataRow(
                        cells: [
                          DataCell(Text(paciente.nombre, style: const TextStyle(color: Colors.white70))),
                          DataCell(Text(paciente.sexo, style: const TextStyle(color: Colors.white54))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: tieneControles ? Colors.green.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tieneControles ? "Estable" : "Pendiente",
                                style: TextStyle(color: tieneControles ? Colors.green : Colors.amber, fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(Text(ultimoDiag, style: const TextStyle(color: Colors.white38, fontStyle: FontStyle.italic))),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENTE: PANEL LATERAL DE RIESGOS GENERAL
// ==========================================
class _DoctorRiskSummarySidePanel extends StatelessWidget {
  const _DoctorRiskSummarySidePanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: const BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.all(Radius.circular(10))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Distribución de Riesgo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: defaultPadding),
          
          // Gráfica de pastel simulando estadísticas clínicas
          SizedBox(
            height: 150,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 100, height: 100,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: bgColor),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("100%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("Estabilidad", style: TextStyle(color: Colors.white38, fontSize: 9))
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: defaultPadding),
          
          const _RiskInfoCard(title: "Riesgo Cardiovascular Alto", count: "0 pac.", color: Colors.redAccent),
          const _RiskInfoCard(title: "Monitoreo Preventivo", count: "0 pac.", color: Colors.amber),
          const _RiskInfoCard(title: "Ritmo Sinusal Estable", count: "Todos", color: Colors.green),
        ],
      ),
    );
  }
}

class _RiskInfoCard extends StatelessWidget {
  final String title, count;
  final Color color;

  const _RiskInfoCard({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: defaultPadding / 2),
      padding: const EdgeInsets.all(defaultPadding * 0.75),
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: Colors.white.withOpacity(0.05)),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        children: [
          Icon(Icons.lens, color: color, size: 12),
          const SizedBox(width: defaultPadding / 2),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(count, style: const TextStyle(color: Colors.white38, fontSize: 11))
        ],
      ),
    );
  }
}