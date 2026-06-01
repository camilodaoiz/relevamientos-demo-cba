import 'package:flutter_test/flutter_test.dart';

import 'package:relevamientos_demo/core/models/encuesta.dart';
import 'package:relevamientos_demo/core/state/demo_store.dart';

void main() {
  Future<DemoStore> storeReady() async {
    final store = DemoStore();
    await store.initialize();
    return store;
  }

  test('RF-003 stores field validations', () async {
    final store = await storeReady();

    store.updatePreguntaValidaciones(
      'enc-salud-2026',
      'p-camas',
      valorMinimo: 1,
      valorMaximo: 250,
      mensajeValidacion: 'Rango inválido',
    );

    final pregunta = store
        .encuestaById('enc-salud-2026')!
        .preguntas
        .firstWhere((item) => item.id == 'p-camas');
    expect(pregunta.valorMinimo, 1);
    expect(pregunta.valorMaximo, 250);
    expect(pregunta.tieneValidaciones, isTrue);
  });

  test('RF-006 publication creates immutable version entry', () async {
    final store = await storeReady();
    final before = store.versionesDe('enc-aprobada').length;

    store.transitionEncuesta('enc-aprobada', EncuestaEstado.publicada);

    final encuesta = store.encuestaById('enc-aprobada')!;
    expect(encuesta.version, 2);
    expect(store.versionesDe('enc-aprobada').length, before + 1);
  });

  test('RF-013 validator comment can be answered and resolved', () async {
    final store = await storeReady();
    final validador = store.usuarios.firstWhere((user) => user.rolId == 'R-04');
    store.selectUser(validador);

    store.addComentarioEncuesta(
      encuestaId: 'enc-revision',
      objetivoId: 'p-domicilio',
      objetivoLabel: 'Pregunta: Domicilio',
      mensaje: 'Agregar localidad.',
    );
    final comentario = store.comentariosDe('enc-revision').first;

    final disenador = store.usuarios.firstWhere((user) => user.rolId == 'R-03');
    store.selectUser(disenador);
    store.responderComentario(comentario.id, 'Localidad agregada.');
    store.resolverComentario(comentario.id);

    expect(comentario.respuestas, isNotEmpty);
    expect(comentario.resuelto, isTrue);
  });

  test(
    'RF-014 users support create edit deactivate and CSV mock import',
    () async {
      final store = await storeReady();

      store.createUsuario(
        nombre: 'Usuario Prueba',
        email: 'prueba@demo.com',
        rolId: 'R-07',
        rolNombre: 'Analista / Visualizador',
        organismo: store.organismo.nombre,
      );
      final created = store.usuarios.firstWhere(
        (user) => user.email == 'prueba@demo.com',
      );

      store.updateUsuario(
        created.id,
        nombre: 'Usuario Editado',
        email: created.email,
        rolId: created.rolId,
        rolNombre: created.rolNombre,
        organismo: created.organismo,
      );
      store.toggleUsuarioEstado(created.id);
      store.importUsuariosCsvMock();

      expect(
        store.usuarios.firstWhere((user) => user.id == created.id).nombre,
        'Usuario Editado',
      );
      expect(
        store.usuarios.firstWhere((user) => user.id == created.id).estado,
        'Inactivo',
      );
      expect(
        store.usuarios.any((user) => user.email == 'inspector3@demo.com'),
        isTrue,
      );
    },
  );
}
