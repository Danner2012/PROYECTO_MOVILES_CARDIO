import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/pacientes/logic/pacientes_provider.dart';
import 'package:flutter_frontend/features/dashboard/presentation/responsive.dart';
import '../../../constants.dart';

class MyHealthSummary extends StatelessWidget {
  const MyHealthSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    final pacientesProvider = Provider.of<PacientesProvider>(context);
    final perfil = pacientesProvider.perfilPaciente;

    if (pacientesProvider.isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final controles = perfil?.historialControles ?? [];
    final ultimoControl = controles.isNotEmpty ? controles.first : null;

    final String presionVal = ultimoControl != null
        ? "${ultimoControl.presionSistolica}/${ultimoControl.presionDiastolica} mmHg"
        : "N/A";
    final int frecuenciaVal = ultimoControl?.frecuenciaCardiaca ?? 0;
    final int oxigenoval = ultimoControl?.saturacionOxigeno ?? 0;
    final int medicamentosActivos = perfil?.tratamientos
            .where((t) => t.estado.toLowerCase() == 'activo')
            .fold<int>(0, (sum, t) => sum + t.medicamentos.length) ??
        0;

    final List<HealthStatInfo> stats = [
      HealthStatInfo(
        title: "Presión Arterial",
        value: presionVal,
        icon: Icons.compress_outlined,
        color: Colors.blueAccent,
        subtitle: ultimoControl != null ? "Último: ${ultimoControl.fecha}" : "Sin registros",
      ),
      HealthStatInfo(
        title: "Ritmo Cardíaco",
        value: frecuenciaVal > 0 ? "$frecuenciaVal lpm" : "N/A",
        icon: Icons.favorite,
        color: Colors.redAccent,
        subtitle: frecuenciaVal > 0 ? "Frecuencia en reposo" : "Sin registros",
      ),
      HealthStatInfo(
        title: "Oxígeno en Sangre",
        value: oxigenoval > 0 ? "$oxigenoval%" : "N/A",
        icon: Icons.bloodtype_outlined,
        color: Colors.tealAccent,
        subtitle: oxigenoval > 0 ? "Saturación de oxígeno" : "Sin registros",
      ),
      HealthStatInfo(
        title: "Medicamentos de Hoy",
        value: "$medicamentosActivos",
        icon: Icons.medication_liquid_outlined,
        color: Colors.orangeAccent,
        subtitle: "Dosis activas recetadas",
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mi Estado de Salud",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: defaultPadding),
        Responsive(
          mobile: HealthCardGridView(
            crossAxisCount: _size.width < 650 ? 2 : 4,
            childAspectRatio: _size.width < 650 && _size.width > 350 ? 1.3 : 1.1,
            stats: stats,
          ),
          tablet: HealthCardGridView(stats: stats),
          desktop: HealthCardGridView(
            childAspectRatio: _size.width < 1400 ? 1.2 : 1.5,
            stats: stats,
          ),
        ),
      ],
    );
  }
}

class HealthCardGridView extends StatelessWidget {
  const HealthCardGridView({
    Key? key,
    this.crossAxisCount = 4,
    this.childAspectRatio = 1.2,
    required this.stats,
  }) : super(key: key);

  final int crossAxisCount;
  final double childAspectRatio;
  final List<HealthStatInfo> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) => HealthStatCard(info: stats[index]),
    );
  }
}

class HealthStatInfo {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  HealthStatInfo({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
}

class HealthStatCard extends StatelessWidget {
  const HealthStatCard({
    Key? key,
    required this.info,
  }) : super(key: key);

  final HealthStatInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Icon(
                  info.icon,
                  color: info.color,
                  size: 22,
                ),
              ),
              const Icon(Icons.monitor_heart_outlined, color: Colors.white24, size: 20)
            ],
          ),
          const SizedBox(height: 8),
          Text(
            info.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            info.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
          ),
          Text(
            info.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}
