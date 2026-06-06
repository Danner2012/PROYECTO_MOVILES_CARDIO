import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/logic/auth_provider.dart';
import '../../../dashboard/logic/menu_app_controller.dart';
import '../../logic/pacientes_provider.dart';
import '../../data/paciente_model.dart';

class MisArritmiasScreen extends StatefulWidget {
  const MisArritmiasScreen({super.key});

  @override
  State<MisArritmiasScreen> createState() => _MisArritmiasScreenState();
}

class _MisArritmiasScreenState extends State<MisArritmiasScreen> {
  static const _bg = Color(0xFF0D1117);
  static const _teal = Color(0xFF00BFA5);
  static const _surface = Color(0xFF161B22);
  static const _border = Color(0xFF30363D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<PacientesProvider>(context, listen: false).fetchMisArritmias(authProv.token!);
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
          'Mis Arritmias',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Provider.of<MenuAppController>(context, listen: false).controlMenu(context),
        ),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : prov.misArritmias.isEmpty
              ? const Center(
                  child: Text(
                    'No tienes arritmias registradas por tu doctor.',
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prov.misArritmias.length,
                  itemBuilder: (context, i) {
                    final arritmia = prov.misArritmias[i];
                    return _ArritmiaPacienteCard(arritmia: arritmia);
                  },
                ),
    );
  }
}

class _ArritmiaPacienteCard extends StatelessWidget {
  final ArritmiaModel arritmia;
  const _ArritmiaPacienteCard({required this.arritmia});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF30363D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DIAGNÓSTICO',
                      style: TextStyle(color: Color(0xFF00BFA5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      arritmia.tipoArritmia,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              _RiesgoBadgePaciente(riesgo: arritmia.nivelRiesgo),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _InfoItem(
                label: 'ESTADO ACTUAL',
                value: arritmia.estado,
                icon: Icons.info_outline,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 40),
              _InfoItem(
                label: 'FECHA DETECCIÓN',
                value: arritmia.fechaDeteccion,
                icon: Icons.calendar_today,
                color: Colors.white38,
              ),
            ],
          ),
          if (arritmia.observaciones?.isNotEmpty ?? false) ...[
            const SizedBox(height: 20),
            const Text(
              'OBSERVACIONES DEL MÉDICO',
              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                arritmia.observaciones!,
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          Text(
            'HISTORIAL DE EPISODIOS (${arritmia.seguimientos.length})',
            style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          if (arritmia.seguimientos.isEmpty)
            const Text('No hay seguimientos registrados aún.', style: TextStyle(color: Colors.white24, fontSize: 12))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: arritmia.seguimientos.length > 3 ? 3 : arritmia.seguimientos.length,
              itemBuilder: (context, i) {
                final s = arritmia.seguimientos[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 10),
                      Text(
                        '${s.frecuenciaCardiaca} BPM',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        s.fechaControl,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (arritmia.seguimientos.length > 3)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _verTodoHistorial(context),
                child: const Text('Ver historial completo', style: TextStyle(color: Color(0xFF00BFA5), fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  void _verTodoHistorial(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Historial: ${arritmia.tipoArritmia}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: arritmia.seguimientos.length,
                itemBuilder: (context, i) {
                  final s = arritmia.seguimientos[i];
                  return ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.redAccent),
                    title: Text('${s.frecuenciaCardiaca} BPM', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Riesgo: ${s.nivelRiesgo} | ${s.estado}', style: const TextStyle(color: Colors.white54)),
                    trailing: Text(s.fechaControl, style: const TextStyle(color: Colors.white38)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

class _RiesgoBadgePaciente extends StatelessWidget {
  final String riesgo;
  const _RiesgoBadgePaciente({required this.riesgo});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.greenAccent;
    if (riesgo.toLowerCase().contains('alto') || riesgo.toLowerCase().contains('critico')) {
      color = Colors.redAccent;
    } else if (riesgo.toLowerCase().contains('medio')) {
      color = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            riesgo.toUpperCase(),
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
