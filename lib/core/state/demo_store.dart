import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../firebase/firebase_bootstrap.dart';
import '../firebase/firebase_demo_repository.dart';
import '../mock/mock_data.dart';
import '../models/area_operativa.dart';
import '../models/campo_estandar.dart';
import '../models/encuesta.dart';
import '../models/pregunta.dart';
import '../models/tarea.dart';
import '../models/usuario.dart';

// Relevamiento individual dentro de una tarea (para múltiples por tarea).
class RelevamientoLocal {
  RelevamientoLocal({
    required this.id,
    required this.numero,
    this.completado = false,
  });
  final String id;
  final int numero;
  bool completado;
}

// RF-012: notificaciones in-app de transición de estado.
class NotificacionApp {
  NotificacionApp({
    required this.id,
    required this.timestamp,
    required this.titulo,
    required this.cuerpo,
    required this.rolDestinatario,
  });
  final String id;
  final String timestamp;
  final String titulo;
  final String cuerpo;
  final String rolDestinatario;
  bool leida = false;
}

class AuditEntry {
  AuditEntry({
    required this.timestamp,
    required this.email,
    required this.rolId,
    required this.accion,
    required this.entidad,
    required this.detalle,
    this.organismo = 'Ministerio de Salud Pública - Córdoba',
    this.valorAnterior,
    this.valorNuevo,
  });
  final String timestamp;
  final String email;
  final String rolId;
  final String accion;
  final String entidad;
  final String detalle;
  final String organismo;
  final String? valorAnterior;
  final String? valorNuevo;
}

// RF-006: historial visible de versiones publicadas de una encuesta.
class EncuestaVersionEntry {
  const EncuestaVersionEntry({
    required this.encuestaId,
    required this.version,
    required this.fecha,
    required this.autor,
    required this.resumen,
  });
  final String encuestaId;
  final int version;
  final String fecha;
  final String autor;
  final String resumen;
}

// RF-013: observaciones del Validador asociadas a secciones o preguntas.
class ComentarioEncuesta {
  ComentarioEncuesta({
    required this.id,
    required this.encuestaId,
    required this.objetivoId,
    required this.objetivoLabel,
    required this.autor,
    required this.fecha,
    required this.mensaje,
    this.resuelto = false,
    List<String>? respuestas,
  }) : respuestas = respuestas ?? [];

  final String id;
  final String encuestaId;
  final String objetivoId;
  final String objetivoLabel;
  final String autor;
  final String fecha;
  final String mensaje;
  final List<String> respuestas;
  bool resuelto;
}

final demoStoreProvider = ChangeNotifierProvider<DemoStore>((ref) {
  return DemoStore();
});

class DemoStore extends ChangeNotifier {
  DemoStore()
    : _encuestas = [],
      _tareas = [],
      _currentUser = MockData.usuarios.first;

  bool _loaded = false;
  bool get loaded => _loaded;

