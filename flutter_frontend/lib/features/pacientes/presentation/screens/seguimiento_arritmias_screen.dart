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
        title: Text(arritmia == null ? 'Nueva Arritmia' : 'Editar Arritmia', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(tipoCtrl, 'Tipo de Arritmia (Ej: Bradicardia)', Icons.heart_broken),
              _buildField(riesgoCtrl, 'Nivel de Riesgo', Icons.warning_amber),
              _buildField(estadoCtrl, 'Estado', Icons.info_outline),
              _buildField(obsCtrl, 'Observaciones', Icons.notes, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _teal),
            onPressed: () async {
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro actualizado')));
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _teal),
          prefixIcon: Icon(icon, color: Colors.white24, size: 20),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _teal)),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D1117),
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      title: Text('Seguimiento: ${widget.arritmia.tipoArritmia}', style: const TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
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
                          child: ListTile(
                            dense: true,
                            title: Text('${s.fechaControl} - ${s.frecuenciaCardiaca} BPM', style: const TextStyle(color: Colors.white)),
                            subtitle: Text('Riesgo: ${s.nivelRiesgo}\nEstado: ${s.estado}', style: const TextStyle(color: Colors.white54)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white24, size: 16),
                              onPressed: () async {
                                final authProv = Provider.of<AuthProvider>(context, listen: false);
                                final pacProv = Provider.of<PacientesProvider>(context, listen: false);
                                await pacProv.eliminarSeguimientoArritmia(token: authProv.token!, seguimientoId: s.id);
                                if (mounted) Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _nuevoSeguimiento(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Nuevo Control BPM'),
              style: ElevatedButton.styleFrom(backgroundColor: _teal),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }

  void _nuevoSeguimiento(BuildContext context) {
    final bpmCtrl = TextEditingController();
    final riesgoCtrl = TextEditingController(text: widget.arritmia.nivelRiesgo);
    final estadoCtrl = TextEditingController(text: widget.arritmia.estado);
    final obsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Nuevo Seguimiento', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bpmCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Frecuencia Cardíaca (BPM)', labelStyle: TextStyle(color: _teal)),
            ),
            TextField(
              controller: riesgoCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Nivel de Riesgo', labelStyle: TextStyle(color: _teal)),
            ),
            TextField(
              controller: estadoCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Estado', labelStyle: TextStyle(color: _teal)),
            ),
            TextField(
              controller: obsCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Observaciones', labelStyle: TextStyle(color: _teal)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final authProv = Provider.of<AuthProvider>(context, listen: false);
              final pacProv = Provider.of<PacientesProvider>(context, listen: false);
              final datos = {
                'fecha_control': DateTime.now().toIso8601String().split('T')[0],
                'frecuencia_cardiaca': int.tryParse(bpmCtrl.text) ?? 0,
                'nivel_riesgo': riesgoCtrl.text,
                'estado': estadoCtrl.text,
                'observaciones': obsCtrl.text,
              };
              final ok = await pacProv.registrarSeguimientoArritmia(token: authProv.token!, arritmiaId: widget.arritmia.id, datos: datos);
              if (ok && context.mounted) {
                Navigator.pop(context); // Cerrar form
                Navigator.pop(context); // Cerrar historial
              }
            },
            child: const Text('Registrar'),
          ),
        ],
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
