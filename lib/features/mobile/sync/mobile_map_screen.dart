import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';

class MobileMapScreen extends ConsumerWidget {
  const MobileMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // RF-024/RF-027: vista de mapa simple sin GIS avanzado ni capas WMS/WFS.
    final tasks = ref.watch(demoStoreProvider).inspectorTasks;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _SimpleMapPainter()),
                ),
                for (var index = 0; index < tasks.length; index++)
                  Positioned(
                    left: 34.0 + (index % 3) * 78,
                    top: 48.0 + (index ~/ 3) * 86,
                    child: Tooltip(
                      message: tasks[index].titulo,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.error,
                        size: 34,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final task in tasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => context.go('/mobile/tasks/${task.id}'),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.place_outlined,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.titulo,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task.direccion,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge.tarea(task.estado),
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SimpleMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final minorPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2;

    for (var y = 32.0; y < size.height; y += 54) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 18), minorPaint);
    }
    canvas.drawLine(
      Offset(20, size.height * .22),
      Offset(size.width - 24, size.height * .72),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * .65, 18),
      Offset(size.width * .22, size.height - 18),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
