import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/tarea.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // RF-024/RF-029: listado de tareas asignadas descargadas para uso offline.
    final tasks = ref.watch(demoStoreProvider).inspectorTasks;

    if (tasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            title: 'Sin tareas asignadas',
            message: 'No tenés tareas pendientes por el momento.',
          ),
        ),
      );
    }

    final pendientes = tasks
        .where((t) => t.estado == TareaEstado.pendiente)
        .length;
    final enCurso = tasks.where((t) => t.estado == TareaEstado.enCurso).length;
    final finalizadas = tasks
        .where((t) => t.estado == TareaEstado.finalizada)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _SummaryItem(
                  count: pendientes,
                  label: 'Pendientes',
                  color: AppColors.accent,
                ),
              ),
              _Divider(),
              Expanded(
                child: _SummaryItem(
                  count: enCurso,
                  label: 'En curso',
                  color: AppColors.warning,
                ),
              ),
              _Divider(),
              Expanded(
                child: _SummaryItem(
                  count: finalizadas,
                  label: 'Completadas',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < tasks.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _TaskCard(task: tasks[i]),
        ],
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.count,
    required this.label,
    required this.color,
  });
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: AppColors.border);
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});
  final Tarea task;

  Color get _priorityColor => switch (task.prioridad) {
    TareaPrioridad.alta => AppColors.error,
    TareaPrioridad.media => AppColors.warning,
    TareaPrioridad.baja => AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        task.estado != TareaEstado.finalizada &&
        task.vencimiento.isBefore(DateTime(2026, 5, 29));
    final vencStr =
        '${task.vencimiento.day.toString().padLeft(2, '0')}/${task.vencimiento.month.toString().padLeft(2, '0')}';

    return AppCard(
      onTap: () => GoRouter.of(context).go('/mobile/tasks/${task.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: _priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.titulo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    StatusBadge.tarea(task.estado),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.direccion,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    StatusBadge(
                      label: task.prioridad.label,
                      color: _priorityColor,
                    ),
                    StatusBadge.sync(task.syncEstado),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      isOverdue
                          ? Icons.warning_amber_outlined
                          : Icons.calendar_today_outlined,
                      size: 12,
                      color: isOverdue
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Vence $vencStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontWeight: isOverdue
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
