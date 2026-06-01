import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/tarea.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/web_download.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';

// ─── Static mock chart data ────────────────────────────────────────────────────

const _weeklyData = [
  ('Sem 1 (5-11 may)', 2),
  ('Sem 2 (12-18 may)', 4),
  ('Sem 3 (19-25 may)', 3),
  ('Sem 4 (26 may-1 jun)', 7),
];

// ─── Screen ────────────────────────────────────────────────────────────────────

class AnalistaScreen extends ConsumerStatefulWidget {
  const AnalistaScreen({super.key});

  @override
  ConsumerState<AnalistaScreen> createState() => _AnalistaScreenState();
}

class _AnalistaScreenState extends ConsumerState<AnalistaScreen> {
  String _filterEncuesta = 'Todas';
  String _filterVersion = 'Todas';
  String _filterArea = 'Todas';
  String _filterEstado = 'Todos';
  String _filterInspector = 'Todos';
  DateTime? _filterFrom;
  DateTime? _filterTo;
  bool _showBucLayer = false;
  bool _showRentasLayer = false;

  @override
  Widget build(BuildContext context) {
    // RF-036/RF-037/RF-038: tablero filtrable, mapa base y exportación mock para el Analista R-07.
    final store = ref.watch(demoStoreProvider);
    final allTareas = store.tareas.toList();

    final inspectorNames = {for (final u in store.usuarios) u.email: u.nombre};
    final inspectorEmails = store.usuarios
        .where((u) => u.rolId == 'R-06')
        .map((u) => u.email)
        .toList();

    final filtered = allTareas.where((t) {
      final survey = store.encuestaById(t.encuestaId);
      if (_filterEncuesta != 'Todas' && t.encuestaId != _filterEncuesta) {
        return false;
      }
      if (_filterVersion != 'Todas' && '${survey?.version}' != _filterVersion) {
        return false;
      }
      if (_filterArea != 'Todas' && store.areaForTask(t)?.id != _filterArea) {
        return false;
      }
      if (_filterEstado != 'Todos') {
        final ok = switch (_filterEstado) {
          'Completadas' => t.estado == TareaEstado.finalizada,
          'En curso' => t.estado == TareaEstado.enCurso,
          'Pendientes' => t.estado == TareaEstado.pendiente,
          _ => true,
        };
        if (!ok) return false;
      }
      if (_filterInspector != 'Todos' && t.asignadoA != _filterInspector) {
        return false;
      }
      if (_filterFrom != null && t.vencimiento.isBefore(_filterFrom!)) {
        return false;
      }
      if (_filterTo != null && t.vencimiento.isAfter(_filterTo!)) return false;
      return true;
    }).toList();
    final completadas = filtered
        .where((t) => t.estado == TareaEstado.finalizada)
        .toList();
    final total = filtered.length;
    final tasa = total > 0 ? (completadas.length / total * 100).round() : 0;
    final inspectores = filtered.map((t) => t.asignadoA).toSet().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Tablero de análisis',
          subtitle:
              'Monitoreo de avance, distribución territorial y exportación de datos.',
          action: _ExportPopup(
            tareas: filtered,
            inspectorNames: inspectorNames,
            onExport: (format) => ref
                .read(demoStoreProvider)
                .registerExport(format, filtered.length),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FilterDropdown(
                label: 'Encuesta',
                value: _filterEncuesta,
                items: [
                  const DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                  for (final encuesta in store.encuestas)
                    DropdownMenuItem(
                      value: encuesta.id,
                      child: Text(
                        encuesta.nombre,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _filterEncuesta = value),
              ),
              _FilterDropdown(
                label: 'Versión',
                value: _filterVersion,
                items: [
                  const DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                  for (final version
                      in store.encuestas.map((e) => '${e.version}').toSet())
                    DropdownMenuItem(value: version, child: Text('v$version')),
                ],
                onChanged: (value) => setState(() => _filterVersion = value),
              ),
              _FilterDropdown(
                label: 'Área operativa',
                value: _filterArea,
                items: [
                  const DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                  for (final area in store.areas)
                    DropdownMenuItem(value: area.id, child: Text(area.nombre)),
                ],
                onChanged: (value) => setState(() => _filterArea = value),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _filterEncuesta = 'Todas';
                  _filterVersion = 'Todas';
                  _filterArea = 'Todas';
                  _filterEstado = 'Todos';
                  _filterInspector = 'Todos';
                  _filterFrom = null;
                  _filterTo = null;
                }),
                icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── KPI row ─────────────────────────────────────────────────────────
        LayoutBuilder(
          builder: (ctx, constraints) {
            final cols = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: cols == 4 ? 2.4 : 2.0,
              children: [
                _KpiCard(
                  label: 'Total relevamientos',
                  value: '$total',
                  icon: Icons.assignment_outlined,
                  color: AppColors.primary,
                ),
                _KpiCard(
                  label: 'Completados',
                  value: '${completadas.length}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                _KpiCard(
                  label: 'Completitud',
                  value: '$tasa%',
                  icon: Icons.trending_up_outlined,
                  color: AppColors.accent,
                ),
                _KpiCard(
                  label: 'Inspectores activos',
                  value: '$inspectores',
                  icon: Icons.person_pin_outlined,
                  color: const Color(0xFF0D9488),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),

        // ── Two-column: progress + weekly chart ──────────────────────────────
        LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _ProgressPanel(tareas: filtered)),
                  const SizedBox(width: 18),
                  Expanded(child: _WeeklyChartPanel()),
                ],
              );
            }
            return Column(
              children: [
                _ProgressPanel(tareas: filtered),
                const SizedBox(height: 14),
                _WeeklyChartPanel(),
              ],
            );
          },
        ),
        const SizedBox(height: 22),

