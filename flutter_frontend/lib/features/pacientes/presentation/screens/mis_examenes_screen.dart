import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../features/auth/logic/auth_provider.dart';
import '../../../dashboard/logic/menu_app_controller.dart';
import '../../logic/pacientes_provider.dart';
import '../../data/paciente_model.dart';

class MisExamenesScreen extends StatefulWidget {
  const MisExamenesScreen({super.key});

  @override
  State<MisExamenesScreen> createState() => _MisExamenesScreenState();
}

class _MisExamenesScreenState extends State<MisExamenesScreen> {
  static const _bg = Color(0xFF0D1117);
  static const _teal = Color(0xFF00BFA5);
  static const _surface = Color(0xFF161B22);
  static const _border = Color(0xFF30363D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<PacientesProvider>(context, listen: false).fetchMisExamenes(authProv.token!);
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
          'Mis Exámenes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Provider.of<MenuAppController>(context, listen: false).controlMenu(context),
        ),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : prov.misExamenes.isEmpty
              ? const Center(
                  child: Text(
                    'No tienes exámenes registrados por tu médico.',
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prov.misExamenes.length,
                  itemBuilder: (context, i) {
                    final examen = prov.misExamenes[i];
                    return _ExamenPacienteCard(examen: examen);
                  },
                ),
    );
  }
}

class _ExamenPacienteCard extends StatelessWidget {
  final ExamenMedicoModel examen;
  const _ExamenPacienteCard({required this.examen});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00BFA5);
    final fecha = DateFormat('dd/MM/yyyy').format(DateTime.parse(examen.fechaExamen));

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: teal.withValues(alpha: 0.3)),
                ),
                child: Text(
                  examen.tipoExamen,
                  style: const TextStyle(color: teal, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Text(
                fecha,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (examen.resultado?.isNotEmpty ?? false) ...[
            const Text(
              'RESULTADO',
              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              examen.resultado!,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
          ],
          if (examen.descripcion?.isNotEmpty ?? false) ...[
            const Text(
              'DESCRIPCIÓN MÉDICA',
              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              examen.descripcion!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 15),
          ],
          if (examen.archivoAdjunto != null) ...[
            const Divider(color: Colors.white10, height: 30),
            InkWell(
              onTap: () async {
                final url = Uri.parse(examen.archivoAdjunto!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo abrir el archivo')),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: teal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: teal, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ver Resultado Adjunto',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Click para abrir el ECG/Informe',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new, color: Colors.white24, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
