import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/campo_estandar.dart';
import '../../../core/models/encuesta.dart';
import '../../../core/models/pregunta.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';

class EncuestaDetailScreen extends ConsumerStatefulWidget {
  const EncuestaDetailScreen({super.key, required this.encuestaId});

  final String encuestaId;

  @override
  ConsumerState<EncuestaDetailScreen> createState() =>
      _EncuestaDetailScreenState();
}

class _EncuestaDetailScreenState extends ConsumerState<EncuestaDetailScreen> {
  bool _cidiLleno = false;
  bool _cidiLoading = false;

  // Valores demo pre-cargados para la preview del formulario
  static const _demoValues = <String, String>{
    'p-cuil': '20-12345678-9',
    'p-nombre': 'Ricardo',
    'p-apellido': 'Gomez',
    'p-dni': '12.345.678',
    'p-telefono': '(0351) 456-7890',
    'p-domicilio': 'Obispo Trejo 1040',
    'p-camas': '48',
    'p-habilitado': 'Sí',
    'p-estado': 'Bueno',
    'p-fecha': '29/05/2026',
  };

  // Campos que se autocompletan desde CIDI al ingresar el CUIL
  static const _cidiCampos = {'p-nombre', 'p-apellido', 'p-dni'};

  Future<void> _showRejectionDialog(
    BuildContext context,
    WidgetRef ref,
    Encuesta survey,
    DemoStore store,
  ) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Rechazar encuesta'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Indicá el motivo del rechazo. El Diseñador recibirá esta observación para realizar correcciones.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones *',
                    hintText:
                        'Ej: Faltan campos estándar obligatorios del catálogo RF-007...',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) => setSt(() {}),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: controller.text.trim().isNotEmpty
                  ? () => Navigator.pop(ctx, true)
                  : null,
              icon: const Icon(Icons.cancel_outlined, size: 15),
              label: const Text('Rechazar'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      store.addComentarioEncuesta(
        encuestaId: survey.id,
        objetivoId: survey.secciones.first,
        objetivoLabel: 'Sección: ${survey.secciones.first}',
        mensaje: controller.text.trim(),
      );
      store.transitionEncuesta(survey.id, EncuestaEstado.rechazada);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✗ Encuesta rechazada — Observación enviada al Diseñador: "${controller.text.trim()}"',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
    controller.dispose();
  }

  Future<void> _showComentarioDialog(
    BuildContext context,
    Encuesta survey,
    DemoStore store,
  ) async {
    final controller = TextEditingController();
    final targets = [
      for (final section in survey.secciones)
        (id: section, label: 'Sección: $section'),
      for (final pregunta in survey.preguntas)
        (id: pregunta.id, label: 'Pregunta: ${pregunta.texto}'),
    ];
    var target = targets.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Agregar observación'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<({String id, String label})>(
                  initialValue: target,
                  decoration: const InputDecoration(
                    labelText: 'Pregunta o sección observada',
                  ),
                  items: [
                    for (final option in targets)
                      DropdownMenuItem(
                        value: option,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => target = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Comentario del validador',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.add_comment_outlined, size: 16),
              label: const Text('Guardar observación'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      store.addComentarioEncuesta(
        encuestaId: survey.id,
        objetivoId: target.id,
        objetivoLabel: target.label,
        mensaje: controller.text.trim(),
      );
    }
    controller.dispose();
  }

  Future<void> _showRespuestaDialog(
    BuildContext context,
    DemoStore store,
    ComentarioEncuesta comentario,
  ) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Responder observación'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Respuesta del diseñador',
              alignLabelWithHint: true,
            ),
            onChanged: (_) => setDialogState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Responder'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      store.responderComentario(comentario.id, controller.text.trim());
    }
    controller.dispose();
  }

  Future<void> _autocomplete() async {
    setState(() => _cidiLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _cidiLoading = false;
      _cidiLleno = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '✓ Datos obtenidos desde CIDI  ·  Ricardo Gomez (DNI 12.345.678)',
        ),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(demoStoreProvider);
    final rolId = store.currentUser.rolId;
    final survey = store.encuestaById(widget.encuestaId);
    if (survey == null) {
      return const EmptyState(
        title: 'Encuesta no encontrada',
        message: 'El registro solicitado no fue encontrado.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: survey.nombre,
          subtitle: '${survey.organismo} · version ${survey.version}',
          action: AppButton(
            label: 'Abrir editor',
            icon: Icons.view_column_outlined,
            onPressed: () =>
                context.go('/backoffice/encuestas/${survey.id}/builder'),
            variant: AppButtonVariant.secondary,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final comments = store.comentariosDe(survey.id);
            final versions = store.versionesDe(survey.id);
            final commentsPanel = _ComentariosPanel(
              comentarios: comments,
              rolId: rolId,
              onAdd: rolId == 'R-04'
                  ? () => _showComentarioDialog(context, survey, store)
                  : null,
              onReply: (comentario) =>
                  _showRespuestaDialog(context, store, comentario),
              onResolve: store.resolverComentario,
            );
            final versionsPanel = _VersionesPanel(versiones: versions);
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: commentsPanel),
                  const SizedBox(width: 18),
                  Expanded(flex: 2, child: versionsPanel),
                ],
              );
            }
            return Column(
              children: [
                commentsPanel,
                const SizedBox(height: 14),
                versionsPanel,
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Preguntas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  StatusBadge.encuesta(survey.estado),
                ],
              ),
              const SizedBox(height: 16),
              for (final section in survey.secciones) ...[
                _SectionDivider(label: section),
                const SizedBox(height: 10),
                for (final question in survey.preguntas.where(
                  (q) => q.seccion == section,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FormFieldItem(
                      pregunta: question,
                      demoValue: _demoValues[question.id],
                      cidiLleno: _cidiLleno,
                      cidiLoading: _cidiLoading,
                      esCidiCampo: _cidiCampos.contains(question.id),
                      onAutocomplete: question.autocompletaCidi
                          ? _autocomplete
                          : null,
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              const Divider(height: 24),
              ..._actionsFor(context, ref, survey, rolId),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _actionsFor(
    BuildContext context,
    WidgetRef ref,
    Encuesta survey,
    String rolId,
  ) {
    final store = ref.read(demoStoreProvider);
    switch (survey.estado) {
      case EncuestaEstado.borrador:
        if (rolId == 'R-03') {
          return [
            AppButton(
              label: 'Enviar a revision',
              icon: Icons.send_outlined,
              onPressed: () => store.transitionEncuesta(
                survey.id,
                EncuestaEstado.enRevision,
              ),
            ),
          ];
        }
        return [
          const _WaitingChip(
            mensaje: 'El Disenador de Encuestas debe enviar a revision',
          ),
        ];
      case EncuestaEstado.enRevision:
        if (rolId == 'R-04') {
          return [
            AppButton(
              label: 'Aprobar',
              icon: Icons.check_circle_outline,
              onPressed: () {
                store.transitionEncuesta(survey.id, EncuestaEstado.aprobada);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '✓ Encuesta aprobada — el Administrador puede publicarla',
                    ),
                    backgroundColor: AppColors.success,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Rechazar con observaciones',
              icon: Icons.cancel_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () =>
                  _showRejectionDialog(context, ref, survey, store),
            ),
          ];
        }
        return [
          const _WaitingChip(
            mensaje: 'El Validador / Controlador debe aprobar o rechazar',
          ),
        ];
      case EncuestaEstado.aprobada:
        if (rolId == 'R-01' || rolId == 'R-02') {
          return [
            AppButton(
              label: 'Publicar',
              icon: Icons.publish_outlined,
              onPressed: () =>
                  store.transitionEncuesta(survey.id, EncuestaEstado.publicada),
            ),
          ];
        }
        return [
          const _WaitingChip(
            mensaje: 'El Administrador debe publicar la encuesta',
          ),
        ];
      case EncuestaEstado.publicada:
        return [
          const StatusBadge(
            label: 'Disponible para tareas',
            color: AppColors.success,
          ),
        ];
      case EncuestaEstado.rechazada:
        if (rolId == 'R-03' || rolId == 'R-04') {
          return [
            AppButton(
              label: 'Volver a borrador',
              icon: Icons.undo,
              variant: AppButtonVariant.secondary,
              onPressed: () =>
                  store.transitionEncuesta(survey.id, EncuestaEstado.borrador),
            ),
          ];
        }
        return [
          const _WaitingChip(mensaje: 'El Disenador puede volver a borrador'),
        ];
    }
  }
}

// ─── FORM FIELD ITEM ───────────────────────────────────────────────────────────

class _FormFieldItem extends StatelessWidget {
  const _FormFieldItem({
    required this.pregunta,
    required this.demoValue,
    required this.cidiLleno,
    required this.cidiLoading,
    required this.esCidiCampo,
    this.onAutocomplete,
  });

  final Pregunta pregunta;
  final String? demoValue;
  final bool cidiLleno;
  final bool cidiLoading;
  final bool esCidiCampo;
  final VoidCallback? onAutocomplete;

  @override
  Widget build(BuildContext context) {
    final relleno = esCidiCampo && cidiLleno;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: relleno
              ? AppColors.success.withValues(alpha: 0.30)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Icon(
                pregunta.esCampoEstandar
                    ? Icons.verified_outlined
                    : Icons.edit_note_outlined,
                color: relleno ? AppColors.success : AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pregunta.texto,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              if (pregunta.obligatoria)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (pregunta.soloLectura && cidiLleno)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              // CIDI button / indicator
              if (pregunta.autocompletaCidi) ...[
                const SizedBox(width: 8),
                if (!cidiLleno)
                  SizedBox(
                    height: 28,
                    child: FilledButton.icon(
                      onPressed: cidiLoading ? null : onAutocomplete,
                      icon: cidiLoading
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_search_outlined, size: 14),
                      label: Text(
                        cidiLoading ? 'Buscando...' : 'Autocompletar CIDI',
                        style: const TextStyle(fontSize: 11),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'CIDI',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Value display
          _buildValue(context),
        ],
      ),
    );
  }

  Widget _buildValue(BuildContext context) {
    // Campo CIDI pendiente de completar
    if (esCidiCampo && !cidiLleno) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Se completará con datos de CIDI',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final value = demoValue ?? '';

    switch (pregunta.tipo) {
      case CampoTipo.booleano:
        return Row(
          children: [
            _RadioOption(label: 'Sí', selected: true),
            const SizedBox(width: 10),
            _RadioOption(label: 'No', selected: false),
          ],
        );

      case CampoTipo.seleccion:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        );

      case CampoTipo.fecha:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );

      case CampoTipo.numerico:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Text(
                '123',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );

      default: // texto
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: esCidiCampo && cidiLleno
                  ? AppColors.success.withValues(alpha: 0.40)
                  : AppColors.border,
            ),
          ),
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        );
    }
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.success.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected
              ? AppColors.success.withValues(alpha: 0.40)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 15,
            color: selected ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

// RF-013: comentarios del Validador, respuestas del Diseñador e historial.
class _ComentariosPanel extends StatelessWidget {
  const _ComentariosPanel({
    required this.comentarios,
    required this.rolId,
    required this.onAdd,
    required this.onReply,
    required this.onResolve,
  });

  final List<ComentarioEncuesta> comentarios;
  final String rolId;
  final VoidCallback? onAdd;
  final ValueChanged<ComentarioEncuesta> onReply;
  final ValueChanged<String> onResolve;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rate_review_outlined,
                size: 19,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Observaciones de revisión',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (onAdd != null)
                OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_comment_outlined, size: 16),
                  label: const Text('Agregar'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (comentarios.isEmpty)
            Text(
              'Sin observaciones registradas.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (var index = 0; index < comentarios.length; index++) ...[
              _ComentarioRow(
                comentario: comentarios[index],
                rolId: rolId,
                onReply: () => onReply(comentarios[index]),
                onResolve: () => onResolve(comentarios[index].id),
              ),
              if (index < comentarios.length - 1) const Divider(height: 22),
            ],
        ],
      ),
    );
  }
}

