import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/campo_estandar.dart';
import '../../../core/models/encuesta.dart';
import '../../../core/models/pregunta.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';

// ─── Question-type catalog shown in the left panel ─────────────────────────────

class _QType {
  const _QType({
    required this.label,
    required this.icon,
    required this.tipo,
    this.opciones = const [],
  });
  final String label;
  final IconData icon;
  final CampoTipo tipo;
  final List<String> opciones;
}

class _QCategory {
  const _QCategory({required this.name, required this.types});
  final String name;
  final List<_QType> types;
}

const _categories = [
  _QCategory(
    name: 'Texto',
    types: [
      _QType(
        label: 'Texto corto',
        icon: Icons.short_text,
        tipo: CampoTipo.texto,
      ),
      _QType(
        label: 'Texto largo',
        icon: Icons.notes_outlined,
        tipo: CampoTipo.texto,
      ),
    ],
  ),
  _QCategory(
    name: 'Numéricos',
    types: [_QType(label: 'Número', icon: Icons.tag, tipo: CampoTipo.numerico)],
  ),
  _QCategory(
    name: 'Selección',
    types: [
      _QType(
        label: 'Opción única',
        icon: Icons.radio_button_checked_outlined,
        tipo: CampoTipo.seleccion,
        opciones: ['Opción A', 'Opción B', 'Opción C'],
      ),
      _QType(
        label: 'Múltiple opción',
        icon: Icons.check_box_outlined,
        tipo: CampoTipo.seleccion,
        opciones: ['Opción A', 'Opción B', 'Opción C'],
      ),
    ],
  ),
  _QCategory(
    name: 'Fecha y captura',
    types: [
      _QType(
        label: 'Fecha',
        icon: Icons.calendar_today_outlined,
        tipo: CampoTipo.fecha,
      ),
      _QType(
        label: 'Sí / No',
        icon: Icons.toggle_on_outlined,
        tipo: CampoTipo.booleano,
      ),
    ],
  ),
];

// ─── Screen ────────────────────────────────────────────────────────────────────

class EncuestaBuilderScreen extends ConsumerStatefulWidget {
  const EncuestaBuilderScreen({super.key, required this.encuestaId});

  final String encuestaId;

  @override
  ConsumerState<EncuestaBuilderScreen> createState() =>
      _EncuestaBuilderScreenState();
}

class _EncuestaBuilderScreenState extends ConsumerState<EncuestaBuilderScreen> {
  String? _activeSection;
  bool _saving = false;

  void _addType(_QType type, String section) {
    final store = ref.read(demoStoreProvider);
    final id = 'p-custom-${DateTime.now().millisecondsSinceEpoch}';
    store.addQuestionToSurvey(
      widget.encuestaId,
      Pregunta(
        id: id,
        texto: type.label,
        tipo: type.tipo,
        seccion: section,
        obligatoria: false,
        opciones: type.opciones,
      ),
    );
    _flashSaving();
  }

  void _addCatalogField(CampoEstandar campo, String section) {
    final store = ref.read(demoStoreProvider);
    store.addCatalogFieldToSurvey(widget.encuestaId, campo, section: section);
    _flashSaving();
  }

  Future<void> _showAddSectionDialog() async {
    final controller = TextEditingController();
    final section = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva sección'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre de la sección',
            hintText: 'Ej: Observaciones finales',
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (section == null || section.isEmpty) return;
    ref.read(demoStoreProvider).addSectionToSurvey(widget.encuestaId, section);
    setState(() => _activeSection = section);
    _flashSaving();
  }

  Future<void> _showDeliveryConfigDialog() async {
    final store = ref.read(demoStoreProvider);
    final result =
        await showDialog<({Set<String> evidencias, Set<String> destinatarios})>(
          context: context,
          builder: (_) => _DeliveryConfigDialog(
            evidencias: store.evidenciasDe(widget.encuestaId),
            destinatarios: store.destinatariosDe(widget.encuestaId),
          ),
        );
    if (result == null) return;
    store.updateEncuestaDeliveryConfig(
      widget.encuestaId,
      evidencias: result.evidencias,
      destinatarios: result.destinatarios,
    );
    _flashSaving();
  }

