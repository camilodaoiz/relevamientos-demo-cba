import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/models/encuesta.dart';
import '../../../core/models/tarea.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/status_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // RF-036/RF-039: tablero operativo diferenciado por rol.
    final store = ref.watch(demoStoreProvider);
    return switch (store.currentUser.rolId) {
      'R-01' => _AdminSistemaDashboard(store: store),
      'R-02' => _AdminOrganismoDashboard(store: store),
      'R-05' => _CoordinadorDashboard(store: store),
      'R-03' => _DisenadorDashboard(store: store),
      'R-04' => _ValidadorDashboard(store: store),
      'R-06' => _InspectorDashboard(store: store),
      'R-07' => _AnalistaDashboard(store: store),
      'R-08' => _AuditorDashboard(store: store),
      _ => _AdminOrganismoDashboard(store: store),
    };
  }
}

// ─── COORDINADOR DE CAMPO (R-05) ───────────────────────────────────────────────

class _CoordinadorDashboard extends StatelessWidget {
  const _CoordinadorDashboard({required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final tareas = store.tareas.toList();
    final inspectorNames = <String, String>{
      for (final u in store.usuarios) u.email: u.nombre,
    };
    final encuestaNames = <String, String>{
      for (final e in store.encuestas) e.id: e.nombre,
    };
    final today = DateTime(2026, 5, 29);
    final pendientes = tareas
        .where((t) => t.estado == TareaEstado.pendiente)
        .length;
    final enCurso = tareas.where((t) => t.estado == TareaEstado.enCurso).length;
    final finalizadas = tareas
        .where((t) => t.estado == TareaEstado.finalizada)
        .length;
    final vencidas = tareas
        .where(
          (t) =>
              t.estado != TareaEstado.finalizada &&
              t.vencimiento.isBefore(today),
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeBanner(
          nombre: store.currentUser.nombre,
          rolNombre: store.currentUser.rolNombre,
          organismo: store.currentUser.organismo,
          color: AppColors.primary,
          primaryLabel: 'Nueva tarea',
          primaryIcon: Icons.add_task,
          primaryRoute: '/backoffice/tareas',
          secondaryLabel: 'Asignar lote',
          secondaryIcon: Icons.playlist_add,
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
              childAspectRatio: cols == 4 ? 2.0 : 1.8,
              children: [
                _CoordKpiCard(
                  label: 'Pendientes',
                  value: '$pendientes',
                  icon: Icons.assignment_outlined,
                  color: AppColors.accent,
                  trend: '+12%',
                  trendUp: true,
                ),
                _CoordKpiCard(
                  label: 'En campo ahora',
                  value: '$enCurso',
                  icon: Icons.route_outlined,
                  color: AppColors.warning,
                  trend: '+5%',
                  trendUp: true,
                ),
                _CoordKpiCard(
                  label: 'Finalizadas',
                  value: '$finalizadas',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  trend: '+8%',
                  trendUp: true,
                ),
                _CoordKpiCard(
                  label: 'Vencidas',
                  value: '$vencidas',
                  icon: Icons.schedule_outlined,
                  color: AppColors.error,
                  trend: '-3%',
                  trendUp: false,
                  alert: true,
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
                    flex: 5,
                    child: _ProgresoEncuestasPanel(
                      encuestas: store.encuestas.toList(),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 4,
                    child: _TareasVencidasPanel(
                      tareas: tareas,
                      today: today,
                      encuestaNames: encuestaNames,
                      inspectorNames: inspectorNames,
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _ProgresoEncuestasPanel(encuestas: store.encuestas.toList()),
                const SizedBox(height: 14),
                _TareasVencidasPanel(
                  tareas: tareas,
                  today: today,
                  encuestaNames: encuestaNames,
                  inspectorNames: inspectorNames,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        _InspectorPanel(tareas: tareas, inspectorNames: inspectorNames),
        const SizedBox(height: 22),
        Text(
          'Actividad reciente',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        AppDataTable(
          columns: const ['Fecha/hora', 'Usuario', 'Acción', 'Detalle'],
          rows: [
            for (final entry in store.auditLog.take(5))
              [
                Text(
                  entry.timestamp,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(inspectorNames[entry.email] ?? entry.email),
                Text(entry.accion, style: const TextStyle(fontSize: 11)),
                Text(entry.detalle, overflow: TextOverflow.ellipsis),
              ],
          ],
        ),
      ],
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.nombre,
    required this.rolNombre,
    required this.organismo,
    required this.color,
    required this.primaryLabel,
    required this.primaryIcon,
    this.primaryRoute,
    this.secondaryLabel,
    this.secondaryIcon,
    this.secondaryRoute,
  });
  final String nombre;
  final String rolNombre;
  final String organismo;
  final Color color;
  final String primaryLabel;
  final IconData primaryIcon;
  final String? primaryRoute;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final String? secondaryRoute;

  @override
  Widget build(BuildContext context) {
    final firstName = nombre.split(' ').first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Hola de nuevo, $firstName!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$rolNombre · $organismo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _BannerButton(
                label: primaryLabel,
                icon: primaryIcon,
                color: color,
                filled: true,
                route: primaryRoute,
              ),
              if (secondaryLabel != null && secondaryIcon != null)
                _BannerButton(
                  label: secondaryLabel!,
                  icon: secondaryIcon!,
                  color: color,
                  filled: false,
                  route: secondaryRoute,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    this.route,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final String? route;

  @override
  Widget build(BuildContext context) {
    void show() {
      if (route != null) {
        context.go(route!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Función disponible en entorno de producción.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    if (filled) {
      return ElevatedButton.icon(
        onPressed: show,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: show,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}

class _CoordKpiCard extends StatelessWidget {
  const _CoordKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendUp,
    this.alert = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool trendUp;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alert
              ? AppColors.error.withValues(alpha: 0.40)
              : AppColors.border,
          width: alert ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trendUp
                      ? AppColors.success.withValues(alpha: 0.10)
                      : AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${trendUp ? '↑' : '↓'} $trend',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: trendUp ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(color: color),
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

class _ProgresoEncuestasPanel extends StatelessWidget {
  const _ProgresoEncuestasPanel({required this.encuestas});
  final List<Encuesta> encuestas;

  static const _data = <String, (int, int)>{
    'enc-salud-2026': (64, 245),
    'enc-aprobada': (38, 189),
    'enc-revision': (22, 180),
    'enc-borrador': (8, 120),
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Progreso por relevamiento',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final enc in encuestas)
            if (_data.containsKey(enc.id)) ...[
              _SurveyProgressRow(
                nombre: enc.nombre,
                completadas: _data[enc.id]!.$1,
                total: _data[enc.id]!.$2,
              ),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

class _SurveyProgressRow extends StatelessWidget {
  const _SurveyProgressRow({
    required this.nombre,
    required this.completadas,
    required this.total,
  });
  final String nombre;
  final int completadas;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completadas / total : 0.0;
    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                nombre,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$completadas / $total ($percent%)',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(
              percent >= 50 ? AppColors.success : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TareasVencidasPanel extends StatelessWidget {
  const _TareasVencidasPanel({
    required this.tareas,
    required this.today,
    required this.encuestaNames,
    required this.inspectorNames,
  });
  final List<Tarea> tareas;
  final DateTime today;
  final Map<String, String> encuestaNames;
  final Map<String, String> inspectorNames;

  @override
  Widget build(BuildContext context) {
    final vencidas =
        tareas
            .where(
              (t) =>
                  t.estado != TareaEstado.finalizada &&
                  t.vencimiento.isBefore(today),
            )
            .toList()
          ..sort((a, b) => a.vencimiento.compareTo(b.vencimiento));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tareas vencidas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              if (vencidas.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${vencidas.length}',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (vencidas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Sin tareas vencidas',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            for (var i = 0; i < vencidas.length; i++) ...[
              _TareaVencidaCard(
                task: vencidas[i],
                today: today,
                encuestaNames: encuestaNames,
                inspectorNames: inspectorNames,
              ),
              if (i < vencidas.length - 1) const Divider(height: 20),
            ],
        ],
      ),
    );
  }
}

class _TareaVencidaCard extends StatelessWidget {
  const _TareaVencidaCard({
    required this.task,
    required this.today,
    required this.encuestaNames,
    required this.inspectorNames,
  });
  final Tarea task;
  final DateTime today;
  final Map<String, String> encuestaNames;
  final Map<String, String> inspectorNames;

  @override
  Widget build(BuildContext context) {
    final diasVencida = today.difference(task.vencimiento).inDays;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.titulo, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                inspectorNames[task.asignadoA] ?? task.asignadoA,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${diasVencida}d vencida',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      encuestaNames[task.encuestaId] ?? task.encuestaId,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Función disponible en entorno de producción.'),
              duration: Duration(seconds: 2),
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text('Reasignar', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

class _InspectorPanel extends StatelessWidget {
  const _InspectorPanel({required this.tareas, required this.inspectorNames});
  final List<Tarea> tareas;
  final Map<String, String> inspectorNames;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Tarea>> byInspector = {};
    for (final t in tareas) {
      byInspector.putIfAbsent(t.asignadoA, () => []).add(t);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people_alt_outlined,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Carga del equipo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final entry in byInspector.entries) ...[
            _InspectorRow(
              email: entry.key,
              nombre: inspectorNames[entry.key] ?? entry.key,
              tareas: entry.value,
            ),
            if (entry.key != byInspector.keys.last) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _InspectorRow extends StatelessWidget {
  const _InspectorRow({
    required this.email,
    required this.nombre,
    required this.tareas,
  });
  final String email;
  final String nombre;
  final List<Tarea> tareas;

  @override
  Widget build(BuildContext context) {
    final pendientes = tareas
        .where((t) => t.estado == TareaEstado.pendiente)
        .length;
    final enCurso = tareas.where((t) => t.estado == TareaEstado.enCurso).length;
    final finalizadas = tareas
        .where((t) => t.estado == TareaEstado.finalizada)
        .length;
    final total = tareas.length;
    final progress = total > 0 ? finalizadas / total : 0.0;
    final initials = _initials(nombre);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent.withValues(alpha: 0.12),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 11,
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
                  Text(email, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              '$finalizadas / $total',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.success),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _StatusDot(
              label: '$pendientes pendiente${pendientes != 1 ? 's' : ''}',
              color: AppColors.accent,
            ),
            _StatusDot(label: '$enCurso en curso', color: AppColors.warning),
            _StatusDot(
              label: '$finalizadas finalizada${finalizadas != 1 ? 's' : ''}',
              color: AppColors.success,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.label, required this.color});
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
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ─── DISENADOR DE ENCUESTAS (R-03) ────────────────────────────────────────────

class _DisenadorDashboard extends StatelessWidget {
  const _DisenadorDashboard({required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final borradores = store.encuestas
        .where((e) => e.estado == EncuestaEstado.borrador)
        .toList();
    final enRevision = store.encuestas
        .where((e) => e.estado == EncuestaEstado.enRevision)
        .toList();
    final rechazadas = store.encuestas
        .where((e) => e.estado == EncuestaEstado.rechazada)
        .toList();
    final aprobadas = store.encuestas
        .where((e) => e.estado == EncuestaEstado.aprobada)
        .toList();
    final publicadas = store.encuestas
        .where((e) => e.estado == EncuestaEstado.publicada)
        .toList();
    final aprobPubl = [...aprobadas, ...publicadas];
    final totalPreguntas = store.encuestas.fold(
      0,
      (sum, e) => sum + e.preguntas.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeBanner(
          nombre: store.currentUser.nombre,
          rolNombre: store.currentUser.rolNombre,
          organismo: store.currentUser.organismo,
          color: AppColors.accent,
          primaryLabel: 'Nueva encuesta',
          primaryIcon: Icons.add,
          primaryRoute: '/backoffice/encuestas',
          secondaryLabel: 'Ver catalogo',
          secondaryIcon: Icons.data_object_outlined,
          secondaryRoute: '/backoffice/encuestas',
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
              childAspectRatio: cols == 4 ? 2.2 : 2.0,
              children: [
                _KpiCard(
                  label: 'Mis borradores',
                  value: '${borradores.length}',
                  icon: Icons.article_outlined,
                  color: AppColors.accent,
                ),
                _KpiCard(
                  label: 'En revision',
                  value: '${enRevision.length}',
                  icon: Icons.pending,
                  color: AppColors.warning,
                ),
                _KpiCard(
                  label: 'Aprobadas / Publicadas',
                  value: '${aprobPubl.length}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                _KpiCard(
                  label: 'Preguntas disenadas',
                  value: '$totalPreguntas',
                  icon: Icons.quiz_outlined,
                  color: AppColors.primary,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        if (borradores.isNotEmpty)
          _CollapsibleSection(
            icon: Icons.edit_outlined,
            label: 'Pendiente tu acción',
            color: AppColors.accent,
            count: borradores.length,
            initiallyExpanded: true,
            children: [
              for (final survey in borradores)
                _DisenadorSurveyCard(survey: survey, actionable: true),
            ],
          ),
        if (rechazadas.isNotEmpty)
          _CollapsibleSection(
            icon: Icons.cancel_outlined,
            label: 'Rechazadas — requieren corrección',
            color: AppColors.error,
            count: rechazadas.length,
            initiallyExpanded: true,
            children: [
              for (final survey in rechazadas)
                _DisenadorSurveyCard(survey: survey, actionable: true),
            ],
          ),
        if (enRevision.isNotEmpty)
          _CollapsibleSection(
            icon: Icons.hourglass_top,
            label: 'Aguardando validación',
            color: AppColors.warning,
            count: enRevision.length,
            initiallyExpanded: true,
            children: [
              for (final survey in enRevision)
                _DisenadorSurveyCard(survey: survey, actionable: false),
            ],
          ),
        if (aprobadas.isNotEmpty)
          _CollapsibleSection(
            icon: Icons.check_circle_outline,
            label: 'Aprobadas',
            color: AppColors.accent,
            count: aprobadas.length,
            initiallyExpanded: false,
            children: [
              for (final survey in aprobadas)
                _DisenadorSurveyCard(survey: survey, actionable: false),
            ],
          ),
        if (publicadas.isNotEmpty)
          _CollapsibleSection(
            icon: Icons.publish_outlined,
            label: 'Publicadas',
            color: AppColors.success,
            count: publicadas.length,
            initiallyExpanded: false,
            children: [
              for (final survey in publicadas)
                _DisenadorSurveyCard(survey: survey, actionable: false),
            ],
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
    required this.count,
  });
  final IconData icon;
  final String label;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({
    required this.icon,
    required this.label,
    required this.color,
    required this.count,
    required this.children,
    this.initiallyExpanded = true,
  });
  final IconData icon;
  final String label;
  final Color color;
  final int count;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            for (final child in widget.children)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: child,
              ),
          ],
        ],
      ),
    );
  }
}

class _DisenadorSurveyCard extends StatelessWidget {
  const _DisenadorSurveyCard({required this.survey, required this.actionable});
  final Encuesta survey;
  final bool actionable;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go('/backoffice/encuestas/${survey.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge.encuesta(survey.estado),
                        const SizedBox(width: 8),
                        Text(
                          'v${survey.version}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      survey.nombre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      children: [
                        _MetaChip(
                          icon: Icons.quiz_outlined,
                          label: '${survey.preguntas.length} preguntas',
                        ),
                        _MetaChip(
                          icon: Icons.layers_outlined,
                          label: '${survey.secciones.length} secciones',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (actionable)
                FilledButton.icon(
                  onPressed: () =>
                      context.go('/backoffice/encuestas/${survey.id}'),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Editar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
          if (survey.secciones.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final seccion in survey.secciones)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      seccion,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ─── VALIDADOR / CONTROLADOR (R-04) ───────────────────────────────────────────

class _ValidadorDashboard extends StatelessWidget {
  const _ValidadorDashboard({required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final enRevision = store.encuestas
        .where((e) => e.estado == EncuestaEstado.enRevision)
        .toList();
    final rechazadas = store.encuestas
        .where((e) => e.estado == EncuestaEstado.rechazada)
        .toList();
    final aprobadas = store.encuestas
        .where((e) => e.estado == EncuestaEstado.aprobada)
        .length;
    final publicadas = store.encuestas
        .where((e) => e.estado == EncuestaEstado.publicada)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeBanner(
          nombre: store.currentUser.nombre,
          rolNombre: store.currentUser.rolNombre,
          organismo: store.currentUser.organismo,
          color: AppColors.warning,
          primaryLabel: 'Revisar encuestas',
          primaryIcon: Icons.rate_review,
          primaryRoute: '/backoffice/encuestas',
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
              childAspectRatio: cols == 4 ? 2.2 : 2.0,
              children: [
                _KpiCard(
                  label: 'Esperando tu revision',
                  value: '${enRevision.length}',
                  icon: Icons.rate_review,
                  color: AppColors.warning,
                ),
                _KpiCard(
                  label: 'Aprobadas',
                  value: '$aprobadas',
                  icon: Icons.thumb_up_alt,
                  color: AppColors.success,
                ),
                _KpiCard(
                  label: 'Publicadas',
                  value: '$publicadas',
                  icon: Icons.publish_outlined,
                  color: AppColors.primary,
                ),
                _KpiCard(
                  label: 'Devueltas al disenador',
                  value: '${rechazadas.length}',
                  icon: Icons.undo_outlined,
                  color: AppColors.error,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        if (enRevision.isNotEmpty) ...[
          _SectionLabel(
            icon: Icons.rate_review,
            label: 'Requieren tu revision',
            color: AppColors.warning,
            count: enRevision.length,
          ),
          const SizedBox(height: 12),
          for (final survey in enRevision)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ValidadorSurveyCard(survey: survey),
            ),
          const SizedBox(height: 10),
        ],
        if (enRevision.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 44,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No hay encuestas esperando revision.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'El Disenador de Encuestas te enviara nuevas cuando esten listas.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (rechazadas.isNotEmpty) ...[
          _SectionLabel(
            icon: Icons.undo_outlined,
            label: 'Devueltas al disenador',
            color: AppColors.error,
            count: rechazadas.length,
          ),
          const SizedBox(height: 12),
          for (final survey in rechazadas)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => context.go('/backoffice/encuestas/${survey.id}'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            survey.nombre,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            children: [
                              _MetaChip(
                                icon: Icons.quiz_outlined,
                                label: '${survey.preguntas.length} preguntas',
                              ),
                              _MetaChip(
                                icon: Icons.history,
                                label: 'v${survey.version}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    StatusBadge.encuesta(survey.estado),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ValidadorSurveyCard extends StatelessWidget {
  const _ValidadorSurveyCard({required this.survey});
  final Encuesta survey;

  static const _hallazgos = <String, List<String>>{
    'enc-revision': [
      'Verificar coherencia entre preguntas 3 y 7',
      'Campo CUIL sin validacion de formato',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final findings = _hallazgos[survey.id] ?? [];

    return AppCard(
      onTap: () => context.go('/backoffice/encuestas/${survey.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge.encuesta(survey.estado),
                        const SizedBox(width: 8),
                        Text(
                          'v${survey.version}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      survey.nombre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      children: [
                        _MetaChip(
                          icon: Icons.quiz_outlined,
                          label: '${survey.preguntas.length} preguntas',
                        ),
                        _MetaChip(
                          icon: Icons.layers_outlined,
                          label: '${survey.secciones.length} secciones',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () =>
                    context.go('/backoffice/encuestas/${survey.id}'),
                icon: const Icon(Icons.rate_review, size: 15),
                label: const Text('Revisar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          if (findings.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.flag_outlined,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  'Hallazgos preliminares',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.warning),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final f in findings)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─── INSPECTOR DE CAMPO (R-06) ────────────────────────────────────────────────

class _InspectorDashboard extends StatelessWidget {
  const _InspectorDashboard({required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final tareas = store.inspectorTasks;
    final pendientes = tareas
        .where((t) => t.estado == TareaEstado.pendiente)
        .length;
    final enCurso = tareas.where((t) => t.estado == TareaEstado.enCurso).length;
    final finalizadas = tareas
        .where((t) => t.estado == TareaEstado.finalizada)
        .length;
    final porSincronizar = tareas
        .where((t) => t.syncEstado == SyncEstado.local)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeBanner(
          nombre: store.currentUser.nombre,
          rolNombre: store.currentUser.rolNombre,
          organismo: store.currentUser.organismo,
          color: AppColors.primary,
          primaryLabel: 'Mis tareas',
          primaryIcon: Icons.assignment_outlined,
          secondaryLabel: 'Sincronizar',
          secondaryIcon: Icons.cloud_upload_outlined,
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
              childAspectRatio: cols == 4 ? 2.0 : 1.8,
              children: [
                _CoordKpiCard(
                  label: 'Pendientes',
                  value: '$pendientes',
                  icon: Icons.assignment_outlined,
                  color: AppColors.accent,
                  trend: '+2',
                  trendUp: true,
                ),
                _CoordKpiCard(
                  label: 'En campo ahora',
                  value: '$enCurso',
                  icon: Icons.route_outlined,
                  color: AppColors.warning,
                  trend: '=',
                  trendUp: true,
                ),
                _CoordKpiCard(
                  label: 'Finalizadas',
                  value: '$finalizadas',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  trend: '+1',
                  trendUp: true,
                ),
                _CoordKpiCard(
                  label: 'Por sincronizar',
                  value: '$porSincronizar',
                  icon: Icons.cloud_upload_outlined,
                  color: porSincronizar > 0
                      ? AppColors.warning
                      : AppColors.textSecondary,
                  trend: porSincronizar > 0 ? 'pendiente' : 'al dia',
                  trendUp: porSincronizar == 0,
                  alert: porSincronizar > 0,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.smartphone_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mis relevamientos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Para ejecutar un relevamiento, ingresá desde la app mobile.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < tareas.length; i++) ...[
                _InspectorTaskRow(tarea: tareas[i]),
                if (i < tareas.length - 1) const Divider(height: 20),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.cloud_sync_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estado de sincronizacion',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final syncVal in SyncEstado.values) ...[
                _SyncStatusRow(
                  estado: syncVal,
                  count: tareas.where((t) => t.syncEstado == syncVal).length,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InspectorTaskRow extends StatelessWidget {
  const _InspectorTaskRow({required this.tarea});
  final Tarea tarea;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tarea.titulo, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                tarea.direccion,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  StatusBadge.tarea(tarea.estado),
                  const SizedBox(width: 8),
                  StatusBadge.sync(tarea.syncEstado),
                ],
              ),
            ],
          ),
        ),
        Text(
          '${tarea.vencimiento.day}/${tarea.vencimiento.month}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SyncStatusRow extends StatelessWidget {
  const _SyncStatusRow({required this.estado, required this.count});
  final SyncEstado estado;
  final int count;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (estado) {
      SyncEstado.local => (
        'Sin subir al servidor',
        AppColors.warning,
        Icons.cloud_upload_outlined,
      ),
      SyncEstado.sincronizando => (
        'Sincronizando',
        AppColors.accent,
        Icons.sync,
      ),
      SyncEstado.sincronizado => (
        'Sincronizados',
        AppColors.success,
        Icons.cloud_done_outlined,
      ),
      SyncEstado.error => (
        'Con error de sync',
        AppColors.error,
        Icons.cloud_off_outlined,
      ),
    };

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── ADMIN DASHBOARD (R-01, R-02) ─────────────────────────────────────────────

// ─── ADMIN SISTEMA (R-01) — vista global de plataforma ────────────────────────

class _FirebaseStatusBanner extends ConsumerStatefulWidget {
  const _FirebaseStatusBanner({required this.store});
  final DemoStore store;

  @override
  ConsumerState<_FirebaseStatusBanner> createState() =>
      _FirebaseStatusBannerState();
}

class _FirebaseStatusBannerState extends ConsumerState<_FirebaseStatusBanner> {
  bool _seeding = false;

  Future<void> _forceSeed() async {
    setState(() => _seeding = true);
    await widget.store.seedFirebaseDemoData();
    if (mounted) {
      setState(() => _seeding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Datos sembrados en Firebase correctamente.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = FirebaseBootstrap.initialized;
    final color = connected ? AppColors.success : AppColors.error;
    final icon = connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined;
    final label = connected
        ? 'Firebase conectado — proyecto: relevamientos-demo-cba-2026'
        : 'Firebase no conectado — los datos no se persisten. Error: ${FirebaseBootstrap.lastError ?? "desconocido"}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (connected) ...[
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _seeding ? null : _forceSeed,
              icon: _seeding
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined, size: 14),
              label: Text(_seeding ? 'Sembrando...' : 'Forzar seed'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.40)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminSistemaDashboard extends StatelessWidget {
  const _AdminSistemaDashboard({required this.store});
  final DemoStore store;

  static const _organismos = [
    (
      nombre: 'Ministerio de Salud Pública',
      encuestas: 4,
      inspectores: 1,
      estado: 'Activo',
    ),
    (
      nombre: 'Dirección de Educación Primaria',
      encuestas: 2,
      inspectores: 0,
      estado: 'Activo',
    ),
    (
      nombre: 'Secretaría de Ambiente',
      encuestas: 0,
      inspectores: 0,
      estado: 'Configurando',
    ),
  ];

  static const _integraciones = [
    (
      nombre: 'CiDi · Ciudadano Digital',
      icono: Icons.account_circle_outlined,
      estado: 'Mock',
    ),
    (
      nombre: 'BUC · Banco Único de Ciudadanos',
      icono: Icons.people_alt_outlined,
      estado: 'Mock',
    ),
    (
      nombre: 'Rentas Córdoba',
      icono: Icons.receipt_long_outlined,
      estado: 'Mock',
    ),
    (nombre: 'ARCA / AFIP', icono: Icons.business_outlined, estado: 'Mock'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeBanner(
          nombre: store.currentUser.nombre,
          rolNombre: store.currentUser.rolNombre,
          organismo: 'Plataforma — acceso global',
          color: AppColors.primary,
          primaryLabel: 'Gestionar organismos',
          primaryIcon: Icons.account_balance_outlined,
          primaryRoute: '/backoffice/organismo',
          secondaryLabel: 'Catálogo RF-007',
          secondaryIcon: Icons.data_object_outlined,
          secondaryRoute: '/backoffice/encuestas',
        ),
        const SizedBox(height: 16),
        _FirebaseStatusBanner(store: store),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 700 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: cols == 4 ? 2.35 : 2.0,
              children: [
                _KpiCard(
                  label: 'Organismos registrados',
                  value: '3',
                  icon: Icons.account_balance_outlined,
                  color: AppColors.primary,
                ),
                _KpiCard(
                  label: 'Usuarios del sistema',
                  value: '${store.usuarios.length}',
                  icon: Icons.people_alt_outlined,
                  color: AppColors.accent,
                ),
                _KpiCard(
                  label: 'Campos estándar RF-007',
                  value: '${store.camposEstandar.length}',
                  icon: Icons.verified_outlined,
                  color: AppColors.success,
                ),
                _KpiCard(
                  label: 'Integraciones simuladas',
                  value: '4',
                  icon: Icons.hub_outlined,
                  color: Color(0xFF7C3AED),
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
                    child: _OrganismosPanel(organismos: _organismos),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 2,
                    child: _IntegracionesPanel(integraciones: _integraciones),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _OrganismosPanel(organismos: _organismos),
                const SizedBox(height: 14),
                _IntegracionesPanel(integraciones: _integraciones),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        _CatalogoRF007Panel(camposEstandar: store.camposEstandar),
      ],
    );
  }
}

class _OrganismosPanel extends StatelessWidget {
  const _OrganismosPanel({required this.organismos});
  final List<({String nombre, int encuestas, int inspectores, String estado})>
  organismos;

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
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Organismos conectados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${organismos.length}',
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
          for (var i = 0; i < organismos.length; i++) ...[
            _OrganismoRow(org: organismos[i]),
            if (i < organismos.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _OrganismoRow extends StatelessWidget {
  const _OrganismoRow({required this.org});
  final ({String nombre, int encuestas, int inspectores, String estado}) org;

  @override
  Widget build(BuildContext context) {
    final isActivo = org.estado == 'Activo';
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.account_balance_outlined,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(org.nombre, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 3),
              Text(
                '${org.encuestas} encuesta${org.encuestas != 1 ? 's' : ''} · ${org.inspectores} inspector${org.inspectores != 1 ? 'es' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        StatusBadge(
          label: org.estado,
          color: isActivo ? AppColors.success : AppColors.warning,
        ),
      ],
    );
  }
}

class _IntegracionesPanel extends StatelessWidget {
  const _IntegracionesPanel({required this.integraciones});
  final List<({String nombre, IconData icono, String estado})> integraciones;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hub_outlined,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Integraciones del sistema',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < integraciones.length; i++) ...[
            Row(
              children: [
                Icon(
                  integraciones[i].icono,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    integraciones[i].nombre,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                StatusBadge(
                  label: integraciones[i].estado,
                  color: AppColors.warning,
                ),
              ],
            ),
            if (i < integraciones.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _CatalogoRF007Panel extends StatelessWidget {
  const _CatalogoRF007Panel({required this.camposEstandar});
  final List<dynamic> camposEstandar;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Catálogo global RF-007',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 8),
              Text(
                '${camposEstandar.length} campos',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Campos estandarizados disponibles para todos los organismos.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final campo in camposEstandar)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        campo.etiqueta as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ADMIN ORGANISMO (R-02) — vista operativa del organismo ───────────────────

class _AdminOrganismoDashboard extends StatelessWidget {
  const _AdminOrganismoDashboard({required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final recentTasks = store.tareas.take(5).toList();
    final inspectorNames = <String, String>{
      for (final u in store.usuarios) u.email: u.nombre,
    };
    final activeSurveys = store.encuestas
        .where(
          (e) =>
              e.estado == EncuestaEstado.publicada ||
              e.estado == EncuestaEstado.aprobada,
        )
        .toList();
    final inspectores = store.usuarios.where((u) => u.rolId == 'R-06').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeBanner(
          nombre: store.currentUser.nombre,
          rolNombre: store.currentUser.rolNombre,
          organismo: store.currentUser.organismo,
          color: AppColors.accent,
          primaryLabel: 'Ver organismo',
          primaryIcon: Icons.account_balance_outlined,
          primaryRoute: '/backoffice/organismo',
          secondaryLabel: 'Gestionar usuarios',
          secondaryIcon: Icons.people_alt_outlined,
          secondaryRoute: '/backoffice/usuarios',
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 980
                ? 4
                : constraints.maxWidth > 560
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: columns == 1 ? 3.2 : 2.35,
              children: [
                _KpiCard(
                  label: 'Encuestas publicadas',
                  value: '${store.publicadas}',
                  icon: Icons.publish_outlined,
                  color: AppColors.success,
                ),
                _KpiCard(
                  label: 'Tareas pendientes',
                  value: '${store.pendientes}',
                  icon: Icons.assignment_late_outlined,
                  color: AppColors.accent,
                ),
                _KpiCard(
                  label: 'Inspectores activos',
                  value: '$inspectores',
                  icon: Icons.smartphone_outlined,
                  color: AppColors.warning,
                ),
                _KpiCard(
                  label: 'Relevamientos completados',
                  value: '${store.finalizadas + store.syncedDemoRelevamientos}',
                  icon: Icons.cloud_done_outlined,
                  color: AppColors.primary,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tareas recientes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  AppDataTable(
                    columns: const ['Tarea', 'Inspector', 'Estado', 'Sync'],
                    rows: [
                      for (final task in recentTasks)
                        [
                          Text(task.titulo),
                          Text(
                            inspectorNames[task.asignadoA] ?? task.asignadoA,
                          ),
                          StatusBadge.tarea(task.estado),
                          StatusBadge.sync(task.syncEstado),
                        ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Encuestas activas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  for (final survey in activeSurveys)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () =>
                            context.go('/backoffice/encuestas/${survey.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusBadge.encuesta(survey.estado),
                            const SizedBox(height: 10),
                            Text(
                              survey.nombre,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${survey.preguntas.length} preguntas · v${survey.version}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── SHARED WIDGETS ────────────────────────────────────────────────────────────

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
              Icon(icon, color: color),
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

// ─── HELPERS ───────────────────────────────────────────────────────────────────

String _initials(String nombre) {
  final parts = nombre.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
  return nombre.isNotEmpty ? nombre[0] : '?';
}

// ─── ANALISTA / VISUALIZADOR (R-07) ───────────────────────────────────────────

class _AnalistaDashboard extends StatelessWidget {
  const _AnalistaDashboard({required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final tareas = store.tareas.toList();
    final total = tareas.length;
    final completadas = tareas
        .where((t) => t.estado == TareaEstado.finalizada)
        .length;
    final tasa = total > 0 ? (completadas / total * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeBanner(
          nombre: store.currentUser.nombre,
          rolNombre: store.currentUser.rolNombre,
          organismo: store.currentUser.organismo,
          color: const Color(0xFF0891B2),
          primaryLabel: 'Ver tablero completo',
          primaryIcon: Icons.bar_chart_outlined,
          primaryRoute: '/backoffice/analista',
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final cols = constraints.maxWidth > 600 ? 3 : 1;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 3.0,
              children: [
                _KpiCard(
                  label: 'Total relevamientos',
                  value: '$total',
                  icon: Icons.assignment_outlined,
                  color: AppColors.primary,
                ),
                _KpiCard(
                  label: 'Completados',
                  value: '$completadas',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                _KpiCard(
                  label: 'Completitud',
                  value: '$tasa%',
                  icon: Icons.trending_up_outlined,
                  color: const Color(0xFF0891B2),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Relevamientos recientes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < tareas.take(5).length; i++) ...[
                Row(
                  children: [
                    Icon(
                      tareas[i].estado == TareaEstado.finalizada
                          ? Icons.check_circle_outline
                          : tareas[i].estado == TareaEstado.enCurso
                          ? Icons.radio_button_unchecked
                          : Icons.schedule_outlined,
                      size: 16,
                      color: tareas[i].estado == TareaEstado.finalizada
                          ? AppColors.success
                          : tareas[i].estado == TareaEstado.enCurso
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tareas[i].titulo,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    StatusBadge.tarea(tareas[i].estado),
                  ],
                ),
                if (i < tareas.take(5).length - 1) const Divider(height: 18),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/backoffice/analista'),
                  icon: const Icon(Icons.open_in_new, size: 15),
                  label: const Text(
                    'Ver tablero completo con filtros y exportación',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── AUDITOR (R-08) ───────────────────────────────────────────────────────────

class _AuditorDashboard extends StatelessWidget {
  const _AuditorDashboard({required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final recentLog = store.auditLog.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeBanner(
          nombre: store.currentUser.nombre,
          rolNombre: store.currentUser.rolNombre,
          organismo: store.currentUser.organismo,
          color: const Color(0xFF64748B),
          primaryLabel: 'Ver log de auditoría',
          primaryIcon: Icons.security_outlined,
          primaryRoute: '/backoffice/auditoria',
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final cols = constraints.maxWidth > 600 ? 3 : 1;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 3.0,
              children: [
                _KpiCard(
                  label: 'Total eventos',
                  value: '${store.auditLog.length}',
                  icon: Icons.list_alt_outlined,
                  color: AppColors.primary,
                ),
                _KpiCard(
                  label: 'Usuarios registrados',
                  value: '${store.usuarios.length}',
                  icon: Icons.people_alt_outlined,
                  color: AppColors.accent,
                ),
                _KpiCard(
                  label: 'Tipos de acción',
                  value:
                      '${store.auditLog.map((e) => e.accion).toSet().length}',
                  icon: Icons.category_outlined,
                  color: const Color(0xFF64748B),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Eventos recientes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  const StatusBadge(
                    label: 'Solo lectura',
                    color: AppColors.textSecondary,
                    icon: Icons.lock_outline,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < recentLog.length; i++) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        recentLog[i].timestamp,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recentLog[i].email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        recentLog[i].accion,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (i < recentLog.length - 1) const Divider(height: 18),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/backoffice/auditoria'),
                  icon: const Icon(Icons.open_in_new, size: 15),
                  label: const Text(
                    'Ver log completo con filtros y exportación',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
