// lib/features/pacientes/presentation/screens/expediente_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/logic/auth_provider.dart';
import '../../logic/pacientes_provider.dart';
import '../../data/paciente_model.dart';
import '../../../pacientes/presentation/screens/agregar_control_screen.dart';  // ruta corregida: agregar_control_screen.dart está en presentation/
// ignore_for_file: use_build_context_synchronously

class ExpedienteScreen extends StatefulWidget {
  final PacienteModel paciente;
  const ExpedienteScreen({super.key, required this.paciente});

  @override
  State<ExpedienteScreen> createState() => _ExpedienteScreenState();
}

class _ExpedienteScreenState extends State<ExpedienteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      Provider.of<PacientesProvider>(context, listen: false).cargarPacientes(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PacientesProvider>(context);
    final p = prov.pacientes.firstWhere(
      (x) => x.id == widget.paciente.id,
      orElse: () => widget.paciente,
    );
    final controles = p.historialControles;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.nombre,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              p.email,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
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
                  '${controles.length} control${controles.length != 1 ? 'es' : ''}',
                  style: const TextStyle(
                      color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _PacienteInfoCard(paciente: p),
          Expanded(
            child: prov.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent))
                : controles.isEmpty
                    ? _EstadoVacio(onAgregar: () => _abrirAgregarControl(context, p))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: controles.length,
                        itemBuilder: (context, i) {
                          final c = controles[controles.length - 1 - i];
                          return _ControlCard(
                            control: c,
                            index: controles.length - i,
                            onVerAdjunto: c.archivoAdjunto != null
                                ? () => _verAdjunto(context, c.archivoAdjunto!)
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: () => _abrirAgregarControl(context, p),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Control',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _abrirAgregarControl(BuildContext context, PacienteModel p) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AgregarControlScreen(paciente: p, token: token)),
    );
    if (result == true && mounted) {
      Provider.of<PacientesProvider>(context, listen: false).cargarPacientes(token);
    }
  }

  // ── Visor de archivo adjunto ────────────────────────────────────────────────
  void _verAdjunto(BuildContext context, String url) {
    final esImagen = url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.png');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0D1117),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.attach_file_outlined,
                      color: Colors.tealAccent, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Estudio adjunto',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white54, size: 22),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            if (esImagen)
              Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 160,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.tealAccent, strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (ctx, error, _) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.broken_image_outlined,
                              color: Colors.white24, size: 48),
                          SizedBox(height: 8),
                          Text('No se pudo cargar la imagen',
                              style: TextStyle(color: Colors.white38)),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined,
                        color: Colors.redAccent, size: 52),
                    const SizedBox(height: 12),
                    const Text(
                      'Archivo PDF',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      url.split('/').last,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Para ver el PDF completo, descárgalo desde\nel panel web del sistema.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Card de info del paciente ────────────────────────────────────────────────
class _PacienteInfoCard extends StatelessWidget {
  final PacienteModel paciente;
  const _PacienteInfoCard({required this.paciente});

  @override
  Widget build(BuildContext context) {
    // Determinar si hay foto para mostrar
    final tieneFoto = paciente.foto != null && paciente.foto!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.teal.withValues(alpha: 0.2),
                backgroundImage: tieneFoto ? NetworkImage(paciente.foto!) : null,
                child: tieneFoto
                    ? null
                    : Text(
                        paciente.nombre.isNotEmpty
                            ? paciente.nombre[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(paciente.nombre,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _InfoChip(
                            icon: Icons.person_outline,
                            label: '${paciente.edad} años'),
                        const SizedBox(width: 8),
                        _InfoChip(
                            icon: Icons.wc_outlined, label: paciente.sexo),
                        const SizedBox(width: 8),
                        _InfoChip(
                            icon: Icons.monitor_weight_outlined,
                            label: '${paciente.pesoInicial} kg'),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${paciente.tallaInicial} m',
                    style: const TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const Text('talla',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ],
          ),
          if (paciente.alergias != 'Ninguna' ||
              paciente.antecedentesBase != 'Ninguno') ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            if (paciente.alergias != 'Ninguna')
              _DatoClinico(
                  icon: Icons.warning_amber_outlined,
                  color: Colors.orangeAccent,
                  label: 'Alergias',
                  valor: paciente.alergias),
            if (paciente.antecedentesBase != 'Ninguno') ...[
              const SizedBox(height: 6),
              _DatoClinico(
                  icon: Icons.history_edu_outlined,
                  color: Colors.blueAccent,
                  label: 'Antecedentes',
                  valor: paciente.antecedentesBase),
            ],
          ],
        ],
      ),
    );
  }
}

