// lib/features/pacientes/presentation/screens/pacientes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/auth/logic/auth_provider.dart';
import '../../../dashboard/presentation/constants.dart';
import '../../../dashboard/presentation/responsive.dart';
import '../../../dashboard/presentation/screens/dashboard/components/header.dart';
import '../../logic/pacientes_provider.dart';
import 'expediente_screen.dart';
import 'registrar_paciente_screen.dart';

class PacientesScreen extends StatefulWidget {
  const PacientesScreen({Key? key}) : super(key: key);

  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      Provider.of<PacientesProvider>(context, listen: false).cargarPacientes(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final prov = Provider.of<PacientesProvider>(context);

    return SafeArea(
      child: prov.isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                children: [
                  const Header(),
                  const SizedBox(height: defaultPadding),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna Principal
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Usamos Flexible para evitar desbordamientos de texto en pantallas pequeñas
                                Flexible(
                                  child: Text(
                                    "Ecosistema de Pacientes",
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  // ◄ FIX: Usamos ElevatedButton.styleFrom y agregamos minimumSize
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(120, 45), // ◄ ANULA EL INFINITO GLOBAL
                                    padding: EdgeInsets.symmetric(
                                      horizontal: defaultPadding * 1.5,
                                      vertical: defaultPadding / (Responsive.isMobile(context) ? 2 : 1),
                                    ),
                                    backgroundColor: primaryColor,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => RegistrarPacienteScreen(token: token)),
                                    ).then((_) {
                                      Provider.of<PacientesProvider>(context, listen: false).cargarPacientes(token);
                                    });
                                  },
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  label: const Text("Registrar", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                            const SizedBox(height: defaultPadding),
                            const PacientesSummaryCards(),
                            const SizedBox(height: defaultPadding),
                            
                            PacientesDataTable(token: token),
                            
                            if (Responsive.isMobile(context)) const SizedBox(height: defaultPadding),
                            if (Responsive.isMobile(context)) const PacientesRiskSidePanel(),
                          ],
                        ),
                      ),
                      
                      // Panel Lateral
                      if (!Responsive.isMobile(context)) const SizedBox(width: defaultPadding),
                      if (!Responsive.isMobile(context))
                        const Expanded(
                          flex: 2,
                          child: PacientesRiskSidePanel(),
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
// COMPONENTE: TARJETAS INFORMATIVAS RÁPIDAS
// ==========================================
class PacientesSummaryCards extends StatelessWidget {
  const PacientesSummaryCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PacientesProvider>(context);
    final totalPacientes = provider.pacientes.length;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 3,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isMobile(context) ? 1 : 3,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: Responsive.isMobile(context) ? 2.5 : 1.4,
      ),
      itemBuilder: (context, index) {
        List<Map<String, dynamic>> cardData = [
          {"title": "Total Pacientes", "value": "$totalPacientes", "icon": Icons.people, "color": primaryColor},
          {"title": "En Monitoreo", "value": "$totalPacientes", "icon": Icons.favorite, "color": Colors.green},
          {"title": "Casos Críticos", "value": "0", "icon": Icons.warning, "color": Colors.orange},
        ];

        return Container(
          padding: const EdgeInsets.all(defaultPadding),
          decoration: const BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(defaultPadding * 0.75),
                    decoration: BoxDecoration(
                      color: cardData[index]["color"].withOpacity(0.1),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Icon(cardData[index]["icon"], color: cardData[index]["color"]),
                  ),
                  const Icon(Icons.more_vert, color: Colors.white54)
                ],
              ),
              Text(cardData[index]["title"], maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                cardData[index]["value"],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              )
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// COMPONENTE: TABLA DE PACIENTES 
// ==========================================
class PacientesDataTable extends StatelessWidget {
  final String token;
  const PacientesDataTable({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PacientesProvider>(context);

    // Si no hay pacientes y no está cargando, mostramos un mensaje amigable
    if (provider.pacientes.isEmpty && !provider.isLoading) {
       return Container(
         width: double.infinity,
         padding: const EdgeInsets.all(defaultPadding * 2),
         decoration: const BoxDecoration(
           color: secondaryColor,
           borderRadius: BorderRadius.all(Radius.circular(10)),
         ),
         child: Column(
           children: [
             Icon(Icons.folder_shared_outlined, size: 48, color: Colors.white.withOpacity(0.3)),
             const SizedBox(height: defaultPadding),
             const Text("No hay pacientes vinculados.", style: TextStyle(color: Colors.white54)),
           ],
         ),
       );
    }

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: const BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Listado Clínico",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              columnSpacing: defaultPadding,
              horizontalMargin: 0,
              columns: const [
                DataColumn(label: Text("Paciente")),
                DataColumn(label: Text("Email")),
                DataColumn(label: Text("Edad")),
                DataColumn(label: Text("Acciones")),
              ],
              rows: provider.pacientes.map((paciente) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: primaryColor,
                            radius: 14,
                            child: Icon(Icons.person, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: defaultPadding / 2),
                          Text(paciente.nombre), 
                        ],
                      ),
                    ),
                    DataCell(Text(paciente.email)),
                    DataCell(Text("${paciente.edad} años")),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.assignment_ind, color: primaryColor),
                        tooltip: "Ver Expediente",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExpedienteScreen(paciente: paciente),
                            ),
                          ).then((_) {
                            Provider.of<PacientesProvider>(context, listen: false).cargarPacientes(token);
                          });
                        },
                      ),
                    ),
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
// COMPONENTE: PANEL LATERAL GRÁFICO
// ==========================================
class PacientesRiskSidePanel extends StatelessWidget {
  const PacientesRiskSidePanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: const BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Segmentación de Riesgo",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
          ),
          const SizedBox(height: defaultPadding),
          
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: bgColor,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("100%", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                          const Text("Estables", style: TextStyle(color: Colors.white54))
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: defaultPadding),
          
          const RiskIndicatorRow(title: "Riesgo Alto", count: "0 Pacientes", color: Colors.orange),
          const RiskIndicatorRow(title: "Riesgo Normal", count: "Todos", color: Colors.green),
          const RiskIndicatorRow(title: "En Tratamiento", count: "Activos", color: primaryColor),
        ],
      ),
    );
  }
}

class RiskIndicatorRow extends StatelessWidget {
  final String title, count;
  final Color color;

  const RiskIndicatorRow({
    Key? key,
    required this.title,
    required this.count,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: primaryColor.withOpacity(0.15)),
        borderRadius: const BorderRadius.all(Radius.circular(defaultPadding)),
      ),
      child: Row(
        children: [
          Icon(Icons.lens, color: color, size: 16),
          const SizedBox(width: defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Text(count, style: const TextStyle(color: Colors.white70))
        ],
      ),
    );
  }
}