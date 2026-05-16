

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      key: menuController.scaffoldKey,
      drawer: SideMenu(),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // We want this side menu only for large screen
            if (Responsive.isDesktop(context))
              Expanded(
                // default flex = 1
                // and it takes 1/6 part of the screen
                child: SideMenu(),
              ),
            Expanded(
              // It takes 5/6 part of the screen
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
