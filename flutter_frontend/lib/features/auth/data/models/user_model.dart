class UserModel {
  final String id;
  final String email;
  final String rol;
  final String nombre;
  final String apellido;
  final String? fechaNacimiento;
  final String? genero;
  final String? telefono;
  final String? direccion;
  final String? foto;

  UserModel({
    required this.id,
    required this.email,
    required this.rol,
    required this.nombre,
    required this.apellido,
    this.fechaNacimiento,
    this.genero,
    this.telefono,
    this.direccion,
    this.foto,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Si viene de la respuesta de login, los datos están planos en 'user'
    // Si viene de /me/, los datos están en 'perfil'
    final perfil = json['perfil'] ?? json;
    
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      rol: json['rol_nombre'] ?? json['rol'] ?? '',
      nombre: perfil['nombre'] ?? '',
      apellido: perfil['apellido'] ?? '',
      fechaNacimiento: perfil['fecha_nacimiento'],
      genero: perfil['genero'],
      telefono: perfil['telefono'],
      direccion: perfil['direccion'],
      foto: perfil['foto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'rol': rol,
      'nombre': nombre,
      'apellido': apellido,
      'fecha_nacimiento': fechaNacimiento,
      'genero': genero,
      'telefono': telefono,
      'direccion': direccion,
      'foto': foto,
    };
  }
}
