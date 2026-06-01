import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campo_estandar.dart';
import '../models/encuesta.dart';
import '../models/pregunta.dart';
import '../models/tarea.dart';
import '../models/usuario.dart';
import 'firebase_bootstrap.dart';

abstract final class FirebaseDemoRepository {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Demo pública: solo requiere que Firebase esté inicializado.
  static bool get canWrite {
    return FirebaseBootstrap.initialized;
  }

  // ─── Read ────────────────────────────────────────────────────────────────

  static Future<List<Encuesta>> getEncuestas() async {
    if (!canWrite) return [];
    final snapshot = await _db.collection('encuestas').get();
    return snapshot.docs.map((doc) => _encuestaFromMap(doc.data())).toList();
  }

  static Future<List<Tarea>> getTareas() async {
    if (!canWrite) return [];
    final snapshot = await _db.collection('tareas').get();
    return snapshot.docs.map((doc) => _tareaFromMap(doc.data())).toList();
  }

  static Future<List<Usuario>> getUsuarios() async {
    if (!canWrite) return [];
    final snapshot = await _db.collection('usuarios').get();
    return snapshot.docs.map((doc) => _usuarioFromMap(doc.data())).toList();
  }

  // ─── Write (batch seed) ───────────────────────────────────────────────────

  static Future<void> seedDemoData({
    required List<Encuesta> encuestas,
    required List<Tarea> tareas,
  }) async {
    if (!canWrite) return;

    final batch = _db.batch();
    for (final encuesta in encuestas) {
      batch.set(
        _db.collection('encuestas').doc(encuesta.id),
        _encuestaToMap(encuesta),
        SetOptions(merge: true),
      );
    }
    for (final tarea in tareas) {
      batch.set(
        _db.collection('tareas').doc(tarea.id),
        _tareaToMap(tarea),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  // ─── Write (single item) ──────────────────────────────────────────────────

  static Future<void> writeEncuesta(Encuesta encuesta) async {
    if (!canWrite) return;
    await _db
        .collection('encuestas')
        .doc(encuesta.id)
        .set(_encuestaToMap(encuesta), SetOptions(merge: true));
  }

  static Future<void> writeTarea(Tarea tarea) async {
    if (!canWrite) return;
    await _db
        .collection('tareas')
        .doc(tarea.id)
        .set(_tareaToMap(tarea), SetOptions(merge: true));
  }

  // ─── Organismo config (modoPreguntas, camposObligatorios, evidencias) ────────

  static Future<Map<String, dynamic>?> getOrgConfig(String orgId) async {
    if (!canWrite) return null;
    final doc = await _db.collection('config').doc(orgId).get();
    return doc.exists ? doc.data() : null;
  }

  static Future<void> writeOrgConfig(
    String orgId,
    Map<String, Object?> data,
  ) async {
    if (!canWrite) return;
    await _db
        .collection('config')
        .doc(orgId)
        .set(data, SetOptions(merge: true));
  }

  static Future<void> writeUsuario(Usuario usuario) async {
    if (!canWrite) return;
    await _db
        .collection('usuarios')
        .doc(usuario.id)
        .set(_usuarioToMap(usuario), SetOptions(merge: true));
  }

  static Future<void> deleteUsuario(String id) async {
    if (!canWrite) return;
    await _db.collection('usuarios').doc(id).delete();
  }

  static Future<void> seedUsuarios(List<Usuario> usuarios) async {
    if (!canWrite) return;
    final batch = _db.batch();
    for (final u in usuarios) {
      batch.set(
        _db.collection('usuarios').doc(u.id),
        _usuarioToMap(u),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  static Future<void> writeSyncedRelevamiento(Tarea tarea) async {
    if (!canWrite) return;

    await _db.collection('relevamientos').doc(tarea.id).set({
      'tareaId': tarea.id,
      'encuestaId': tarea.encuestaId,
      'inspectorEmail': tarea.asignadoA,
      'estadoSync': SyncEstado.sincronizado.name,
      'estadoTarea': TareaEstado.finalizada.name,
      'sincronizadoEn': FieldValue.serverTimestamp(),
      'mock': true,
    }, SetOptions(merge: true));
  }

  // ─── Serializers ─────────────────────────────────────────────────────────

  static Map<String, Object?> _encuestaToMap(Encuesta encuesta) {
    return {
      'id': encuesta.id,
      'nombre': encuesta.nombre,
      'organismo': encuesta.organismo,
      'version': encuesta.version,
      'estado': encuesta.estado.name,
      'secciones': encuesta.secciones,
      'preguntas': encuesta.preguntas.map(_preguntaToMap).toList(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, Object?> _preguntaToMap(Pregunta pregunta) {
    return {
      'id': pregunta.id,
      'texto': pregunta.texto,
      'tipo': pregunta.tipo.name,
      'seccion': pregunta.seccion,
      'obligatoria': pregunta.obligatoria,
      'opciones': pregunta.opciones,
      'esCampoEstandar': pregunta.esCampoEstandar,
      'autocompletaCidi': pregunta.autocompletaCidi,
      'soloLectura': pregunta.soloLectura,
      if (pregunta.condicionCampoId != null)
        'condicionCampoId': pregunta.condicionCampoId,
      if (pregunta.condicionValor != null)
        'condicionValor': pregunta.condicionValor,
      if (pregunta.longitudMinima != null)
        'longitudMinima': pregunta.longitudMinima,
      if (pregunta.longitudMaxima != null)
        'longitudMaxima': pregunta.longitudMaxima,
      if (pregunta.valorMinimo != null) 'valorMinimo': pregunta.valorMinimo,
      if (pregunta.valorMaximo != null) 'valorMaximo': pregunta.valorMaximo,
      if (pregunta.mensajeValidacion != null)
        'mensajeValidacion': pregunta.mensajeValidacion,
    };
  }

  static Map<String, Object?> _tareaToMap(Tarea tarea) {
    return {
      'id': tarea.id,
      'encuestaId': tarea.encuestaId,
      'titulo': tarea.titulo,
      'direccion': tarea.direccion,
      'asignadoA': tarea.asignadoA,
      'estado': tarea.estado.name,
      'prioridad': tarea.prioridad.name,
      'vencimiento': Timestamp.fromDate(tarea.vencimiento),
      'syncEstado': tarea.syncEstado.name,
      'lat': tarea.lat,
      'lng': tarea.lng,
      if (tarea.areaId != null) 'areaId': tarea.areaId,
      if (tarea.motivo != null) 'motivo': tarea.motivo,
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
  }

  // ─── Deserializers ────────────────────────────────────────────────────────

  static Encuesta _encuestaFromMap(Map<String, dynamic> map) {
    return Encuesta(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      organismo: map['organismo'] as String,
      version: (map['version'] as num?)?.toInt() ?? 1,
      estado: EncuestaEstado.values.byName(map['estado'] as String),
      secciones: List<String>.from(map['secciones'] as List? ?? []),
      preguntas: (map['preguntas'] as List? ?? [])
          .map((p) => _preguntaFromMap(Map<String, dynamic>.from(p as Map)))
          .toList(),
    );
  }

  static Pregunta _preguntaFromMap(Map<String, dynamic> map) {
    return Pregunta(
      id: map['id'] as String,
      texto: map['texto'] as String,
      tipo: CampoTipo.values.byName(map['tipo'] as String),
      seccion: map['seccion'] as String,
      obligatoria: map['obligatoria'] as bool? ?? false,
      opciones: List<String>.from(map['opciones'] as List? ?? []),
      esCampoEstandar: map['esCampoEstandar'] as bool? ?? false,
      autocompletaCidi: map['autocompletaCidi'] as bool? ?? false,
      soloLectura: map['soloLectura'] as bool? ?? false,
      condicionCampoId: map['condicionCampoId'] as String?,
      condicionValor: map['condicionValor'] as String?,
      longitudMinima: (map['longitudMinima'] as num?)?.toInt(),
      longitudMaxima: (map['longitudMaxima'] as num?)?.toInt(),
      valorMinimo: map['valorMinimo'] as num?,
      valorMaximo: map['valorMaximo'] as num?,
      mensajeValidacion: map['mensajeValidacion'] as String?,
    );
  }

  static Tarea _tareaFromMap(Map<String, dynamic> map) {
    final vencimientoRaw = map['vencimiento'];
    final vencimiento = vencimientoRaw is Timestamp
        ? vencimientoRaw.toDate()
        : DateTime.now().add(const Duration(days: 7));

    return Tarea(
      id: map['id'] as String,
      encuestaId: map['encuestaId'] as String,
      titulo: map['titulo'] as String,
      direccion: map['direccion'] as String,
      asignadoA: map['asignadoA'] as String,
      estado: TareaEstado.values.byName(map['estado'] as String),
      prioridad: TareaPrioridad.values.byName(map['prioridad'] as String),
      vencimiento: vencimiento,
      syncEstado: SyncEstado.values.byName(
        map['syncEstado'] as String? ?? SyncEstado.sincronizado.name,
      ),
      lat: (map['lat'] as num?)?.toDouble() ?? -31.4261,
      lng: (map['lng'] as num?)?.toDouble() ?? -64.1888,
      areaId: map['areaId'] as String?,
      motivo: map['motivo'] as String?,
    );
  }

  static Map<String, Object?> _usuarioToMap(Usuario usuario) {
    return {
      'id': usuario.id,
      'email': usuario.email,
      'nombre': usuario.nombre,
      'rolId': usuario.rolId,
      'rolNombre': usuario.rolNombre,
      'organismo': usuario.organismo,
      'estado': usuario.estado,
    };
  }

  static Usuario _usuarioFromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String,
      email: map['email'] as String,
      nombre: map['nombre'] as String,
      rolId: map['rolId'] as String,
      rolNombre: map['rolNombre'] as String,
      organismo: map['organismo'] as String,
      estado: map['estado'] as String? ?? 'Activo',
    );
  }
}