  final List<CampoEstandar> camposEstandar = MockData.camposEstandar;
  final List<Usuario> usuarios = MockData.usuarios.toList();
  final List<AreaOperativa> areas = MockData.areasOperativas;
  String _modoPreguntas = 'libre'; // RF-009: libre / restringido / bloqueado
  final List<NotificacionApp> _notificaciones = []; // RF-012
  final Map<String, List<RelevamientoLocal>> _relevamientosMap = {}; // multi-relevamiento
  final Map<String, Set<String>> _evidenciasPorEncuesta = {
    'enc-borrador': {'Foto', 'GPS', 'Firma'},
  };
  final Map<String, Set<String>> _destinatariosPorEncuesta = {
    'enc-borrador': {'Coordinador de Campo'},
  };
  final Set<String> _camposObligatorios = {
    for (final c in MockData.camposEstandar)
      if (c.obligatorio) c.id,
  };
  final List<AuditEntry> _auditLog = [
    AuditEntry(
      timestamp: '29/05/2026 11:15',
      email: 'disenador@demo.com',
      rolId: 'R-03',
      accion: 'ENVIAR_REVISION',
      entidad: 'enc-salud-2026',
      detalle: 'Encuesta enviada a revisión',
    ),
    AuditEntry(
      timestamp: '29/05/2026 10:02',
      email: 'validador@demo.com',
      rolId: 'R-04',
      accion: 'APROBAR',
      entidad: 'enc-salud-2026',
      detalle: 'Encuesta aprobada',
    ),
    AuditEntry(
      timestamp: '28/05/2026 17:45',
      email: 'orgadmin@demo.com',
      rolId: 'R-02',
      accion: 'PUBLICAR',
      entidad: 'enc-salud-2026',
      detalle: 'Encuesta publicada v3',
    ),
    AuditEntry(
      timestamp: '28/05/2026 14:30',
      email: 'coordinador@demo.com',
      rolId: 'R-05',
      accion: 'CREAR_TAREA',
      entidad: 't-008',
      detalle: 'Asignada a inspector@demo.com',
    ),
    AuditEntry(
      timestamp: '28/05/2026 14:28',
      email: 'coordinador@demo.com',
      rolId: 'R-05',
      accion: 'CREAR_TAREA',
      entidad: 't-007',
      detalle: 'Asignada a inspector@demo.com',
    ),
    AuditEntry(
      timestamp: '27/05/2026 18:10',
      email: 'inspector@demo.com',
      rolId: 'R-06',
      accion: 'SINCRONIZAR',
      entidad: 't-006',
      detalle: 'Relevamiento sincronizado — Firebase',
    ),
    AuditEntry(
      timestamp: '27/05/2026 17:55',
      email: 'inspector@demo.com',
      rolId: 'R-06',
      accion: 'COMPLETAR',
      entidad: 't-006',
      detalle: 'Posta San Vicente — completada',
    ),
    AuditEntry(
      timestamp: '27/05/2026 09:20',
      email: 'inspector@demo.com',
      rolId: 'R-06',
      accion: 'INICIAR',
      entidad: 't-006',
      detalle: 'Relevamiento iniciado',
    ),
    AuditEntry(
      timestamp: '26/05/2026 16:33',
      email: 'disenador@demo.com',
      rolId: 'R-03',
      accion: 'CREAR_ENCUESTA',
      entidad: 'enc-borrador',
      detalle: 'Nueva encuesta en borrador',
    ),
    AuditEntry(
      timestamp: '26/05/2026 11:05',
      email: 'admin@demo.com',
      rolId: 'R-01',
      accion: 'CREAR_CAMPO',
      entidad: 'cuil',
      detalle: 'Campo CUIL agregado al catálogo RF-007',
    ),
    AuditEntry(
      timestamp: '25/05/2026 10:30',
      email: 'admin@demo.com',
      rolId: 'R-01',
      accion: 'ALTA_ORGANISMO',
      entidad: 'org-salud',
      detalle: 'Ministerio de Salud Pública registrado',
    ),
    AuditEntry(
      timestamp: '25/05/2026 10:15',
      email: 'admin@demo.com',
      rolId: 'R-01',
      accion: 'ALTA_USUARIO',
      entidad: 'u-inspector',
      detalle: 'Inspector de Campo dado de alta',
    ),
  ];
  final List<EncuestaVersionEntry> _versiones = [
    const EncuestaVersionEntry(
      encuestaId: 'enc-salud-2026',
      version: 3,
      fecha: '28/05/2026 17:45',
      autor: 'orgadmin@demo.com',
      resumen: 'Publicada para el operativo 2026',
    ),
    const EncuestaVersionEntry(
      encuestaId: 'enc-salud-2026',
      version: 2,
      fecha: '20/05/2026 12:10',
      autor: 'orgadmin@demo.com',
      resumen: 'Ajuste de condiciones edilicias',
    ),
    const EncuestaVersionEntry(
      encuestaId: 'enc-salud-2026',
      version: 1,
      fecha: '08/05/2026 09:35',
      autor: 'orgadmin@demo.com',
      resumen: 'Primera publicación',
    ),
  ];
  final List<ComentarioEncuesta> _comentarios = [
    ComentarioEncuesta(
      id: 'com-001',
      encuestaId: 'enc-revision',
      objetivoId: 'p-domicilio',
      objetivoLabel: 'Pregunta: Domicilio del establecimiento',
      autor: 'validador@demo.com',
      fecha: '29/05/2026 09:40',
      mensaje: 'Confirmar si el domicilio debe incluir barrio y localidad.',
    ),
  ];
  final organismo = MockData.organismo;
  List<Encuesta> _encuestas;
  List<Tarea> _tareas;
  Usuario _currentUser;
  int _syncedDemoRelevamientos = 0;
  bool _offlineMode = false;
  bool _tareasCsvImportadas = false;

