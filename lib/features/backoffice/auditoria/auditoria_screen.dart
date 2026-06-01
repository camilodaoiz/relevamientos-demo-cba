import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/web_download.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';

const _tiposAccion = [
  'TODOS',
  'CREAR_ENCUESTA',
  'ENVIAR_REVISION',
  'APROBAR',
  'PUBLICAR',
  'RECHAZAR',
  'CREAR_TAREA',
  'INICIAR',
  'COMPLETAR',
  'SINCRONIZAR',
  'VOLVER_BORRADOR',
  'CREAR_CAMPO',
  'ALTA_ORGANISMO',
  'ALTA_USUARIO',
];

// ─── Screen ────────────────────────────────────────────────────────────────────

class AuditoriaScreen extends ConsumerStatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  ConsumerState<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends ConsumerState<AuditoriaScreen> {
  String _search = '';
  String _filterAccion = 'TODOS';
  String _filterUsuario = 'TODOS';
  String _filterOrganismo = 'TODOS';
  String _filterEntidad = 'TODOS';
  DateTime? _filterFrom;
  DateTime? _filterTo;

  @override
  Widget build(BuildContext context) {
    // RF-038: log de auditoria de solo lectura para el Auditor R-08.
    final log = ref.watch(demoStoreProvider).auditLog;
    final acciones = {
      'TODOS',
      ..._tiposAccion,
      ...log.map((e) => e.accion),
    }.toList()..sort();
    final usuarios = {'TODOS', ...log.map((e) => e.email)}.toList()..sort();
    final organismos = {'TODOS', ...log.map((e) => e.organismo)}.toList()
      ..sort();
    final entidades = {'TODOS', ...log.map((e) => e.entidad)}.toList()..sort();

    final filtered = log.where((e) {
      if (_filterAccion != 'TODOS' && e.accion != _filterAccion) return false;
      if (_filterUsuario != 'TODOS' && e.email != _filterUsuario) return false;
      if (_filterOrganismo != 'TODOS' && e.organismo != _filterOrganismo) {
        return false;
      }
      if (_filterEntidad != 'TODOS' && e.entidad != _filterEntidad) {
        return false;
      }
      final timestamp = _parseAuditTimestamp(e.timestamp);
      if (_filterFrom != null && timestamp.isBefore(_filterFrom!)) return false;
      if (_filterTo != null &&
          timestamp.isAfter(_filterTo!.add(const Duration(days: 1)))) {
        return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!e.email.contains(q) &&
            !e.entidad.contains(q) &&
            !e.detalle.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Log de Auditoría',
          subtitle: 'Registro completo de acciones del sistema — solo lectura.',
          action: OutlinedButton.icon(
            onPressed: () {
              final buf = StringBuffer();
              buf.writeln('Fecha/Hora,Usuario,Rol,Organismo,Accion,Entidad,Detalle,Valor anterior,Valor nuevo');
              for (final e in filtered) {
                buf.writeln(
                  '"${e.timestamp}","${e.email}","${e.rolId}","${e.organismo}","${e.accion}","${e.entidad}","${e.detalle}","${e.valorAnterior ?? ''}","${e.valorNuevo ?? ''}"',
                );
              }
              downloadText(buf.toString(), 'auditoria_${DateTime.now().millisecondsSinceEpoch}.csv',
                  mime: 'text/csv;charset=utf-8');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ CSV exportado con ${filtered.length} eventos.'),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Exportar log'),
          ),
        ),
        const SizedBox(height: 22),

        // ── Summary KPIs ──────────────────────────────────────────────────
        LayoutBuilder(
          builder: (ctx, constraints) {
            final cols = constraints.maxWidth > 600 ? 3 : 1;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: cols == 3 ? 3.0 : 4.0,
              children: [
                _SummaryCard(
                  label: 'Total de eventos',
                  value: '${log.length}',
                  icon: Icons.list_alt_outlined,
                  color: AppColors.primary,
                ),
                _SummaryCard(
                  label: 'Usuarios involucrados',
                  value: '${log.map((e) => e.email).toSet().length}',
                  icon: Icons.people_alt_outlined,
                  color: AppColors.accent,
                ),
                _SummaryCard(
                  label: 'Tipos de acción',
                  value: '${log.map((e) => e.accion).toSet().length}',
                  icon: Icons.category_outlined,
                  color: const Color(0xFF7C3AED),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),

        // ── Filters ───────────────────────────────────────────────────────
        AppCard(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 330,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por usuario, entidad o descripción',
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              _AuditDropdown(
                label: 'Usuario',
                value: _filterUsuario,
                items: usuarios,
                onChanged: (value) => setState(() => _filterUsuario = value),
              ),
              _AuditDropdown(
                label: 'Organismo',
                value: _filterOrganismo,
                items: organismos,
                onChanged: (value) => setState(() => _filterOrganismo = value),
              ),
              _AuditDropdown(
                label: 'Entidad',
                value: _filterEntidad,
                items: entidades,
                onChanged: (value) => setState(() => _filterEntidad = value),
              ),
              _AuditDropdown(
                label: 'Acción',
                value: _filterAccion,
                items: acciones,
                onChanged: (value) => setState(() => _filterAccion = value),
              ),
              _AuditDateChip(
                label: 'Desde',
                date: _filterFrom,
                onPicked: (date) => setState(() => _filterFrom = date),
                onCleared: () => setState(() => _filterFrom = null),
              ),
              _AuditDateChip(
                label: 'Hasta',
                date: _filterTo,
                onPicked: (date) => setState(() => _filterTo = date),
                onCleared: () => setState(() => _filterTo = null),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _filterAccion = 'TODOS';
                  _filterUsuario = 'TODOS';
                  _filterOrganismo = 'TODOS';
                  _filterEntidad = 'TODOS';
                  _filterFrom = null;
                  _filterTo = null;
                }),
                icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                label: const Text('Limpiar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Table ─────────────────────────────────────────────────────────
        AppCard(
          child: filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Sin eventos para los filtros seleccionados.'),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          _ColHeader('Fecha / hora', flex: 2),
                          _ColHeader('Usuario', flex: 3),
                          _ColHeader('Acción', flex: 2),
                          _ColHeader('Entidad', flex: 2),
                          _ColHeader('Detalle · Valor anterior → nuevo', flex: 4),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    for (final entry in filtered) ...[
                      _AuditRow(entry: entry),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

DateTime _parseAuditTimestamp(String value) {
  final parts = value.split(RegExp(r'[/ :]'));
  if (parts.length < 5) return DateTime(2026);
  return DateTime(
    int.parse(parts[2]),
    int.parse(parts[1]),
    int.parse(parts[0]),
    int.parse(parts[3]),
    int.parse(parts[4]),
  );
}

class _AuditDropdown extends StatelessWidget {
  const _AuditDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$value'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final item in items)
            DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }
}

class _AuditDateChip extends StatelessWidget {
  const _AuditDateChip({
    required this.label,
    required this.date,
    required this.onPicked,
    required this.onCleared,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPicked;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final value = date == null
        ? label
        : '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}';
    return InputChip(
      label: Text(value),
      avatar: date == null
          ? const Icon(Icons.calendar_today_outlined, size: 14)
          : null,
      deleteIcon: date != null ? const Icon(Icons.close, size: 14) : null,
      onDeleted: date != null ? onCleared : null,
      onPressed: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime(2026, 5, 1),
          firstDate: DateTime(2026, 1, 1),
          lastDate: DateTime(2026, 12, 31),
        );
        if (selected != null) onPicked(selected);
      },
    );
  }
}

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.label, {required this.flex});
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.entry});
  final AuditEntry entry;

  static Color _colorFor(String accion) {
    if (accion == 'APROBAR' ||
        accion == 'PUBLICAR' ||
        accion == 'SINCRONIZAR' ||
        accion == 'COMPLETAR') {
      return AppColors.success;
    }
    if (accion == 'RECHAZAR') return AppColors.error;
    if (accion.startsWith('CREAR') || accion.startsWith('ALTA')) {
      return AppColors.accent;
    }
    if (accion == 'ENVIAR_REVISION') return const Color(0xFF7C3AED);
    if (accion == 'INICIAR') return AppColors.warning;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(entry.accion);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              entry.timestamp,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.email,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  entry.rolId,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.accion,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.entidad,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.detalle,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.valorAnterior != null || entry.valorNuevo != null)
                  Row(
                    children: [
                      if (entry.valorAnterior != null)
                        Container(
                          margin: const EdgeInsets.only(top: 3, right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '← ${entry.valorAnterior}',
                            style: const TextStyle(fontSize: 9, color: AppColors.error),
                          ),
                        ),
                      if (entry.valorNuevo != null)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '→ ${entry.valorNuevo}',
                            style: const TextStyle(fontSize: 9, color: AppColors.success),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(color: color),
              ),
              Text(
                label,
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
