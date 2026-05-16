import 'package:flutter/material.dart';

class MenuAppController extends ChangeNotifier {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedPage = "dashboard";

  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;
  String get selectedPage => _selectedPage;

  void controlMenu() {
    if (!_scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.openDrawer();
    }
  }

  void setSelectedPage(String page) {
    _selectedPage = page;
    notifyListeners();
  }
}
