import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import '../../../../features/auth/logic/auth_provider.dart';
import '../../../dashboard/logic/menu_app_controller.dart';
import '../../logic/pacientes_provider.dart';
import '../../data/paciente_model.dart';

class ExamenesMedicosScreen extends StatefulWidget {
  const ExamenesMedicosScreen({super.key});

  @override
  State<ExamenesMedicosScreen> createState() => _ExamenesMedicosScreenState();
}

class _ExamenesMedicosScreenState extends State<ExamenesMedicosScreen> {
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
          '5. Gestión de Exámenes',
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
                          trailing: const Icon(Icons.assignment, color: _teal),
                          onTap: () => _verExamenesPaciente(p),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _verExamenesPaciente(PacienteModel paciente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DetalleExamenesSheet(paciente: paciente),
    );
  }
}

class _DetalleExamenesSheet extends StatefulWidget {
  final PacienteModel paciente;
  const _DetalleExamenesSheet({required this.paciente});

  @override
  State<_DetalleExamenesSheet> createState() => _DetalleExamenesSheetState();
}

class _DetalleExamenesSheetState extends State<_DetalleExamenesSheet> {
  static const _teal = Color(0xFF00BFA5);
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PacientesProvider>(context);
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
                'Exámenes de ${pacienteActual.nombre}',
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
            child: pacienteActual.examenesMedicos.isEmpty
                ? const Center(child: Text('No hay exámenes registrados.', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: pacienteActual.examenesMedicos.length,
                    itemBuilder: (context, i) {
                      final ex = pacienteActual.examenesMedicos[i];
                      return _ExamenItem(
                        examen: ex,
                        onEdit: () => _mostrarFormularioExamen(context, examen: ex),
                        onDelete: () => _confirmarEliminarExamen(context, ex.id),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _mostrarFormularioExamen(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Examen Médico'),
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

  void _mostrarFormularioExamen(BuildContext context, {ExamenMedicoModel? examen}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ExamenFormDialog(
        pacienteId: widget.paciente.id,
        examen: examen,
      ),
    );
  }

  void _confirmarEliminarExamen(BuildContext context, String examenId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('¿Eliminar examen?', style: TextStyle(color: Colors.white)),
        content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final authProv = Provider.of<AuthProvider>(context, listen: false);
              final pacProv = Provider.of<PacientesProvider>(context, listen: false);
              final ok = await pacProv.eliminarExamenMedico(token: authProv.token!, examenId: examenId);
              if (ok && context.mounted) {
                Navigator.pop(context); // Cerrar dialogo
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Examen eliminado')));
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _ExamenItem extends StatelessWidget {
  final ExamenMedicoModel examen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExamenItem({
    required this.examen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00BFA5);
    final fecha = DateFormat('dd/MM/yyyy').format(DateTime.parse(examen.fechaExamen));

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
                child: Text(examen.tipoExamen, style: const TextStyle(color: teal, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Fecha: $fecha',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (examen.resultado?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              'Resultado: ${examen.resultado}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
          if (examen.descripcion?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              examen.descripcion!,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
          if (examen.archivoAdjunto != null) ...[
            const SizedBox(height: 12),
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
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: teal, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Ver archivo adjunto (${examen.archivoAdjunto!.split('/').last})',
                      style: TextStyle(
                        color: teal.withValues(alpha: 0.8), 
                        fontSize: 12, 
                        decoration: TextDecoration.underline,
                        overflow: TextOverflow.ellipsis
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExamenFormDialog extends StatefulWidget {
  final int pacienteId;
  final ExamenMedicoModel? examen;

  const _ExamenFormDialog({required this.pacienteId, this.examen});

  @override
  State<_ExamenFormDialog> createState() => _ExamenFormDialogState();
}

class _ExamenFormDialogState extends State<_ExamenFormDialog> {
  static const _teal = Color(0xFF00BFA5);
  bool _isSaving = false;
  
  late TextEditingController _resultadoCtrl;
  late TextEditingController _descripcionCtrl;
  String _tipoExamen = 'ECG';
  DateTime _fechaExamen = DateTime.now();
  
  Uint8List? _archivoBytes;
  String? _archivoNombre;

  final List<String> _tipos = ['ECG', 'HOLTER', 'ECOCARDIOGRAMA', 'INFORME_CARDIOLOGICO', 'OTRO'];

  @override
  void initState() {
    super.initState();
    _resultadoCtrl = TextEditingController(text: widget.examen?.resultado);
    _descripcionCtrl = TextEditingController(text: widget.examen?.descripcion);
    if (widget.examen != null) {
      _tipoExamen = widget.examen!.tipoExamen;
      _fechaExamen = DateTime.parse(widget.examen!.fechaExamen);
    }
  }

  Future<void> _seleccionarArchivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _archivoBytes = result.files.single.bytes;
        _archivoNombre = result.files.single.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        widget.examen == null ? 'Nuevo Examen Médico' : 'Editar Examen',
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TIPO DE EXAMEN', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _tipoExamen,
              dropdownColor: const Color(0xFF1C2128),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(''),
              items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _tipoExamen = val!),
            ),
            const SizedBox(height: 15),
            const Text('FECHA', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaExamen,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _fechaExamen = picked);
              },
              child: InputDecorator(
                decoration: _inputDecoration(''),
                child: Text(DateFormat('dd/MM/yyyy').format(_fechaExamen), style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 15),
            _buildField(_resultadoCtrl, 'Resultado', Icons.analytics),
            _buildField(_descripcionCtrl, 'Descripción', Icons.description, maxLines: 3),
            const SizedBox(height: 10),
            const Text('ARCHIVO ADJUNTO', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _seleccionarArchivo,
              icon: const Icon(Icons.upload_file, color: _teal),
              label: Text(_archivoNombre ?? (widget.examen?.archivoAdjunto != null ? 'Reemplazar archivo' : 'Subir ECG/Holter/PDF'), style: const TextStyle(color: Colors.white70)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white10),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: _isSaving ? null : _guardar,
          style: ElevatedButton.styleFrom(backgroundColor: _teal),
          child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label.isEmpty ? null : label,
      labelStyle: const TextStyle(color: _teal, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _teal)),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: _inputDecoration(label).copyWith(
          prefixIcon: Icon(icon, color: Colors.white24, size: 20),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    setState(() => _isSaving = true);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final pacProv = Provider.of<PacientesProvider>(context, listen: false);

    final datos = {
      'tipo_examen': _tipoExamen,
      'fecha_examen': DateFormat('yyyy-MM-dd').format(_fechaExamen),
      'resultado': _resultadoCtrl.text,
      'descripcion': _descripcionCtrl.text,
    };

    bool ok;
    if (widget.examen == null) {
      ok = await pacProv.registrarExamenMedico(
        token: authProv.token!,
        pacienteId: widget.pacienteId,
        datos: datos,
        archivoBytes: _archivoBytes,
        archivoNombre: _archivoNombre,
      );
    } else {
      ok = await pacProv.actualizarExamenMedico(
        token: authProv.token!,
        examenId: widget.examen!.id,
        datos: datos,
        archivoBytes: _archivoBytes,
        archivoNombre: _archivoNombre,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Examen guardado')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar'), backgroundColor: Colors.redAccent));
      }
    }
  }
}
