// lib/features/pacientes/presentation/screens/expediente_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/logic/auth_provider.dart';
import '../../../dashboard/presentation/constants.dart';
import '../../logic/pacientes_provider.dart';
import '../../data/paciente_model.dart';
import 'agregar_control_screen.dart';

class ExpedienteScreen extends StatefulWidget {
  final PacienteModel paciente;
  const ExpedienteScreen({super.key, required this.paciente});

  @override
  State<ExpedienteScreen> createState() => _ExpedienteScreenState();
}

class _ExpedienteScreenState extends State<ExpedienteScreen> {
  String _filtroSeleccionado = 'Todos';
  final List<String> _opcionesFiltro = ['Todos', 'Últimos 30 días', 'Últimos 7 días'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      Provider.of<PacientesProvider>(context, listen: false).cargarPacientes(token);
    });
  }

  List<dynamic> _obtenerControlesFiltrados(List<dynamic> todos) {
    if (_filtroSeleccionado == 'Todos') return todos;
    
    final now = DateTime.now();
    return todos.where((c) {
      final fechaStr = (c['fecha'] ?? c.fecha ?? '').toString();
      if (fechaStr.isEmpty) return false;
      try {
        final dt = DateTime.parse(fechaStr);
        if (_filtroSeleccionado == 'Últimos 7 días') {
          return now.difference(dt).inDays <= 7;
        } else if (_filtroSeleccionado == 'Últimos 30 días') {
          return now.difference(dt).inDays <= 30;
        }
      } catch (_) {}
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PacientesProvider>(context);
    final p = prov.pacientes.firstWhere((x) => x.id == widget.paciente.id, orElse: () => widget.paciente);
    
    final todosLosControles = p.historialControles ?? [];
    final controlesFiltrados = _obtenerControlesFiltrados(todosLosControles);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.nombre, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(p.email, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          // ▼ FIX: Envolvemos TODO en un SingleChildScrollView
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PacienteInfoCard(paciente: p),
                  
                  if (todosLosControles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Historial Clínico', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Container(
                            height: 35,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: primaryColor.withOpacity(0.3)),
                            ),
                            child: DropdownButton<String>(
                              value: _filtroSeleccionado,
                              dropdownColor: secondaryColor,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.filter_list, color: primaryColor, size: 16),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              items: _opcionesFiltro.map((String value) {
                                return DropdownMenuItem<String>(value: value, child: Text(value));
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _filtroSeleccionado = newValue!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                  const SizedBox(height: defaultPadding),

                  if (todosLosControles.isEmpty)
                    _EstadoVacio(onAgregar: () => _abrirAgregarControl(context, p))
                  else ...[
                    // ─── PANEL CARRUSEL DE MINI GRÁFICAS ───
                    if (controlesFiltrados.length > 1)
                      _PanelGraficas(controles: controlesFiltrados),
                    
                    if (controlesFiltrados.length > 1) 
                      const SizedBox(height: defaultPadding),

                    // ─── LISTA DE CONTROLES ───
                    if (controlesFiltrados.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(defaultPadding),
                        child: Center(child: Text("No hay controles en este periodo.", style: TextStyle(color: Colors.white54))),
                      )
                    else
                      ListView.builder(
                        // ▼ FIX: Permitimos que la lista sea parte del scroll general sin "rebelarse"
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(defaultPadding, 0, defaultPadding, 100),
                        itemCount: controlesFiltrados.length,
                        itemBuilder: (context, i) {
                          final control = controlesFiltrados[controlesFiltrados.length - 1 - i];
                          return _ControlCard(control: control, index: controlesFiltrados.length - i);
                        },
                      ),
                  ]
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: () => _abrirAgregarControl(context, p),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Control', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _abrirAgregarControl(BuildContext context, PacienteModel p) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AgregarControlScreen(paciente: p, token: token)));
    if (result == true && mounted) {
      Provider.of<PacientesProvider>(context, listen: false).cargarPacientes(token);
    }
  }
}

// ==========================================
// COMPONENTE: PANEL DE MINI GRÁFICAS (CARRUSEL)
// ==========================================
class _PanelGraficas extends StatelessWidget {
  final List<dynamic> controles;
  const _PanelGraficas({required this.controles});

  @override
  Widget build(BuildContext context) {
    // Cronológico: De más antiguo a más reciente (Izq a Der)
    final cronologico = List.from(controles).reversed.toList();

    return SizedBox(
      height: 190, // Altura compacta para las mini gráficas
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        children: [
          _MiniGraficaPresion(cronologico: cronologico),
          const SizedBox(width: defaultPadding),
          _MiniGraficaFrecuencia(cronologico: cronologico),
          const SizedBox(width: defaultPadding),
          _MiniGraficaSpO2(cronologico: cronologico),
        ],
      ),
    );
  }
}

// ─── MINI GRÁFICA 1: PRESIÓN ARTERIAL ───
class _MiniGraficaPresion extends StatelessWidget {
  final List<dynamic> cronologico;
  const _MiniGraficaPresion({required this.cronologico});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spotsSistolica = [];
    List<FlSpot> spotsDiastolica = [];

    for (int i = 0; i < cronologico.length; i++) {
      final sis = (cronologico[i]['presion_sistolica'] ?? 0).toDouble();
      final dia = (cronologico[i]['presion_diastolica'] ?? 0).toDouble();
      spotsSistolica.add(FlSpot(i.toDouble(), sis));
      spotsDiastolica.add(FlSpot(i.toDouble(), dia));
    }

    return _MiniCardBase(
      title: 'Presión Arterial',
      icon: Icons.favorite_outline,
      iconColor: Colors.redAccent,
      leyenda: 'Sis (Rojo) / Dia (Azul)',
      child: LineChart(
        LineChartData(
          minX: 0, maxX: (cronologico.length - 1).toDouble(), minY: 40, maxY: 200,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(spots: spotsSistolica, color: Colors.redAccent, barWidth: 2.5, isStrokeCapRound: true, dotData: const FlDotData(show: true)),
            LineChartBarData(spots: spotsDiastolica, color: primaryColor, barWidth: 2.5, isStrokeCapRound: true, dotData: const FlDotData(show: true)),
          ],
        ),
      ),
    );
  }
}

