

import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/dashboard/logic/menu_app_controller.dart';
import 'package:flutter_frontend/features/dashboard/presentation/responsive.dart';
import 'package:flutter_frontend/features/dashboard/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_frontend/features/dashboard/presentation/screens/doctors/doctors_screen.dart';
import 'package:flutter_frontend/features/dashboard/presentation/screens/ia_prediction/ia_prediction_screen.dart';
import 'package:flutter_frontend/features/ollama/presentation/screens/ollama/ollama_screen.dart';
import 'package:provider/provider.dart';

import 'components/side_menu.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final menuController = Provider.of<MenuAppController>(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      key: menuController.scaffoldKey,
      // Solo mostramos el drawer si NO es escritorio, 
      // para evitar duplicar el SideMenu (y sus llaves) en el árbol de widgets.
      drawer: !isDesktop ? const SideMenu() : null,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop)
              const Expanded(
                child: SideMenu(),
              ),
            Expanded(
              flex: 5,
              child: _getContent(menuController.selectedPage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getContent(String page) {
    switch (page) {
      case "dashboard":
        return DashboardScreen();
      case "doctors":
        return DoctorsScreen();
      case "ia_prediction":
        return IaPredictionScreen();
      case "ollama":
        return OllamaScreen();
      default:
        return DashboardScreen();
    }
  }
}
