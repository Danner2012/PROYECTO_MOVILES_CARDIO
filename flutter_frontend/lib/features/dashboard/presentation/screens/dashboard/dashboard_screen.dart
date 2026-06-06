import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/dashboard/presentation/responsive.dart';
import 'package:flutter_frontend/features/auth/logic/auth_provider.dart';
import 'package:flutter_frontend/features/dashboard/presentation/screens/dashboard/components/my_fields.dart';

import '../../constants.dart';
import 'components/header.dart';
import 'components/recent_files.dart';
import 'components/storage_details.dart';

import 'package:flutter_frontend/features/dashboard/logic/dashboard_doctor_provider.dart';

import 'components/my_files_doctor.dart';
import 'components/recent_alerts.dart';
import 'components/next_appointments.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.rol.toLowerCase() == 'doctor') {
        Provider.of<DashboardDoctorProvider>(context, listen: false)
            .fetchDashboardData(authProvider.token!);
      }
    });
  }

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
                      if (rol == 'doctor') MyFilesDoctor() else if (rol != 'paciente') MyFiles(),
                      if (rol != 'paciente') SizedBox(height: defaultPadding),
                      
                      // RecentFiles: Visible para todos
                      if (rol == 'doctor') RecentAlerts() else RecentFiles(),
                      
                      if (Responsive.isMobile(context))
                        SizedBox(height: defaultPadding),
                      if (Responsive.isMobile(context)) (rol == 'doctor' ? NextAppointments() : StorageDetails()),
                    ],
                  ),
                ),
                if (!Responsive.isMobile(context))
                  SizedBox(width: defaultPadding),
                // StorageDetails: Siempre visible en desktop/tablet
                if (!Responsive.isMobile(context))
                  Expanded(
                    flex: 2,
                    child: rol == 'doctor' ? NextAppointments() : StorageDetails(),
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
