import 'package:flutter/material.dart';

import '../models/encuesta.dart';
import '../models/tarea.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.encuesta(EncuestaEstado estado) {
    return StatusBadge(label: estado.label, color: _surveyColor(estado));
  }

  factory StatusBadge.tarea(TareaEstado estado) {
    return StatusBadge(label: estado.label, color: _taskColor(estado));
  }

  factory StatusBadge.sync(SyncEstado estado) {
    return StatusBadge(
      label: estado.label,
      color: _syncColor(estado),
      icon: estado == SyncEstado.sincronizado
          ? Icons.check_circle_outline
          : null,
    );
  }

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _surveyColor(EncuestaEstado estado) {
  switch (estado) {
    case EncuestaEstado.publicada:
      return AppColors.success;
    case EncuestaEstado.aprobada:
      return AppColors.accent;
    case EncuestaEstado.enRevision:
      return AppColors.warning;
    case EncuestaEstado.rechazada:
      return AppColors.error;
    case EncuestaEstado.borrador:
      return AppColors.textSecondary;
  }
}

Color _taskColor(TareaEstado estado) {
  switch (estado) {
    case TareaEstado.finalizada:
      return AppColors.success;
    case TareaEstado.enCurso:
      return AppColors.warning;
    case TareaEstado.pendiente:
      return AppColors.accent;
    case TareaEstado.devuelta:
      return const Color(0xFFEA580C);
  }
}

Color _syncColor(SyncEstado estado) {
  switch (estado) {
    case SyncEstado.sincronizado:
      return AppColors.success;
    case SyncEstado.sincronizando:
      return AppColors.accent;
    case SyncEstado.error:
      return AppColors.error;
    case SyncEstado.local:
      return AppColors.warning;
  }
}
