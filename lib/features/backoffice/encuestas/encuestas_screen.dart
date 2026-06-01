import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/encuesta.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';

// RF-005: Resultado del diálogo lleva el nombre y la plantilla opcional.
class _NuevaEncuestaResult {
  const _NuevaEncuestaResult(this.nombre, {this.templateId});
  final String nombre;
  final String? templateId;
}

// ─── Dialog for creating a new survey (RF-005: templates) ──────────────────────

class _NuevaEncuestaDialog extends ConsumerStatefulWidget {
  const _NuevaEncuestaDialog();

  @override
  ConsumerState<_NuevaEncuestaDialog> createState() =>
      _NuevaEncuestaDialogState();
}

class _NuevaEncuestaDialogState extends ConsumerState<_NuevaEncuestaDialog> {
  final _controller = TextEditingController();
  bool _valid = false;
  String? _templateId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plantillas = ref
        .watch(demoStoreProvider)
        .encuestas
        .where(
          (e) =>
              e.estado == EncuestaEstado.publicada ||
              e.estado == EncuestaEstado.aprobada,
        )
        .toList();

    return AlertDialog(
      title: const Text('Nueva encuesta'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresá el nombre del formulario. Se creará en estado borrador.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Ej: Relevamiento sanitario 2026',
              ),
              autofocus: true,
              onChanged: (v) => setState(() => _valid = v.trim().isNotEmpty),
              onSubmitted: (v) {
                if (_valid) {
                  Navigator.pop(
                    context,
                    _NuevaEncuestaResult(v.trim(), templateId: _templateId),
                  );
                }
              },
            ),
            const SizedBox(height: 14),
            // RF-005: selección de plantilla
            DropdownButtonFormField<String?>(
              initialValue: _templateId,
              decoration: const InputDecoration(
                labelText: 'Usar plantilla (opcional)',
                prefixIcon: Icon(Icons.copy_outlined),
              ),
              hint: const Text('Encuesta en blanco'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sin plantilla — encuesta en blanco'),
                ),
                for (final e in plantillas)
                  DropdownMenuItem<String?>(
                    value: e.id,
                    child: Text(
                      '${e.nombre} (${e.preguntas.length} preguntas)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _templateId = v),
            ),
            if (_templateId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 13, color: AppColors.accent),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Las preguntas se copiarán. Podrás editarlas sin afectar la original.',
                        style: TextStyle(fontSize: 11, color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Organismo: Ministerio de Salud Pública · Estado inicial: Borrador',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _valid
              ? () => Navigator.pop(
                  context,
                  _NuevaEncuestaResult(
                    _controller.text.trim(),
                    templateId: _templateId,
                  ),
                )
              : null,
          icon: const Icon(Icons.add, size: 15),
          label: const Text('Crear y diseñar'),
        ),
      ],
    );
  }
}

class EncuestasScreen extends ConsumerStatefulWidget {
  const EncuestasScreen({super.key});

  @override
  ConsumerState<EncuestasScreen> createState() => _EncuestasScreenState();
}

class _EncuestasScreenState extends ConsumerState<EncuestasScreen> {
  String query = '';

