enum TareaEstado { pendiente, enCurso, finalizada, devuelta }

enum TareaPrioridad { alta, media, baja }

enum SyncEstado { local, sincronizando, sincronizado, error }

extension TareaEstadoLabel on TareaEstado {
  String get label {
    switch (this) {
      case TareaEstado.pendiente:
        return 'Pendiente';
      case TareaEstado.enCurso:
        return 'En curso';
      case TareaEstado.finalizada:
        return 'Finalizada';
      case TareaEstado.devuelta:
        return 'Devuelta';
    }
  }
}

extension TareaPrioridadLabel on TareaPrioridad {
  String get label {
    switch (this) {
      case TareaPrioridad.alta:
        return 'Alta';
      case TareaPrioridad.media:
        return 'Media';
      case TareaPrioridad.baja:
        return 'Baja';
    }
  }
}

extension SyncEstadoLabel on SyncEstado {
  String get label {
    switch (this) {
      case SyncEstado.local:
        return 'Pendiente de sincronizar';
      case SyncEstado.sincronizando:
        return 'Sincronizando';
      case SyncEstado.sincronizado:
        return 'Sincronizado';
      case SyncEstado.error:
        return 'Error';
    }
  }
}

class Tarea {
  const Tarea({
    required this.id,
    required this.encuestaId,
    required this.titulo,
    required this.direccion,
    required this.asignadoA,
    required this.estado,
    required this.prioridad,
    required this.vencimiento,
    required this.syncEstado,
    required this.lat,
    required this.lng,
    this.areaId,
    this.motivo,
  });

  final String id;
  final String encuestaId;
  final String titulo;
  final String direccion;
  final String asignadoA;
  final TareaEstado estado;
  final TareaPrioridad prioridad;
  final DateTime vencimiento;
  final SyncEstado syncEstado;
  final double lat;
  final double lng;
  final String? areaId;
  final String? motivo;

  Tarea copyWith({
    String? asignadoA,
    String? areaId,
    TareaEstado? estado,
    SyncEstado? syncEstado,
    String? motivo,
    bool clearArea = false,
    bool clearMotivo = false,
  }) {
    return Tarea(
      id: id,
      encuestaId: encuestaId,
      titulo: titulo,
      direccion: direccion,
      asignadoA: asignadoA ?? this.asignadoA,
      estado: estado ?? this.estado,
      prioridad: prioridad,
      vencimiento: vencimiento,
      syncEstado: syncEstado ?? this.syncEstado,
      lat: lat,
      lng: lng,
      areaId: clearArea ? null : areaId ?? this.areaId,
      motivo: clearMotivo ? null : motivo ?? this.motivo,
    );
  }
}
