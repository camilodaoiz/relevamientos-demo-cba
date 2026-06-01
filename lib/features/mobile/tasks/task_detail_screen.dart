import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/tarea.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // RF-024/RF-025: detalle de tarea y acceso a ejecucion del formulario.
    final store = ref.watch(demoStoreProvider);
    final task = store.tareaById(taskId);
    if (task == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: EmptyState(
          title: 'Tarea no encontrada',
          message: 'El registro solicitado no fue encontrado.',
        ),
      );
    }

    final survey = store.encuestaById(task.encuestaId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.titulo,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  StatusBadge.tarea(task.estado),
                ],
              ),
              const SizedBox(height: 12),
              _InfoLine(icon: Icons.place_outlined, label: task.direccion),
              _InfoLine(
                icon: Icons.calendar_today_outlined,
                label:
                    'Vence ${task.vencimiento.day}/${task.vencimiento.month}/${task.vencimiento.year}',
              ),
              _InfoLine(
                icon: Icons.dynamic_form_outlined,
                label: survey?.nombre ?? 'Sin encuesta asignada',
              ),
              const SizedBox(height: 14),
              StatusBadge.sync(task.syncEstado),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (task.estado == TareaEstado.finalizada)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Relevamiento completado',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Este relevamiento fue completado. Sincronizá desde la pestaña Sync para enviarlo al servidor.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Ir a sincronizar',
                  icon: Icons.sync,
                  onPressed: () => context.go('/mobile/sync'),
                ),
              ],
            ),
          )
        else if (task.estado == TareaEstado.devuelta)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.undo_outlined,
                      color: Color(0xFFEA580C),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Tarea devuelta al coordinador',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
                if (task.motivo != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Motivo: ${task.motivo}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          _RelevamientosCard(task: task),
      ],
    );
  }

}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _RelevamientosCard extends ConsumerWidget {
  const _RelevamientosCard({required this.task});
  final Tarea task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(demoStoreProvider);
    final relevamientos = store.relevamientosForTask(task.id);
    final completados = relevamientos.where((r) => r.completado).length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Relevamientos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (relevamientos.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$completados/${relevamientos.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            relevamientos.isEmpty
                ? 'Iniciá el primer relevamiento para este punto. Podés agregar tantos como necesites (ej: una encuesta por cama).'
                : 'Cada fila es un relevamiento individual completado en este punto.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (relevamientos.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final rel in relevamientos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: rel.completado
                        ? AppColors.success.withValues(alpha: 0.06)
                        : AppColors.muted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: rel.completado
                          ? AppColors.success.withValues(alpha: 0.25)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        rel.completado
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: rel.completado
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Relevamiento #${rel.numero}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (!rel.completado)
                        TextButton.icon(
                          onPressed: () =>
                              context.go('/mobile/form/${task.id}/${rel.id}'),
                          icon: const Icon(Icons.edit_note_outlined, size: 16),
                          label: const Text('Completar'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          AppButton(
            label: 'Nuevo relevamiento',
            icon: Icons.add,
            onPressed: () {
              final relId = ref.read(demoStoreProvider).addRelevamiento(task.id);
              context.go('/mobile/form/${task.id}/$relId');
            },
          ),
          if (relevamientos.isNotEmpty && completados > 0) ...[
            const SizedBox(height: 10),
            AppButton(
              label: 'Finalizar tarea',
              icon: Icons.check_circle_outline,
              onPressed: () {
                ref.read(demoStoreProvider).finishTaskLocal(task.id);
                context.go('/mobile/sync');
              },
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _showRejectDialog(context, ref, task.id),
            icon: const Icon(Icons.undo_outlined, size: 16),
            label: const Text('No puedo completar esta tarea'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEA580C),
              side: const BorderSide(color: Color(0xFFEA580C)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref, String taskId) async {
    String? motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => const _RejectDialog(),
    );
    if (motivo != null && context.mounted) {
      ref.read(demoStoreProvider).rejectTask(taskId, motivo);
    }
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Devolver tarea'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Indicá el motivo por el que no podés completar esta tarea.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ej: Dirección inaccesible, propietario ausente...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final motivo = _controller.text.trim();
            if (motivo.isNotEmpty) Navigator.of(context).pop(motivo);
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEA580C),
          ),
          child: const Text('Devolver tarea'),
        ),
      ],
    );
  }
}
