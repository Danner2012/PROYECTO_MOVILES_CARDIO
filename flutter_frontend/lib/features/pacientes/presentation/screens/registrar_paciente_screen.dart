// lib/features/pacientes/presentation/screens/registrar_paciente_screen.dart
import 'dart:io' show File; // solo para móvil, no se usa en web
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../logic/pacientes_provider.dart';

class RegistrarPacienteScreen extends StatefulWidget {
  final String token;
  const RegistrarPacienteScreen({super.key, required this.token});

  @override
  State<RegistrarPacienteScreen> createState() => _RegistrarPacienteScreenState();
}

class _RegistrarPacienteScreenState extends State<RegistrarPacienteScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _tallaCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  
  String _sexoSeleccionado = 'Masculino';
  bool _isSaving = false;
  File? _imagenSeleccionada; // solo en móvil, en web será null
  Uint8List? _imagenBytes;   // bytes de la imagen
  String? _imagenNombre;
  DateTime? _fechaRegistro;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _teal = Color(0xFF00BFA5);
  static const _bg = Color(0xFF0D1117);
  static const _border = Color(0xFF30363D);
  static const _surface = Color(0xFF161B22);

  @override
  void initState() {
    super.initState();
    _fechaRegistro = DateTime.now();
    _fechaCtrl.text = "${_fechaRegistro!.day}/${_fechaRegistro!.month}/${_fechaRegistro!.year}";

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _edadCtrl.dispose();
    _pesoCtrl.dispose();
    _tallaCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    try {
      final picker = ImagePicker();
      final fuente = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: const Color(0xFF1C2128),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: _teal),
                title: const Text('Tomar Foto', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: _teal),
                title: const Text('Seleccionar de Galería', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (fuente == null) return;

      final archivo = await picker.pickImage(source: fuente, imageQuality: 80);
      if (archivo != null) {
        // Leer bytes para compatibilidad web
        final bytes = await archivo.readAsBytes();
        final nombre = archivo.name;

        setState(() {
          _imagenBytes = bytes;
          _imagenNombre = nombre;
          // Si es móvil, guardamos también el File para la previsualización
          _imagenSeleccionada = File(archivo.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: _teal,
              duration: const Duration(seconds: 2),
              content: Text('Imagen seleccionada: ${nombre.overflowAt(20)}'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error al elegir imagen: $e");
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaRegistro ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _teal,
              onPrimary: Colors.white,
              surface: _surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        _fechaRegistro = fecha;
        _fechaCtrl.text = "${fecha.day}/${fecha.month}/${fecha.year}";
      });
    }
  }

  Future<void> _guardarPaciente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final exito = await Provider.of<PacientesProvider>(context, listen: false)
        .registrarPaciente(
      token: widget.token,
      email: _emailCtrl.text.trim(),
      edad: int.parse(_edadCtrl.text),
      sexo: _sexoSeleccionado,
      peso: double.parse(_pesoCtrl.text),
      talla: double.parse(_tallaCtrl.text),
      fotoBytes: _imagenBytes,
      fotoNombre: _imagenNombre,
      fecha: _fechaCtrl.text, // no se usa en backend
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _teal,
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
      final errorMsg = Provider.of<PacientesProvider>(context, listen: false).ultimoError
          ?? 'Verifica que el email exista y no esté duplicado.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFCF6679),
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
    // Previsualización de imagen: si hay File (móvil) lo usamos, si no hay bytes no mostramos nada
    final tieneImagen = _imagenBytes != null;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nuevo Paciente',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _teal, strokeWidth: 2.5),
                  SizedBox(height: 16),
                  Text('Vinculando paciente y guardando datos...', style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Selector de Imagen de Perfil ─────────────────
                        Center(
                          child: GestureDetector(
                            onTap: _seleccionarImagen,
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: _surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: tieneImagen ? _teal : _border, width: 2),
                                    image: tieneImagen
                                        ? DecorationImage(
                                            image: MemoryImage(_imagenBytes!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: tieneImagen
                                      ? null
                                      : const Icon(Icons.person_rounded, size: 50, color: Colors.white24),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                                    child: Icon(
                                      tieneImagen ? Icons.edit_rounded : Icons.add_a_photo_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        if (tieneImagen) ...[
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'Imagen cargada correctamente',
                              style: TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // ── Sección: Identificación ──────────────────────────
                        const _SectionLabel(label: 'IDENTIFICACIÓN'),
                        const SizedBox(height: 12),

                        _DarkField(
                          controller: _emailCtrl,
                          label: 'Email del usuario',
                          hint: 'correo@ejemplo.com',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Campo requerido';
                            if (!v.contains('@')) return 'Email inválido';
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Campo de Fecha (Tappable)
                        GestureDetector(
                          onTap: _seleccionarFecha,
                          child: AbsorbPointer(
                            child: _DarkField(
                              controller: _fechaCtrl,
                              label: 'Fecha de Registro / Ingreso',
                              hint: 'DD/MM/AAAA',
                              icon: Icons.calendar_today_rounded,
                              keyboardType: TextInputType.datetime,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Sección: Datos clínicos ──────────────────────────
                        const _SectionLabel(label: 'DATOS CLÍNICOS'),
                        const SizedBox(height: 12),

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
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SexoDropdown(
                                value: _sexoSeleccionado,
                                onChanged: (val) => setState(() => _sexoSeleccionado = val!),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _DarkField(
                                controller: _pesoCtrl,
                                label: 'Peso',
                                hint: 'kg',
                                icon: Icons.monitor_weight_outlined,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Requerido';
                                  if (double.tryParse(v) == null) return 'Número inválido';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DarkField(
                                controller: _tallaCtrl,
                                label: 'Talla',
                                hint: 'm',
                                icon: Icons.height_rounded,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Requerido';
                                  final d = double.tryParse(v);
                                  if (d == null) return 'Número inválido';
                                  if (d > 3.0) return 'Usa metros (ej: 1.70)';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _teal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _guardarPaciente,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.link_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Registrar Expediente', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              ],
                            ),
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

extension on String {
  String overflowAt(int fixedLength) => length > fixedLength ? '${substring(0, fixedLength)}...' : this;
}

// ─── Sub-widgets (sin cambios) ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF00BFA5),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  const _DarkField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: const Color(0xFF00BFA5),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white54, size: 18),
        filled: true,
        fillColor: const Color(0xFF161B22),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCF6679)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFCF6679), fontSize: 11),
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
      dropdownColor: const Color(0xFF1C2128),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white54),
      decoration: InputDecoration(
        labelText: 'Sexo',
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: const Icon(Icons.wc_rounded, color: Colors.white54, size: 18),
        filled: true,
        fillColor: const Color(0xFF161B22),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 1.5),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
        DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
        DropdownMenuItem(value: 'Otro', child: Text('Otro')),
      ],
    );
  }
}
