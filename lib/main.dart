import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'core/state/demo_store.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();

  final container = ProviderContainer();
  await container.read(demoStoreProvider).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const RelevamientosDemoApp(),
    ),
  );
}

class RelevamientosDemoApp extends StatelessWidget {
  const RelevamientosDemoApp({super.key, this.routerConfig});

  final GoRouter? routerConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Relevamientos Digitales',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: routerConfig ?? appRouter,
    );
  }
}
