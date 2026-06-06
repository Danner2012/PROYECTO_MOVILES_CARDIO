import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/dashboard/logic/dashboard_doctor_provider.dart';
import 'package:flutter_frontend/features/dashboard/data/models/dashboard_doctor_model.dart';
import '../../../constants.dart';

class RecentAlerts extends StatelessWidget {
  const RecentAlerts({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardDoctorProvider>(context);
    final alerts = dashboardProvider.data?.alertasRecientes ?? [];

    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Alertas de Arritmias Recientes",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              columnSpacing: defaultPadding,
              columns: [
                DataColumn(label: Text("Paciente")),
                DataColumn(label: Text("Tipo")),
                DataColumn(label: Text("Riesgo")),
                DataColumn(label: Text("Fecha")),
              ],
              rows: List.generate(
                alerts.length,
                (index) => alertDataRow(alerts[index]),
              ),
            ),
          ),
          if (alerts.isEmpty && !dashboardProvider.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: Center(child: Text("No hay alertas recientes")),
            ),
        ],
      ),
    );
  }
}

DataRow alertDataRow(AlertaReciente alert) {
  Color riskColor = Colors.white;
  if (alert.nivelRiesgo == 'Crítico') riskColor = Colors.red;
  if (alert.nivelRiesgo == 'Alto') riskColor = Colors.orange;

  return DataRow(
    cells: [
      DataCell(
        Row(
          children: [
            Icon(Icons.person, size: 20, color: Colors.blue),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Text(alert.pacienteNombre),
            ),
          ],
        ),
      ),
      DataCell(Text(alert.tipoArritmia)),
      DataCell(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: riskColor),
          ),
          child: Text(
            alert.nivelRiesgo,
            style: TextStyle(color: riskColor),
          ),
        ),
      ),
      DataCell(Text(alert.fecha)),
    ],
  );
}
