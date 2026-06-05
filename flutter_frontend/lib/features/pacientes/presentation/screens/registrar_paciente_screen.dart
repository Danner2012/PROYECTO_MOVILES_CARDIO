// lib/features/pacientes/presentation/screens/registrar_paciente_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../dashboard/presentation/constants.dart';
import '../../logic/pacientes_provider.dart';

class RegistrarPacienteScreen extends StatefulWidget {
  final String token;
  const RegistrarPacienteScreen({super.key, required this.token});

  @override
  State<RegistrarPacienteScreen> createState() => _RegistrarPacienteScreenState();
}

class _RegistrarPacienteScreenState extends State<RegistrarPacienteScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Controlador capturado desde el Autocomplete
  TextEditingController? _emailTextCtrl;
  
  final _edadCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _tallaCtrl = TextEditingController();
  String _sexoSeleccionado = 'Masculino';
  bool _isSaving = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // TODO: Esta lista debería ser cargada desde el Backend/Provider con los usuarios disponibles
  final List<String> _correosDisponibles = [
    'paciente@cardio.com',
    'juan.perez@cardio.com',
    'maria.lopez@cardio.com',
    'carlos.m@cardio.com',
    'ana.gomez@cardio.com'
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _edadCtrl.dispose();
    _pesoCtrl.dispose();
    _tallaCtrl.dispose();
    // No hacemos dispose de _emailTextCtrl porque el widget Autocomplete lo maneja internamente
    super.dispose();
  }

  Future<void> _guardarPaciente() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Verificamos que se haya escrito o seleccionado un correo
    if (_emailTextCtrl == null || _emailTextCtrl!.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes seleccionar o escribir un correo válido')));
       return;
    }

    setState(() => _isSaving = true);

    final exito = await Provider.of<PacientesProvider>(context, listen: false).registrarPaciente(
      token: widget.token,
      email: _emailTextCtrl!.text.trim(),
      edad: int.parse(_edadCtrl.text),
      sexo: _sexoSeleccionado,
      peso: double.parse(_pesoCtrl.text),
      talla: double.parse(_tallaCtrl.text),
    );

    setState(() => _isSaving = false);
    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Paciente vinculado exitosamente.', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      final errorMsg = Provider.of<PacientesProvider>(context, listen: false).ultimoError ?? 'Verifica que el email exista y no esté duplicado.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMsg, style: const TextStyle(color: Colors.white))),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Nuevo Paciente', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _isSaving
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
                  const SizedBox(height: defaultPadding),
                  Text('Vinculando paciente...', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card
                        Container(
                          padding: const EdgeInsets.all(defaultPadding),
                          decoration: BoxDecoration(
                            color: secondaryColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: primaryColor.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.person_add_alt_1_rounded, color: primaryColor, size: 28),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Vincular expediente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    SizedBox(height: 4),
                                    Text('El usuario debe estar registrado en el sistema.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: defaultPadding * 1.5),

                        const _SectionLabel(label: 'IDENTIFICACIÓN'),
                        const SizedBox(height: defaultPadding),
                        
                        // ─── CAMPO CON AUTOCOMPLETADO Y DESPLEGABLE ───
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Autocomplete<String>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return _correosDisponibles;
                                }
                                return _correosDisponibles.where((String option) {
                                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                });
                              },
                              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                // Guardamos la referencia del controlador para poder sacar el texto al guardar
                                _emailTextCtrl = textEditingController; 
                                
                                return _DarkField(
                                  controller: textEditingController,
                                  focusNode: focusNode, // Pasamos el foco
                                  label: 'Email del usuario',
                                  hint: 'Buscar o escribir correo...',
                                  icon: Icons.search_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Campo requerido';
                                    if (!v.contains('@')) return 'Email inválido';
                                    return null;
                                  },
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      width: constraints.maxWidth, // Mismo ancho que el campo de texto
                                      margin: const EdgeInsets.only(top: 5),
                                      clipBehavior: Clip.hardEdge,
                                      decoration: BoxDecoration(
                                        color: secondaryColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: primaryColor.withOpacity(0.5)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          )
                                        ]
                                      ),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          final String option = options.elementAt(index);
                                          return InkWell(
                                            onTap: () => onSelected(option),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              decoration: BoxDecoration(
                                                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.person_outline, color: primaryColor, size: 18),
                                                  const SizedBox(width: 10),
                                                  Text(option, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        ),
                        // ──────────────────────────────────────────────

                        const SizedBox(height: defaultPadding * 1.5),

                        const _SectionLabel(label: 'DATOS CLÍNICOS'),
                        const SizedBox(height: defaultPadding),
                        Row(
                          children: [
                            Expanded(
                              child: _DarkField(
                                controller: _edadCtrl,
                                label: 'Edad',
                                hint: 'años',
                                icon: Icons.cake_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                              ),
                            ),
                            const SizedBox(width: defaultPadding),
                            Expanded(
                              child: _SexoDropdown(
                                value: _sexoSeleccionado,
                                onChanged: (val) => setState(() => _sexoSeleccionado = val!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: defaultPadding),
                        Row(
                          children: [
                            Expanded(
                              child: _DarkField(
                                controller: _pesoCtrl,
                                label: 'Peso',
                                hint: 'kg',
                                icon: Icons.monitor_weight_outlined,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                              ),
                            ),
                            const SizedBox(width: defaultPadding),
                            Expanded(
                              child: _DarkField(
                                controller: _tallaCtrl,
                                label: 'Talla',
                                hint: 'm',
                                icon: Icons.height_rounded,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: defaultPadding * 2),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _guardarPaciente,
                            icon: const Icon(Icons.link_rounded, color: Colors.white),
                            label: const Text('Registrar Expediente', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

// Helpers
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2));
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode; // <--- Nuevo parámetro añadido
  final String label, hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _DarkField({required this.controller, this.focusNode, required this.label, required this.hint, required this.icon, required this.keyboardType, this.validator, this.inputFormatters});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode, // <--- Conectado aquí
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        filled: true, fillColor: secondaryColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}

class _SexoDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _SexoDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      dropdownColor: bgColor,
      icon: const Icon(Icons.expand_more_rounded, color: Colors.white38),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Sexo', prefixIcon: const Icon(Icons.wc_rounded, color: Colors.white38, size: 18),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        filled: true, fillColor: secondaryColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
      ),
      items: ['Masculino', 'Femenino', 'Otro'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
    );
  }
}