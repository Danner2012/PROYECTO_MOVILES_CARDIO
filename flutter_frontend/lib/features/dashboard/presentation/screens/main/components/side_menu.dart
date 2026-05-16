import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/auth/logic/auth_provider.dart';
import 'package:flutter_frontend/features/dashboard/logic/menu_app_controller.dart';

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
              height: 100, // Un poco más grande
            ),
          ),
          DrawerListTile(
            title: "Dashboard",
            svgSrc: "assets/icons/menu_dashboard.svg",
            press: () {
              menuController.setSelectedPage("dashboard");
            },
          ),
          if (rol == 'administrador' || rol == 'superadmin')
            DrawerListTile(
              title: "Médicos",
              svgSrc: "assets/icons/menu_doc.svg",
              press: () {
                menuController.setSelectedPage("doctors");
              },
            ),
          if (rol == 'administrador' || rol == 'superadmin')
            DrawerListTile(
              title: "IA Predicción",
              svgSrc: "assets/icons/menu_task.svg",
              press: () {
                menuController.setSelectedPage("ia_prediction");
              },
            ),
          if (rol == 'administrador' || rol == 'superadmin')
            DrawerListTile(
              title: "Ollama",
              svgSrc: "assets/icons/menu_notification.svg",
              press: () {
                menuController.setSelectedPage("ollama");
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
    // For selecting those three line once press "Command+D"
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
        colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
        height: 16,
      ),
      title: Text(title, style: TextStyle(color: Colors.white54)),
    );
  }
}