  Future<void> _showNuevaEncuestaDialog(BuildContext context) async {
    final result = await showDialog<_NuevaEncuestaResult>(
      context: context,
      builder: (_) => const _NuevaEncuestaDialog(),
    );
    if (result != null && mounted) {
      final store = ref.read(demoStoreProvider);
      final newId = result.templateId != null
          ? store.createEncuestaDesdeTemplate(result.nombre, result.templateId!)
          : store.createEncuesta(result.nombre);
      if (context.mounted) {
        context.go('/backoffice/encuestas/$newId/builder');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // RF-001/RF-007/RF-011: listado de encuestas y catalogo de campos estandar.
    final store = ref.watch(demoStoreProvider);
    final rolId = store.currentUser.rolId;
    final filtered = store.encuestas
        .where(
          (encuesta) =>
              encuesta.nombre.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rolId == 'R-03' || rolId == 'R-04') ...[
          _EncuestaRolNotice(rolId: rolId),
          const SizedBox(height: 16),
        ] else if (rolId == 'R-02' || rolId == 'R-01') ...[
          _PublicarNotice(store: store),
          const SizedBox(height: 16),
        ],
        SectionHeader(
          title: rolId == 'R-04' ? 'Encuestas para revision' : 'Encuestas',
          subtitle: rolId == 'R-03'
              ? 'Diseña tus formularios y envialos a revision cuando esten listos.'
              : rolId == 'R-04'
              ? 'Revisa las encuestas enviadas por el Disenador y aprueba o rechaza.'
              : 'Diseno, versionado y ciclo de vida del formulario.',
          action: rolId == 'R-03'
              ? FilledButton.icon(
                  onPressed: () => _showNuevaEncuestaDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nueva encuesta'),
                )
              : null,
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar encuesta',
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 14),
        AppDataTable(
          columns: const ['Nombre', 'Estado', 'Version', 'Preguntas', 'Accion'],
          rows: [
            for (final survey in filtered)
              [
                Text(survey.nombre),
                StatusBadge.encuesta(survey.estado),
                Text('v${survey.version}'),
                Text('${survey.preguntas.length}'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionButton(
                      context,
                      survey,
                      rolId,
                      onPublish:
                          (rolId == 'R-01' || rolId == 'R-02') &&
                              survey.estado == EncuestaEstado.aprobada
                          ? () {
                              ref
                                  .read(demoStoreProvider)
                                  .transitionEncuesta(
                                    survey.id,
                                    EncuestaEstado.publicada,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '✓ "${survey.nombre}" publicada — ya puede usarse en tareas de campo.',
                                  ),
                                  backgroundColor: AppColors.success,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          : null,
                    ),
                    if (rolId == 'R-03' &&
                        survey.estado == EncuestaEstado.borrador) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar encuesta'),
                              content: Text(
                                '¿Eliminar "${survey.nombre}"? Esta acción no se puede deshacer.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            ref
                                .read(demoStoreProvider)
                                .deleteEncuesta(survey.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✓ "${survey.nombre}" eliminada.',
                                ),
                                backgroundColor: AppColors.error,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppColors.error.withValues(alpha: 0.70),
                        tooltip: 'Eliminar encuesta',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
              ],
          ],
        ),
      ],
    );
  }
}

Widget _actionButton(
  BuildContext context,
  Encuesta survey,
  String rolId, {
  VoidCallback? onPublish,
}) {
  if (onPublish != null) {
    return FilledButton.icon(
      onPressed: onPublish,
      icon: const Icon(Icons.publish_outlined, size: 15),
      label: const Text('Publicar'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.success,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  final isActionable =
      (rolId == 'R-03' && survey.estado == EncuestaEstado.borrador) ||
      (rolId == 'R-04' && survey.estado == EncuestaEstado.enRevision);

  if (isActionable) {
    final route = rolId == 'R-03'
        ? '/backoffice/encuestas/${survey.id}/builder'
        : '/backoffice/encuestas/${survey.id}';
    return FilledButton.icon(
      onPressed: () => context.go(route),
      icon: Icon(
        rolId == 'R-04' ? Icons.rate_review : Icons.edit_outlined,
        size: 15,
      ),
      label: Text(rolId == 'R-04' ? 'Revisar' : 'Editar'),
      style: FilledButton.styleFrom(
        backgroundColor: rolId == 'R-04' ? AppColors.warning : AppColors.accent,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  return TextButton.icon(
    onPressed: () => context.go('/backoffice/encuestas/${survey.id}'),
    icon: const Icon(Icons.open_in_new, size: 16),
    label: const Text('Abrir'),
  );
}

class _PublicarNotice extends StatelessWidget {
  const _PublicarNotice({required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final aprobadas = store.encuestas
        .where((e) => e.estado == EncuestaEstado.aprobada)
        .length;
    if (aprobadas == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.publish_outlined,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$aprobadas encuesta${aprobadas != 1 ? 's' : ''} aprobada${aprobadas != 1 ? 's' : ''} esperando publicación — usá el botón "Publicar" en la tabla.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EncuestaRolNotice extends StatelessWidget {
  const _EncuestaRolNotice({required this.rolId});
  final String rolId;

  @override
  Widget build(BuildContext context) {
    final (message, color, icon) = rolId == 'R-03'
        ? (
            'Solo podes actuar sobre encuestas en borrador. Abrí una para enviarla a revision.',
            AppColors.accent,
            Icons.article_outlined,
          )
        : (
            'Solo podes aprobar o rechazar encuestas en revision. Las demas son de solo lectura.',
            AppColors.warning,
            Icons.rate_review,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