  void _removeQuestion(String preguntaId) {
    ref
        .read(demoStoreProvider)
        .removeQuestionFromSurvey(widget.encuestaId, preguntaId);
    _flashSaving();
  }

  Future<void> _showCondicionalDialog(
    Pregunta pregunta,
    List<Pregunta> allQuestions,
  ) async {
    final result = await showDialog<({String? campoId, String? valor})>(
      context: context,
      builder: (ctx) =>
          _CondicionalDialog(pregunta: pregunta, allQuestions: allQuestions),
    );
    if (result != null) {
      ref
          .read(demoStoreProvider)
          .updatePreguntaCondicion(
            widget.encuestaId,
            pregunta.id,
            result.campoId,
            result.valor,
          );
      _flashSaving();
    }
  }

  Future<void> _showValidacionDialog(Pregunta pregunta) async {
    final result =
        await showDialog<
          ({
            int? longitudMinima,
            int? longitudMaxima,
            num? valorMinimo,
            num? valorMaximo,
            String? mensaje,
          })
        >(
          context: context,
          builder: (ctx) => _ValidacionDialog(pregunta: pregunta),
        );
    if (result == null) return;
    ref
        .read(demoStoreProvider)
        .updatePreguntaValidaciones(
          widget.encuestaId,
          pregunta.id,
          longitudMinima: result.longitudMinima,
          longitudMaxima: result.longitudMaxima,
          valorMinimo: result.valorMinimo,
          valorMaximo: result.valorMaximo,
          mensajeValidacion: result.mensaje,
        );
    _flashSaving();
  }

