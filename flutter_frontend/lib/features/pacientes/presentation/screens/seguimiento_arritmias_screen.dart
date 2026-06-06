// lib/features/pacientes/presentation/screens/seguimiento_arritmias_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../features/auth/logic/auth_provider.dart';
import '../../../dashboard/logic/menu_app_controller.dart';
import '../../logic/pacientes_provider.dart';
import '../../data/paciente_model.dart';

class SeguimientoArritmiasScreen extends StatefulWidget {
  const SeguimientoArritmiasScreen({super.key});

  @override
  State<SeguimientoArritmiasScreen> createState() => _SeguimientoArritmiasScreenState();
}

class _SeguimientoArritmiasScreenState extends State<SeguimientoArritmiasScreen> {
  static const _bg      = Color(0xFF0D1117);
  static const _teal    = Color(0xFF00BFA5);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF30363D);

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
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
          '4. Seguimiento de Arritmias',
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
                          trailing: const Icon(Icons.monitor_heart, color: _teal),
                          onTap: () => _gestionarArritmias(p),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _gestionarArritmias(PacienteModel paciente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ListaArritmiasSheet(paciente: paciente),
    );
  }
}

class _ListaArritmiasSheet extends StatefulWidget {
  final PacienteModel paciente;
  const _ListaArritmiasSheet({required this.paciente});

  @override
  State<_ListaArritmiasSheet> createState() => _ListaArritmiasSheetState();
}

class _ListaArritmiasSheetState extends State<_ListaArritmiasSheet> {
  static const _teal = Color(0xFF00BFA5);

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PacientesProvider>(context);
    final pActual = prov.pacientes.firstWhere((p) => p.id == widget.paciente.id, orElse: () => widget.paciente);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arritmias de ${pActual.nombre}',
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
            child: pActual.arritmias.isEmpty
                ? const Center(child: Text('No hay arritmias registradas.', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: pActual.arritmias.length,
                    itemBuilder: (context, i) {
                      final a = pActual.arritmias[i];
                      return _ArritmiaCard(arritmia: a, paciente: pActual);
                    },
                  ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _mostrarFormArritmia(context),
              icon: const Icon(Icons.add),
              label: const Text('Registrar Nueva Arritmia'),
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

  void _mostrarFormArritmia(BuildContext context, {ArritmiaModel? arritmia}) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final pacProv = Provider.of<PacientesProvider>(context, listen: false);
    
    final tipoCtrl = TextEditingController(text: arritmia?.tipoArritmia);
    final riesgoCtrl = TextEditingController(text: arritmia?.nivelRiesgo ?? 'Bajo');
    final estadoCtrl = TextEditingController(text: arritmia?.estado ?? 'Activa');
    final obsCtrl = TextEditingController(text: arritmia?.observaciones);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(arritmia == null ? 'Nueva Arritmia' : 'Editar Arritmia', style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(tipoCtrl, 'Tipo de Arritmia', Icons.heart_broken, hint: 'Ej: Bradicardia Sinusal'),
                _buildField(riesgoCtrl, 'Nivel de Riesgo', Icons.warning_amber, hint: 'Bajo, Medio, Alto, Crítico'),
                _buildField(estadoCtrl, 'Estado', Icons.info_outline, hint: 'Activa, En tratamiento, Controlada'),
                _buildField(obsCtrl, 'Observaciones Médicas', Icons.notes, maxLines: 3, hint: 'Detalles adicionales...'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              if (tipoCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El tipo de arritmia es obligatorio')));
                return;
              }

              final datos = {
                'tipo_arritmia': tipoCtrl.text,
                'fecha_deteccion': DateTime.now().toIso8601String().split('T')[0],
                'nivel_riesgo': riesgoCtrl.text,
                'estado': estadoCtrl.text,
                'observaciones': obsCtrl.text,
              };
              
              bool ok;
              if (arritmia == null) {
                ok = await pacProv.registrarArritmia(
                  token: authProv.token!,
                  pacienteId: widget.paciente.id,
                  datos: datos,
                );
              } else {
                ok = await pacProv.actualizarArritmia(
                  token: authProv.token!,
                  arritmiaId: arritmia.id,
                  datos: datos,
                );
              }

              if (ok && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro guardado correctamente')));
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar registro'), backgroundColor: Colors.redAccent));
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _teal)),
        ),
      ),
    );
  }
}

