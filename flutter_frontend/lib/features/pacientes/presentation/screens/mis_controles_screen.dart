import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/logic/auth_provider.dart';
import '../../logic/pacientes_provider.dart';

class MisControlesScreen extends StatefulWidget {
  const MisControlesScreen({super.key});

  @override
  State<MisControlesScreen> createState() => _MisControlesScreenState();
}

class _MisControlesScreenState extends State<MisControlesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      Provider.of<PacientesProvider>(context, listen: false).fetchMisControles(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PacientesProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;
    final controles = prov.misControles;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Text(
          'Mis Controles Cardiológicos',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${controles.length} registro${controles.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bienvenida simple
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.withValues(alpha: 0.2), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${user?.nombre ?? 'Paciente'}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Aquí puedes ver el historial de tus controles registrados por tu doctor y obtener información educativa asistida por IA.',
                  style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),

          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                : controles.isEmpty
                    ? const _EstadoVacio()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: controles.length,
                        itemBuilder: (context, i) {
                          final c = controles[i]; // Ya vienen ordenados por fecha desc del backend
                          return _ControlCard(control: c, index: controles.length - i);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  final Map<String, dynamic> control;
  final int index;
  const _ControlCard({required this.control, required this.index});

  Color _getPresionColor(int sistolica) {
    if (sistolica >= 140) return Colors.redAccent;
    if (sistolica >= 120) return Colors.orange;
    return Colors.tealAccent;
  }

  @override
  Widget build(BuildContext context) {
    final sistolica = control['presion_sistolica'] ?? 0;
    final diastolica = control['presion_diastolica'] ?? 0;
    final frecuencia = control['frecuencia_cardiaca'] ?? 0;
    final saturacion = control['saturacion_oxigeno'] ?? 0;
    final sintomas = control['sintomas'] ?? 'Ninguno';
    final diagnostico = control['diagnostico_ecg'] ?? 'Pendiente';
    final fecha = control['fecha'] ?? '';
    final explicacionIa = control['explicacion_ia'] ?? '';

    final presionColor = _getPresionColor(sistolica);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Control #$index',
                    style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, color: Colors.white30, size: 12),
                const SizedBox(width: 4),
                Text(
                  _formatFecha(fecha.toString()),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          // Métricas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _MetricItem(label: 'Presión', value: '$sistolica/$diastolica', color: presionColor),
                _MetricItem(label: 'Ritmo', value: '$frecuencia bpm', color: Colors.purpleAccent),
                _MetricItem(label: 'Oxígeno', value: '$saturacion%', color: Colors.blueAccent),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Síntomas y Diagnóstico original
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LabelValue(label: 'Síntomas:', value: sintomas),
                const SizedBox(height: 8),
                _LabelValue(label: 'Diagnóstico ECG:', value: diagnostico, valueColor: Colors.amber),
              ],
            ),
          ),

          // SECCIÓN IA (Inspirada en Ollama)
          if (explicacionIa.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border(top: BorderSide(color: Colors.teal.withValues(alpha: 0.2))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.tealAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Información Educativa (Asistente IA)',
                        style: TextStyle(
                          color: Colors.tealAccent.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    explicacionIa,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '* Esta información es referencial y educativa. Consulte siempre con su médico.',
                    style: TextStyle(color: Colors.white24, fontSize: 9),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return fecha;
    }
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _LabelValue({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, color: Colors.white10, size: 80),
          const SizedBox(height: 16),
          const Text(
            'Aún no tienes controles registrados',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