  Usuario get currentUser => _currentUser;
  List<Encuesta> get encuestas => List.unmodifiable(_encuestas);
  List<Tarea> get tareas => List.unmodifiable(_tareas);
  Set<String> get camposObligatorios => Set.unmodifiable(_camposObligatorios);
  List<AuditEntry> get auditLog => List.unmodifiable(_auditLog);
  List<EncuestaVersionEntry> versionesDe(String encuestaId) =>
      _versiones.where((version) => version.encuestaId == encuestaId).toList();
  List<ComentarioEncuesta> comentariosDe(String encuestaId) => _comentarios
      .where((comentario) => comentario.encuestaId == encuestaId)
      .toList();

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (!FirebaseBootstrap.initialized) {
      _encuestas = MockData.createEncuestas();
      _tareas = MockData.createTareas();
      _loaded = true;
      notifyListeners();
      return;
    }

    try {
      var encuestas = await FirebaseDemoRepository.getEncuestas();
      var tareas = await FirebaseDemoRepository.getTareas();

      if (encuestas.isEmpty) {
        encuestas = MockData.createEncuestas();
        tareas = MockData.createTareas();
        await FirebaseDemoRepository.seedDemoData(
          encuestas: encuestas,
          tareas: tareas,
        );
      }

      _encuestas = encuestas;
      _tareas = tareas;
    } catch (e) {
      _encuestas = MockData.createEncuestas();
      _tareas = MockData.createTareas();
    }

