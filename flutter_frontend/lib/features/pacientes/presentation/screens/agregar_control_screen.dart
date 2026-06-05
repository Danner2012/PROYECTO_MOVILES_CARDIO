// lib/features/pacientes/presentation/screens/agregar_control_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../dashboard/presentation/constants.dart';
import '../../logic/pacientes_provider.dart';
import '../../data/paciente_model.dart';

class AgregarControlScreen extends StatefulWidget {
  final PacienteModel paciente;
  final String token;
  const AgregarControlScreen({super.key, required this.paciente, required this.token});

  @override
  State<AgregarControlScreen> createState() => _AgregarControlScreenState();
}

class _AgregarControlScreenState extends State<AgregarControlScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final _sistolicaCtrl = TextEditingController();
  final _diastolicaCtrl = TextEditingController();
  final _frecuenciaCtrl = TextEditingController();
  final _saturacionCtrl = TextEditingController();
  final _sintomasCtrl = TextEditingController(text: 'Ninguno');
  final _diagnosticoCtrl = TextEditingController(text: 'Pendiente');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _sistolicaCtrl.dispose(); _diastolicaCtrl.dispose(); _frecuenciaCtrl.dispose();
    _saturacionCtrl.dispose(); _sintomasCtrl.dispose(); _diagnosticoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final datos = {
      'presion_sistolica': int.parse(_sistolicaCtrl.text.trim()),
      'presion_diastolica': int.parse(_diastolicaCtrl.text.trim()),
      'frecuencia_cardiaca': int.parse(_frecuenciaCtrl.text.trim()),
      'saturacion_oxigeno': int.parse(_saturacionCtrl.text.trim()),
      'sintomas': _sintomasCtrl.text.trim(),
      'diagnostico_ecg': _diagnosticoCtrl.text.trim(),
    };

    final ok = await Provider.of<PacientesProvider>(context, listen: false).agregarControlCardio(
      token: widget.token, pacienteId: widget.paciente.id, datosControl: datos,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.green, content: const Text('Control registrado correctamente')));
      Navigator.pop(context, true);
    } else {
      final error = Provider.of<PacientesProvider>(context, listen: false).ultimoError ?? 'Error al registrar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: secondaryColor, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nuevo Control', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.paciente.nombre, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(defaultPadding),
                    decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.monitor_heart_outlined, color: primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Control Cardiológico', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('Registro clínico actualizado', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: defaultPadding * 1.5),

                  const _SectionLabel(label: 'PRESIÓN ARTERIAL', icon: Icons.favorite_outline),
                  const SizedBox(height: defaultPadding),
                  Row(
                    children: [
                      Expanded(child: _DarkField(controller: _sistolicaCtrl, label: 'Sistólica', hint: '120', suffix: 'mmHg', inputType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Req' : null)),
                      const SizedBox(width: defaultPadding),
                      Expanded(child: _DarkField(controller: _diastolicaCtrl, label: 'Diastólica', hint: '80', suffix: 'mmHg', inputType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Req' : null)),
                    ],
                  ),
                  const SizedBox(height: defaultPadding * 1.5),

                  const _SectionLabel(label: 'SIGNOS VITALES', icon: Icons.sensors_outlined),
                  const SizedBox(height: defaultPadding),
                  Row(
                    children: [
                      Expanded(child: _DarkField(controller: _frecuenciaCtrl, label: 'Frecuencia', hint: '72', suffix: 'bpm', inputType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Req' : null)),
                      const SizedBox(width: defaultPadding),
                      Expanded(child: _DarkField(controller: _saturacionCtrl, label: 'SpO₂', hint: '98', suffix: '%', inputType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Req' : null)),
                    ],
                  ),
                  const SizedBox(height: defaultPadding * 1.5),

                  const _SectionLabel(label: 'OBSERVACIONES', icon: Icons.notes_outlined),
                  const SizedBox(height: defaultPadding),
                  _DarkMultilineField(controller: _sintomasCtrl, label: 'Síntomas', hint: 'Describe...', validator: (v) => v!.isEmpty ? 'Req' : null),
                  const SizedBox(height: defaultPadding),
                  _DarkField(controller: _diagnosticoCtrl, label: 'Diagnóstico ECG', hint: 'Ritmo normal...', validator: (v) => v!.isEmpty ? 'Req' : null),
                  
                  const SizedBox(height: defaultPadding * 2),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: _isLoading ? null : _guardar,
                      icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save_alt_outlined, color: Colors.white),
                      label: Text(_isLoading ? 'Guardando...' : 'Guardar Control', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helpers locales
class _SectionLabel extends StatelessWidget {
  final String label; final IconData icon;
  const _SectionLabel({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 16), const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(width: 10), Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
      ],
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller; final String label, hint; final String? suffix; final TextInputType inputType; final String? Function(String?)? validator;
  const _DarkField({required this.controller, required this.label, required this.hint, this.suffix, this.inputType = TextInputType.text, this.validator});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller, keyboardType: inputType, validator: validator, style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label, hintText: hint, suffixText: suffix,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        filled: true, fillColor: secondaryColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
      ),
    );
  }
}

class _DarkMultilineField extends StatelessWidget {
  final TextEditingController controller; final String label, hint; final String? Function(String?)? validator;
  const _DarkMultilineField({required this.controller, required this.label, required this.hint, this.validator});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller, maxLines: 3, validator: validator, style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, hintText: hint, alignLabelWithHint: true,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        filled: true, fillColor: secondaryColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
      ),
    );
  }
}