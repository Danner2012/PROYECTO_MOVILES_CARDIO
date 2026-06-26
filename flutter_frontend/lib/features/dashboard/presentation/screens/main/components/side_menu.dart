import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/auth/logic/auth_provider.dart';
import 'package:flutter_frontend/features/dashboard/logic/menu_app_controller.dart';
import 'package:flutter_frontend/features/dashboard/presentation/responsive.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final menuController = Provider.of<MenuAppController>(context);
    final rol = authProvider.user?.rol.toLowerCase() ?? 'paciente';

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Image.asset(
              "assets/images/app.png",
              height: 100,
            ),
          ),
          DrawerListTile(
            title: "Dashboard",
            svgSrc: "assets/icons/menu_dashboard.svg",
            press: () {
              menuController.setSelectedPage("dashboard");
              if (!Responsive.isDesktop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          if (rol == 'paciente')
            DrawerListTile(
              title: "Mis Datos",
              svgSrc: "assets/icons/menu_task.svg",
              press: () {
                menuController.setSelectedPage("patient_ai");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (rol == 'doctor' || rol == 'superadmin' || rol == 'administrador')
            DrawerListTile(
              title: "Pacientes",
              svgSrc: "assets/icons/menu_profile.svg",
              press: () {
                menuController.setSelectedPage("pacientes");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (rol == 'doctor')
            DrawerListTile(
              title: "3. Historial Clínico",
              svgSrc: "assets/icons/menu_doc.svg",
              press: () {
                menuController.setSelectedPage("historial_clinico");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (rol == 'doctor')
            DrawerListTile(
              title: "4. Seguimiento de Arritmias",
              svgSrc: "assets/icons/media.svg",
              press: () {
                menuController.setSelectedPage("seguimiento_arritmias");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (rol == 'doctor')
            DrawerListTile(
              title: "5. Gestión de Exámenes",
              svgSrc: "assets/icons/menu_doc.svg",
              press: () {
                menuController.setSelectedPage("gestion_examenes");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (rol == 'doctor')
            DrawerListTile(
              title: "6. Tratamientos y Rec.",
              svgSrc: "assets/icons/menu_task.svg",
              press: () {
                menuController.setSelectedPage("tratamientos_recomendaciones");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (rol == 'doctor')
            DrawerListTile(
              title: "8. Reportes",
              svgSrc: "assets/icons/Documents.svg",
              press: () {
                menuController.setSelectedPage("reportes_pacientes");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (rol == 'doctor')
            DrawerListTile(
              title: "9. Análisis IA (ECG)",
              svgSrc: "assets/icons/menu_task.svg",
              press: () {
                menuController.setSelectedPage("ia_prediction");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (rol == 'paciente')
            DrawerListTile(
              title: "Mis Arritmias",
              svgSrc: "assets/icons/media.svg",
              press: () {
                menuController.setSelectedPage("mis_arritmias");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (rol == 'paciente')
            DrawerListTile(
              title: "Mis Exámenes",
              svgSrc: "assets/icons/menu_doc.svg",
              press: () {
                menuController.setSelectedPage("mis_examenes");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (rol == 'paciente')
            DrawerListTile(
              title: "Mis Tratamientos",
              svgSrc: "assets/icons/menu_task.svg",
              press: () {
                menuController.setSelectedPage("mis_tratamientos");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (rol == 'administrador' || rol == 'superadmin')
            DrawerListTile(
              title: "Médicos",
              svgSrc: "assets/icons/menu_doc.svg",
              press: () {
                menuController.setSelectedPage("doctors");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (rol == 'administrador' || rol == 'superadmin')
            DrawerListTile(
              title: "IA Predicción",
              svgSrc: "assets/icons/menu_task.svg",
              press: () {
                menuController.setSelectedPage("ia_prediction");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          if (rol == 'administrador' || rol == 'superadmin')
            DrawerListTile(
              title: "Ollama",
              svgSrc: "assets/icons/menu_notification.svg",
              press: () {
                menuController.setSelectedPage("ollama");
                if (!Responsive.isDesktop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
    Key? key,
    required this.title,
    required this.svgSrc,
    required this.press,
  }) : super(key: key);

  final String title, svgSrc;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      horizontalTitleGap: 0.0,
      leading: SvgPicture.asset(
        svgSrc,
        colorFilter: const ColorFilter.mode(Colors.white54, BlendMode.srcIn),
        height: 16,
      ),
      title: Text(title, style: const TextStyle(color: Colors.white54)),
    );
  }
}
