// lib/features/dashboard/logic/menu_app_controller.dart
import 'package:flutter/material.dart';

class MenuAppController extends ChangeNotifier {
  String _selectedPage = "dashboard";

  String get selectedPage => _selectedPage;

  void controlMenu(BuildContext context) {
    final scaffold = Scaffold.of(context);
    if (scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    } else {
      scaffold.openDrawer();
    }
  }

  void setSelectedPage(String page) {
    _selectedPage = page;
    notifyListeners();
  }
}
