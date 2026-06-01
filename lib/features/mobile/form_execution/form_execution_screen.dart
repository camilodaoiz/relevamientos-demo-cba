import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/campo_estandar.dart';
import '../../../core/models/pregunta.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';

class FormExecutionScreen extends ConsumerStatefulWidget {
  const FormExecutionScreen({super.key, required this.taskId, this.relId});

  final String taskId;
  final String? relId;

  @override
  ConsumerState<FormExecutionScreen> createState() =>
      _FormExecutionScreenState();
}

class _FormExecutionScreenState extends ConsumerState<FormExecutionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _values = <String, Object?>{};
  final _signaturePoints = <Offset?>[];
  Uint8List? _pickedImageBytes;
  int _sectionIndex = 0;
  bool _gpsCaptured = false;
  bool _cidiLoading = false;
  bool _cidiVerified = false;
  bool _cidiUnverified = false;
  Timer? _cuilTimer;

  static const _demoAnswers = <String, Object>{
    'p-cuil': '20304567891',
    'p-nombre': 'Sofia',
    'p-apellido': 'Peralta',
    'p-dni': '30456789',
    'p-telefono': '3515550198',
    'p-domicilio': 'Av. Colon 1250, Cordoba',
    'p-camas': '18',
    'p-habilitado': true,
    'p-estado': 'Bueno',
    'p-fecha': '29/5/2026',
  };

  @override
  void dispose() {
    _cuilTimer?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RF-003/RF-025/RF-026/RF-027/RF-030/RF-034: ejecucion mobile offline con validaciones, evidencias y mock CiDi.
    final store = ref.watch(demoStoreProvider);
    final task = store.tareaById(widget.taskId);
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
    if (survey == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: EmptyState(
          title: 'Encuesta no encontrada',
          message: 'El registro solicitado no fue encontrado.',
        ),
      );
    }

    final section = survey.secciones[_sectionIndex];
    final questions = survey.preguntas
        .where((question) => question.seccion == section)
        .where(_isVisible)
        .toList();
    final progress = (_sectionIndex + 1) / survey.secciones.length;
    final isLast = _sectionIndex == survey.secciones.length - 1;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        survey.nombre,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (widget.relId != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Relevamiento #${widget.relId!.split('-').last}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusBadge.sync(task.syncEstado),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seccion ${_sectionIndex + 1} de ${survey.secciones.length}: $section',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Cargar datos de ejemplo',
                        icon: Icons.fact_check_outlined,
                        variant: AppButtonVariant.secondary,
                        onPressed: _loadDemoAnswers,
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
                        section,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 14),
                      for (final question in questions) ...[
                        _QuestionInput(
                          question: question,
                          controller: _controllerFor(question),
                          value: _values[question.id],
                          cidiLoading:
                              question.autocompletaCidi && _cidiLoading,
                          cidiVerified: _cidiVerified,
                          cidiUnverified: _cidiUnverified,
                          allowManualOverride: _cidiUnverified,
                          onChanged: (value) =>
                              _onQuestionChanged(question, value),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                if (isLast) ...[
                  const SizedBox(height: 14),
                  _EvidenceCard(
                    pickedImageBytes: _pickedImageBytes,
                    gpsCaptured: _gpsCaptured,
                    signaturePoints: _signaturePoints,
                    onPickImage: _pickImage,
                    onGps: () => setState(() => _gpsCaptured = true),
                    onSignaturePan: (point) =>
                        setState(() => _signaturePoints.add(point)),
                    onSignatureEnd: () =>
                        setState(() => _signaturePoints.add(null)),
                    onClearSignature: () => setState(_signaturePoints.clear),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Borrador local guardado automaticamente',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (_sectionIndex > 0)
                    Expanded(
                      child: AppButton(
                        label: 'Anterior',
                        icon: Icons.arrow_back,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => setState(() => _sectionIndex -= 1),
                      ),
                    ),
                  if (_sectionIndex > 0) const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: isLast
                          ? (widget.relId != null ? 'Completar relevamiento' : 'Finalizar')
                          : 'Siguiente',
                      icon: isLast
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward,
                      onPressed: () {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        if (isLast) {
                          final store = ref.read(demoStoreProvider);
                          if (widget.relId != null) {
                            // modo multi-relevamiento: solo marca este como completado
                            store.completeRelevamiento(widget.taskId, widget.relId!);
                            context.go('/mobile/tasks/${widget.taskId}');
                          } else {
                            store.finishTaskLocal(widget.taskId);
                            context.go('/mobile/sync');
                          }
                        } else {
                          setState(() => _sectionIndex += 1);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // RF-004: lógica condicional — mostrar solo si la condición del campo se cumple.
  bool _isVisible(Pregunta question) {
    if (!question.tieneCondicion) return true;
    final actual = _values[question.condicionCampoId!];
    if (actual == null) return false;
    return actual.toString() == question.condicionValor;
  }

  TextEditingController _controllerFor(Pregunta question) {
    return _controllers.putIfAbsent(question.id, () => TextEditingController());
  }

  void _onQuestionChanged(Pregunta question, Object? value) {
    _values[question.id] = value;
    if (!question.autocompletaCidi || value is! String || value.length != 11) {
      if (question.autocompletaCidi && mounted) {
        setState(() {
          _cidiLoading = false;
          _cidiVerified = false;
          _cidiUnverified = false;
        });
      }
      return;
    }

    _cuilTimer?.cancel();
    final store = ref.read(demoStoreProvider);
    if (store.offlineMode) {
      setState(() {
        _cidiLoading = false;
        _cidiVerified = false;
        _cidiUnverified = true;
      });
      store.registerCidiLookup(value, verified: false);
      return;
    }
    setState(() {
      _cidiLoading = true;
      _cidiVerified = false;
      _cidiUnverified = false;
    });

    _cuilTimer = Timer(const Duration(milliseconds: 1500), () {
      _controllerFor(
        const Pregunta(
          id: 'p-nombre',
          texto: 'Nombre',
          tipo: CampoTipo.texto,
          seccion: '',
        ),
      ).text = 'Sofia';
      _controllerFor(
        const Pregunta(
          id: 'p-apellido',
          texto: 'Apellido',
          tipo: CampoTipo.texto,
          seccion: '',
        ),
      ).text = 'Peralta';
      setState(() {
        _values['p-nombre'] = 'Sofia';
        _values['p-apellido'] = 'Peralta';
        _cidiLoading = false;
        _cidiVerified = true;
        _cidiUnverified = false;
      });
      ref.read(demoStoreProvider).registerCidiLookup(value, verified: true);
    });
  }

  void _loadDemoAnswers() {
    _cuilTimer?.cancel();

    for (final entry in _demoAnswers.entries) {
      _values[entry.key] = entry.value;
      if (entry.value is String) {
        _controllers
                .putIfAbsent(entry.key, () => TextEditingController())
                .text =
            entry.value as String;
      }
    }

    final store = ref.read(demoStoreProvider);
    final offline = store.offlineMode;
    setState(() {
      _cidiLoading = false;
      _cidiVerified = !offline;
      _cidiUnverified = offline;
      _gpsCaptured = true;
      _signaturePoints
        ..clear()
        ..addAll(const [
          Offset(18, 96),
          Offset(34, 78),
          Offset(54, 102),
          Offset(78, 55),
          Offset(105, 95),
          null,
          Offset(116, 92),
          Offset(148, 72),
          Offset(186, 86),
        ]);
    });
    store.registerCidiLookup(
      _demoAnswers['p-cuil']! as String,
      verified: !offline,
    );
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }
    final bytes = await image.readAsBytes();
    setState(() => _pickedImageBytes = bytes);
  }
}

class _QuestionInput extends StatelessWidget {
  const _QuestionInput({
    required this.question,
    required this.controller,
    required this.value,
    required this.onChanged,
    this.cidiLoading = false,
    this.cidiVerified = false,
    this.cidiUnverified = false,
    this.allowManualOverride = false,
  });

  final Pregunta question;
  final TextEditingController controller;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final bool cidiLoading;
  final bool cidiVerified;
  final bool cidiUnverified;
  final bool allowManualOverride;

  @override
  Widget build(BuildContext context) {
    final label = question.obligatoria ? '${question.texto} *' : question.texto;
    final suffix = cidiLoading
        ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : question.autocompletaCidi && cidiVerified
        ? const Padding(
            padding: EdgeInsets.only(right: 8),
            child: StatusBadge(
              label: 'Verificado via CiDi',
              color: AppColors.success,
              icon: Icons.verified_outlined,
            ),
          )
        : question.autocompletaCidi && cidiUnverified
        ? const Padding(
            padding: EdgeInsets.only(right: 8),
            child: StatusBadge(
              label: 'No verificado',
              color: AppColors.warning,
              icon: Icons.wifi_off_outlined,
            ),
          )
        : null;

    switch (question.tipo) {
      case CampoTipo.seleccion:
        return DropdownButtonFormField<String>(
          key: ValueKey('${question.id}-${value ?? ''}'),
          initialValue: value as String?,
          decoration: InputDecoration(labelText: label),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          items: [
            for (final option in question.opciones)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          validator: (value) => _validateQuestion(question, value),
          onChanged: onChanged,
        );
      case CampoTipo.booleano:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: (value as bool?) ?? false,
          onChanged: onChanged,
        );
      case CampoTipo.fecha:
        return TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => _validateQuestion(question, value),
          onTap: () async {
            final selected = await showDatePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              initialDate: DateTime(2026, 5, 29),
            );
            if (selected == null) return;
            controller.text =
                '${selected.day}/${selected.month}/${selected.year}';
            onChanged(controller.text);
          },
        );
      case CampoTipo.numerico:
        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => _validateQuestion(question, value),
          onChanged: onChanged,
        );
      case CampoTipo.texto:
        return TextFormField(
          controller: controller,
          readOnly: question.soloLectura && !allowManualOverride,
          decoration: InputDecoration(labelText: label, suffixIcon: suffix),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => _validateQuestion(question, value),
          onChanged: onChanged,
        );
    }
  }
}

String? _validateQuestion(Pregunta question, String? value) {
  final text = value?.trim() ?? '';
  if (question.obligatoria && text.isEmpty) return 'Campo obligatorio';
  if (text.isEmpty) return null;
  if (question.longitudMinima != null &&
      text.length < question.longitudMinima!) {
    return question.mensajeValidacion ??
        'Debe tener al menos ${question.longitudMinima} caracteres';
  }
  if (question.longitudMaxima != null &&
      text.length > question.longitudMaxima!) {
    return question.mensajeValidacion ??
        'Debe tener como máximo ${question.longitudMaxima} caracteres';
  }
  if (question.tipo == CampoTipo.numerico) {
    final number = num.tryParse(text);
    if (number == null) return 'Ingresá un número válido';
    if (question.valorMinimo != null && number < question.valorMinimo!) {
      return question.mensajeValidacion ??
          'El valor mínimo es ${question.valorMinimo}';
    }
    if (question.valorMaximo != null && number > question.valorMaximo!) {
      return question.mensajeValidacion ??
          'El valor máximo es ${question.valorMaximo}';
    }
  }
  return null;
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.pickedImageBytes,
    required this.gpsCaptured,
    required this.signaturePoints,
    required this.onPickImage,
    required this.onGps,
    required this.onSignaturePan,
    required this.onSignatureEnd,
    required this.onClearSignature,
  });

  final Uint8List? pickedImageBytes;
  final bool gpsCaptured;
  final List<Offset?> signaturePoints;
  final VoidCallback onPickImage;
  final VoidCallback onGps;
  final ValueChanged<Offset> onSignaturePan;
  final VoidCallback onSignatureEnd;
  final VoidCallback onClearSignature;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evidencias del relevamiento',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Foto',
                  icon: Icons.photo_camera_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: onPickImage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: gpsCaptured ? 'GPS OK' : 'GPS',
                  icon: Icons.my_location,
                  variant: AppButtonVariant.secondary,
                  onPressed: onGps,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pickedImageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                pickedImageBytes!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (gpsCaptured) ...[
            const SizedBox(height: 10),
            const StatusBadge(
              label: 'Ubicacion capturada OK',
              color: AppColors.success,
              icon: Icons.location_on_outlined,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Firma', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: onClearSignature,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Limpiar'),
              ),
            ],
          ),
          GestureDetector(
            onPanUpdate: (details) => onSignaturePan(details.localPosition),
            onPanEnd: (_) => onSignatureEnd(),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: CustomPaint(
                painter: _SignaturePainter(signaturePoints),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    for (var index = 0; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
