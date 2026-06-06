// lib/features/pacientes/presentation/screens/historial_clinico_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../features/auth/logic/auth_provider.dart';
import '../../../dashboard/logic/menu_app_controller.dart';
import '../../logic/pacientes_provider.dart';
import '../../data/paciente_model.dart';

class HistorialClinicoScreen extends StatefulWidget {
  const HistorialClinicoScreen({super.key});

  @override
  State<HistorialClinicoScreen> createState() => _HistorialClinicoScreenState();
}

class _HistorialClinicoScreenState extends State<HistorialClinicoScreen> {
  static const _bg      = Color(0xFF0D1117);
  static const _teal    = Color(0xFF00BFA5);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF30363D);

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      Provider.of<PacientesProvider>(context, listen: false).cargarPacientes(token);
    });
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PacienteModel> _filtrar(List<PacienteModel> todos) {
    if (_query.isEmpty) return todos;
    return todos.where((p) {
      return p.nombre.toLowerCase().contains(_query) ||
          p.email.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PacientesProvider>(context);
    final filtrados = _filtrar(prov.pacientes);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          '3. Historial Clínico',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Provider.of<MenuAppController>(context, listen: false).controlMenu(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar paciente...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: _teal),
                filled: true,
                fillColor: _surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _teal),
                ),
              ),
            ),
          ),
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator(color: _teal))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtrados.length,
                    itemBuilder: (context, i) {
                      final p = filtrados[i];
                      return Card(
                        color: _surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _border),
                        ),
                        child: ListTile(
                          title: Text(p.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(p.email, style: const TextStyle(color: Colors.white54)),
                          trailing: const Icon(Icons.history_edu, color: _teal),
                          onTap: () => _verHistorialPaciente(p),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _verHistorialPaciente(PacienteModel paciente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DetalleHistorialSheet(paciente: paciente),
    );
  }
}

class _DetalleHistorialSheet extends StatefulWidget {
  final PacienteModel paciente;
  const _DetalleHistorialSheet({required this.paciente});

  @override
  State<_DetalleHistorialSheet> createState() => _DetalleHistorialSheetState();
}

