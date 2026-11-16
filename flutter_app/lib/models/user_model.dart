class UserModel {
  final int id;
  final String nombre;
  final String usuario;
  final String rol;
  final bool activo;

  UserModel({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.rol,
    this.activo = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      usuario: json['usuario'] as String? ?? '',
      rol: json['rol'] as String? ?? 'staff',
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'usuario': usuario,
        'rol': rol,
        'activo': activo,
      };
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final UserModel usuario;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.usuario,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      usuario: UserModel.fromJson(json['usuario'] as Map<String, dynamic>),
    );
  }
}