  Future<void> _flashSaving() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _saving = false);
  }

  void _enviarARevision() {
    ref
        .read(demoStoreProvider)
        .transitionEncuesta(widget.encuestaId, EncuestaEstado.enRevision);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Encuesta enviada a revisión — el Validador recibirá una notificación',
        ),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 3),
      ),
    );
    context.go('/backoffice/encuestas');
  }

  @override
  Widget build(BuildContext context) {
    // RF-001/RF-002/RF-003/RF-007: builder visual con catálogo estandar.
    final store = ref.watch(demoStoreProvider);
    final rolId = store.currentUser.rolId;
    final survey = store.encuestaById(widget.encuestaId);
    if (survey == null) {
      return const EmptyState(
        title: 'Encuesta no encontrada',
        message: 'El registro solicitado no fue encontrado.',
      );
    }

    final activeSection = _activeSection ?? survey.secciones.firstOrNull ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Builder header ──────────────────────────────────────────────────
        _BuilderHeader(
          survey: survey,
          saving: _saving,
          rolId: rolId,
          onConfigureDelivery: _showDeliveryConfigDialog,
          onEnviarARevision:
              (survey.estado == EncuestaEstado.borrador && rolId == 'R-03')
              ? _enviarARevision
              : null,
        ),
        const SizedBox(height: 18),
        _DeliveryConfigSummary(
          evidencias: store.evidenciasDe(widget.encuestaId),
          destinatarios: store.destinatariosDe(widget.encuestaId),
          onConfigure: _showDeliveryConfigDialog,
        ),
        const SizedBox(height: 18),
        // ── Two-column layout ───────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: question type panel
            SizedBox(
              width: 270,
              child: _TypePanel(
                camposEstandar: store.camposEstandar,
                activeSection: activeSection,
                onAddType: _addType,
                onAddCatalog: _addCatalogField,
              ),
            ),
            const SizedBox(width: 18),
            // Right: design canvas
            Expanded(
              child: _DesignCanvas(
                survey: survey,
                activeSection: activeSection,
                onSelectSection: (s) => setState(() => _activeSection = s),
                onRemoveQuestion: _removeQuestion,
                onSetCondicion: (p) =>
                    _showCondicionalDialog(p, survey.preguntas),
                onSetValidacion: _showValidacionDialog,
                onAddSection: _showAddSectionDialog,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Builder header ─────────────────────────────────────────────────────────────

class _BuilderHeader extends StatelessWidget {
  const _BuilderHeader({
    required this.survey,
    required this.saving,
    required this.rolId,
    required this.onConfigureDelivery,
    this.onEnviarARevision,
  });
  final Encuesta survey;
  final bool saving;
  final String rolId;
  final VoidCallback onConfigureDelivery;
  final VoidCallback? onEnviarARevision;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diseñador de encuesta',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    survey.nombre,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusBadge.encuesta(survey.estado),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AnimatedOpacity(
          opacity: saving ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Guardando...',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.success),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: onConfigureDelivery,
          icon: const Icon(Icons.tune_outlined, size: 16),
          label: const Text('Configurar entrega'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => context.go('/backoffice/encuestas/${survey.id}'),
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: const Text('Vista previa'),
        ),
        const SizedBox(width: 8),
        if (onEnviarARevision != null)
          FilledButton.icon(
            onPressed: onEnviarARevision,
            icon: const Icon(Icons.send_outlined, size: 16),
            label: const Text('Enviar a revisión'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          ),
      ],
    );
  }
}

class _DeliveryConfigSummary extends StatelessWidget {
  const _DeliveryConfigSummary({
    required this.evidencias,
    required this.destinatarios,
    required this.onConfigure,
  });

  final Set<String> evidencias;
  final Set<String> destinatarios;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    // RF-026/RF-028: evidencias requeridas y destinatarios del relevamiento.
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.fact_check_outlined, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrega en campo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Evidencias: ${evidencias.isEmpty ? 'sin requisitos' : evidencias.join(', ')} · Destinatarios: ${destinatarios.isEmpty ? 'sin destinatarios' : destinatarios.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onConfigure,
            tooltip: 'Configurar entrega',
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}

class _DeliveryConfigDialog extends StatefulWidget {
  const _DeliveryConfigDialog({
    required this.evidencias,
    required this.destinatarios,
  });

  final Set<String> evidencias;
  final Set<String> destinatarios;

  @override
  State<_DeliveryConfigDialog> createState() => _DeliveryConfigDialogState();
}

class _DeliveryConfigDialogState extends State<_DeliveryConfigDialog> {
  late final Set<String> _evidencias = Set.of(widget.evidencias);
  late final Set<String> _destinatarios = Set.of(widget.destinatarios);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar entrega en campo'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evidencias requeridas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final option in const ['Foto', 'GPS', 'Firma'])
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _evidencias.contains(option),
                title: Text(option),
                onChanged: (selected) => setState(() {
                  if (selected == true) {
                    _evidencias.add(option);
                  } else {
                    _evidencias.remove(option);
                  }
                }),
              ),
            const Divider(height: 24),
            Text(
              'Destinatarios',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final option in const [
              'Coordinador de Campo',
              'Administrador de Organismo',
            ])
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _destinatarios.contains(option),
                title: Text(option),
                onChanged: (selected) => setState(() {
                  if (selected == true) {
                    _destinatarios.add(option);
                  } else {
                    _destinatarios.remove(option);
                  }
                }),
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
          onPressed: () => Navigator.pop(context, (
            evidencias: _evidencias,
            destinatarios: _destinatarios,
          )),
          icon: const Icon(Icons.save_outlined, size: 16),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ─── Left panel: question types + catalog ──────────────────────────────────────

class _TypePanel extends StatelessWidget {
  const _TypePanel({
    required this.camposEstandar,
    required this.activeSection,
    required this.onAddType,
    required this.onAddCatalog,
  });
  final List<CampoEstandar> camposEstandar;
  final String activeSection;
  final void Function(_QType, String) onAddType;
  final void Function(CampoEstandar, String) onAddCatalog;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipos de preguntas',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Clic para agregar a la sección activa',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          for (final cat in _categories) ...[
            _CategorySection(
              category: cat,
              activeSection: activeSection,
              onAddType: onAddType,
            ),
            const SizedBox(height: 10),
          ],
          const Divider(height: 24),
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 14,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                'Catálogo RF-007',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Campos estandarizados del sistema',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          for (final campo in camposEstandar)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _CatalogTypeButton(
                campo: campo,
                activeSection: activeSection,
                onTap: onAddCatalog,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.activeSection,
    required this.onAddType,
  });
  final _QCategory category;
  final String activeSection;
  final void Function(_QType, String) onAddType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        for (final type in category.types)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _TypeButton(
              type: type,
              activeSection: activeSection,
              onTap: onAddType,
            ),
          ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.type,
    required this.activeSection,
    required this.onTap,
  });
  final _QType type;
  final String activeSection;
  final void Function(_QType, String) onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(type, activeSection),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(type.icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                type.label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.add, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _CatalogTypeButton extends StatelessWidget {
  const _CatalogTypeButton({
    required this.campo,
    required this.activeSection,
    required this.onTap,
  });
  final CampoEstandar campo;
  final String activeSection;
  final void Function(CampoEstandar, String) onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(campo, activeSection),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.04),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.20)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_outlined,
              size: 13,
              color: AppColors.success,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                campo.etiqueta,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.success,
                ),
              ),
            ),
            const Icon(Icons.add, size: 13, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}