        // ── Per-inspector breakdown ──────────────────────────────────────────
        _InspectorBreakdownPanel(
          tareas: filtered,
          inspectorEmails: inspectorEmails,
          inspectorNames: inspectorNames,
        ),
        const SizedBox(height: 22),

        _TerritorialMapPanel(
          tareas: filtered,
          showBucLayer: _showBucLayer,
          showRentasLayer: _showRentasLayer,
          onBucLayer: (value) => setState(() => _showBucLayer = value),
          onRentasLayer: (value) => setState(() => _showRentasLayer = value),
        ),
        const SizedBox(height: 22),

        // ── Data table ───────────────────────────────────────────────────────
        Row(
          children: [
            Text(
              'Listado de relevamientos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _filterEstado,
              underline: const SizedBox(),
              items: ['Todos', 'Completadas', 'En curso', 'Pendientes']
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _filterEstado = v!),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: _filterInspector,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(
                  value: 'Todos',
                  child: Text(
                    'Todos los inspectores',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final email in inspectorEmails)
                  DropdownMenuItem(
                    value: email,
                    child: Text(
                      inspectorNames[email] ?? email,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _filterInspector = v!),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _DateChip(
              label: 'Desde',
              date: _filterFrom,
              onPicked: (d) => setState(() => _filterFrom = d),
              onCleared: () => setState(() => _filterFrom = null),
            ),
            const SizedBox(width: 8),
            _DateChip(
              label: 'Hasta',
              date: _filterTo,
              onPicked: (d) => setState(() => _filterTo = d),
              onCleared: () => setState(() => _filterTo = null),
            ),
            if (_filterFrom != null || _filterTo != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => setState(() {
                  _filterFrom = null;
                  _filterTo = null;
                }),
                icon: const Icon(Icons.clear_all, size: 14),
                label: const Text('Limpiar fechas'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          child: filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Sin relevamientos para los filtros seleccionados.',
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < filtered.length; i++) ...[
                      _TareaRow(
                        tarea: filtered[i],
                        inspectorNames: inspectorNames,
                      ),
                      if (i < filtered.length - 1) const Divider(height: 20),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _TerritorialMapPanel extends StatelessWidget {
  const _TerritorialMapPanel({
    required this.tareas,
    required this.showBucLayer,
    required this.showRentasLayer,
    required this.onBucLayer,
    required this.onRentasLayer,
  });

  final List<Tarea> tareas;
  final bool showBucLayer;
  final bool showRentasLayer;
  final ValueChanged<bool> onBucLayer;
  final ValueChanged<bool> onRentasLayer;

  @override
  Widget build(BuildContext context) {
    // RF-037: visualización geográfica simple con capas externas simuladas.
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Distribución territorial',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${tareas.length} puntos',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Mapa base del operativo. Las capas externas se muestran con datos hardcodeados.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                selected: showBucLayer,
                onSelected: onBucLayer,
                avatar: const Icon(Icons.apartment_outlined, size: 16),
                label: const Text('BUC mock'),
              ),
              FilterChip(
                selected: showRentasLayer,
                onSelected: onRentasLayer,
                avatar: const Icon(Icons.home_work_outlined, size: 16),
                label: const Text('Rentas mock'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 280,
              width: double.infinity,
              child: CustomPaint(
                painter: _TerritorialMapPainter(
                  tareas: tareas,
                  showBucLayer: showBucLayer,
                  showRentasLayer: showRentasLayer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _MapLegend(color: AppColors.accent, label: 'Pendiente'),
              _MapLegend(color: AppColors.warning, label: 'En curso'),
              _MapLegend(color: AppColors.success, label: 'Finalizada'),
              _MapLegend(color: Color(0xFFEA580C), label: 'Devuelta'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, size: 15, color: color),
        const SizedBox(width: 3),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TerritorialMapPainter extends CustomPainter {
  const _TerritorialMapPainter({
    required this.tareas,
    required this.showBucLayer,
    required this.showRentasLayer,
  });

  final List<Tarea> tareas;
  final bool showBucLayer;
  final bool showRentasLayer;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF1F5F9),
    );
    final street = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var index = 1; index < 6; index++) {
      final y = size.height * index / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 18), street);
    }
    for (var index = 1; index < 8; index++) {
      final x = size.width * index / 8;
      canvas.drawLine(Offset(x, 0), Offset(x + 24, size.height), street);
    }

    if (showBucLayer) {
      _drawMockLayer(canvas, size, const Color(0xFF7C3AED), const [
        Offset(0.16, 0.24),
        Offset(0.72, 0.31),
        Offset(0.45, 0.72),
      ]);
    }
    if (showRentasLayer) {
      _drawMockLayer(canvas, size, const Color(0xFF0D9488), const [
        Offset(0.29, 0.53),
        Offset(0.62, 0.64),
        Offset(0.83, 0.74),
      ]);
    }

    for (var index = 0; index < tareas.length; index++) {
      final task = tareas[index];
      final x = 30 + ((index * 83) % (size.width - 60));
      final y = 30 + ((index * 57) % (size.height - 60));
      final color = switch (task.estado) {
        TareaEstado.pendiente => AppColors.accent,
        TareaEstado.enCurso => AppColors.warning,
        TareaEstado.finalizada => AppColors.success,
        TareaEstado.devuelta => const Color(0xFFEA580C),
      };
      canvas.drawCircle(Offset(x, y), 9, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = color);
    }
  }

  void _drawMockLayer(
    Canvas canvas,
    Size size,
    Color color,
    List<Offset> points,
  ) {
    final paint = Paint()..color = color.withValues(alpha: 0.18);
    for (final point in points) {
      canvas.drawCircle(
        Offset(size.width * point.dx, size.height * point.dy),
        22,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TerritorialMapPainter oldDelegate) {
    return oldDelegate.tareas != tareas ||
        oldDelegate.showBucLayer != showBucLayer ||
        oldDelegate.showRentasLayer != showRentasLayer;
  }
}

// ─── Inspector breakdown ───────────────────────────────────────────────────────

class _InspectorBreakdownPanel extends StatelessWidget {
  const _InspectorBreakdownPanel({
    required this.tareas,
    required this.inspectorEmails,
    required this.inspectorNames,
  });
  final List<Tarea> tareas;
  final List<String> inspectorEmails;
  final Map<String, String> inspectorNames;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_pin_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Rendimiento por inspector',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 600;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final email in inspectorEmails) ...[
                          Expanded(
                            child: _InspectorCard(
                              email: email,
                              nombre: inspectorNames[email] ?? email,
                              tareas: tareas
                                  .where((t) => t.asignadoA == email)
                                  .toList(),
                            ),
                          ),
                          if (email != inspectorEmails.last)
                            const SizedBox(width: 14),
                        ],
                      ],
                    )
                  : Column(
                      children: [
                        for (final email in inspectorEmails) ...[
                          _InspectorCard(
                            email: email,
                            nombre: inspectorNames[email] ?? email,
                            tareas: tareas
                                .where((t) => t.asignadoA == email)
                                .toList(),
                          ),
                          if (email != inspectorEmails.last)
                            const SizedBox(height: 10),
                        ],
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _InspectorCard extends StatelessWidget {
  const _InspectorCard({
    required this.email,
    required this.nombre,
    required this.tareas,
  });
  final String email;
  final String nombre;
  final List<Tarea> tareas;

  @override
  Widget build(BuildContext context) {
    final total = tareas.length;
    final completadas = tareas
        .where((t) => t.estado == TareaEstado.finalizada)
        .length;
    final enCurso = tareas.where((t) => t.estado == TareaEstado.enCurso).length;
    final pendientes = tareas
        .where((t) => t.estado == TareaEstado.pendiente)
        .length;
    final progress = total > 0 ? completadas / total : 0.0;
    final pct = (progress * 100).round();
    final initials = nombre.trim().split(' ').take(2).map((p) => p[0]).join();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre, style: Theme.of(context).textTheme.labelLarge),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: pct >= 50 ? AppColors.success : AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                pct >= 50 ? AppColors.success : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat(
                value: completadas,
                label: 'listas',
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              _MiniStat(
                value: enCurso,
                label: 'en curso',
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              _MiniStat(
                value: pendientes,
                label: 'pendientes',
                color: AppColors.textSecondary,
              ),
              const Spacer(),
              Text(
                '$total total',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Export popup ───────────────────────────────────────────────────────────────

class _ExportPopup extends StatelessWidget {
  const _ExportPopup({
    required this.onExport,
    required this.tareas,
    required this.inspectorNames,
  });
  final ValueChanged<String> onExport;
  final List<Tarea> tareas;
  final Map<String, String> inspectorNames;

  String _buildCsv() {
    final buf = StringBuffer();
    buf.writeln('ID,Titulo,Direccion,Inspector,Estado,Prioridad,Vencimiento,Lat,Lng');
    for (final t in tareas) {
      final inspector = inspectorNames[t.asignadoA] ?? t.asignadoA;
      final venc =
          '${t.vencimiento.day.toString().padLeft(2, '0')}/${t.vencimiento.month.toString().padLeft(2, '0')}/${t.vencimiento.year}';
      buf.writeln(
        '"${t.id}","${t.titulo}","${t.direccion}","$inspector","${t.estado.label}","${t.prioridad.label}","$venc","${t.lat}","${t.lng}"',
      );
    }
    return buf.toString();
  }

  String _buildGeoJson() {
    final features = tareas.map((t) {
      return '{"type":"Feature","geometry":{"type":"Point","coordinates":[${t.lng},${t.lat}]},'
          '"properties":{"id":"${t.id}","titulo":"${t.titulo}","estado":"${t.estado.label}","inspector":"${t.asignadoA}"}}';
    }).join(',');
    return '{"type":"FeatureCollection","features":[$features]}';
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Exportar datos',
      onSelected: (fmt) {
        onExport(fmt);
        switch (fmt) {
          case 'CSV':
            downloadText(_buildCsv(),
                'relevamientos_${DateTime.now().millisecondsSinceEpoch}.csv',
                mime: 'text/csv;charset=utf-8');
          case 'GeoJSON':
            downloadText(_buildGeoJson(),
                'relevamientos_${DateTime.now().millisecondsSinceEpoch}.geojson',
                mime: 'application/geo+json');
          default:
            break;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $fmt exportado con ${tareas.length} registros.'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'CSV',
          child: ListTile(
            leading: Icon(Icons.table_chart_outlined),
            title: Text('CSV'),
          ),
        ),
        PopupMenuItem(
          value: 'Excel',
          child: ListTile(
            leading: Icon(Icons.grid_on_outlined),
            title: Text('Excel (.xlsx)'),
          ),
        ),
        PopupMenuItem(
          value: 'GeoJSON',
          child: ListTile(
            leading: Icon(Icons.map_outlined),
            title: Text('GeoJSON'),
          ),
        ),
        PopupMenuItem(
          value: 'PDF',
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf_outlined),
            title: Text('Reporte PDF'),
          ),
        ),
      ],
      child: OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.download_outlined, size: 16),
        label: const Text('Exportar ▾'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$value'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: items,
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }
}

// ─── KPI card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(color: color),
              ),
            ],
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Progress panel ─────────────────────────────────────────────────────────────

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.tareas});
  final List<Tarea> tareas;

  @override
  Widget build(BuildContext context) {
    final total = tareas.length;
    final completadas = tareas
        .where((t) => t.estado == TareaEstado.finalizada)
        .length;
    final enCurso = tareas.where((t) => t.estado == TareaEstado.enCurso).length;
    final pendientes = tareas
        .where((t) => t.estado == TareaEstado.pendiente)
        .length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución por estado',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          _BarRow(
            label: 'Finalizadas',
            value: completadas,
            total: total,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          _BarRow(
            label: 'En curso',
            value: enCurso,
            total: total,
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          _BarRow(
            label: 'Pendientes',
            value: pendientes,
            total: total,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });
  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Text(
              '$value de $total',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (ctx, constraints) => Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                height: 10,
                width: constraints.maxWidth * pct,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Weekly chart ───────────────────────────────────────────────────────────────

class _WeeklyChartPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const maxVal = 7;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completados por semana (historial)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          for (final (label, val) in _weeklyData) ...[
            Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) => Stack(
                      children: [
                        Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          height: 22,
                          width: constraints.maxWidth * val / maxVal,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 20,
                  child: Text(
                    '$val',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ─── Date filter chip ──────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.date,
    required this.onPicked,
    required this.onCleared,
  });
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPicked;
  final VoidCallback onCleared;

  String get _text {
    if (date == null) return label;
    return '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(_text, style: const TextStyle(fontSize: 12)),
      avatar: date == null
          ? const Icon(Icons.calendar_today_outlined, size: 14)
          : null,
      deleteIcon: date != null ? const Icon(Icons.close, size: 14) : null,
      onDeleted: date != null ? onCleared : null,
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime(2026, 5, 1),
          firstDate: DateTime(2026, 1, 1),
          lastDate: DateTime(2026, 12, 31),
        );
        if (picked != null) onPicked(picked);
      },
      visualDensity: VisualDensity.compact,
      backgroundColor: date != null
          ? AppColors.accent.withValues(alpha: 0.10)
          : null,
      side: date != null
          ? BorderSide(color: AppColors.accent.withValues(alpha: 0.30))
          : null,
    );
  }
}

// ─── Tarea row ─────────────────────────────────────────────────────────────────

class _TareaRow extends StatelessWidget {
  const _TareaRow({required this.tarea, required this.inspectorNames});
  final Tarea tarea;
  final Map<String, String> inspectorNames;

  @override
  Widget build(BuildContext context) {
    final inspector = inspectorNames[tarea.asignadoA] ?? tarea.asignadoA;
    final venc =
        '${tarea.vencimiento.day.toString().padLeft(2, '0')}/${tarea.vencimiento.month.toString().padLeft(2, '0')}';
    final prioColor = switch (tarea.prioridad) {
      TareaPrioridad.alta => AppColors.error,
      TareaPrioridad.media => AppColors.warning,
      TareaPrioridad.baja => AppColors.success,
    };

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tarea.titulo, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(
                tarea.direccion,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            inspector,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        StatusBadge(label: tarea.prioridad.label, color: prioColor),
        const SizedBox(width: 8),
        Text(
          venc,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        StatusBadge.tarea(tarea.estado),
      ],
    );
  }
}