class _DetalleHistorialSheetState extends State<_DetalleHistorialSheet> {
  static const _teal = Color(0xFF00BFA5);
  static const _surface = Color(0xFF161B22);
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PacientesProvider>(context);
    // Buscar el paciente actualizado en la lista del provider
    final pacienteActual = prov.pacientes.firstWhere(
      (p) => p.id == widget.paciente.id, 
      orElse: () => widget.paciente
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historial de ${pacienteActual.nombre}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: pacienteActual.historialesClinicos.isEmpty
                ? const Center(child: Text('No hay registros de historial.', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: pacienteActual.historialesClinicos.length,
                    itemBuilder: (context, i) {
                      final h = pacienteActual.historialesClinicos[i];
                      return _HistorialItem(
                        historial: h, 
                        pacienteId: pacienteActual.id,
                        onEdit: (model) => _mostrarFormularioHistorial(context, historial: model),
                        onDelete: () {
                          // El provider ya refresca la lista al eliminar
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _mostrarFormularioHistorial(context),
              icon: const Icon(Icons.add_chart),
              label: const Text('Nuevo Registro Histórico'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioHistorial(BuildContext context, {HistorialClinicoModel? historial}) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final pacProv = Provider.of<PacientesProvider>(context, listen: false);
    
    final motivoCtrl = TextEditingController(text: historial?.motivoConsulta);
    final antCardioCtrl = TextEditingController(text: historial?.antecedentesCardiacos);
    final antFamCtrl = TextEditingController(text: historial?.antecedentesFamiliares);
    final enfPrevCtrl = TextEditingController(text: historial?.enfermedadesPrevias);
    final alergiasCtrl = TextEditingController(text: historial?.alergias);
    final obsCtrl = TextEditingController(text: historial?.observacionesMedicas);
    final estadoCtrl = TextEditingController(text: historial?.estadoActual ?? 'Estable');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(historial == null ? 'Nuevo Registro de Historial' : 'Editar Historial Clínico', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DATOS DE LA CONSULTA', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  const SizedBox(height: 12),
                  _buildField(motivoCtrl, 'Motivo de Consulta', Icons.message, hint: 'Ej: Dolor torácico persistente'),
                  _buildField(estadoCtrl, 'Estado Actual del Paciente', Icons.info, hint: 'Estable, Crítico, Reservado...'),
                  
                  const Divider(color: Colors.white10, height: 30),
                  const Text('ANTECEDENTES Y CLÍNICA', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  const SizedBox(height: 12),
                  _buildField(antCardioCtrl, 'Antecedentes Cardíacos', Icons.favorite, maxLines: 2, hint: 'Cirugías previas, arritmias conocidas...'),
                  _buildField(antFamCtrl, 'Antecedentes Familiares', Icons.people, maxLines: 2, hint: 'Hipertensión en padres, etc.'),
                  _buildField(enfPrevCtrl, 'Enfermedades Previas', Icons.medical_services, maxLines: 2),
                  _buildField(alergiasCtrl, 'Alergias Conocidas', Icons.warning),
                  
                  const Divider(color: Colors.white10, height: 30),
                  const Text('NOTAS MÉDICAS', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  const SizedBox(height: 12),
                  _buildField(obsCtrl, 'Observaciones Detalladas', Icons.notes, maxLines: 5, hint: 'Anotaciones adicionales sobre el examen físico...'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context), 
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _isSaving ? null : () async {
                if (motivoCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El motivo de consulta es obligatorio')));
                  return;
                }

                setDialogState(() => _isSaving = true);
                
                final datos = {
                  'fecha_registro': DateTime.now().toIso8601String(),
                  'motivo_consulta': motivoCtrl.text,
                  'antecedentes_cardiacos': antCardioCtrl.text,
                  'antecedentes_familiares': antFamCtrl.text,
                  'enfermedades_previas': enfPrevCtrl.text,
                  'alergias': alergiasCtrl.text,
                  'observaciones_medicas': obsCtrl.text,
                  'estado_actual': estadoCtrl.text,
                };
                
                bool ok;
                try {
                  if (historial == null) {
                    ok = await pacProv.agregarHistorialClinico(
                      token: authProv.token!,
                      pacienteId: widget.paciente.id,
                      datosHistorial: datos,
                    );
                  } else {
                    ok = await pacProv.actualizarHistorialClinico(
                      token: authProv.token!,
                      historialId: historial.id,
                      datosHistorial: datos,
                    );
                  }
                } catch (e) {
                  ok = false;
                  debugPrint('Error al guardar: $e');
                }

                if (mounted) {
                  setDialogState(() => _isSaving = false);
                  if (ok) {
                    Navigator.pop(context); // Cerrar dialogo
                    Navigator.pop(context); // Cerrar sheet para refrescar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Historial guardado correctamente')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al guardar. Verifique los datos o su conexión.'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          labelStyle: const TextStyle(color: _teal, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.white24, size: 20),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.03),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _teal),
          ),
        ),
      ),
    );
  }
}

class _HistorialItem extends StatelessWidget {
  final HistorialClinicoModel historial;
  final int pacienteId;
  final Function(HistorialClinicoModel) onEdit;
  final VoidCallback onDelete;

  const _HistorialItem({
    required this.historial,
    required this.pacienteId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(historial.fechaRegistro));
    const teal = Color(0xFF00BFA5);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(fecha, style: const TextStyle(color: teal, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 20),
                    tooltip: 'Editar',
                    onPressed: () => onEdit(historial),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    tooltip: 'Desactivar',
                    onPressed: () => _confirmarDesactivar(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            historial.motivoConsulta,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          
          _infoSection('Antecedentes Cardíacos', historial.antecedentesCardiacos, teal),
          _infoSection('Antecedentes Familiares', historial.antecedentesFamiliares, teal),
          _infoSection('Enfermedades Previas', historial.enfermedadesPrevias, teal),
          _infoSection('Alergias', historial.alergias, teal),
          
          const Divider(color: Colors.white10, height: 24),
          
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.white38),
              const SizedBox(width: 4),
              const Text('Estado: ', style: TextStyle(color: Colors.white38, fontSize: 12)),
              Text(historial.estadoActual, style: TextStyle(color: _getColorEstado(historial.estadoActual), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          
          if (historial.observacionesMedicas?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Observaciones:', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    historial.observacionesMedicas!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoSection(String label, String? value, Color teal) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: teal, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Color _getColorEstado(String estado) {
    estado = estado.toLowerCase();
    if (estado.contains('estable')) return Colors.greenAccent;
    if (estado.contains('critico') || estado.contains('grave')) return Colors.redAccent;
    if (estado.contains('reservado')) return Colors.orangeAccent;
    return Colors.white54;
  }

  void _confirmarDesactivar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('¿Desactivar registro?', style: TextStyle(color: Colors.white)),
        content: const Text('El registro dejará de ser visible en el historial clínico pero permanecerá en el sistema.', style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final authProv = Provider.of<AuthProvider>(context, listen: false);
              final pacProv = Provider.of<PacientesProvider>(context, listen: false);
              final ok = await pacProv.eliminarHistorialClinico(token: authProv.token!, historialId: historial.id);
              if (ok && context.mounted) {
                Navigator.pop(context); // Cerrar dialogo
                onDelete(); // Notificar al padre para refrescar
              }
            },
            child: const Text('Desactivar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
