import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../logic/pacientes_provider.dart';
import '../../data/paciente_model.dart';
// ignore_for_file: use_build_context_synchronously

class AgregarControlScreen extends StatefulWidget {
  final PacienteModel paciente;
  final String token;

  const AgregarControlScreen({
    super.key,
    required this.paciente,
    required this.token,
  });

  @override
  State<AgregarControlScreen> createState() => _AgregarControlScreenState();
}

class _AgregarControlScreenState extends State<AgregarControlScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // Controladores
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
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _sistolicaCtrl.dispose();
    _diastolicaCtrl.dispose();
    _frecuenciaCtrl.dispose();
    _saturacionCtrl.dispose();
    _sintomasCtrl.dispose();
    _diagnosticoCtrl.dispose();
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

    final prov = Provider.of<PacientesProvider>(context, listen: false);
    final ok = await prov.agregarControlCardio(
      token: widget.token,
      pacienteId: widget.paciente.id,
      datosControl: datos,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.teal.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Control registrado correctamente', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (prov.ultimoError ?? '').isNotEmpty
                      ? prov.ultimoError!
                      : 'Error al registrar el control.',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Nuevo Control',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.paciente.nombre,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header informativo
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monitor_heart_outlined, color: Colors.tealAccent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Control Cardiológico',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Paciente: ${widget.paciente.nombre}',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Sección: Presión Arterial ──
                  _SectionLabel(label: 'PRESIÓN ARTERIAL', icon: Icons.favorite_outline),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DarkField(
                          controller: _sistolicaCtrl,
                          label: 'Sistólica',
                          hint: 'ej: 120',
                          suffix: 'mmHg',
                          inputType: TextInputType.number,
                          formatter: FilteringTextInputFormatter.digitsOnly,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            final n = int.tryParse(v);
                            if (n == null || n < 60 || n > 250) return '60–250';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DarkField(
                          controller: _diastolicaCtrl,
                          label: 'Diastólica',
                          hint: 'ej: 80',
                          suffix: 'mmHg',
                          inputType: TextInputType.number,
                          formatter: FilteringTextInputFormatter.digitsOnly,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            final n = int.tryParse(v);
                            if (n == null || n < 30 || n > 150) return '30–150';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Sección: Signos Vitales ──
                  _SectionLabel(label: 'SIGNOS VITALES', icon: Icons.sensors_outlined),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DarkField(
                          controller: _frecuenciaCtrl,
                          label: 'Frec. Cardíaca',
                          hint: 'ej: 72',
                          suffix: 'bpm',
                          inputType: TextInputType.number,
                          formatter: FilteringTextInputFormatter.digitsOnly,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            final n = int.tryParse(v);
                            if (n == null || n < 30 || n > 250) return '30–250';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DarkField(
                          controller: _saturacionCtrl,
                          label: 'Saturación O₂',
                          hint: 'ej: 98',
                          suffix: '%',
                          inputType: TextInputType.number,
                          formatter: FilteringTextInputFormatter.digitsOnly,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            final n = int.tryParse(v);
                            if (n == null || n < 50 || n > 100) return '50–100';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Sección: Síntomas ──
                  _SectionLabel(label: 'SÍNTOMAS', icon: Icons.notes_outlined),
                  const SizedBox(height: 12),
                  _DarkMultilineField(
                    controller: _sintomasCtrl,
                    label: 'Síntomas observados',
                    hint: 'Describe los síntomas o escribe "Ninguno"',
                    maxLines: 3,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── Sección: Diagnóstico ECG ──
                  _SectionLabel(label: 'DIAGNÓSTICO ECG', icon: Icons.monitor_heart_outlined),
                  const SizedBox(height: 12),
                  _DarkField(
                    controller: _diagnosticoCtrl,
                    label: 'Diagnóstico ECG',
                    hint: 'ej: Ritmo sinusal normal',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      return null;
                    },
                  ),

                  const SizedBox(height: 36),

                  // Botón guardar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        disabledBackgroundColor: Colors.teal.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Guardando...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_alt_outlined, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Guardar Control',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Widgets helpers ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.tealAccent, size: 15),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.tealAccent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08), thickness: 1)),
      ],
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? suffix;
  final TextInputType inputType;
  final TextInputFormatter? formatter;
  final String? Function(String?)? validator;

  const _DarkField({
    required this.controller,
    required this.label,
    required this.hint,
    this.suffix,
    this.inputType = TextInputType.text,
    this.formatter,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: formatter != null ? [formatter!] : null,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        suffixStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF161B22),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
      ),
    );
  }
}

class _DarkMultilineField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _DarkMultilineField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 3,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF161B22),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
      ),
    );
  }
}
