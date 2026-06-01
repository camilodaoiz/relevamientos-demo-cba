// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:relevamientos_demo/core/state/demo_store.dart';
import 'package:relevamientos_demo/main.dart';
import 'package:relevamientos_demo/router.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(demoStoreProvider).initialize();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RelevamientosDemoApp(routerConfig: createAppRouter()),
      ),
    );
    await tester.pump();
  }

  Future<void> openSelector(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.ensureVisible(
      find.text('Ver todos los perfiles de presentación'),
    );
    await tester.tap(find.text('Ver todos los perfiles de presentación'));
    await tester.pumpAndSettle();
  }

  test(
    'task CSV mock imports once and reassignment clears rejection',
    () async {
      final store = DemoStore();
      await store.initialize();
      final initialCount = store.tareas.length;

      expect(store.importTareasCsvMock(), 2);
      expect(store.tareas.length, initialCount + 2);
      expect(store.importTareasCsvMock(), 0);

      store.reassignTask('t-012', 'inspector@demo.com', areaId: 'area-sur');
      final reassigned = store.tareaById('t-012')!;
      expect(reassigned.asignadoA, 'inspector@demo.com');
      expect(reassigned.areaId, 'area-sur');
      expect(reassigned.motivo, isNull);
    },
  );

  test('offline CiDi lookup and builder delivery config are audited', () async {
    final store = DemoStore();
    await store.initialize();

    store.toggleOfflineMode();
    store.registerCidiLookup('20304567891', verified: false);
    store.addSectionToSurvey('enc-borrador', 'Observaciones finales');
    store.updateEncuestaDeliveryConfig(
      'enc-borrador',
      evidencias: {'Foto', 'GPS'},
      destinatarios: {'Coordinador de Campo'},
    );

    expect(store.auditLog.first.accion, 'CONFIGURAR_ENTREGA');
    expect(
      store.auditLog.any(
        (entry) =>
            entry.accion == 'CONSULTA_CIDI' &&
            entry.detalle.contains('no verificada'),
      ),
      isTrue,
    );
    expect(
      store.encuestaById('enc-borrador')!.secciones,
      contains('Observaciones finales'),
    );
  });

  testWidgets('RBAC login loads', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester);

    expect(find.text('Ingresar'), findsWidgets);
    expect(
      find.text('Contraseña para todos los perfiles demo: 123'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('government-slogan-logo')), findsOneWidget);
  });

  testWidgets('admin login routes to backoffice dashboard', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester);

    await tester.tap(find.text('Ingresar').last);
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido, Camila.'), findsOneWidget);
  });

  testWidgets('backoffice session closes from sidebar', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester);

    await tester.tap(find.text('Ingresar').last);
    await tester.pumpAndSettle();
    expect(find.text('Cambiar rol'), findsNothing);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresar'), findsWidgets);
  });

  testWidgets('demo selector loads', (WidgetTester tester) async {
    await openSelector(tester);

    expect(find.text('Seleccioná tu perfil de acceso'), findsOneWidget);
    expect(find.text('Validador / Controlador'), findsOneWidget);
  });

  testWidgets('admin role opens backoffice dashboard', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await openSelector(tester);
    await tester.tap(find.text('Administrador del Sistema'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido, Camila.'), findsOneWidget);
  });

  testWidgets('validator role opens backoffice dashboard', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await openSelector(tester);
    await tester.tap(find.text('Validador / Controlador'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido, Sofia.'), findsOneWidget);
    expect(find.text('Validador / Controlador'), findsOneWidget);
  });

  testWidgets('inspector role opens mobile tasks', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await openSelector(tester);
    await tester.ensureVisible(find.text('Inspector de Campo').first);
    await tester.tap(find.text('Inspector de Campo').first);
    await tester.pumpAndSettle();

    expect(find.text('CAPS Nueva Cordoba'), findsOneWidget);
  });

  testWidgets('mobile form loads demo answers and finishes locally', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await openSelector(tester);
    await tester.ensureVisible(find.text('Inspector de Campo').first);
    await tester.tap(find.text('Inspector de Campo').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('CAPS Nueva Cordoba'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar relevamiento').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cargar datos de ejemplo'));
    await tester.pump();
    expect(find.text('Verificado via CiDi'), findsOneWidget);

    await tester.ensureVisible(find.text('Siguiente'));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Siguiente'));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Finalizar'), findsOneWidget);

    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();

    expect(find.text('Estado de sincronización'), findsOneWidget);
    expect(find.text('Pendiente de sincronizar'), findsWidgets);
  });
}
