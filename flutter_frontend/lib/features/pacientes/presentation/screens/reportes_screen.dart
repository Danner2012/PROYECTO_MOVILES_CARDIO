import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../../../../core/utils/pdf_helper.dart';

import '../../../../features/auth/logic/auth_provider.dart';
import '../../../dashboard/logic/menu_app_controller.dart';
import '../../logic/pacientes_provider.dart';
import '../../data/paciente_model.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  static const _bg      = Color(0xFF0D1117);
  static const _teal    = Color(0xFF00BFA5);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF30363D);

  final _searchCtrl = TextEditingController();
  String _query = '';
  PacienteModel? _pacienteSeleccionado;

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
          '8. Reportes Clínicos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Provider.of<MenuAppController>(context, listen: false).controlMenu(context),
        ),
      ),
      body: Row(
        children: [
          // Lado Izquierdo: Lista de Pacientes
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: _border)),
              ),
              child: Column(
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
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _teal)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: prov.isLoading
                        ? const Center(child: CircularProgressIndicator(color: _teal))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: filtrados.length,
                            itemBuilder: (context, i) {
                              final p = filtrados[i];
                              final esSeleccionado = _pacienteSeleccionado?.id == p.id;
                              return Card(
                                color: esSeleccionado ? _teal.withValues(alpha: 0.1) : _surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: esSeleccionado ? _teal : _border),
                                ),
                                child: ListTile(
                                  title: Text(p.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text(p.email, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                  onTap: () => setState(() => _pacienteSeleccionado = p),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Lado Derecho: Acciones de Reporte
          Expanded(
            flex: 3,
            child: _pacienteSeleccionado == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 60, color: Colors.white10),
                        SizedBox(height: 10),
                        Text('Seleccione un paciente para generar el reporte', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  )
                : _buildReportDetail(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportDetail() {
    final p = _pacienteSeleccionado!;
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generación de Reporte Integral',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            'Paciente: ${p.nombre}',
            style: const TextStyle(color: _teal, fontSize: 16),
          ),
          const SizedBox(height: 30),
          _buildInfoCard(
            title: 'Contenido del Reporte',
            items: [
              'Datos Personales y Antecedentes.',
              'Historial Clínico y Observaciones.',
              'Episodios de Arritmias y Seguimientos.',
              'Planes de Tratamiento Activos.',
              'Medicamentos y Recomendaciones.',
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amberAccent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El reporte se generará en formato PDF y se abrirá en una nueva pestaña o aplicación externa.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _generarReporte,
                    icon: _isDownloading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf, size: 24),
                    label: Text(
                      _isDownloading ? 'GENERANDO...' : 'DESCARGAR REPORTE COMPLETO', 
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<String> items}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 15),
          ...items.map((it) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: _teal, size: 16),
                const SizedBox(width: 10),
                Text(it, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  bool _isDownloading = false;

  Future<void> _generarReporte() async {
    if (_pacienteSeleccionado == null) return;
    
    setState(() => _isDownloading = true);
    
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final token = authProv.token;
    final pacienteId = _pacienteSeleccionado!.id;
    final emailPaciente = _pacienteSeleccionado!.email;
    
    final url = Uri.parse('http://127.0.0.1:8000/api/pacientes/$pacienteId/reporte-pdf/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final fileName = 'reporte_${emailPaciente}_${DateTime.now().millisecondsSinceEpoch}.pdf';

        // Usamos el Helper multiplataforma
        await getPdfHelperInstance().saveAndOpenPdf(bytes, fileName);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reporte generado correctamente')),
          );
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error descargando PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar reporte: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }
}
