import 'tarea.dart';

class Relevamiento {
  const Relevamiento({
    required this.id,
    required this.tareaId,
    required this.inspectorEmail,
    required this.syncEstado,
  });

  final String id;
  final String tareaId;
  final String inspectorEmail;
  final SyncEstado syncEstado;
}
