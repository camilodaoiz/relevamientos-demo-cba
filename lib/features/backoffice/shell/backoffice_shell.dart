import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/encuesta.dart';
import '../../../core/models/tarea.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';

class BackofficeShell extends ConsumerStatefulWidget {
  const BackofficeShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  ConsumerState<BackofficeShell> createState() => _BackofficeShellState();
}

class _BackofficeShellState extends ConsumerState<BackofficeShell> {
  bool _notifOpen = false;

  @override
  Widget build(BuildContext context) {
    // RF-001/RF-019/RF-036: shell web para diseno, planificacion y analisis.
    final store = ref.watch(demoStoreProvider);
    final user = store.currentUser;
    final location = widget.location;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            color: AppColors.primary,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/logos/hacer_para_crecer_icon.png',
                          width: 36,
                          height: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Relevamientos',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._navItemsFor(context, location, user.rolId, store),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _breadcrumb(location),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      // RF-012: campana de notificaciones
                      _NotifBell(
                        count: store.notificacionesNoLeidas,
                        onTap: () => setState(() => _notifOpen = !_notifOpen),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              user.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              user.rolNombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: AppColors.accent.withValues(
                          alpha: 0.12,
                        ),
                        child: Text(
                          user.nombre.characters.first,
                          style: const TextStyle(color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: widget.child,
                      ),
                      if (_notifOpen)
                        _NotifPanel(
                          notificaciones: store.notificaciones,
                          rolId: user.rolId,
                          onClose: () => setState(() => _notifOpen = false),
                          onMarcarLeidas: () =>
                              ref.read(demoStoreProvider).marcarTodasLeidas(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// RF-012: campana de notificaciones.
class _NotifBell extends StatelessWidget {
  const _NotifBell({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.textSecondary,
          tooltip: 'Notificaciones',
        ),
        if (count > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotifPanel extends StatelessWidget {
  const _NotifPanel({
    required this.notificaciones,
    required this.rolId,
    required this.onClose,
    required this.onMarcarLeidas,
  });
  final List<NotificacionApp> notificaciones;
  final String rolId;
  final VoidCallback onClose;
  final VoidCallback onMarcarLeidas;

  @override
  Widget build(BuildContext context) {
    final relevantes = notificaciones
        .where((n) => n.rolDestinatario == rolId)
        .toList();

    return Positioned(
      top: 0,
      right: 0,
      child: Material(
        elevation: 8,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        child: Container(
          width: 360,
          constraints: const BoxConstraints(maxHeight: 480),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Notificaciones',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (relevantes.any((n) => !n.leida))
                      TextButton(
                        onPressed: onMarcarLeidas,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          'Marcar todas',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (relevantes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Sin notificaciones para tu rol.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: relevantes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final n = relevantes[i];
                      return Container(
                        color: n.leida
                            ? Colors.transparent
                            : AppColors.accent.withValues(alpha: 0.04),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: n.leida
                                    ? Colors.transparent
                                    : AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.titulo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    n.cuerpo,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n.timestamp,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: active
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _navItemsFor(
  BuildContext context,
  String location,
  String rolId,
  DemoStore store,
) {
  final all = [
    (Icons.dashboard_outlined, 'Dashboard', '/backoffice/dashboard'),
    (Icons.dynamic_form_outlined, 'Encuestas', '/backoffice/encuestas'),
    (Icons.assignment_outlined, 'Tareas', '/backoffice/tareas'),
    (Icons.people_alt_outlined, 'Usuarios', '/backoffice/usuarios'),
    (Icons.account_balance_outlined, 'Organismo', '/backoffice/organismo'),
    (Icons.bar_chart_outlined, 'Tableros', '/backoffice/analista'),
    (Icons.security_outlined, 'Auditoría', '/backoffice/auditoria'),
  ];
  final allowed = switch (rolId) {
    'R-03' || 'R-04' => {'/backoffice/dashboard', '/backoffice/encuestas'},
    'R-05' => {'/backoffice/dashboard', '/backoffice/tareas'},
    'R-06' => {'/backoffice/dashboard'},
    'R-07' => {'/backoffice/dashboard', '/backoffice/analista'},
    'R-08' => {'/backoffice/dashboard', '/backoffice/auditoria'},
    _ => {
      '/backoffice/dashboard',
      '/backoffice/encuestas',
      '/backoffice/tareas',
      '/backoffice/usuarios',
      '/backoffice/organismo',
    },
  };

  final enRevision = rolId == 'R-04'
      ? store.encuestas
            .where((e) => e.estado == EncuestaEstado.enRevision)
            .length
      : 0;
  final localPending = rolId == 'R-05'
      ? store.tareas.where((t) => t.syncEstado == SyncEstado.local).length
      : 0;

  return [
    for (final (icon, label, route) in all)
      if (allowed.contains(route))
        _NavItem(
          icon: icon,
          label: label,
          active: location.startsWith(route),
          onTap: () => context.go(route),
          badge: route == '/backoffice/encuestas'
              ? enRevision
              : route == '/backoffice/tareas'
              ? localPending
              : 0,
        ),
  ];
}

String _breadcrumb(String location) {
  if (location.contains('encuestas')) return 'Backoffice / Encuestas';
  if (location.contains('tareas')) return 'Backoffice / Tareas';
  if (location.contains('usuarios')) return 'Backoffice / Usuarios';
  if (location.contains('organismo')) return 'Backoffice / Organismo';
  if (location.contains('analista')) return 'Backoffice / Tableros';
  if (location.contains('auditoria')) return 'Backoffice / Auditoría';
  return 'Backoffice / Dashboard';
}
