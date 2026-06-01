import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/encuesta.dart';
import '../../../core/models/tarea.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';

class TareasScreen extends ConsumerStatefulWidget {
  const TareasScreen({super.key});

  @override
  ConsumerState<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends ConsumerState<TareasScreen> {
  TareaEstado? estado;
  String inspector = 'Todos';
  bool _syncing = false;
  bool _calendarView = false;

  Future<void> _syncPending() async {
    setState(() => _syncing = true);
    await ref.read(demoStoreProvider).syncPending();
    if (mounted) setState(() => _syncing = false);
  }

  Future<void> _showNuevaTareaDialog(BuildContext context) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _NuevaTareaDialog(),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Tarea creada y asignada al inspector'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _importCsvMock() {
    final imported = ref.read(demoStoreProvider).importTareasCsvMock();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          imported > 0
              ? '✓ $imported tareas importadas desde CSV mock'
              : 'El CSV mock ya fue importado en esta sesión.',
        ),
        backgroundColor: imported > 0 ? AppColors.success : AppColors.warning,
      ),
    );
  }

  Future<void> _showReassignDialog(Tarea task) async {
    final reassigned = await showDialog<bool>(
      context: context,
      builder: (_) => _ReassignTaskDialog(task: task),
    );
    if (reassigned == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Tarea reasignada y notificación generada'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // RF-019/RF-020/RF-021/RF-022/RF-039: planificacion, asignacion y reporte operativo demo.
    final store = ref.watch(demoStoreProvider);
    final isCoordinador = store.currentUser.rolId == 'R-05';
    final inspectorNames = {for (final u in store.usuarios) u.email: u.nombre};
    final tareas = store.tareas.where((task) {
      final matchEstado = estado == null || task.estado == estado;
      final matchInspector =
          inspector == 'Todos' || task.asignadoA == inspector;
      return matchEstado && matchInspector;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCoordinador) ...[
          _OperativoCard(tareas: store.tareas.toList()),
          const SizedBox(height: 18),
        ],
        SectionHeader(
          title: isCoordinador ? 'Coordinacion de campo' : 'Tareas de campo',
          subtitle: isCoordinador
              ? 'Asignacion, seguimiento y sincronizacion del operativo.'
              : 'Asignacion y seguimiento operativo del organismo piloto.',
          action: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ViewToggle(
                calendarView: _calendarView,
                onToggle: (v) => setState(() => _calendarView = v),
              ),
              if (isCoordinador) ...[
                OutlinedButton.icon(
                  onPressed: _importCsvMock,
                  icon: const Icon(Icons.upload_file_outlined, size: 16),
                  label: const Text('Importar CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: _syncing ? null : _syncPending,
                  icon: _syncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: Text(
                    _syncing ? 'Sincronizando...' : 'Sincronizar pendientes',
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showNuevaTareaDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nueva tarea'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_calendarView)
          _CalendarView(tareas: store.tareas.toList())
        else ...[
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TareaEstado?>(
                    initialValue: estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: [
                      const DropdownMenuItem<TareaEstado?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      for (final value in TareaEstado.values)
                        DropdownMenuItem<TareaEstado?>(
                          value: value,
                          child: Text(value.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => estado = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: inspector,
                    decoration: const InputDecoration(labelText: 'Inspector'),
                    items: [
                      const DropdownMenuItem(
                        value: 'Todos',
                        child: Text('Todos'),
                      ),
                      for (final u in store.usuarios.where(
                        (u) => u.rolId == 'R-06',
                      ))
                        DropdownMenuItem(value: u.email, child: Text(u.nombre)),
                    ],
                    onChanged: (value) =>
                        setState(() => inspector = value ?? 'Todos'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppDataTable(
            columns: const [
              'Tarea',
              'Direccion',
              'Prioridad',
              'Vencimiento',
              'Estado',
              'Área',
              'Inspector',
              'Sync',
              'Acción',
            ],
            rows: [
              for (final task in tareas)
                [
                  Text(task.titulo),
                  SizedBox(
                    width: 200,
                    child: Text(
                      task.direccion,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(
                    label: task.prioridad.label,
                    color: _priorityColor(task.prioridad),
                  ),
                  Text(
                    '${task.vencimiento.day.toString().padLeft(2, '0')}/${task.vencimiento.month.toString().padLeft(2, '0')}/${task.vencimiento.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          task.estado != TareaEstado.finalizada &&
                              task.vencimiento.isBefore(DateTime(2026, 5, 29))
                          ? AppColors.error
                          : AppColors.textSecondary,
                      fontWeight:
                          task.estado != TareaEstado.finalizada &&
                              task.vencimiento.isBefore(DateTime(2026, 5, 29))
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  StatusBadge.tarea(task.estado),
                  Text(store.areaForTask(task)?.nombre ?? 'Sin área'),
                  Text(inspectorNames[task.asignadoA] ?? task.asignadoA),
                  StatusBadge.sync(task.syncEstado),
                  isCoordinador
                      ? IconButton(
                          onPressed: () => _showReassignDialog(task),
                          tooltip: 'Reasignar tarea',
                          icon: const Icon(Icons.swap_horiz_outlined, size: 18),
                        )
                      : const SizedBox.shrink(),
                ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.calendarView, required this.onToggle});
  final bool calendarView;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            icon: Icons.list_outlined,
            active: !calendarView,
            onTap: () => onToggle(false),
          ),
          Container(width: 1, height: 32, color: AppColors.border),
          _ToggleBtn(
            icon: Icons.calendar_month_outlined,
            active: calendarView,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 36,
        height: 34,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

Color _priorityColor(TareaPrioridad priority) {
  return switch (priority) {
    TareaPrioridad.alta => AppColors.error,
    TareaPrioridad.media => AppColors.warning,
    TareaPrioridad.baja => AppColors.success,
  };
}

class _OperativoCard extends StatelessWidget {
  const _OperativoCard({required this.tareas});
  final List<Tarea> tareas;

  @override
  Widget build(BuildContext context) {
    final total = tareas.length;
    final finalizadas = tareas
        .where((t) => t.estado == TareaEstado.finalizada)
        .length;
    final enCurso = tareas.where((t) => t.estado == TareaEstado.enCurso).length;
    final devueltas = tareas
        .where((t) => t.estado == TareaEstado.devuelta)
        .length;
    final sinSync = tareas
        .where(
          (t) =>
              t.syncEstado == SyncEstado.local ||
              t.syncEstado == SyncEstado.error,
        )
        .length;
    final errSync = tareas
        .where((t) => t.syncEstado == SyncEstado.error)
        .length;
    final progress = total > 0 ? finalizadas / total : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado del operativo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$finalizadas de $total finalizadas · $enCurso en campo${devueltas > 0 ? ' · $devueltas devueltas' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              if (sinSync == 0)
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Todo sincronizado',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.upload_outlined,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$sinSync sin sincronizar',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (errSync > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.sync_problem_outlined,
                            size: 14,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$errSync error${errSync != 1 ? 'es' : ''} de sync',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
            ],
          ),
          const Divider(height: 28),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _OperativoMetric(
                icon: Icons.assignment_return_outlined,
                label: 'Devueltas',
                value: '$devueltas',
                color: devueltas > 0 ? AppColors.error : AppColors.success,
              ),
              const _OperativoMetric(
                icon: Icons.schedule_outlined,
                label: 'Tiempo medio',
                value: '1 h 42 min',
                color: AppColors.accent,
              ),
              const _OperativoMetric(
                icon: Icons.speed_outlined,
                label: 'Cumplimiento SLA',
                value: '91%',
                color: AppColors.success,
              ),
              _OperativoMetric(
                icon: Icons.cloud_off_outlined,
                label: 'Sin sincronizar',
                value: '$sinSync',
                color: sinSync > 0 ? AppColors.warning : AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperativoMetric extends StatelessWidget {
  const _OperativoMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: color),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── CALENDAR VIEW ─────────────────────────────────────────────────────────────

class _CalendarView extends StatefulWidget {
  const _CalendarView({required this.tareas});
  final List<Tarea> tareas;

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  DateTime _month = DateTime(2026, 5);

  static const _monthNames = [
    '',
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  static const _weekDays = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

  Map<int, List<Tarea>> _tasksByDay() {
    final result = <int, List<Tarea>>{};
    for (final tarea in widget.tareas) {
      final v = tarea.vencimiento;
      if (v.year == _month.year && v.month == _month.month) {
        result.putIfAbsent(v.day, () => []).add(tarea);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final tasksByDay = _tasksByDay();
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // weekday: 1=Mon…7=Sun → offset for Sun-based grid
    final startOffset = firstDay.weekday % 7;
    const today = 29; // May 29 2026
    final isCurrentMonth = _month.year == 2026 && _month.month == 5;

    final cells = <({int day, bool isToday, List<Tarea> tareas})>[];
    for (var i = 0; i < startOffset; i++) {
      cells.add((day: 0, isToday: false, tareas: []));
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add((
        day: d,
        isToday: isCurrentMonth && d == today,
        tareas: tasksByDay[d] ?? [],
      ));
    }
    while (cells.length % 7 != 0) {
      cells.add((day: 0, isToday: false, tareas: []));
    }

    final rows = <List<({int day, bool isToday, List<Tarea> tareas})>>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(cells.sublist(i, i + 7));
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                visualDensity: VisualDensity.compact,
                iconSize: 20,
              ),
              Expanded(
                child: Text(
                  '${_monthNames[_month.month]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
                visualDensity: VisualDensity.compact,
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final wd in _weekDays)
                Expanded(
                  child: Text(
                    wd,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (final row in rows)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final cell in row)
                  Expanded(child: _DayCellWidget(cell: cell)),
              ],
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Legend(color: AppColors.accent, label: 'Pendiente'),
              _Legend(color: AppColors.warning, label: 'En curso'),
              _Legend(color: AppColors.success, label: 'Finalizada'),
              _Legend(color: Color(0xFFEA580C), label: 'Devuelta'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCellWidget extends StatelessWidget {
  const _DayCellWidget({required this.cell});
  final ({int day, bool isToday, List<Tarea> tareas}) cell;

  Color _tareaColor(TareaEstado estado) => switch (estado) {
    TareaEstado.pendiente => AppColors.accent,
    TareaEstado.enCurso => AppColors.warning,
    TareaEstado.finalizada => AppColors.success,
    TareaEstado.devuelta => const Color(0xFFEA580C),
  };

  @override
  Widget build(BuildContext context) {
    if (cell.day == 0) {
      return const SizedBox(height: 74);
    }
    return Container(
      height: 74,
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cell.isToday
            ? AppColors.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        border: Border.all(
          color: cell.isToday ? AppColors.primary : AppColors.border,
          width: cell.isToday ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: cell.isToday
                ? const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  )
                : null,
            child: Text(
              '${cell.day}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cell.isToday ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          for (final tarea in cell.tareas.take(2))
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: _tareaColor(tarea.estado).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                tarea.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: _tareaColor(tarea.estado),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (cell.tareas.length > 2)
            Text(
              '+${cell.tareas.length - 2} más',
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.20),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ─── Dialog: Nueva tarea ────────────────────────────────────────────────────────

class _NuevaTareaDialog extends ConsumerStatefulWidget {
  const _NuevaTareaDialog();

  @override
  ConsumerState<_NuevaTareaDialog> createState() => _NuevaTareaDialogState();
}

class _NuevaTareaDialogState extends ConsumerState<_NuevaTareaDialog> {
  final _tituloCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  String? _encuestaId;
  String? _inspectorEmail;
  String? _areaId;
  TareaPrioridad _prioridad = TareaPrioridad.media;
  DateTime _vencimiento = DateTime(2026, 6, 10);

  bool get _valid =>
      _tituloCtrl.text.trim().isNotEmpty &&
      _direccionCtrl.text.trim().isNotEmpty &&
      _encuestaId != null &&
      _inspectorEmail != null;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    ref
        .read(demoStoreProvider)
        .createTarea(
          titulo: _tituloCtrl.text.trim(),
          direccion: _direccionCtrl.text.trim(),
          encuestaId: _encuestaId!,
          asignadoA: _inspectorEmail!,
          prioridad: _prioridad,
          vencimiento: _vencimiento,
          areaId: _areaId,
        );
    Navigator.pop(context, true);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _vencimiento,
      firstDate: DateTime(2026, 5, 29),
      lastDate: DateTime(2026, 12, 31),
      helpText: 'Fecha límite de la tarea',
    );
    if (picked != null && mounted) setState(() => _vencimiento = picked);
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(demoStoreProvider);
    final encuestasPublicadas = store.encuestas
        .where((e) => e.estado == EncuestaEstado.publicada)
        .toList();
    final inspectores = store.usuarios.where((u) => u.rolId == 'R-06').toList();
    final vencStr =
        '${_vencimiento.day.toString().padLeft(2, '0')}/${_vencimiento.month.toString().padLeft(2, '0')}/${_vencimiento.year}';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_task_outlined, size: 22, color: Color(0xFF0D9488)),
          SizedBox(width: 10),
          Text('Nueva tarea de relevamiento'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'La tarea se creará en estado Pendiente y el inspector la verá en su app mobile.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),

              // Establecimiento
              TextField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Establecimiento *',
                  hintText: 'Ej: CAPS Barrio Centro',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                onChanged: (_) => setState(() {}),
                autofocus: true,
              ),
              const SizedBox(height: 12),

              // Dirección
              TextField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dirección *',
                  hintText: 'Ej: Av. Colón 1234, Córdoba',
                  prefixIcon: Icon(Icons.pin_drop_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Encuesta
              DropdownButtonFormField<String>(
                initialValue: _encuestaId,
                decoration: const InputDecoration(
                  labelText: 'Encuesta publicada *',
                  prefixIcon: Icon(Icons.dynamic_form_outlined),
                ),
                hint: const Text('Seleccioná una encuesta'),
                items: encuestasPublicadas
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.nombre, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _encuestaId = v),
              ),
              const SizedBox(height: 12),

              // Inspector
              DropdownButtonFormField<String?>(
                initialValue: _areaId,
                decoration: const InputDecoration(
                  labelText: 'Área operativa',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                hint: const Text('Seleccioná un área'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin área específica'),
                  ),
                  for (final area in store.areas)
                    DropdownMenuItem<String?>(
                      value: area.id,
                      child: Text(area.nombre),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _areaId = v;
                  final area = store.areas.where((a) => a.id == v).firstOrNull;
                  if (area != null) _inspectorEmail = area.inspector;
                }),
              ),
              const SizedBox(height: 12),

              // Inspector
              DropdownButtonFormField<String>(
                key: ValueKey(_inspectorEmail),
                initialValue: _inspectorEmail,
                decoration: const InputDecoration(
                  labelText: 'Inspector asignado *',
                  prefixIcon: Icon(Icons.person_pin_outlined),
                ),
                hint: const Text('Seleccioná un inspector'),
                items: inspectores
                    .map(
                      (u) => DropdownMenuItem(
                        value: u.email,
                        child: Text('${u.nombre}  ·  ${u.email}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _inspectorEmail = v),
              ),
              const SizedBox(height: 16),

              // Prioridad
              Text(
                'Prioridad',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final p in TareaPrioridad.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: OutlinedButton(
                          onPressed: () => setState(() => _prioridad = p),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _prioridad == p
                                ? _priorityColor(p).withValues(alpha: 0.12)
                                : null,
                            side: BorderSide(
                              color: _prioridad == p
                                  ? _priorityColor(p)
                                  : AppColors.border,
                              width: _prioridad == p ? 1.5 : 1.0,
                            ),
                            foregroundColor: _priorityColor(p),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            p.label,
                            style: TextStyle(
                              fontWeight: _prioridad == p
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Vencimiento
              Text(
                'Fecha límite',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        vencStr,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      const Text(
                        'Cambiar',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _valid ? _submit : null,
          icon: const Icon(Icons.add, size: 15),
          label: const Text('Crear tarea'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0D9488),
          ),
        ),
      ],
    );
  }
}

class _ReassignTaskDialog extends ConsumerStatefulWidget {
  const _ReassignTaskDialog({required this.task});

  final Tarea task;

  @override
  ConsumerState<_ReassignTaskDialog> createState() =>
      _ReassignTaskDialogState();
}

class _ReassignTaskDialogState extends ConsumerState<_ReassignTaskDialog> {
  late String _inspectorEmail;
  String? _areaId;

  @override
  void initState() {
    super.initState();
    _inspectorEmail = widget.task.asignadoA;
    _areaId = widget.task.areaId;
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(demoStoreProvider);
    final inspectores = store.usuarios.where((u) => u.rolId == 'R-06').toList();
    return AlertDialog(
      title: const Text('Reasignar tarea'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.titulo,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _areaId,
              decoration: const InputDecoration(labelText: 'Área operativa'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sin área específica'),
                ),
                for (final area in store.areas)
                  DropdownMenuItem<String?>(
                    value: area.id,
                    child: Text(area.nombre),
                  ),
              ],
              onChanged: (value) => setState(() {
                _areaId = value;
                final area = store.areas
                    .where((candidate) => candidate.id == value)
                    .firstOrNull;
                if (area != null) _inspectorEmail = area.inspector;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_inspectorEmail),
              initialValue: _inspectorEmail,
              decoration: const InputDecoration(labelText: 'Inspector'),
              items: [
                for (final inspector in inspectores)
                  DropdownMenuItem(
                    value: inspector.email,
                    child: Text(inspector.nombre),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _inspectorEmail = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () {
            ref
                .read(demoStoreProvider)
                .reassignTask(widget.task.id, _inspectorEmail, areaId: _areaId);
            Navigator.pop(context, true);
          },
          icon: const Icon(Icons.swap_horiz_outlined, size: 16),
          label: const Text('Reasignar'),
        ),
      ],
    );
  }
}