class _ComentarioRow extends StatelessWidget {
  const _ComentarioRow({
    required this.comentario,
    required this.rolId,
    required this.onReply,
    required this.onResolve,
  });

  final ComentarioEncuesta comentario;
  final String rolId;
  final VoidCallback onReply;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                comentario.objetivoLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            StatusBadge(
              label: comentario.resuelto ? 'Resuelto' : 'Pendiente',
              color: comentario.resuelto
                  ? AppColors.success
                  : AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(comentario.mensaje, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          '${comentario.autor} · ${comentario.fecha}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (comentario.respuestas.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final respuesta in comentario.respuestas)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '↳ $respuesta',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
              ),
            ),
        ],
        if (rolId == 'R-03' && !comentario.resuelto) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: onReply,
                icon: const Icon(Icons.reply_outlined, size: 15),
                label: const Text('Responder'),
              ),
              TextButton.icon(
                onPressed: onResolve,
                icon: const Icon(Icons.check_outlined, size: 15),
                label: const Text('Marcar resuelto'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// RF-006: timeline de publicaciones inmutables.
class _VersionesPanel extends StatelessWidget {
  const _VersionesPanel({required this.versiones});
  final List<EncuestaVersionEntry> versiones;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_outlined,
                size: 19,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Historial de versiones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (versiones.isEmpty)
            Text(
              'Todavía no existen publicaciones inmutables.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (var index = 0; index < versiones.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: index == 0
                          ? AppColors.accent
                          : AppColors.muted,
                      child: Text(
                        'v${versiones[index].version}',
                        style: TextStyle(
                          color: index == 0
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            versiones[index].resumen,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${versiones[index].fecha} · ${versiones[index].autor}',
                            style: Theme.of(context).textTheme.bodySmall,
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

// ─── SHARED WIDGETS ────────────────────────────────────────────────────────────

class _WaitingChip extends StatelessWidget {
  const _WaitingChip({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_empty_outlined,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowLine extends StatelessWidget {
  const _WorkflowLine({required this.estado});

  final EncuestaEstado estado;

  @override
  Widget build(BuildContext context) {
    final states = [
      EncuestaEstado.borrador,
      EncuestaEstado.enRevision,
      EncuestaEstado.aprobada,
      EncuestaEstado.publicada,
    ];
    final currentIndex = states.indexOf(estado);

    return Column(
      children: [
        for (var index = 0; index < states.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: index <= currentIndex
                      ? AppColors.accent
                      : AppColors.border,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  states[index].label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
