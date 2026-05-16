import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/dashboard/presentation/responsive.dart';
import 'package:flutter_frontend/features/auth/logic/auth_provider.dart';
import 'package:flutter_frontend/features/dashboard/presentation/screens/dashboard/components/my_fields.dart';

import '../../constants.dart';
import 'components/header.dart';
import 'components/recent_files.dart';
import 'components/storage_details.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final rol = user?.rol.toLowerCase() ?? 'paciente';

    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Header(),
            SizedBox(height: defaultPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      // Título dinámico según el rol
                      _buildRoleTitle(context, rol),
                      SizedBox(height: defaultPadding),
                      
                      // MyFiles: Visible para todos menos quizás pacientes (o personalizado)
                      if (rol != 'paciente') MyFiles(),
                      if (rol != 'paciente') SizedBox(height: defaultPadding),
                      
                      // RecentFiles: Visible para todos
                      RecentFiles(),
                      
                      if (Responsive.isMobile(context))
                        SizedBox(height: defaultPadding),
                      if (Responsive.isMobile(context)) StorageDetails(),
                    ],
                  ),
                ),
                if (!Responsive.isMobile(context))
                  SizedBox(width: defaultPadding),
                // StorageDetails: Siempre visible en desktop/tablet
                if (!Responsive.isMobile(context))
                  Expanded(
                    flex: 2,
                    child: StorageDetails(),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTitle(BuildContext context, String rol) {
    String title = "Dashboard";
    if (rol == 'superadmin') title = "Panel de Control - SuperAdmin";
    if (rol == 'administrador') title = "Gestión del Sistema - Admin";
    if (rol == 'doctor') title = "Panel Médico - Especialista";
    if (rol == 'paciente') title = "Mi Historial de Salud";

    return Container(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