// ─── MINI GRÁFICA 2: FRECUENCIA CARDÍACA ───
class _MiniGraficaFrecuencia extends StatelessWidget {
  final List<dynamic> cronologico;
  const _MiniGraficaFrecuencia({required this.cronologico});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];

    for (int i = 0; i < cronologico.length; i++) {
      final val = (cronologico[i]['frecuencia_cardiaca'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), val));
    }

    return _MiniCardBase(
      title: 'Frecuencia',
      icon: Icons.monitor_heart_outlined,
      iconColor: Colors.purpleAccent,
      leyenda: 'Latidos por minuto (bpm)',
      child: LineChart(
        LineChartData(
          minX: 0, maxX: (cronologico.length - 1).toDouble(), minY: 40, maxY: 160,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots, color: Colors.purpleAccent, barWidth: 3,
              isStrokeCapRound: true, dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.purpleAccent.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MINI GRÁFICA 3: SATURACIÓN O2 (SpO2) ───
class _MiniGraficaSpO2 extends StatelessWidget {
  final List<dynamic> cronologico;
  const _MiniGraficaSpO2({required this.cronologico});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];

    for (int i = 0; i < cronologico.length; i++) {
      final val = (cronologico[i]['saturacion_oxigeno'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), val));
    }

    return _MiniCardBase(
      title: 'Saturación SpO₂',
      icon: Icons.air_outlined,
      iconColor: Colors.tealAccent,
      leyenda: 'Porcentaje de oxígeno (%)',
      child: LineChart(
        LineChartData(
          minX: 0, maxX: (cronologico.length - 1).toDouble(), minY: 70, maxY: 105,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots, color: Colors.tealAccent, barWidth: 3,
              isStrokeCapRound: true, dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.tealAccent.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ENVOLTORIO BASE PARA LAS MINI GRÁFICAS ───
class _MiniCardBase extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String leyenda;
  final Widget child;

  const _MiniCardBase({
    required this.title, required this.icon, required this.iconColor, required this.leyenda, required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260, // Ancho fijo para el carrusel
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 2),
          Text(leyenda, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
          const SizedBox(height: 12),
          Expanded(child: child), // Aquí se dibuja la gráfica
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENTES EXISTENTES REUTILIZADOS
// ==========================================

class _PacienteInfoCard extends StatelessWidget {
  final PacienteModel paciente;
  const _PacienteInfoCard({required this.paciente});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28, backgroundColor: primaryColor.withOpacity(0.2),
            child: Text(paciente.nombre.isNotEmpty ? paciente.nombre[0].toUpperCase() : '?', style: const TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paciente.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _InfoChip(icon: Icons.person_outline, label: '${paciente.edad} años'), const SizedBox(width: 8),
                    _InfoChip(icon: Icons.wc_outlined, label: paciente.sexo), const SizedBox(width: 8),
                    _InfoChip(icon: Icons.monitor_weight_outlined, label: '${paciente.pesoInicial} kg'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 14), const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _ControlCard extends StatelessWidget {
  final dynamic control; final int index;
  const _ControlCard({required this.control, required this.index});

  Color _getPresionColor(int sistolica) {
    if (sistolica >= 140) return Colors.redAccent;
    if (sistolica >= 120) return Colors.orange;
    return Colors.green;
  }

  Color _getSaturacionColor(int sat) {
    if (sat < 90) return Colors.redAccent;
    if (sat < 95) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final sistolica = control['presion_sistolica'] ?? control.presionSistolica ?? 0;
    final diastolica = control['presion_diastolica'] ?? control.presionDiastolica ?? 0;
    final frecuencia = control['frecuencia_cardiaca'] ?? control.frecuenciaCardiaca ?? 0;
    final saturacion = control['saturacion_oxigeno'] ?? control.saturacionOxigeno ?? 0;
    final sintomas = control['sintomas'] ?? control.sintomas ?? 'Ninguno';
    final diagnostico = control['diagnostico_ecg'] ?? control.diagnosticoEcg ?? 'Pendiente';
    
    return Container(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text('Control #$index', style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined, color: Colors.white30, size: 14),
                const SizedBox(width: 6),
                Text((control['fecha'] ?? '').toString().split(' ').first, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _MetricBox(label: 'Presión', value: '$sistolica/$diastolica', unit: 'mmHg', color: _getPresionColor(sistolica), icon: Icons.favorite_outline),
                const SizedBox(width: 8),
                _MetricBox(label: 'Frecuencia', value: '$frecuencia', unit: 'bpm', color: Colors.purpleAccent, icon: Icons.monitor_heart_outlined),
                const SizedBox(width: 8),
                _MetricBox(label: 'SpO₂', value: '$saturacion', unit: '%', color: _getSaturacionColor(saturacion), icon: Icons.air_outlined),
              ],
            ),
          ),
          if (sintomas != 'Ninguno' || diagnostico != 'Pendiente')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
              child: Column(
                children: [
                  if (sintomas != 'Ninguno') Row(children: [const Icon(Icons.notes_outlined, color: Colors.white38, size: 16), const SizedBox(width: 8), Expanded(child: Text(sintomas, style: const TextStyle(color: Colors.white70, fontSize: 13)))]),
                  if (diagnostico != 'Pendiente') Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [const Icon(Icons.monitor_heart, color: Colors.amber, size: 16), const SizedBox(width: 8), Text('ECG: $diagnostico', style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold))])),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label, value, unit; final Color color; final IconData icon;
  const _MetricBox({required this.label, required this.value, required this.unit, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: color, size: 14), const SizedBox(width: 6), Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11))]),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(unit, style: TextStyle(color: color.withOpacity(0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final VoidCallback onAgregar;
  const _EstadoVacio({required this.onAgregar});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_heart_outlined, color: Colors.white.withOpacity(0.2), size: 80),
          const SizedBox(height: 20),
          const Text('Sin controles registrados', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Agrega el primer control cardiológico\npara comenzar el historial.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }
}