// ─── Right: design canvas ───────────────────────────────────────────────────────

class _DesignCanvas extends StatelessWidget {
  const _DesignCanvas({
    required this.survey,
    required this.activeSection,
    required this.onSelectSection,
    required this.onRemoveQuestion,
    required this.onSetCondicion,
    required this.onSetValidacion,
    required this.onAddSection,
  });
  final Encuesta survey;
  final String activeSection;
  final ValueChanged<String> onSelectSection;
  final ValueChanged<String> onRemoveQuestion;
  final ValueChanged<Pregunta> onSetCondicion;
  final ValueChanged<Pregunta> onSetValidacion;
  final VoidCallback onAddSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Row(
            children: [
              const Icon(
                Icons.dynamic_form_outlined,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  survey.nombre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${survey.preguntas.length} preguntas',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final section in survey.secciones)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _SectionCard(
              section: section,
              questions: survey.preguntas
                  .where((q) => q.seccion == section)
                  .toList(),
              isActive: section == activeSection,
              onTap: () => onSelectSection(section),
              onRemoveQuestion: onRemoveQuestion,
              onSetCondicion: onSetCondicion,
              onSetValidacion: onSetValidacion,
            ),
          ),
        OutlinedButton.icon(
          onPressed: onAddSection,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Agregar sección'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: AppColors.border, width: 1.5),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Los cambios se guardan automáticamente.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.questions,
    required this.isActive,
    required this.onTap,
    required this.onRemoveQuestion,
    required this.onSetCondicion,
    required this.onSetValidacion,
  });
  final String section;
  final List<Pregunta> questions;
  final bool isActive;
  final VoidCallback onTap;
  final ValueChanged<String> onRemoveQuestion;
  final ValueChanged<Pregunta> onSetCondicion;
  final ValueChanged<Pregunta> onSetValidacion;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.accent.withValues(alpha: 0.50)
                : AppColors.border,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.05)
                    : AppColors.muted,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.segment,
                    size: 16,
                    color: isActive
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      section,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isActive
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${questions.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Activa',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Questions
            if (questions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive
                        ? 'Clic en un tipo de pregunta para agregar aquí'
                        : 'Sin preguntas — seleccioná la sección para activarla',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    for (final q in questions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _QuestionDesignCard(
                          pregunta: q,
                          onDelete: () => onRemoveQuestion(q.id),
                          onSetCondicion: () => onSetCondicion(q),
                          onSetValidacion: () => onSetValidacion(q),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestionDesignCard extends StatelessWidget {
  const _QuestionDesignCard({
    required this.pregunta,
    required this.onDelete,
    required this.onSetCondicion,
    required this.onSetValidacion,
  });
  final Pregunta pregunta;
  final VoidCallback onDelete;
  final VoidCallback onSetCondicion;
  final VoidCallback onSetValidacion;

  static IconData _iconFor(CampoTipo tipo) => switch (tipo) {
    CampoTipo.texto => Icons.short_text,
    CampoTipo.numerico => Icons.tag,
    CampoTipo.seleccion => Icons.radio_button_checked_outlined,
    CampoTipo.fecha => Icons.calendar_today_outlined,
    CampoTipo.booleano => Icons.toggle_on_outlined,
  };

  static String _labelFor(CampoTipo tipo) => switch (tipo) {
    CampoTipo.texto => 'Texto',
    CampoTipo.numerico => 'Número',
    CampoTipo.seleccion => 'Selección',
    CampoTipo.fecha => 'Fecha',
    CampoTipo.booleano => 'Sí / No',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle (visual only)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.drag_indicator,
              size: 16,
              color: AppColors.border,
            ),
          ),
          const SizedBox(width: 10),
          // Type icon
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              _iconFor(pregunta.tipo),
              size: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          // Label + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pregunta.texto,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Tag(
                      label: _labelFor(pregunta.tipo),
                      color: AppColors.textSecondary,
                    ),
                    if (pregunta.obligatoria)
                      const _Tag(label: 'Obligatoria', color: AppColors.error),
                    if (pregunta.esCampoEstandar)
                      const _Tag(
                        label: 'Estándar RF-007',
                        color: AppColors.success,
                        icon: Icons.verified_outlined,
                      ),
                    if (pregunta.autocompletaCidi)
                      const _Tag(
                        label: 'CiDi',
                        color: AppColors.accent,
                        icon: Icons.account_circle_outlined,
                      ),
                    if (pregunta.tieneCondicion)
                      const _Tag(
                        label: 'Condicional',
                        color: AppColors.warning,
                        icon: Icons.filter_alt_outlined,
                      ),
                    if (pregunta.tieneValidaciones)
                      const _Tag(
                        label: 'Validaciones',
                        color: AppColors.accent,
                        icon: Icons.rule_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Validaciones (RF-003)
          IconButton(
            onPressed: onSetValidacion,
            icon: Icon(
              pregunta.tieneValidaciones ? Icons.rule : Icons.rule_outlined,
              size: 17,
            ),
            color: pregunta.tieneValidaciones
                ? AppColors.accent
                : AppColors.border,
            visualDensity: VisualDensity.compact,
            tooltip: pregunta.tieneValidaciones
                ? 'Editar validaciones'
                : 'Configurar validaciones',
          ),
          // Condición (RF-004)
          IconButton(
            onPressed: onSetCondicion,
            icon: Icon(
              pregunta.tieneCondicion
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              size: 16,
            ),
            color: pregunta.tieneCondicion
                ? AppColors.warning
                : AppColors.border,
            visualDensity: VisualDensity.compact,
            tooltip: pregunta.tieneCondicion
                ? 'Editar condición'
                : 'Agregar condición',
          ),
          // Delete
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 16),
            color: AppColors.error.withValues(alpha: 0.70),
            visualDensity: VisualDensity.compact,
            tooltip: 'Eliminar pregunta',
          ),
        ],
      ),
    );
  }
}

