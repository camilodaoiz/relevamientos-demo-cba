import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

abstract final class FirebaseBootstrap {
  static bool _initialized = false;
  static String? lastError;

  static bool get initialized => _initialized;

  static Future<void> initialize() async {
    try {
      // Si ya fue inicializado en una sesión anterior, reutilizarlo.
      if (Firebase.apps.isNotEmpty) {
        _initialized = true;
        lastError = null;
        return;
      }
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      lastError = null;
      debugPrint('Firebase initialized OK — project: ${DefaultFirebaseOptions.web.projectId}');
    } catch (error) {
      _initialized = false;
      lastError = error.toString();
      debugPrint('Firebase init failed: $error');
    }
  }
}
