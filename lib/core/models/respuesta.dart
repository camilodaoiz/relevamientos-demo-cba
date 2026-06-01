class Respuesta {
  const Respuesta({
    required this.preguntaId,
    required this.valor,
    this.verificada = false,
  });

  final String preguntaId;
  final Object? valor;
  final bool verificada;
}
