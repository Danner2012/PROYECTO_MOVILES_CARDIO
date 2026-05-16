import 'dart:io';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_frontend/features/auth/logic/auth_provider.dart';
import 'package:flutter_frontend/features/dashboard/presentation/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _telefonoController;
  late TextEditingController _direccionController;
  
  String? _genero;
  XFile? _pickedFile; // Usamos XFile en lugar de File para compatibilidad web
  Uint8List? _webImage; // Para previsualización en web
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    print('DEBUG: Inicializando perfil con datos: ${user?.toJson()}');
    _nombreController = TextEditingController(text: user?.nombre ?? '');
    _apellidoController = TextEditingController(text: user?.apellido ?? '');
    _telefonoController = TextEditingController(text: user?.telefono ?? '');
    _direccionController = TextEditingController(text: user?.direccion ?? '');
    _currentImageUrl = user?.foto;
    _genero = (user?.genero != null && user!.genero!.isNotEmpty) ? user.genero : null;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? selected = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      
      if (selected != null) {
        if (kIsWeb) {
          final bytes = await selected.readAsBytes();
          setState(() {
            _webImage = bytes;
            _pickedFile = selected;
          });
        } else {
          setState(() {
            _pickedFile = selected;
          });
        }
      }
    } catch (e) {
      print('DEBUG: Error al seleccionar imagen: $e');
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      
      final Map<String, String> data = {
        'nombre': _nombreController.text,
        'apellido': _apellidoController.text,
        'telefono': _telefonoController.text,
        'direccion': _direccionController.text,
        'genero': _genero ?? '',
      };

      List<int>? bytes;
      if (_pickedFile != null) {
        bytes = await _pickedFile!.readAsBytes();
      }

      final success = await authProvider.updateProfile(
        data, 
        imagePath: kIsWeb ? null : _pickedFile?.path,
        imageBytes: kIsWeb ? bytes : null,
        fileName: _pickedFile?.name
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el perfil'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: secondaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(60),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: secondaryColor,
                          backgroundImage: _getProfileImage(),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: primaryColor,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: _pickImage,
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: defaultPadding),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: "Nombre"),
                  validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                ),
                SizedBox(height: defaultPadding),
                TextFormField(
                  controller: _apellidoController,
                  decoration: const InputDecoration(labelText: "Apellido"),
                  validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                ),
                SizedBox(height: defaultPadding),
                DropdownButtonFormField<String>(
                  value: _genero,
                  decoration: const InputDecoration(labelText: "Género"),
                  items: ["Masculino", "Femenino", "Otro"]
                      .map((label) => DropdownMenuItem(
                            child: Text(label),
                            value: label,
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _genero = value),
                ),
                SizedBox(height: defaultPadding),
                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(labelText: "Teléfono"),
                ),
                SizedBox(height: defaultPadding),
                TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(labelText: "Dirección"),
                  maxLines: 2,
                ),
                SizedBox(height: defaultPadding * 2),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: primaryColor,
                  ),
                  child: const Text("Guardar Cambios"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider _getProfileImage() {
    if (kIsWeb && _webImage != null) {
      return MemoryImage(_webImage!);
    } else if (!kIsWeb && _pickedFile != null) {
      return FileImage(File(_pickedFile!.path));
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return NetworkImage("http://localhost:8000$_currentImageUrl");
    }
    return const AssetImage("assets/images/profile_pic.png");
  }
}