class _ArritmiaCard extends StatelessWidget {
  final ArritmiaModel arritmia;
  final PacienteModel paciente;
  const _ArritmiaCard({required this.arritmia, required this.paciente});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(arritmia.tipoArritmia, style: const TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.bold, fontSize: 16)),
              _RiesgoBadge(riesgo: arritmia.nivelRiesgo),
            ],
          ),
          const SizedBox(height: 8),
          Text('Desde: ${arritmia.fechaDeteccion}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Text('Estado: ${arritmia.estado}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (arritmia.observaciones?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(arritmia.observaciones!, style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
            ),
          const Divider(color: Colors.white10, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _verSeguimientos(context),
                icon: const Icon(Icons.history, size: 16),
                label: Text('Seguimientos (${arritmia.seguimientos.length})'),
                style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => _confirmarEliminar(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _verSeguimientos(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _SeguimientosArritmiaDialog(arritmia: arritmia),
    );
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('¿Eliminar registro?', style: TextStyle(color: Colors.white)),
        content: const Text('Se eliminará la arritmia y todo su historial de seguimiento.', style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final authProv = Provider.of<AuthProvider>(context, listen: false);
              final pacProv = Provider.of<PacientesProvider>(context, listen: false);
              final ok = await pacProv.eliminarArritmia(token: authProv.token!, arritmiaId: arritmia.id);
              if (ok && context.mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _SeguimientosArritmiaDialog extends StatefulWidget {
  final ArritmiaModel arritmia;
  const _SeguimientosArritmiaDialog({required this.arritmia});

  @override
  State<_SeguimientosArritmiaDialog> createState() => _SeguimientosArritmiaDialogState();
}

class _SeguimientosArritmiaDialogState extends State<_SeguimientosArritmiaDialog> {
  static const _teal = Color(0xFF00BFA5);
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D1117),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text('Seguimiento: ${widget.arritmia.tipoArritmia}', style: const TextStyle(color: Colors.white, fontSize: 16))),
          IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: () => Navigator.pop(context)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: widget.arritmia.seguimientos.isEmpty
                  ? const Center(child: Text('No hay controles registrados.', style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      itemCount: widget.arritmia.seguimientos.length,
                      itemBuilder: (context, i) {
                        final s = widget.arritmia.seguimientos[i];
                        return Card(
                          color: const Color(0xFF161B22),
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.favorite, color: Colors.redAccent, size: 16),
                            ),
                            title: Text('${s.frecuenciaCardiaca} BPM', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('Fecha: ${s.fechaControl}\nRiesgo: ${s.nivelRiesgo} | Estado: ${s.estado}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 18),
                              onPressed: () => _confirmarEliminarSeguimiento(s.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _nuevoSeguimiento(context),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Nuevo Control de Seguimiento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminarSeguimiento(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('¿Eliminar control?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final authProv = Provider.of<AuthProvider>(context, listen: false);
              final pacProv = Provider.of<PacientesProvider>(context, listen: false);
              await pacProv.eliminarSeguimientoArritmia(token: authProv.token!, seguimientoId: id);
              if (mounted) {
                Navigator.pop(context); // Cerrar confirma
                Navigator.pop(context); // Cerrar lista para refrescar
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _nuevoSeguimiento(BuildContext context) {
    final bpmCtrl = TextEditingController();
    final riesgoCtrl = TextEditingController(text: widget.arritmia.nivelRiesgo);
    final estadoCtrl = TextEditingController(text: widget.arritmia.estado);
    final obsCtrl = TextEditingController();
    bool isSavingLocal = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Registrar Seguimiento Evolutivo', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 350,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField(bpmCtrl, 'Frecuencia Cardíaca (BPM)', Icons.speed, isNumeric: true),
                  _buildDialogField(riesgoCtrl, 'Nivel de Riesgo Actual', Icons.warning_amber),
                  _buildDialogField(estadoCtrl, 'Estado Clínico', Icons.info_outline),
                  _buildDialogField(obsCtrl, 'Observaciones de Evolución', Icons.notes, maxLines: 3),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isSavingLocal ? null : () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _teal),
              onPressed: isSavingLocal ? null : () async {
                if (bpmCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese la frecuencia cardíaca')));
                  return;
                }

                setDialogState(() => isSavingLocal = true);
                final authProv = Provider.of<AuthProvider>(context, listen: false);
                final pacProv = Provider.of<PacientesProvider>(context, listen: false);
                
                final datos = {
                  'fecha_control': DateTime.now().toIso8601String().split('T')[0],
                  'frecuencia_cardiaca': int.tryParse(bpmCtrl.text) ?? 0,
                  'nivel_riesgo': riesgoCtrl.text,
                  'estado': estadoCtrl.text,
                  'observaciones': obsCtrl.text,
                };
                
                final ok = await pacProv.registrarSeguimientoArritmia(
                  token: authProv.token!, 
                  arritmiaId: widget.arritmia.id, 
                  datos: datos
                );

                if (mounted) {
                  setDialogState(() => isSavingLocal = false);
                  if (ok) {
                    Navigator.pop(context); // Cerrar form
                    Navigator.pop(context); // Cerrar lista para refrescar
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Control registrado con éxito')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al registrar control'), backgroundColor: Colors.redAccent));
                  }
                }
              },
              child: isSavingLocal 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Registrar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _teal, fontSize: 12),
          prefixIcon: Icon(icon, color: Colors.white24, size: 18),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _teal)),
        ),
      ),
    );
  }
}

class _RiesgoBadge extends StatelessWidget {
  final String riesgo;
  const _RiesgoBadge({required this.riesgo});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.greenAccent;
    if (riesgo.toLowerCase().contains('alto') || riesgo.toLowerCase().contains('critico')) {
      color = Colors.redAccent;
    } else if (riesgo.toLowerCase().contains('medio')) {
      color = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        riesgo.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