class _DatoClinico extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String valor;
  const _DatoClinico(
      {required this.icon,
      required this.color,
      required this.label,
      required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(valor,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 13),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

// ─── Card de control cardiológico con botón de adjunto ────────────────────────
class _ControlCard extends StatelessWidget {
  final ControlCardioModel control;
  final int index;
  final VoidCallback? onVerAdjunto;

  const _ControlCard({
    required this.control,
    required this.index,
    this.onVerAdjunto,
  });

  Color _getPresionColor(int sistolica) {
    if (sistolica >= 140) return Colors.redAccent;
    if (sistolica >= 120) return Colors.orange;
    return Colors.tealAccent;
  }

  Color _getSaturacionColor(int sat) {
    if (sat < 90) return Colors.redAccent;
    if (sat < 95) return Colors.orange;
    return Colors.tealAccent;
  }

  @override
  Widget build(BuildContext context) {
    final presionColor  = _getPresionColor(control.presionSistolica);
    final satColor      = _getSaturacionColor(control.saturacionOxigeno);
    final tieneAdjunto  = control.archivoAdjunto != null &&
        control.archivoAdjunto!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Control #$index',
                    style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                if (tieneAdjunto)
                  GestureDetector(
                    onTap: onVerAdjunto,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_file_outlined,
                              color: Colors.blueAccent, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Ver estudio',
                            style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time, color: Colors.white30, size: 12),
                const SizedBox(width: 4),
                Text(
                  _formatFecha(control.fecha),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                _MetricBox(
                  label: 'Presión',
                  value:
                      '${control.presionSistolica}/${control.presionDiastolica}',
                  unit: 'mmHg',
                  color: presionColor,
                  icon: Icons.favorite_outline,
                ),
                const SizedBox(width: 8),
                _MetricBox(
                  label: 'Frecuencia',
                  value: '${control.frecuenciaCardiaca}',
                  unit: 'bpm',
                  color: Colors.purpleAccent,
                  icon: Icons.monitor_heart_outlined,
                ),
                const SizedBox(width: 8),
                _MetricBox(
                  label: 'SpO₂',
                  value: '${control.saturacionOxigeno}',
                  unit: '%',
                  color: satColor,
                  icon: Icons.air_outlined,
                ),
              ],
            ),
          ),
          if (control.sintomas != 'Ninguno' ||
              control.diagnosticoEcg != 'Pendiente')
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (control.sintomas != 'Ninguno') ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_outlined,
                            color: Colors.white38, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            control.sintomas,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (control.diagnosticoEcg != 'Pendiente')
                    Row(
                      children: [
                        const Icon(Icons.monitor_heart_outlined,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'ECG: ${control.diagnosticoEcg}',
                          style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatFecha(String fecha) {
    if (fecha.isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return fecha.length > 10 ? fecha.substring(0, 10) : fecha;
    }
  }
}

// ─── Caja de métrica ──────────────────────────────────────────────────────────
class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 13),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        color: color.withValues(alpha: 0.8), fontSize: 10)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(unit,
                style: TextStyle(
                    color: color.withValues(alpha: 0.6), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────
class _EstadoVacio extends StatelessWidget {
  final VoidCallback onAgregar;
  const _EstadoVacio({required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.monitor_heart_outlined,
                color: Colors.teal, size: 36),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sin controles registrados',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega el primer control cardiológico\nde este paciente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 28),
          TextButton.icon(
            onPressed: onAgregar,
            icon: const Icon(Icons.add, color: Colors.tealAccent),
            label: const Text('Agregar control',
                style: TextStyle(color: Colors.tealAccent)),
          ),
        ],
      ),
    );
  }
}