    _loaded = true;
    notifyListeners();
  }

  // ─── Internal helpers ─────────────────────────────────────────────────────

  void _notify(String titulo, String cuerpo, String rolDestinatario) {
    final now = DateTime.now();
    final ts =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _notificaciones.insert(
      0,
      NotificacionApp(
        id: 'notif-${now.millisecondsSinceEpoch}',
        timestamp: ts,
        titulo: titulo,
        cuerpo: cuerpo,
        rolDestinatario: rolDestinatario,
      ),
    );
  }

  void marcarNotificacionLeida(String id) {
    for (final n in _notificaciones) {
      if (n.id == id) n.leida = true;
    }
    notifyListeners();
  }

  void marcarTodasLeidas() {
    for (final n in _notificaciones) {
      n.leida = true;
    }
    notifyListeners();
  }

  void setModoPreguntas(String modo) {
    final prev = _modoPreguntas;
    _modoPreguntas = modo;
    _log('MODO_PREGUNTAS', 'organismo', 'Modo → $modo',
        valorAnterior: prev, valorNuevo: modo);
    notifyListeners();
  }

  // ─── Multi-relevamiento por tarea ────────────────────────────────────────────

  List<RelevamientoLocal> relevamientosForTask(String taskId) =>
      List.unmodifiable(_relevamientosMap[taskId] ?? []);

  String addRelevamiento(String taskId) {
    final list = _relevamientosMap.putIfAbsent(taskId, () => []);
    final numero = list.length + 1;
    final id = 'rel-$taskId-$numero';
    list.add(RelevamientoLocal(id: id, numero: numero));
    // Transicionar la tarea a enCurso si está pendiente
    _tareas = [
      for (final t in _tareas)
        if (t.id == taskId && t.estado == TareaEstado.pendiente)
          t.copyWith(estado: TareaEstado.enCurso)
        else
          t,
    ];
    _log('INICIAR', taskId, 'Relevamiento #$numero iniciado en campo');
    _persistTarea(taskId);
    notifyListeners();
    return id;
  }

  void completeRelevamiento(String taskId, String relId) {
    final list = _relevamientosMap[taskId] ?? [];
    for (final r in list) {
      if (r.id == relId) r.completado = true;
    }
    notifyListeners();
  }

  void _log(
    String accion,
    String entidad,
    String detalle, {
    String? valorAnterior,
    String? valorNuevo,
  }) {
    final now = DateTime.now();
    final ts =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _auditLog.insert(
      0,
      AuditEntry(
        timestamp: ts,
        email: _currentUser.email,
        rolId: _currentUser.rolId,
        accion: accion,
        entidad: entidad,
        detalle: detalle,
        valorAnterior: valorAnterior,
        valorNuevo: valorNuevo,
      ),
    );
  }

  void _persistEncuesta(String id) {
    final enc = _encuestas.where((e) => e.id == id).firstOrNull;
    if (enc != null) unawaited(FirebaseDemoRepository.writeEncuesta(enc));
  }

  void _persistTarea(String id) {
    final t = _tareas.where((t) => t.id == id).firstOrNull;
    if (t != null) unawaited(FirebaseDemoRepository.writeTarea(t));
  }

  // ─── Queries ──────────────────────────────────────────────────────────────

  bool isCampoObligatorio(String id) => _camposObligatorios.contains(id);
  int get syncedDemoRelevamientos => _syncedDemoRelevamientos;
  bool get offlineMode => _offlineMode;
  String get modoPreguntas => _modoPreguntas;
  List<NotificacionApp> get notificaciones =>
      List.unmodifiable(_notificaciones);
  int get notificacionesNoLeidas =>
      _notificaciones.where((n) => !n.leida).length;

  int get pendientes =>
      _tareas.where((t) => t.estado == TareaEstado.pendiente).length;
  int get enCurso =>
      _tareas.where((t) => t.estado == TareaEstado.enCurso).length;
  int get finalizadas =>
      _tareas.where((t) => t.estado == TareaEstado.finalizada).length;
  int get publicadas =>
      _encuestas.where((e) => e.estado == EncuestaEstado.publicada).length;

  List<Tarea> get inspectorTasks {
    return _tareas.where((t) => t.asignadoA == _currentUser.email).toList();
  }

  Encuesta? encuestaById(String id) {
    for (final encuesta in _encuestas) {
      if (encuesta.id == id) return encuesta;
    }
    return null;
  }

  Tarea? tareaById(String id) {
    for (final tarea in _tareas) {
      if (tarea.id == id) return tarea;
    }
    return null;
  }

  AreaOperativa? areaForTask(Tarea tarea) {
    final explicit = areas.where((area) => area.id == tarea.areaId).firstOrNull;
    return explicit ??
        areas.where((area) => area.inspector == tarea.asignadoA).firstOrNull;
  }

  Set<String> evidenciasDe(String encuestaId) =>
      Set.unmodifiable(_evidenciasPorEncuesta[encuestaId] ?? const {});

  Set<String> destinatariosDe(String encuestaId) =>
      Set.unmodifiable(_destinatariosPorEncuesta[encuestaId] ?? const {});

  // ─── Mutations ────────────────────────────────────────────────────────────

  void selectUser(Usuario usuario) {
    _currentUser = usuario;
    notifyListeners();
  }

  Usuario? authenticateDemo(String email, String password) {
    if (password != '123') return null;
    for (final usuario in usuarios) {
      if (usuario.email == email && usuario.estado == 'Activo') {
        selectUser(usuario);
        _log('LOGIN', usuario.id, 'Acceso demo RBAC');
        return usuario;
      }
    }
    return null;
  }

  void toggleOfflineMode() {
    _offlineMode = !_offlineMode;
    notifyListeners();
  }

  // RF-030/RF-034: trazabilidad de consulta CiDi mock, incluso sin conexión.
  void registerCidiLookup(String identifier, {required bool verified}) {
    _log(
      'CONSULTA_CIDI',
      identifier,
      verified
          ? 'CUIL verificado mediante CiDi mock'
          : 'Sin conexión: carga manual no verificada',
    );
    notifyListeners();
  }

  void toggleCampoObligatorio(String id) {
    if (_camposObligatorios.contains(id)) {
      _camposObligatorios.remove(id);
    } else {
      _camposObligatorios.add(id);
    }
    notifyListeners();
  }

  void transitionEncuesta(String encuestaId, EncuestaEstado next) {
    final prev = encuestaById(encuestaId)?.estado;
    _encuestas = [
      for (final encuesta in _encuestas)
        if (encuesta.id == encuestaId)
          encuesta.copyWith(
            estado: next,
            version: next == EncuestaEstado.publicada
                ? encuesta.version + 1
                : encuesta.version,
          )
        else
          encuesta,
    ];
    final accion = switch (next) {
      EncuestaEstado.enRevision => 'ENVIAR_REVISION',
      EncuestaEstado.aprobada => 'APROBAR',
      EncuestaEstado.publicada => 'PUBLICAR',
      EncuestaEstado.rechazada => 'RECHAZAR',
      EncuestaEstado.borrador => 'VOLVER_BORRADOR',
    };
    _log(
      accion,
      encuestaId,
      'Estado → ${next.label}',
      valorAnterior: prev?.label,
      valorNuevo: next.label,
    );
    // RF-012: notificación de transición
    switch (next) {
      case EncuestaEstado.enRevision:
        _notify(
          'Encuesta enviada a revisión',
          'Requiere aprobación del Validador.',
          'R-04',
        );
      case EncuestaEstado.aprobada:
        _notify(
          'Encuesta aprobada',
          'Lista para publicar por el Administrador de Organismo.',
          'R-02',
        );
      case EncuestaEstado.rechazada:
        _notify(
          'Encuesta rechazada',
          'El Validador la devolvió al Diseñador.',
          'R-03',
        );
      case EncuestaEstado.publicada:
        _notify(
          'Encuesta publicada',
          'Ya puede asignarse a tareas de campo.',
          'R-05',
        );
      default:
        break;
    }
    if (next == EncuestaEstado.publicada) {
      final encuesta = encuestaById(encuestaId);
      if (encuesta != null) {
        _versiones.insert(
          0,
          EncuestaVersionEntry(
            encuestaId: encuesta.id,
            version: encuesta.version,
            fecha: _now(),
            autor: _currentUser.email,
            resumen:
                'Publicación inmutable con ${encuesta.preguntas.length} preguntas',
          ),
        );
      }
    }
    _persistEncuesta(encuestaId);
    notifyListeners();
  }

  String _now() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // RF-013: observaciones y respuestas de la revisión.
  void addComentarioEncuesta({
    required String encuestaId,
    required String objetivoId,
    required String objetivoLabel,
    required String mensaje,
  }) {
    final id = 'com-${DateTime.now().millisecondsSinceEpoch}';
    _comentarios.insert(
      0,
      ComentarioEncuesta(
        id: id,
        encuestaId: encuestaId,
        objetivoId: objetivoId,
        objetivoLabel: objetivoLabel,
        autor: _currentUser.email,
        fecha: _now(),
        mensaje: mensaje,
      ),
    );
    _log('COMENTAR_ENCUESTA', encuestaId, '$objetivoLabel · $mensaje');
    notifyListeners();
  }

  void responderComentario(String comentarioId, String respuesta) {
    final comentario = _comentarios
        .where((c) => c.id == comentarioId)
        .firstOrNull;
    if (comentario == null) return;
    comentario.respuestas.add('${_currentUser.email}: $respuesta');
    _log(
      'RESPONDER_COMENTARIO',
      comentario.encuestaId,
      comentario.objetivoLabel,
    );
    notifyListeners();
  }

  void resolverComentario(String comentarioId) {
    final comentario = _comentarios
        .where((c) => c.id == comentarioId)
        .firstOrNull;
    if (comentario == null) return;
    comentario.resuelto = true;
    _log(
      'RESOLVER_COMENTARIO',
      comentario.encuestaId,
      comentario.objetivoLabel,
    );
    notifyListeners();
  }

  // RF-004: lógica condicional en preguntas.
  void updatePreguntaCondicion(
    String encuestaId,
    String preguntaId,
    String? campoId,
    String? valor,
  ) {
    _encuestas = [
      for (final encuesta in _encuestas)
        if (encuesta.id == encuestaId)
          encuesta.copyWith(
            preguntas: encuesta.preguntas
                .map(
                  (p) => p.id == preguntaId
                      ? p.copyWithCondicion(campoId, valor)
                      : p,
                )
                .toList(),
          )
        else
          encuesta,
    ];
    _persistEncuesta(encuestaId);
    notifyListeners();
  }

  // RF-003: validaciones de calidad configuradas por campo.
  void updatePreguntaValidaciones(
    String encuestaId,
    String preguntaId, {
    int? longitudMinima,
    int? longitudMaxima,
    num? valorMinimo,
    num? valorMaximo,
    String? mensajeValidacion,
  }) {
    _encuestas = [
      for (final encuesta in _encuestas)
        if (encuesta.id == encuestaId)
          encuesta.copyWith(
            preguntas: encuesta.preguntas
                .map(
                  (pregunta) => pregunta.id == preguntaId
                      ? pregunta.copyWithValidaciones(
                          longitudMinima: longitudMinima,
                          longitudMaxima: longitudMaxima,
                          valorMinimo: valorMinimo,
                          valorMaximo: valorMaximo,
                          mensajeValidacion: mensajeValidacion,
                        )
                      : pregunta,
                )
                .toList(),
          )
        else
          encuesta,
    ];
    _log(
      'VALIDAR_CAMPO',
      encuestaId,
      'Validaciones configuradas en $preguntaId',
    );
    _persistEncuesta(encuestaId);
    notifyListeners();
  }

  // RF-014/RF-015: ABM mock de usuarios y roles.
  void createUsuario({
    required String nombre,
    required String email,
    required String rolId,
    required String rolNombre,
    required String organismo,
  }) {
    final id = 'u-${DateTime.now().millisecondsSinceEpoch}';
    usuarios.add(
      Usuario(
        id: id,
        email: email,
        nombre: nombre,
        rolId: rolId,
        rolNombre: rolNombre,
        organismo: organismo,
        estado: 'Activo',
      ),
    );
    _log('ALTA_USUARIO', id, '$email · $rolId');
    notifyListeners();
  }

  void updateUsuario(
    String id, {
    required String nombre,
    required String email,
    required String rolId,
    required String rolNombre,
    required String organismo,
  }) {
    final index = usuarios.indexWhere((usuario) => usuario.id == id);
    if (index == -1) return;
    usuarios[index] = usuarios[index].copyWith(
      nombre: nombre,
      email: email,
      rolId: rolId,
      rolNombre: rolNombre,
      organismo: organismo,
    );
    _log('MODIFICAR_USUARIO', id, '$email · $rolId');
    notifyListeners();
  }

  void toggleUsuarioEstado(String id) {
    final index = usuarios.indexWhere((usuario) => usuario.id == id);
    if (index == -1) return;
    final estado = usuarios[index].estado == 'Activo' ? 'Inactivo' : 'Activo';
    usuarios[index] = usuarios[index].copyWith(estado: estado);
    _log('CAMBIAR_ESTADO_USUARIO', id, estado);
    notifyListeners();
  }

  void importUsuariosCsvMock() {
    if (usuarios.any((usuario) => usuario.email == 'inspector3@demo.com')) {
      return;
    }
    createUsuario(
      nombre: 'Nicolas Aguirre',
      email: 'inspector3@demo.com',
      rolId: 'R-06',
      rolNombre: 'Inspector de Campo',
      organismo: organismo.nombre,
    );
    _log('IMPORTAR_USUARIOS', 'usuarios', '1 alta importada desde CSV mock');
  }

  // RF-038: toda exportación mock deja trazabilidad en auditoría.
  void registerExport(String formato, int registros) {
    _log(
      'EXPORTAR_DATOS',
      'tablero-analista',
      '$formato · $registros registros',
    );
  }

  void addCatalogFieldToSurvey(
    String encuestaId,
    CampoEstandar campo, {
    String section = 'Datos del responsable',
  }) {
    final pregunta = Pregunta(
      id: 'p-${campo.id}-${DateTime.now().millisecondsSinceEpoch}',
      texto: campo.etiqueta,
      tipo: campo.tipo,
      seccion: section,
      obligatoria: campo.obligatorio,
      opciones: campo.opciones,
      esCampoEstandar: true,
      autocompletaCidi: campo.id == 'cuil',
    );

    _encuestas = [
      for (final encuesta in _encuestas)
        if (encuesta.id == encuestaId)
          encuesta.copyWith(preguntas: [...encuesta.preguntas, pregunta])
        else
          encuesta,
    ];
    _persistEncuesta(encuestaId);
    notifyListeners();
  }

  void addQuestionToSurvey(String encuestaId, Pregunta pregunta) {
    _encuestas = [
      for (final encuesta in _encuestas)
        if (encuesta.id == encuestaId)
          encuesta.copyWith(preguntas: [...encuesta.preguntas, pregunta])
        else
          encuesta,
    ];
    _persistEncuesta(encuestaId);
    notifyListeners();
  }

  // RF-002: secciones configurables del formulario.
  void addSectionToSurvey(String encuestaId, String section) {
    final normalized = section.trim();
    if (normalized.isEmpty) return;
    _encuestas = [
      for (final encuesta in _encuestas)
        if (encuesta.id == encuestaId &&
            !encuesta.secciones.contains(normalized))
          encuesta.copyWith(secciones: [...encuesta.secciones, normalized])
        else
          encuesta,
    ];
    _log('AGREGAR_SECCION', encuestaId, normalized);
    _persistEncuesta(encuestaId);
    notifyListeners();
  }

  // RF-026/RF-028: configuración mock de evidencias y destinatarios.
  void updateEncuestaDeliveryConfig(
    String encuestaId, {
    required Set<String> evidencias,
    required Set<String> destinatarios,
  }) {
    _evidenciasPorEncuesta[encuestaId] = Set.of(evidencias);
    _destinatariosPorEncuesta[encuestaId] = Set.of(destinatarios);
    _log(
      'CONFIGURAR_ENTREGA',
      encuestaId,
      'Evidencias: ${evidencias.join(', ')} · Destinatarios: ${destinatarios.join(', ')}',
    );
    notifyListeners();
  }

  void deleteEncuesta(String encuestaId) {
    _encuestas = _encuestas.where((e) => e.id != encuestaId).toList();
    _log('ELIMINAR_ENCUESTA', encuestaId, 'Encuesta eliminada por el Diseñador',
        valorAnterior: 'borrador', valorNuevo: 'eliminada');
    if (FirebaseBootstrap.initialized) {
      unawaited(
        FirebaseFirestore.instance.collection('encuestas').doc(encuestaId).delete(),
      );
    }
    notifyListeners();
  }

  void removeQuestionFromSurvey(String encuestaId, String preguntaId) {
    _encuestas = [
      for (final encuesta in _encuestas)
        if (encuesta.id == encuestaId)
          encuesta.copyWith(
            preguntas: encuesta.preguntas
                .where((p) => p.id != preguntaId)
                .toList(),
          )
        else
          encuesta,
    ];
    _persistEncuesta(encuestaId);
    notifyListeners();
  }

  void createTarea({
    required String titulo,
    required String direccion,
    required String encuestaId,
    required String asignadoA,
    required TareaPrioridad prioridad,
    required DateTime vencimiento,
    String? areaId,
  }) {
    final id = 't-new-${DateTime.now().millisecondsSinceEpoch}';
    final nueva = Tarea(
      id: id,
      encuestaId: encuestaId,
      titulo: titulo,
      direccion: direccion,
      asignadoA: asignadoA,
      estado: TareaEstado.pendiente,
      prioridad: prioridad,
      vencimiento: vencimiento,
      syncEstado: SyncEstado.sincronizado,
      lat: -31.4261,
      lng: -64.1888,
      areaId: areaId,
    );
    _tareas = [..._tareas, nueva];
    _log('CREAR_TAREA', id, 'Asignada a $asignadoA · $titulo');
    _notify('Nueva tarea asignada', '$titulo → $asignadoA', 'R-06'); // RF-012
    unawaited(FirebaseDemoRepository.writeTarea(nueva));
    notifyListeners();
  }

  // RF-020/RF-022: reasignación operativa con notificación al inspector.
  void reassignTask(String taskId, String asignadoA, {String? areaId}) {
    final prev = tareaById(taskId)?.asignadoA;
    _tareas = [
      for (final tarea in _tareas)
        if (tarea.id == taskId)
          tarea.copyWith(
            asignadoA: asignadoA,
            areaId: areaId,
            clearArea: areaId == null,
            estado: TareaEstado.pendiente,
            clearMotivo: true,
          )
        else
          tarea,
    ];
    _log('REASIGNAR_TAREA', taskId, 'Asignada a $asignadoA',
        valorAnterior: prev, valorNuevo: asignadoA);
    _notify('Tarea reasignada', '$taskId → $asignadoA', 'R-06');
    _persistTarea(taskId);
    notifyListeners();
  }

  // RF-020: carga masiva mock para demostrar el flujo CSV sin integración.
  int importTareasCsvMock() {
    if (_tareasCsvImportadas) return 0;
    _tareasCsvImportadas = true;
    createTarea(
      titulo: 'CAPS Parque Liceo',
      direccion: 'Av. Rancagua 3550, Córdoba',
      encuestaId: 'enc-salud-2026',
      asignadoA: 'inspector2@demo.com',
      prioridad: TareaPrioridad.media,
      vencimiento: DateTime(2026, 6, 8),
      areaId: 'area-norte',
    );
    createTarea(
      titulo: 'Dispensario Barrio Jardín',
      direccion: 'Riccheri 2890, Córdoba',
      encuestaId: 'enc-salud-2026',
      asignadoA: 'inspector@demo.com',
      prioridad: TareaPrioridad.alta,
      vencimiento: DateTime(2026, 6, 6),
      areaId: 'area-sur',
    );
    _log('IMPORTAR_TAREAS', 'tareas', '2 tareas importadas desde CSV mock');
    return 2;
  }

  // RF-005: crear encuesta desde plantilla.
  String createEncuestaDesdeTemplate(String nombre, String templateId) {
    final template = encuestaById(templateId);
    if (template == null) return createEncuesta(nombre);
    final id = 'ENC-NEW-${DateTime.now().millisecondsSinceEpoch}';
    final nueva = Encuesta(
      id: id,
      nombre: nombre,
      organismo: organismo.nombre,
      version: 1,
      estado: EncuestaEstado.borrador,
      secciones: List.from(template.secciones),
      preguntas: template.preguntas
          .map(
            (p) => Pregunta(
              id: '${p.id}-tpl-${DateTime.now().millisecondsSinceEpoch}',
              texto: p.texto,
              tipo: p.tipo,
              seccion: p.seccion,
              obligatoria: p.obligatoria,
              opciones: p.opciones,
              esCampoEstandar: p.esCampoEstandar,
              autocompletaCidi: p.autocompletaCidi,
              soloLectura: p.soloLectura,
              longitudMinima: p.longitudMinima,
              longitudMaxima: p.longitudMaxima,
              valorMinimo: p.valorMinimo,
              valorMaximo: p.valorMaximo,
              mensajeValidacion: p.mensajeValidacion,
            ),
          )
          .toList(),
    );
    _encuestas = [..._encuestas, nueva];
    _log('CREAR_ENCUESTA', id, 'Desde plantilla: ${template.nombre} → $nombre');
    unawaited(FirebaseDemoRepository.writeEncuesta(nueva));
    notifyListeners();
    return id;
  }

  String createEncuesta(String nombre) {
    final id = 'ENC-NEW-${DateTime.now().millisecondsSinceEpoch}';
    final nueva = Encuesta(
      id: id,
      nombre: nombre,
      organismo: organismo.nombre,
      version: 1,
      estado: EncuestaEstado.borrador,
      secciones: const ['Datos generales', 'Hallazgos'],
      preguntas: const [],
    );
    _encuestas = [..._encuestas, nueva];
    _log('CREAR_ENCUESTA', id, nombre);
    unawaited(FirebaseDemoRepository.writeEncuesta(nueva));
    notifyListeners();
    return id;
  }

  void startTask(String taskId) {
    _tareas = [
      for (final tarea in _tareas)
        if (tarea.id == taskId && tarea.estado == TareaEstado.pendiente)
          tarea.copyWith(estado: TareaEstado.enCurso)
        else
          tarea,
    ];
    _log('INICIAR', taskId, 'Relevamiento iniciado en campo');
    _persistTarea(taskId);
    notifyListeners();
  }

  void rejectTask(String taskId, String motivo) {
    final prev = tareaById(taskId)?.estado.label;
    _tareas = [
      for (final tarea in _tareas)
        if (tarea.id == taskId)
          tarea.copyWith(estado: TareaEstado.devuelta, motivo: motivo)
        else
          tarea,
    ];
    _log('DEVOLVER', taskId, 'Tarea devuelta — motivo: $motivo',
        valorAnterior: prev, valorNuevo: TareaEstado.devuelta.label);
    _notify(
      'Tarea devuelta por inspector',
      'Motivo: $motivo',
      'R-05',
    ); // RF-012
    _persistTarea(taskId);
    notifyListeners();
  }

  void finishTaskLocal(String taskId) {
    _tareas = [
      for (final tarea in _tareas)
        if (tarea.id == taskId)
          tarea.copyWith(
            estado: TareaEstado.finalizada,
            syncEstado: SyncEstado.local,
          )
        else
          tarea,
    ];
    _log('COMPLETAR', taskId, 'Relevamiento completado — pendiente de sync');
    _persistTarea(taskId);
    notifyListeners();
  }

  Future<void> syncTask(String taskId) async {
    _tareas = [
      for (final tarea in _tareas)
        if (tarea.id == taskId)
          tarea.copyWith(syncEstado: SyncEstado.sincronizando)
        else
          tarea,
    ];
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _tareas = [
      for (final tarea in _tareas)
        if (tarea.id == taskId)
          tarea.copyWith(syncEstado: SyncEstado.sincronizado)
        else
          tarea,
    ];
    _syncedDemoRelevamientos += 1;
    final syncedTask = tareaById(taskId);
    if (syncedTask != null) {
      await FirebaseDemoRepository.writeSyncedRelevamiento(syncedTask);
      await FirebaseDemoRepository.writeTarea(syncedTask);
      _log(
        'SINCRONIZAR',
        taskId,
        'Relevamiento sincronizado a Firebase — ${syncedTask.titulo}',
      );
    }
    notifyListeners();
  }

  Future<void> seedFirebaseDemoData() async {
    await FirebaseDemoRepository.seedDemoData(
      encuestas: _encuestas,
      tareas: _tareas,
    );
  }

  Future<void> syncPending() async {
    final pending = _tareas
        .where((t) => t.syncEstado == SyncEstado.local)
        .map((t) => t.id)
        .toList();
    for (final taskId in pending) {
      await syncTask(taskId);
    }
  }
}