// RF-003: diálogo de validaciones por campo.
class _ValidacionDialog extends StatefulWidget {
  const _ValidacionDialog({required this.pregunta});
  final Pregunta pregunta;

  @override
  State<_ValidacionDialog> createState() => _ValidacionDialogState();
}

class _ValidacionDialogState extends State<_ValidacionDialog> {
  late final TextEditingController _minLength;
  late final TextEditingController _maxLength;
  late final TextEditingController _minValue;
  late final TextEditingController _maxValue;
  late final TextEditingController _message;

  @override
  void initState() {
    super.initState();
    _minLength = TextEditingController(
      text: widget.pregunta.longitudMinima?.toString() ?? '',
    );
    _maxLength = TextEditingController(
      text: widget.pregunta.longitudMaxima?.toString() ?? '',
    );
    _minValue = TextEditingController(
      text: widget.pregunta.valorMinimo?.toString() ?? '',
    );
    _maxValue = TextEditingController(
      text: widget.pregunta.valorMaximo?.toString() ?? '',
    );
    _message = TextEditingController(
      text: widget.pregunta.mensajeValidacion ?? '',
    );
  }

  @override
  void dispose() {
    _minLength.dispose();
    _maxLength.dispose();
    _minValue.dispose();
    _maxValue.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esNumerica = widget.pregunta.tipo == CampoTipo.numerico;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.rule_outlined, size: 20, color: AppColors.accent),
          SizedBox(width: 8),
          Text('Validaciones RF-003'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pregunta.texto,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              esNumerica
                  ? 'Definí el rango aceptado para este campo numérico.'
                  : 'Definí la longitud aceptada para este campo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: esNumerica ? _minValue : _minLength,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: esNumerica
                          ? 'Valor mínimo'
                          : 'Longitud mínima',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: esNumerica ? _maxValue : _maxLength,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: esNumerica
                          ? 'Valor máximo'
                          : 'Longitud máxima',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Mensaje de error personalizado',
                hintText: 'Ej: Ingresá un valor dentro del rango permitido.',
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
          onPressed: () => Navigator.pop(context, (
            longitudMinima: esNumerica ? null : int.tryParse(_minLength.text),
            longitudMaxima: esNumerica ? null : int.tryParse(_maxLength.text),
            valorMinimo: esNumerica ? num.tryParse(_minValue.text) : null,
            valorMaximo: esNumerica ? num.tryParse(_maxValue.text) : null,
            mensaje: _message.text.trim().isEmpty ? null : _message.text.trim(),
          )),
          icon: const Icon(Icons.save_outlined, size: 16),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}

// RF-004: diálogo de lógica condicional.
class _CondicionalDialog extends StatefulWidget {
  const _CondicionalDialog({
    required this.pregunta,
    required this.allQuestions,
  });
  final Pregunta pregunta;
  final List<Pregunta> allQuestions;

