import 'pregunta.dart';

enum EncuestaEstado { borrador, enRevision, aprobada, publicada, rechazada }

extension EncuestaEstadoLabel on EncuestaEstado {
  String get label {
    switch (this) {
      case EncuestaEstado.borrador:
        return 'Borrador';
      case EncuestaEstado.enRevision:
        return 'En revision';
      case EncuestaEstado.aprobada:
        return 'Aprobada';
      case EncuestaEstado.publicada:
        return 'Publicada';
      case EncuestaEstado.rechazada:
        return 'Rechazada';
    }
  }
}

class Encuesta {
  const Encuesta({
    required this.id,
    required this.nombre,
    required this.organismo,
    required this.version,
    required this.estado,
    required this.secciones,
    required this.preguntas,
  });

  final String id;
  final String nombre;
  final String organismo;
  final int version;
  final EncuestaEstado estado;
  final List<String> secciones;
  final List<Pregunta> preguntas;

  Encuesta copyWith({
    EncuestaEstado? estado,
    List<String>? secciones,
    List<Pregunta>? preguntas,
    int? version,
  }) {
    return Encuesta(
      id: id,
      nombre: nombre,
      organismo: organismo,
      version: version ?? this.version,
      estado: estado ?? this.estado,
      secciones: secciones ?? this.secciones,
      preguntas: preguntas ?? this.preguntas,
    );
  }
}
