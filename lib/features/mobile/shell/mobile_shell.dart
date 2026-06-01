import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/tarea.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';

class MobileShell extends ConsumerWidget {
  const MobileShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // RF-024/RF-033: shell mobile para tareas, mapa simple y estado de sync visible.
    final store = ref.watch(demoStoreProvider);
    final pendingSync = store.tareas
        .where((task) => task.syncEstado == SyncEstado.local)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(location)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: pendingSync > 0
                      ? AppColors.warning.withValues(alpha: 0.12)
                      : AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  pendingSync > 0 ? '$pendingSync local' : 'Sync OK',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: pendingSync > 0
                        ? AppColors.warning
                        : AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (store.offlineMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFD97706),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, size: 15, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modo offline — los datos se sincronizarán cuando haya conexión',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(location),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/mobile/tasks');
              break;
            case 1:
              context.go('/mobile/map');
              break;
            case 2:
              context.go('/mobile/profile');
              break;
            case 3:
              context.go('/mobile/sync');
              break;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Tareas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingSync > 0,
              label: Text('$pendingSync'),
              child: const Icon(Icons.sync_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendingSync > 0,
              label: Text('$pendingSync'),
              child: const Icon(Icons.sync),
            ),
            label: 'Sync',
          ),
        ],
      ),
    );
  }
}

int _selectedIndex(String location) {
  if (location.startsWith('/mobile/map')) return 1;
  if (location.startsWith('/mobile/profile')) return 2;
  if (location.startsWith('/mobile/sync')) return 3;
  return 0;
}

String _title(String location) {
  if (location.startsWith('/mobile/map')) return 'Mapa';
  if (location.startsWith('/mobile/profile')) return 'Perfil';
  if (location.startsWith('/mobile/sync')) return 'Sincronizacion';
  if (location.startsWith('/mobile/form')) return 'Relevamiento';
  return 'Tareas';
}
