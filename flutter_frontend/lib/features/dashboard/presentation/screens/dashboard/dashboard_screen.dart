import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/dashboard/presentation/responsive.dart';
import 'package:flutter_frontend/features/auth/logic/auth_provider.dart';
import 'package:flutter_frontend/features/dashboard/presentation/screens/dashboard/components/my_fields.dart';

import 'package:flutter_frontend/features/pacientes/presentation/screens/ecg_screen.dart'; // <--- NUEVA IMPORTACIÓN
import '../../constants.dart';
import 'components/header.dart';
import 'components/recent_files.dart';
import 'components/storage_details.dart';

import 'package:flutter_frontend/features/dashboard/logic/dashboard_doctor_provider.dart';
import 'package:flutter_frontend/features/pacientes/logic/pacientes_provider.dart';

import 'components/my_files_doctor.dart';
import 'components/recent_alerts.dart';
import 'components/next_appointments.dart';
import 'components/quick_actions.dart';
import 'components/doctor_charts.dart';

// Importaciones de los componentes del Paciente
import 'components/patient_quick_actions.dart';
import 'components/my_health_summary.dart';
import 'components/health_evolution_chart.dart';
import 'components/active_treatments.dart';
import 'components/patient_recent_exams.dart';

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
      final rol = authProvider.user?.rol.toLowerCase();
      
      if (rol == 'doctor') {
        Provider.of<DashboardDoctorProvider>(context, listen: false)
            .fetchDashboardData(authProvider.token!);
      } else if (rol == 'paciente') {
        final pacientesProv = Provider.of<PacientesProvider>(context, listen: false);
        pacientesProv.fetchMisControles(authProvider.token!);
        pacientesProv.fetchMisArritmias(authProvider.token!);
        pacientesProv.fetchMisExamenes(authProvider.token!);
        pacientesProv.fetchMisTratamientos(authProvider.token!);
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
                      
                      // Vistas condicionales según el Rol
                      if (rol == 'doctor') ...[
                        QuickActions(),
                        SizedBox(height: defaultPadding),
                        MyFilesDoctor(),
                        SizedBox(height: defaultPadding),
                        DoctorCharts(),
                        SizedBox(height: defaultPadding),
                        RecentAlerts(),
                      ] else if (rol == 'paciente') ...[
                        PatientQuickActions(),
                        SizedBox(height: defaultPadding),
                        MyHealthSummary(),
                        SizedBox(height: defaultPadding),
                        HealthEvolutionChart(),
                        SizedBox(height: defaultPadding),
                        ActiveTreatments(),
                      ] else ...[
                        MyFiles(),
                        SizedBox(height: defaultPadding),
                        RecentFiles(),
                      ],
                      // MyFiles: Visible para todos menos quizás pacientes (o personalizado)
                      if (rol != 'paciente') MyFiles(),
                      if (rol != 'paciente') SizedBox(height: defaultPadding),
                      
                      // RecentFiles: Visible para todos
                      RecentFiles(),
                      
                      if (Responsive.isMobile(context)) ...[
                        SizedBox(height: defaultPadding),
                        _buildMobileSideContent(rol),
                      ],
                    ],
                  ),
                ),
                if (!Responsive.isMobile(context)) ...[
                  SizedBox(width: defaultPadding),
                  Expanded(
                    flex: 2,
                    child: _buildDesktopSideContent(rol),
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSideContent(String rol) {
    if (rol == 'doctor') {
      return NextAppointments();
    } else if (rol == 'paciente') {
      return const PatientRecentExams();
    } else {
      return StorageDetails();
    }
  }

  Widget _buildDesktopSideContent(String rol) {
    if (rol == 'doctor') {
      return NextAppointments();
    } else if (rol == 'paciente') {
      return const PatientRecentExams();
    } else {
      return StorageDetails();
    }
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
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  // Tarjeta elegante de acceso al ECG para el paciente
  Widget _buildEcgAccessCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor, // Usando los colores de tu plantilla
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Monitoreo Cardíaco Activo",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.favorite, color: Colors.redAccent, size: 28),
            ],
          ),
          SizedBox(height: defaultPadding / 2),
          Text(
            "Accede al monitoreo en tiempo real de tu electrocardiograma (AD8232) y visualiza las métricas analizadas por nuestra Inteligencia Artificial.",
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          SizedBox(height: defaultPadding),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // El color azul/teal por defecto del dashboard
                padding: EdgeInsets.symmetric(
                  vertical: defaultPadding / (Responsive.isMobile(context) ? 1.5 : 1),
                ),
              ),
              onPressed: () {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (context) => const EcgScreen(),
    ),
  );
},
              icon: Icon(Icons.analytics_outlined, color: Colors.white),
              label: Text(
                "Ver Mi Electrocardiograma",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}