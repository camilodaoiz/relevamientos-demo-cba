import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/area_operativa.dart';
import '../../../core/models/encuesta.dart';
import '../../../core/models/tarea.dart';
import '../../../core/models/usuario.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';

class OrganismoScreen extends ConsumerWidget {
  const OrganismoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // RF-014/RF-015: vista de organismo con estadísticas y equipo.
    final store = ref.watch(demoStoreProvider);
    final tareas = store.tareas.toList();
    final encuestasPublicadas = store.encuestas
        .where((e) => e.estado == EncuestaEstado.publicada)
        .toList();
    final encuestasAprobadas = store.encuestas
        .where((e) => e.estado == EncuestaEstado.aprobada)
        .toList();
    final inspectores = store.usuarios.where((u) => u.rolId == 'R-06').toList();
    final pendientes = tareas
        .where((t) => t.estado == TareaEstado.pendiente)
        .length;
    final finalizadas = tareas
        .where((t) => t.estado == TareaEstado.finalizada)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: store.organismo.nombre,
          subtitle: 'Ministerio de Innovación · Provincia de Córdoba',
          action: const StatusBadge(
            label: 'Activo',
            color: AppColors.success,
            icon: Icons.verified_outlined,
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 700 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: cols == 4 ? 2.4 : 2.0,
              children: [
                _StatCard(
                  label: 'Encuestas publicadas',
                  value: '${encuestasPublicadas.length}',
                  icon: Icons.publish_outlined,
                  color: AppColors.success,
                ),
                _StatCard(
                  label: 'Inspectores activos',
                  value: '${inspectores.length}',
                  icon: Icons.people_alt_outlined,
                  color: AppColors.accent,
                ),
                _StatCard(
                  label: 'Tareas pendientes',
                  value: '$pendientes',
                  icon: Icons.assignment_outlined,
                  color: AppColors.warning,
                ),
                _StatCard(
                  label: 'Relevamientos completados',
                  value: '$finalizadas',
                  icon: Icons.check_circle_outline,
                  color: AppColors.primary,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _EncuestasActivasPanel(
                      publicadas: encuestasPublicadas,
                      aprobadas: encuestasAprobadas,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(flex: 2, child: _OrganismoInfoPanel()),
                ],
              );
            }
            return Column(
              children: [
                _EncuestasActivasPanel(
                  publicadas: encuestasPublicadas,
                  aprobadas: encuestasAprobadas,
                ),
                const SizedBox(height: 14),
                _OrganismoInfoPanel(),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        if (store.currentUser.rolId == 'R-02') ...[
          _ModosPreguntasPanel(store: store),
          const SizedBox(height: 22),
          _AreasOperativasPanel(areas: store.areas, usuarios: store.usuarios),
        ],
        const SizedBox(height: 22),
        _EquipoPanel(store: store),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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

class _EncuestasActivasPanel extends StatelessWidget {
  const _EncuestasActivasPanel({
    required this.publicadas,
    required this.aprobadas,
  });
  final List<Encuesta> publicadas;
  final List<Encuesta> aprobadas;

  @override
  Widget build(BuildContext context) {
    final all = [...publicadas, ...aprobadas];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.dynamic_form_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Encuestas activas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final enc in all) ...[
            _EncuestaRow(encuesta: enc),
            if (enc != all.last) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _EncuestaRow extends StatelessWidget {
  const _EncuestaRow({required this.encuesta});
  final Encuesta encuesta;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                encuesta.nombre,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${encuesta.preguntas.length} preguntas · ${encuesta.secciones.length} secciones · v${encuesta.version}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        StatusBadge.encuesta(encuesta.estado),
      ],
    );
  }
}

class _OrganismoInfoPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_outlined,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Datos del organismo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Jurisdiccion', value: 'Provincia de Córdoba'),
          _InfoRow(label: 'Area', value: 'Salud Pública'),
          _InfoRow(label: 'Codigo organismo', value: 'MSP-CBA-2026'),
          _InfoRow(label: 'Modulo', value: 'Relevamientos en campo'),
          _InfoRow(label: 'Vigencia operativo', value: 'Ene 2026 – Dic 2026'),
          _InfoRow(label: 'Estado', value: 'Operativo activo'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── RF-008: Configuracion de campos obligatorios por organismo ─────────────────

class _CamposObligatoriosPanel extends ConsumerWidget {
  const _CamposObligatoriosPanel({required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campos = store.camposEstandar;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_outlined,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campos requeridos por el organismo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RF-008 · Definí qué campos del catálogo son obligatorios en todas las encuestas de este organismo.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final campo in campos)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.data_object_outlined,
                    size: 16,
                    color: AppColors.accent.withValues(alpha: 0.70),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campo.etiqueta,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          campo.tipo.name,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: ref
                        .watch(demoStoreProvider)
                        .isCampoObligatorio(campo.id),
                    activeThumbColor: AppColors.accent,
                    onChanged: (_) => ref
                        .read(demoStoreProvider)
                        .toggleCampoObligatorio(campo.id),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los campos marcados como requeridos se agregan automáticamente al catálogo del diseñador y no podrán eliminarse.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.success),
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

// RF-009: configuración del modo de preguntas por organismo.
class _ModosPreguntasPanel extends ConsumerWidget {
  const _ModosPreguntasPanel({required this.store});
  final DemoStore store;

  static const _modos = [
    (
      id: 'libre',
      label: 'Libre',
      descripcion:
          'El diseñador puede agregar cualquier pregunta al formulario.',
      icon: Icons.lock_open_outlined,
      color: AppColors.success,
    ),
    (
      id: 'restringido',
      label: 'Restringido',
      descripcion:
          'Solo se permiten preguntas del catálogo de campos estandarizados.',
      icon: Icons.tune_outlined,
      color: AppColors.warning,
    ),
    (
      id: 'bloqueado',
      label: 'Bloqueado',
      descripcion: 'No se puede agregar ni eliminar preguntas. Solo lectura.',
      icon: Icons.lock_outlined,
      color: AppColors.error,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modo = ref.watch(demoStoreProvider).modoPreguntas;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo de preguntas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RF-009 · Controlá qué tipo de preguntas pueden agregar los diseñadores.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final m in _modos)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(demoStoreProvider).setModoPreguntas(m.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: modo == m.id
                              ? m.color.withValues(alpha: 0.10)
                              : AppColors.surface,
                          border: Border.all(
                            color: modo == m.id ? m.color : AppColors.border,
                            width: modo == m.id ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              m.icon,
                              size: 18,
                              color: modo == m.id
                                  ? m.color
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              m.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: modo == m.id
                                    ? m.color
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m.descripcion,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// RF-023: áreas operativas geográficas.
class _AreasOperativasPanel extends StatelessWidget {
  const _AreasOperativasPanel({required this.areas, required this.usuarios});
  final List<AreaOperativa> areas;
  final List<Usuario> usuarios;

  @override
  Widget build(BuildContext context) {
    final inspectorNames = {for (final u in usuarios) u.email: u.nombre};

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Áreas operativas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RF-023 · Zonas geográficas con inspectores asignados.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${areas.length} zonas',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < areas.length; i++) ...[
            _AreaRow(
              area: areas[i],
              inspectorNombre:
                  inspectorNames[areas[i].inspector] ?? areas[i].inspector,
            ),
            if (i < areas.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.area, required this.inspectorNombre});
  final AreaOperativa area;
  final String inspectorNombre;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.place_outlined,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(area.nombre, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(
                area.descripcion,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Inspector',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            Text(
              inspectorNombre,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EquipoPanel extends ConsumerWidget {
  const _EquipoPanel({required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarios = store.usuarios.toList();
    final tareas = store.tareas.toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_outlined,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Equipo asignado',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${usuarios.length} usuarios',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < usuarios.length; i++) ...[
            _EquipoRow(usuario: usuarios[i], tareas: tareas),
            if (i < usuarios.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _EquipoRow extends StatelessWidget {
  const _EquipoRow({required this.usuario, required this.tareas});
  final Usuario usuario;
  final List<Tarea> tareas;

  @override
  Widget build(BuildContext context) {
    final parts = usuario.nombre.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : usuario.nombre.isNotEmpty
        ? usuario.nombre[0]
        : '?';
    final userTareas = tareas
        .where((t) => t.asignadoA == usuario.email)
        .toList();
    final finalizadas = userTareas
        .where((t) => t.estado == TareaEstado.finalizada)
        .length;
    final isInspector = usuario.rolId == 'R-06';

    return Row(
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario.nombre,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                usuario.email,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(
              label: '${usuario.rolId} · ${usuario.rolNombre}',
              color: AppColors.primary,
            ),
            if (isInspector && userTareas.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '$finalizadas/${userTareas.length} tareas',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
