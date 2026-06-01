import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/usuario.dart';
import '../../core/state/demo_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';

// ─── Role metadata ─────────────────────────────────────────────────────────────

const _roleMeta = <String, _RoleMeta>{
  'R-01': _RoleMeta(
    color: AppColors.primary,
    icon: Icons.admin_panel_settings_outlined,
    description: 'Gestión global del sistema, organismos e integraciones.',
    accesos: ['Sistema global', 'Todos los módulos', 'Configuración'],
    entorno: 'Backoffice web',
    entornoIcon: Icons.computer_outlined,
  ),
  'R-02': _RoleMeta(
    color: AppColors.accent,
    icon: Icons.account_balance_outlined,
    description: 'Administra usuarios, roles y encuestas de su organismo.',
    accesos: ['Organismo Salud CBA', 'Encuestas', 'Tareas', 'Usuarios'],
    entorno: 'Backoffice web',
    entornoIcon: Icons.computer_outlined,
  ),
  'R-03': _RoleMeta(
    color: Color(0xFF7C3AED),
    icon: Icons.draw_outlined,
    description:
        'Diseña formularios y los envía al validador para su aprobación.',
    accesos: ['Dashboard de diseño', 'Builder de encuestas', 'Catálogo RF-007'],
    entorno: 'Backoffice web',
    entornoIcon: Icons.computer_outlined,
  ),
  'R-04': _RoleMeta(
    color: Color(0xFFD97706),
    icon: Icons.fact_check_outlined,
    description:
        'Revisa encuestas enviadas, aprueba o devuelve con observaciones.',
    accesos: ['Dashboard de revisión', 'Cola de aprobación', 'Hallazgos'],
    entorno: 'Backoffice web',
    entornoIcon: Icons.computer_outlined,
  ),
  'R-05': _RoleMeta(
    color: Color(0xFF0D9488),
    icon: Icons.map_outlined,
    description:
        'Asigna tareas a inspectores y monitorea el operativo en tiempo real.',
    accesos: [
      'Dashboard del operativo',
      'Asignación de tareas',
      'Calendario',
      'Sync',
    ],
    entorno: 'Backoffice web',
    entornoIcon: Icons.computer_outlined,
  ),
  'R-06': _RoleMeta(
    color: AppColors.success,
    icon: Icons.smartphone_outlined,
    description:
        'Ejecuta relevamientos en terreno. Opera en modo offline con sincronización.',
    accesos: [
      'Lista de tareas',
      'Formulario offline',
      'GPS + foto + firma',
      'Sincronizar',
    ],
    entorno: 'App mobile',
    entornoIcon: Icons.phone_android_outlined,
  ),
  'R-07': _RoleMeta(
    color: Color(0xFF0891B2),
    icon: Icons.bar_chart_outlined,
    description:
        'Consume los datos recolectados para análisis, reportes y visualización territorial.',
    accesos: [
      'Tableros configurables',
      'Filtros avanzados',
      'Exportar CSV/Excel/GeoJSON',
      'Reportes PDF',
    ],
    entorno: 'Backoffice web',
    entornoIcon: Icons.computer_outlined,
  ),
  'R-08': _RoleMeta(
    color: Color(0xFF64748B),
    icon: Icons.security_outlined,
    description:
        'Acceso de solo lectura al log de auditoría y historial de cambios del sistema.',
    accesos: [
      'Log de auditoría',
      'Historial por entidad',
      'Exportar registros',
      'Solo lectura',
    ],
    entorno: 'Backoffice web',
    entornoIcon: Icons.computer_outlined,
  ),
};

class _RoleMeta {
  const _RoleMeta({
    required this.color,
    required this.icon,
    required this.description,
    required this.accesos,
    required this.entorno,
    required this.entornoIcon,
  });
  final Color color;
  final IconData icon;
  final String description;
  final List<String> accesos;
  final String entorno;
  final IconData entornoIcon;
}

// ─── Screen ────────────────────────────────────────────────────────────────────

class DemoSelectorScreen extends ConsumerWidget {
  const DemoSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // RF-014/RF-015: selector demo de usuarios y roles sin autenticacion real.
    final store = ref.watch(demoStoreProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AppHeader(),
                  const SizedBox(height: 28),
                  _WorkflowRibbon(),
                  const SizedBox(height: 28),
                  Text(
                    'Seleccioná tu perfil de acceso',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cada perfil muestra una vista diferente del sistema según su rol en el proceso.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 760 ? 3 : 1;
                      final width = cols == 3
                          ? (constraints.maxWidth - 28) / 3
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          for (final user in store.usuarios)
                            SizedBox(
                              width: width,
                              child: _RoleCard(
                                user: user,
                                meta: _roleMeta[user.rolId]!,
                                onTap: () {
                                  ref.read(demoStoreProvider).selectUser(user);
                                  if (user.rolId == 'R-06') {
                                    context.go('/mobile/tasks');
                                  } else if (user.rolId == 'R-07') {
                                    context.go('/backoffice/analista');
                                  } else if (user.rolId == 'R-08') {
                                    context.go('/backoffice/auditoria');
                                  } else {
                                    context.go('/backoffice/dashboard');
                                  }
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.assignment_turned_in_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plataforma de Relevamientos Digitales',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Ministerio de Innovación · Provincia de Córdoba',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkflowRibbon extends StatelessWidget {
  static const _steps = [
    (
      icon: Icons.draw_outlined,
      label: 'Diseñar',
      sub: 'R-03 Disenador',
      color: Color(0xFF7C3AED),
    ),
    (
      icon: Icons.fact_check_outlined,
      label: 'Revisar',
      sub: 'R-04 Validador',
      color: Color(0xFFD97706),
    ),
    (
      icon: Icons.map_outlined,
      label: 'Coordinar',
      sub: 'R-05 Coordinador',
      color: Color(0xFF0D9488),
    ),
    (
      icon: Icons.smartphone_outlined,
      label: 'Ejecutar',
      sub: 'R-06 Inspector',
      color: AppColors.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flujo del operativo de relevamiento',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              if (isWide) {
                return Row(
                  children: [
                    for (var i = 0; i < _steps.length; i++) ...[
                      Expanded(child: _StepChip(step: _steps[i])),
                      if (i < _steps.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final step in _steps) _StepChip(step: step)],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.step});
  final ({IconData icon, String label, String sub, Color color}) step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: step.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: step.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(step.icon, size: 16, color: step.color),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: step.color,
                  ),
                ),
                Text(
                  step.sub,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.user,
    required this.meta,
    required this.onTap,
  });
  final Usuario user;
  final _RoleMeta meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(meta.icon, color: meta.color, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: meta.color.withValues(alpha: 0.22)),
                ),
                child: Text(
                  user.rolId,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: meta.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.rolNombre,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            meta.description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final acceso in meta.accesos)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    acceso,
                    style: TextStyle(
                      fontSize: 10,
                      color: meta.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(meta.entornoIcon, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  meta.entorno,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: meta.color,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Ingresar con este perfil'),
            ),
          ),
        ],
      ),
    );
  }
}
