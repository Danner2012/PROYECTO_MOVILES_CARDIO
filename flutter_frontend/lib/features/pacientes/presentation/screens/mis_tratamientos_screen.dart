import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../features/auth/logic/auth_provider.dart';
import '../../../dashboard/logic/menu_app_controller.dart';
import '../../logic/pacientes_provider.dart';
import '../../data/paciente_model.dart';

class MisTratamientosScreen extends StatefulWidget {
  const MisTratamientosScreen({super.key});

  @override
  State<MisTratamientosScreen> createState() => _MisTratamientosScreenState();
}

class _MisTratamientosScreenState extends State<MisTratamientosScreen> {
  static const _bg = Color(0xFF0D1117);
  static const _teal = Color(0xFF00BFA5);
  static const _surface = Color(0xFF161B22);
  static const _border = Color(0xFF30363D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<PacientesProvider>(context, listen: false).fetchMisTratamientos(authProv.token!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PacientesProvider>(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Mis Tratamientos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Provider.of<MenuAppController>(context, listen: false).controlMenu(context),
        ),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : prov.misTratamientos.isEmpty
              ? const Center(
                  child: Text(
                    'No tienes tratamientos registrados por tu médico.',
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prov.misTratamientos.length,
                  itemBuilder: (context, i) {
                    final tratamiento = prov.misTratamientos[i];
                    return _TratamientoPacienteCard(tratamiento: tratamiento);
                  },
                ),
    );
  }
}

class _TratamientoPacienteCard extends StatelessWidget {
  final TratamientoModel tratamiento;
  const _TratamientoPacienteCard({required this.tratamiento});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00BFA5);
    final fechaInicio = DateFormat('dd/MM/yyyy').format(DateTime.parse(tratamiento.fechaInicio));
    final fechaFin = tratamiento.fechaFin != null 
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(tratamiento.fechaFin!))
        : 'Indefinido';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Tratamiento
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PERIODO', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$fechaInicio - $fechaFin', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                _EstadoBadge(estado: tratamiento.estado),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MEDICAMENTOS
                const Row(
                  children: [
                    Icon(Icons.medication, color: teal, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'MEDICAMENTOS RECETADOS',
                      style: TextStyle(color: teal, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (tratamiento.medicamentos.isEmpty)
                  const Text('Sin medicamentos registrados.', style: TextStyle(color: Colors.white24, fontSize: 13))
                else
                  ...tratamiento.medicamentos.map((med) => _MedicamentoItem(med: med)),

                const SizedBox(height: 25),

                // RECOMENDACIONES
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orangeAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'INDICACIONES Y RECOMENDACIONES',
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (tratamiento.recomendaciones.isEmpty)
                  const Text('Sin indicaciones adicionales.', style: TextStyle(color: Colors.white24, fontSize: 13))
                else
                  ...tratamiento.recomendaciones.map((rec) => _RecomendacionItem(rec: rec)),
                
                if (tratamiento.observaciones?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  const Text('NOTAS DEL MÉDICO', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(tratamiento.observaciones!, style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicamentoItem extends StatelessWidget {
  final MedicamentoModel med;
  const _MedicamentoItem({required this.med});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(med.nombreMedicamento, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Row(
            children: [
              _BadgeInfo(icon: Icons.timer, text: med.frecuencia),
              const SizedBox(width: 12),
              _BadgeInfo(icon: Icons.science, text: med.dosis),
            ],
          ),
          if (med.observaciones?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(med.observaciones!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _RecomendacionItem extends StatelessWidget {
  final RecomendacionModel rec;
  const _RecomendacionItem({required this.rec});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.info_outline;
    if (rec.tipoRecomendacion == 'Dieta') icon = Icons.restaurant;
    if (rec.tipoRecomendacion == 'Ejercicio') icon = Icons.directions_run;
    if (rec.tipoRecomendacion == 'Restricción') icon = Icons.warning_amber;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white24, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.tipoRecomendacion, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(rec.descripcion, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BadgeInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blueAccent, size: 12),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.greenAccent;
    if (estado == 'Suspendido') color = Colors.redAccent;
    if (estado == 'Finalizado') color = Colors.blueAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(estado.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
