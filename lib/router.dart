import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/demo_selector_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/backoffice/analista/analista_screen.dart';
import 'features/backoffice/auditoria/auditoria_screen.dart';
import 'features/backoffice/dashboard/dashboard_screen.dart';
import 'features/backoffice/encuestas/encuesta_builder_screen.dart';
import 'features/backoffice/encuestas/encuesta_detail_screen.dart';
import 'features/backoffice/encuestas/encuestas_screen.dart';
import 'features/backoffice/organismo/organismo_screen.dart';
import 'features/backoffice/shell/backoffice_shell.dart';
import 'features/backoffice/tareas/tareas_screen.dart';
import 'features/backoffice/usuarios/usuarios_screen.dart';
import 'features/mobile/form_execution/form_execution_screen.dart';
import 'features/mobile/shell/mobile_shell.dart';
import 'features/mobile/sync/mobile_map_screen.dart';
import 'features/mobile/sync/mobile_profile_screen.dart';
import 'features/mobile/sync/sync_screen.dart';
import 'features/mobile/tasks/task_detail_screen.dart';
import 'features/mobile/tasks/tasks_screen.dart';

Page<void> _noTransition(Widget child) => NoTransitionPage(child: child);

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/login'),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _noTransition(const LoginScreen()),
      ),
      GoRoute(
        path: '/demo-selector',
        pageBuilder: (context, state) =>
            _noTransition(const DemoSelectorScreen()),
      ),
      GoRoute(path: '/backoffice', redirect: (_, _) => '/backoffice/dashboard'),
      ShellRoute(
        pageBuilder: (context, state, child) => _noTransition(
          BackofficeShell(location: state.uri.path, child: child),
        ),
        routes: [
          GoRoute(
            path: '/backoffice/dashboard',
            pageBuilder: (context, state) =>
                _noTransition(const DashboardScreen()),
          ),
          GoRoute(
            path: '/backoffice/encuestas',
            pageBuilder: (context, state) =>
                _noTransition(const EncuestasScreen()),
          ),
          GoRoute(
            path: '/backoffice/encuestas/:id',
            pageBuilder: (context, state) => _noTransition(
              EncuestaDetailScreen(encuestaId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/backoffice/encuestas/:id/builder',
            pageBuilder: (context, state) => _noTransition(
              EncuestaBuilderScreen(encuestaId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/backoffice/tareas',
            pageBuilder: (context, state) =>
                _noTransition(const TareasScreen()),
          ),
          GoRoute(
            path: '/backoffice/usuarios',
            pageBuilder: (context, state) =>
                _noTransition(const UsuariosScreen()),
          ),
          GoRoute(
            path: '/backoffice/organismo',
            pageBuilder: (context, state) =>
                _noTransition(const OrganismoScreen()),
          ),
          GoRoute(
            path: '/backoffice/analista',
            pageBuilder: (context, state) =>
                _noTransition(const AnalistaScreen()),
          ),
          GoRoute(
            path: '/backoffice/auditoria',
            pageBuilder: (context, state) =>
                _noTransition(const AuditoriaScreen()),
          ),
        ],
      ),
      GoRoute(path: '/mobile', redirect: (_, _) => '/mobile/tasks'),
      ShellRoute(
        pageBuilder: (context, state, child) =>
            _noTransition(MobileShell(location: state.uri.path, child: child)),
        routes: [
          GoRoute(
            path: '/mobile/tasks',
            pageBuilder: (context, state) => _noTransition(const TasksScreen()),
          ),
          GoRoute(
            path: '/mobile/tasks/:id',
            pageBuilder: (context, state) => _noTransition(
              TaskDetailScreen(taskId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/mobile/form/:id',
            pageBuilder: (context, state) => _noTransition(
              FormExecutionScreen(taskId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/mobile/form/:id/:relId',
            pageBuilder: (context, state) => _noTransition(
              FormExecutionScreen(
                taskId: state.pathParameters['id']!,
                relId: state.pathParameters['relId'],
              ),
            ),
          ),
          GoRoute(
            path: '/mobile/map',
            pageBuilder: (context, state) =>
                _noTransition(const MobileMapScreen()),
          ),
          GoRoute(
            path: '/mobile/profile',
            pageBuilder: (context, state) =>
                _noTransition(const MobileProfileScreen()),
          ),
          GoRoute(
            path: '/mobile/sync',
            pageBuilder: (context, state) => _noTransition(const SyncScreen()),
          ),
        ],
      ),
    ],
  );
}

final appRouter = createAppRouter();
