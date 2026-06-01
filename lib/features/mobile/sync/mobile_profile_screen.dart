import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/tarea.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';

class MobileProfileScreen extends ConsumerWidget {
  const MobileProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // RF-014/RF-015/RF-030: perfil del inspector demo y simulacion modo offline.
    final store = ref.watch(demoStoreProvider);
    final user = store.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                child: Text(
                  user.nombre.substring(0, 1),
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 12),
              Text(user.nombre, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(user.email, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              StatusBadge(
                label: '${user.rolId} · ${user.rolNombre}',
                color: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Organismo', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                user.organismo,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Cerrar sesión',
                icon: Icons.logout,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mis relevamientos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              Builder(
                builder: (ctx) {
                  final tasks = store.inspectorTasks;
                  final pendientes = tasks
                      .where((t) => t.estado == TareaEstado.pendiente)
                      .length;
                  final enCurso = tasks
                      .where((t) => t.estado == TareaEstado.enCurso)
                      .length;
                  final finalizadas = tasks
                      .where((t) => t.estado == TareaEstado.finalizada)
                      .length;
                  final porSync = tasks
                      .where((t) => t.syncEstado == SyncEstado.local)
                      .length;
                  final progress = tasks.isNotEmpty
                      ? finalizadas / tasks.length
                      : 0.0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatChip(
                            label: 'Pendientes',
                            value: pendientes,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            label: 'En curso',
                            value: enCurso,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            label: 'Completadas',
                            value: finalizadas,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$finalizadas de ${tasks.length} completadas${porSync > 0 ? '  ·  $porSync por sincronizar' : ''}',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conectividad',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    store.offlineMode ? Icons.wifi_off : Icons.wifi,
                    color: store.offlineMode
                        ? const Color(0xFFD97706)
                        : AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      store.offlineMode
                          ? 'Modo offline activo — sincronización en espera'
                          : 'Conectado — sincronización disponible',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Switch(
                    value: store.offlineMode,
                    onChanged: (_) =>
                        ref.read(demoStoreProvider).toggleOfflineMode(),
                    activeThumbColor: const Color(0xFFD97706),
                  ),
                ],
              ),
              if (store.offlineMode) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Los relevamientos se guardan localmente y se sincronizarán automáticamente al recuperar conexión.',
                    style: TextStyle(fontSize: 11, color: Color(0xFFD97706)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
