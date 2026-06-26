import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/dashboard/logic/menu_app_controller.dart';
import '../../../constants.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final menuController = Provider.of<MenuAppController>(context, listen: false);

    final List<Map<String, dynamic>> actions = [
      {
        "title": "Ver Pacientes",
        "icon": Icons.people_outline,
        "color": Colors.blue,
        "page": "pacientes",
        "description": "Lista de pacientes y registro"
      },
      {
        "title": "Historiales Clínicos",
        "icon": Icons.assignment_outlined,
        "color": Colors.purple,
        "page": "historial_clinico",
        "description": "Consultar historial de consultas"
      },
      {
        "title": "Seguimiento Arritmias",
        "icon": Icons.monitor_heart_outlined,
        "color": Colors.redAccent,
        "page": "seguimiento_arritmias",
        "description": "Monitoreo y evolución de alertas"
      },
      {
        "title": "Gestionar Exámenes",
        "icon": Icons.science_outlined,
        "color": Colors.teal,
        "page": "gestion_examenes",
        "description": "Subir ECG, Holter e informes"
      },
      {
        "title": "Tratamientos y Rec.",
        "icon": Icons.medication_outlined,
        "color": Colors.orange,
        "page": "tratamientos_recomendaciones",
        "description": "Recetas y sugerencias de dieta"
      },
      {
        "title": "Reportes Médicos",
        "icon": Icons.picture_as_pdf_outlined,
        "color": Colors.deepOrange,
        "page": "reportes_pacientes",
        "description": "Generar e imprimir reportes PDF"
      },
    ];

    final Size _size = MediaQuery.of(context).size;
    final int crossAxisCount = _size.width < 650 ? 2 : (_size.width < 1100 ? 3 : 6);
    final double childAspectRatio = _size.width < 650 ? 1.3 : 1.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Accesos Rápidos",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: defaultPadding),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: defaultPadding,
            mainAxisSpacing: defaultPadding,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return InkWell(
              onTap: () {
                menuController.setSelectedPage(action["page"]);
              },
              borderRadius: BorderRadius.circular(10),
              child: Ink(
                padding: const EdgeInsets.all(defaultPadding),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (action["color"] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        action["icon"] as IconData,
                        color: action["color"] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action["title"] as String,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action["description"] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
