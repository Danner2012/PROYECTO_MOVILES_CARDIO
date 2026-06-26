import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/dashboard/logic/menu_app_controller.dart';
import '../../../constants.dart';

class PatientQuickActions extends StatelessWidget {
  const PatientQuickActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final menuController = Provider.of<MenuAppController>(context, listen: false);

    final List<Map<String, dynamic>> actions = [
      {
        "title": "Ver Mis Datos",
        "icon": Icons.health_and_safety_outlined,
        "color": Colors.blue,
        "page": "patient_ai",
        "description": "Ficha médica y datos básicos"
      },
      {
        "title": "Mis Arritmias",
        "icon": Icons.favorite_border_outlined,
        "color": Colors.redAccent,
        "page": "mis_arritmias",
        "description": "Lista de arritmias detectadas"
      },
      {
        "title": "Mis Exámenes",
        "icon": Icons.assignment_outlined,
        "color": Colors.teal,
        "page": "mis_examenes",
        "description": "Ver informes y resultados médicos"
      },
      {
        "title": "Mis Tratamientos",
        "icon": Icons.medication_outlined,
        "color": Colors.orange,
        "page": "mis_tratamientos",
        "description": "Ver recetas y dosis activas"
      },
    ];

    final Size _size = MediaQuery.of(context).size;
    final int crossAxisCount = _size.width < 600 ? 2 : 4;
    final double childAspectRatio = _size.width < 600 ? 1.3 : 1.2;

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
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action["title"] as String,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
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
                        fontSize: 9,
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
