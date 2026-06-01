class Usuario {
  const Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rolId,
    required this.rolNombre,
    required this.organismo,
    required this.estado,
  });

  final String id;
  final String email;
  final String nombre;
  final String rolId;
  final String rolNombre;
  final String organismo;
  final String estado;

  Usuario copyWith({
    String? email,
    String? nombre,
    String? rolId,
    String? rolNombre,
    String? organismo,
    String? estado,
  }) {
    return Usuario(
      id: id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rolId: rolId ?? this.rolId,
      rolNombre: rolNombre ?? this.rolNombre,
      organismo: organismo ?? this.organismo,
      estado: estado ?? this.estado,
    );
  }
}
