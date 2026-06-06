import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../features/auth/logic/auth_provider.dart';
import '../../../dashboard/logic/menu_app_controller.dart';
import '../../logic/pacientes_provider.dart';
import '../../data/paciente_model.dart';

class TratamientosScreen extends StatefulWidget {
  const TratamientosScreen({super.key});

  @override
  State<TratamientosScreen> createState() => _TratamientosScreenState();
}

class _TratamientosScreenState extends State<TratamientosScreen> {
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
          '6. Tratamientos y Recomendaciones',
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
                          trailing: const Icon(Icons.medical_services, color: _teal),
                          onTap: () => _verTratamientosPaciente(p),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _verTratamientosPaciente(PacienteModel paciente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DetalleTratamientosSheet(paciente: paciente),
    );
  }
}

class _DetalleTratamientosSheet extends StatefulWidget {
  final PacienteModel paciente;
  const _DetalleTratamientosSheet({required this.paciente});

  @override
  State<_DetalleTratamientosSheet> createState() => _DetalleTratamientosSheetState();
}

class _DetalleTratamientosSheetState extends State<_DetalleTratamientosSheet> {
  static const _teal = Color(0xFF00BFA5);

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
                'Planes de ${pacienteActual.nombre}',
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
            child: pacienteActual.tratamientos.isEmpty
                ? const Center(child: Text('No hay planes registrados.', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: pacienteActual.tratamientos.length,
                    itemBuilder: (context, i) {
                      final tr = pacienteActual.tratamientos[i];
                      return _TratamientoItem(
                        tratamiento: tr,
                        onEdit: () => _mostrarFormularioTratamiento(context, tratamiento: tr),
                        onDelete: () => _confirmarEliminarTratamiento(context, tr.id),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _mostrarFormularioTratamiento(context),
              icon: const Icon(Icons.add_task),
              label: const Text('Nuevo Plan de Tratamiento'),
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

  void _mostrarFormularioTratamiento(BuildContext context, {TratamientoModel? tratamiento}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TratamientoFormDialog(
        pacienteId: widget.paciente.id,
        tratamiento: tratamiento,
      ),
    );
  }

  void _confirmarEliminarTratamiento(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('¿Eliminar plan?', style: TextStyle(color: Colors.white)),
        content: const Text('Esta acción eliminará el tratamiento y sus medicamentos.', style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final authProv = Provider.of<AuthProvider>(context, listen: false);
              final pacProv = Provider.of<PacientesProvider>(context, listen: false);
              final ok = await pacProv.eliminarTratamiento(token: authProv.token!, tratamientoId: id);
              if (ok && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan eliminado')));
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _TratamientoItem extends StatelessWidget {
  final TratamientoModel tratamiento;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TratamientoItem({
    required this.tratamiento,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00BFA5);
    final fInicio = DateFormat('dd/MM/yyyy').format(DateTime.parse(tratamiento.fechaInicio));
    final fFin = tratamiento.fechaFin != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(tratamiento.fechaFin!)) : 'Indefinido';

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
                  color: _getColorEstado(tratamiento.estado).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tratamiento.estado, style: TextStyle(color: _getColorEstado(tratamiento.estado), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 20), onPressed: onEdit),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: onDelete),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Desde: $fInicio  -  Hasta: $fFin', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          
          if (tratamiento.medicamentos.isNotEmpty) ...[
            const Divider(color: Colors.white10, height: 25),
            const Text('MEDICAMENTOS', style: TextStyle(color: teal, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ...tratamiento.medicamentos.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medication, size: 14, color: Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.nombreMedicamento, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${m.dosis} - ${m.frecuencia} (${m.duracion})', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],

          if (tratamiento.recomendaciones.isNotEmpty) ...[
            const Divider(color: Colors.white10, height: 25),
            const Text('RECOMENDACIONES', style: TextStyle(color: teal, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ...tratamiento.recomendaciones.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(_getIconRec(r.tipoRecomendacion), size: 14, color: Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${r.tipoRecomendacion}: ${r.descripcion}', style: const TextStyle(color: Colors.white70, fontSize: 13))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Color _getColorEstado(String estado) {
    if (estado == 'Activo') return Colors.greenAccent;
    if (estado == 'Suspendido') return Colors.redAccent;
    return Colors.orangeAccent;
  }

  IconData _getIconRec(String tipo) {
    switch (tipo) {
      case 'Ejercicio': return Icons.directions_run;
      case 'Dieta': return Icons.restaurant;
      case 'Restricción': return Icons.block;
      case 'Control Médico': return Icons.event_available;
      default: return Icons.info_outline;
    }
  }
}

class _TratamientoFormDialog extends StatefulWidget {
  final int pacienteId;
  final TratamientoModel? tratamiento;

  const _TratamientoFormDialog({required this.pacienteId, this.tratamiento});

  @override
  State<_TratamientoFormDialog> createState() => _TratamientoFormDialogState();
}

class _TratamientoFormDialogState extends State<_TratamientoFormDialog> {
  static const _teal = Color(0xFF00BFA5);
  bool _isSaving = false;

  late DateTime _fechaInicio;
  DateTime? _fechaFin;
  String _estado = 'Activo';
  final _obsCtrl = TextEditingController();

  final List<_MedicamentoForm> _medicamentos = [];
  final List<_RecomendacionForm> _recomendaciones = [];

  @override
  void initState() {
    super.initState();
    _fechaInicio = widget.tratamiento != null ? DateTime.parse(widget.tratamiento!.fechaInicio) : DateTime.now();
    if (widget.tratamiento?.fechaFin != null) _fechaFin = DateTime.parse(widget.tratamiento!.fechaFin!);
    _estado = widget.tratamiento?.estado ?? 'Activo';
    _obsCtrl.text = widget.tratamiento?.observaciones ?? '';

    if (widget.tratamiento != null) {
      for (var m in widget.tratamiento!.medicamentos) {
        _medicamentos.add(_MedicamentoForm(
          nombre: TextEditingController(text: m.nombreMedicamento),
          dosis: TextEditingController(text: m.dosis),
          frecuencia: TextEditingController(text: m.frecuencia),
          duracion: TextEditingController(text: m.duracion),
        ));
      }
      for (var r in widget.tratamiento!.recomendaciones) {
        _recomendaciones.add(_RecomendacionForm(
          tipo: r.tipoRecomendacion,
          desc: TextEditingController(text: r.descripcion),
        ));
      }
    } else {
      _agregarMedicamento();
    }
  }

  void _agregarMedicamento() => setState(() => _medicamentos.add(_MedicamentoForm()));
  void _agregarRecomendacion() => setState(() => _recomendaciones.add(_RecomendacionForm()));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(widget.tratamiento == null ? 'Nuevo Plan' : 'Editar Plan', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker('INICIO', _fechaInicio, (d) => setState(() => _fechaInicio = d)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildDatePicker('FIN (OPCIONAL)', _fechaFin, (d) => setState(() => _fechaFin = d), clearable: true),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('MEDICAMENTOS', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.bold)),
              ..._medicamentos.asMap().entries.map((entry) => _buildMedItem(entry.key, entry.value)),
              TextButton.icon(onPressed: _agregarMedicamento, icon: const Icon(Icons.add, size: 16), label: const Text('Agregar Medicamento'), style: TextButton.styleFrom(foregroundColor: _teal)),
              
              const Divider(color: Colors.white10, height: 30),
              const Text('RECOMENDACIONES', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.bold)),
              ..._recomendaciones.asMap().entries.map((entry) => _buildRecItem(entry.key, entry.value)),
              TextButton.icon(onPressed: _agregarRecomendacion, icon: const Icon(Icons.add, size: 16), label: const Text('Agregar Recomendación'), style: TextButton.styleFrom(foregroundColor: _teal)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
        ElevatedButton(onPressed: _isSaving ? null : _guardar, style: ElevatedButton.styleFrom(backgroundColor: _teal), child: const Text('Guardar')),
      ],
    );
  }

  Widget _buildMedItem(int i, _MedicamentoForm form) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _miniField(form.nombre, 'Nombre (Ej: Amiodarona)')),
              IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.redAccent), onPressed: () => setState(() => _medicamentos.removeAt(i))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _miniField(form.dosis, 'Dosis (Ej: 200mg)')),
              const SizedBox(width: 8),
              Expanded(child: _miniField(form.frecuencia, 'Frecuencia (Ej: C/24h)')),
              const SizedBox(width: 8),
              Expanded(child: _miniField(form.duracion, 'Duración')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecItem(int i, _RecomendacionForm form) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          DropdownButton<String>(
            value: form.tipo,
            dropdownColor: const Color(0xFF1C2128),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            items: ['Ejercicio', 'Dieta', 'Restricción', 'Control Médico', 'Otro'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => form.tipo = v!),
          ),
          const SizedBox(width: 10),
          Expanded(child: _miniField(form.desc, 'Descripción')),
          IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.redAccent), onPressed: () => setState(() => _recomendaciones.removeAt(i))),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? val, Function(DateTime) onPick, {bool clearable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: val ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (d != null) onPick(d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(val != null ? DateFormat('dd/MM/yyyy').format(val) : 'Seleccionar', style: const TextStyle(color: Colors.white, fontSize: 13)),
                if (clearable && val != null) IconButton(icon: const Icon(Icons.clear, size: 14), onPressed: () => setState(() => _fechaFin = null), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _teal)),
      ),
    );
  }

  Future<void> _guardar() async {
    if (_medicamentos.isEmpty && _recomendaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debe agregar al menos un medicamento o recomendación')));
      return;
    }

    setState(() => _isSaving = true);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final pacProv = Provider.of<PacientesProvider>(context, listen: false);

    final datos = {
      'fecha_inicio': DateFormat('yyyy-MM-dd').format(_fechaInicio),
      'fecha_fin': _fechaFin != null ? DateFormat('yyyy-MM-dd').format(_fechaFin!) : null,
      'estado': _estado,
      'observaciones': _obsCtrl.text,
      'medicamentos': _medicamentos.map((m) => {
        'nombre_medicamento': m.nombre.text,
        'dosis': m.dosis.text,
        'frecuencia': m.frecuencia.text,
        'duracion': m.duracion.text,
      }).toList(),
      'recomendaciones': _recomendaciones.map((r) => {
        'tipo_recomendacion': r.tipo,
        'descripcion': r.desc.text,
      }).toList(),
    };

    bool ok;
    if (widget.tratamiento == null) {
      ok = await pacProv.registrarTratamiento(token: authProv.token!, pacienteId: widget.pacienteId, datos: datos);
    } else {
      ok = await pacProv.actualizarTratamiento(token: authProv.token!, tratamientoId: widget.tratamiento!.id, datos: datos);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tratamiento guardado')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar'), backgroundColor: Colors.redAccent));
      }
    }
  }
}

class _MedicamentoForm {
  final TextEditingController nombre;
  final TextEditingController dosis;
  final TextEditingController frecuencia;
  final TextEditingController duracion;
  _MedicamentoForm({TextEditingController? nombre, TextEditingController? dosis, TextEditingController? frecuencia, TextEditingController? duracion}) 
    : nombre = nombre ?? TextEditingController(),
      dosis = dosis ?? TextEditingController(),
      frecuencia = frecuencia ?? TextEditingController(),
      duracion = duracion ?? TextEditingController();
}

class _RecomendacionForm {
  String tipo;
  final TextEditingController desc;
  _RecomendacionForm({this.tipo = 'Ejercicio', TextEditingController? desc}) : desc = desc ?? TextEditingController();
}