  @override
  State<_CondicionalDialog> createState() => _CondicionalDialogState();
}

class _CondicionalDialogState extends State<_CondicionalDialog> {
  String? _campoId;
  String? _valor;

  @override
  void initState() {
    super.initState();
    _campoId = widget.pregunta.condicionCampoId;
    _valor = widget.pregunta.condicionValor;
  }

  List<Pregunta> get _candidatos => widget.allQuestions
      .where(
        (q) =>
            q.id != widget.pregunta.id &&
            (q.tipo == CampoTipo.seleccion || q.tipo == CampoTipo.booleano),
      )
      .toList();

  Pregunta? get _campoPregunta => _campoId == null
      ? null
      : widget.allQuestions.where((q) => q.id == _campoId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.filter_alt_outlined, size: 20, color: AppColors.warning),
          SizedBox(width: 8),
          Text('Lógica condicional RF-004'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mostrar "${widget.pregunta.texto}" solo cuando:',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _campoId,
              decoration: const InputDecoration(labelText: 'Campo disparador'),
              hint: const Text('Sin condición — siempre visible'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sin condición'),
                ),
                for (final q in _candidatos)
                  DropdownMenuItem<String?>(value: q.id, child: Text(q.texto)),
              ],
              onChanged: (v) => setState(() {
                _campoId = v;
                _valor = null;
              }),
            ),
            if (_campoPregunta != null) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _valor,
                decoration: const InputDecoration(
                  labelText: 'Cuando el valor sea igual a',
                ),
                items: _campoPregunta!.tipo == CampoTipo.booleano
                    ? const [
                        DropdownMenuItem(value: 'true', child: Text('Sí')),
                        DropdownMenuItem(value: 'false', child: Text('No')),
                      ]
                    : [
                        for (final opt in _campoPregunta!.opciones)
                          DropdownMenuItem(value: opt, child: Text(opt)),
                      ],
                onChanged: (v) => setState(() => _valor = v),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, (campoId: _campoId, valor: _valor)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
