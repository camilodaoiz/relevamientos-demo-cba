import 'campo_estandar.dart';

class Pregunta {
  const Pregunta({
    required this.id,
    required this.texto,
    required this.tipo,
    required this.seccion,
    this.obligatoria = false,
    this.opciones = const [],
    this.esCampoEstandar = false,
    this.autocompletaCidi = false,
    this.soloLectura = false,
    this.condicionCampoId,
    this.condicionValor,
    this.longitudMinima,
    this.longitudMaxima,
    this.valorMinimo,
    this.valorMaximo,
    this.mensajeValidacion,
  });

  final String id;
  final String texto;
  final CampoTipo tipo;
  final String seccion;
  final bool obligatoria;
  final List<String> opciones;
  final bool esCampoEstandar;
  final bool autocompletaCidi;
  final bool soloLectura;
  final String? condicionCampoId;
  final String? condicionValor;
  final int? longitudMinima;
  final int? longitudMaxima;
  final num? valorMinimo;
  final num? valorMaximo;
  final String? mensajeValidacion;

  bool get tieneCondicion => condicionCampoId != null && condicionValor != null;
  bool get tieneValidaciones =>
      longitudMinima != null ||
      longitudMaxima != null ||
      valorMinimo != null ||
      valorMaximo != null;

  Pregunta copyWithCondicion(String? campoId, String? valor) {
    return Pregunta(
      id: id,
      texto: texto,
      tipo: tipo,
      seccion: seccion,
      obligatoria: obligatoria,
      opciones: opciones,
      esCampoEstandar: esCampoEstandar,
      autocompletaCidi: autocompletaCidi,
      soloLectura: soloLectura,
      condicionCampoId: campoId,
      condicionValor: valor,
      longitudMinima: longitudMinima,
      longitudMaxima: longitudMaxima,
      valorMinimo: valorMinimo,
      valorMaximo: valorMaximo,
      mensajeValidacion: mensajeValidacion,
    );
  }

  Pregunta copyWithValidaciones({
    int? longitudMinima,
    int? longitudMaxima,
    num? valorMinimo,
    num? valorMaximo,
    String? mensajeValidacion,
  }) {
    return Pregunta(
      id: id,
      texto: texto,
      tipo: tipo,
      seccion: seccion,
      obligatoria: obligatoria,
      opciones: opciones,
      esCampoEstandar: esCampoEstandar,
      autocompletaCidi: autocompletaCidi,
      soloLectura: soloLectura,
      condicionCampoId: condicionCampoId,
      condicionValor: condicionValor,
      longitudMinima: longitudMinima,
      longitudMaxima: longitudMaxima,
      valorMinimo: valorMinimo,
      valorMaximo: valorMaximo,
      mensajeValidacion: mensajeValidacion,
    );
  }
}
