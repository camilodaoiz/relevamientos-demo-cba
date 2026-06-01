enum CampoTipo { texto, numerico, seleccion, fecha, booleano }

class CampoEstandar {
  const CampoEstandar({
    required this.id,
    required this.etiqueta,
    required this.tipo,
    this.obligatorio = false,
    this.opciones = const [],
  });

  final String id;
  final String etiqueta;
  final CampoTipo tipo;
  final bool obligatorio;
  final List<String> opciones;
}
