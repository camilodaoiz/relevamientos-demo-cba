import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/tarea.dart';
import '../../../core/models/usuario.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';

const _roles = <String, String>{
  'R-01': 'Administrador del Sistema',
  'R-02': 'Administrador de Organismo',
  'R-03': 'Disenador de Encuestas',
  'R-04': 'Validador / Controlador',
  'R-05': 'Coordinador de Campo',
  'R-06': 'Inspector de Campo',
  'R-07': 'Analista / Visualizador',
  'R-08': 'Auditor',
};

class UsuariosScreen extends ConsumerWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // RF-014/RF-015/RF-016: gestión de usuarios, roles y permisos.
    final store = ref.watch(demoStoreProvider);
    final usuarios = store.usuarios.toList();
    final tareas = store.tareas.toList();

    final inspectores = usuarios.where((u) => u.rolId == 'R-06').toList();
    final staff = usuarios.where((u) => u.rolId != 'R-06').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Usuarios',
          subtitle: 'Usuarios registrados · gestión de roles y accesos.',
          action: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(demoStoreProvider).importUsuariosCsvMock();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'CSV mock procesado · inspector3@demo.com incorporado.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file_outlined, size: 16),
                label: const Text('Importar CSV'),
              ),
              FilledButton.icon(
                onPressed: () => _showUsuarioDialog(context, ref),
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Nuevo usuario'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 700 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: cols == 4 ? 3.0 : 2.2,
              children: [
                _SummaryCard(
                  label: 'Total usuarios',
                  value: '${usuarios.length}',
                  icon: Icons.people_alt_outlined,
                  color: AppColors.primary,
                ),
                _SummaryCard(
                  label: 'Inspectores',
                  value: '${inspectores.length}',
                  icon: Icons.smartphone_outlined,
                  color: AppColors.accent,
                ),
                _SummaryCard(
                  label: 'Coordinadores',
                  value: '${usuarios.where((u) => u.rolId == 'R-05').length}',
                  icon: Icons.manage_accounts_outlined,
                  color: AppColors.warning,
                ),
                _SummaryCard(
                  label: 'Activos',
                  value:
                      '${usuarios.where((u) => u.estado == 'Activo').length}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        if (inspectores.isNotEmpty) ...[
          _SectionLabel(
            icon: Icons.smartphone_outlined,
            label: 'Inspectores de campo',
            count: inspectores.length,
            color: AppColors.accent,
          ),
          const SizedBox(height: 12),
          for (final inspector in inspectores)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InspectorCard(
                usuario: inspector,
                tareas: tareas
                    .where((t) => t.asignadoA == inspector.email)
                    .toList(),
                onEdit: () => _showUsuarioDialog(context, ref, inspector),
                onToggleState: () => ref
                    .read(demoStoreProvider)
                    .toggleUsuarioEstado(inspector.id),
              ),
            ),
          const SizedBox(height: 10),
        ],
        if (staff.isNotEmpty) ...[
          _SectionLabel(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Personal de backoffice',
            count: staff.length,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                for (var i = 0; i < staff.length; i++) ...[
                  _StaffRow(
                    usuario: staff[i],
                    onEdit: () => _showUsuarioDialog(context, ref, staff[i]),
                    onToggleState: () => ref
                        .read(demoStoreProvider)
                        .toggleUsuarioEstado(staff[i].id),
                  ),
                  if (i < staff.length - 1) const Divider(height: 20),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showUsuarioDialog(
    BuildContext context,
    WidgetRef ref, [
    Usuario? usuario,
  ]) async {
    final nombre = TextEditingController(text: usuario?.nombre ?? '');
    final email = TextEditingController(text: usuario?.email ?? '');
    final organismo = TextEditingController(
      text: usuario?.organismo ?? 'Ministerio de Salud Publica - Cordoba',
    );
    var rolId = usuario?.rolId ?? 'R-06';
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(usuario == null ? 'Nuevo usuario' : 'Editar usuario'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: rolId,
                  decoration: const InputDecoration(labelText: 'Rol RBAC'),
                  items: [
                    for (final role in _roles.entries)
                      DropdownMenuItem(
                        value: role.key,
                        child: Text('${role.key} · ${role.value}'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => rolId = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: organismo,
                  decoration: const InputDecoration(labelText: 'Organismo'),
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
              onPressed: nombre.text.trim().isEmpty || email.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      final store = ref.read(demoStoreProvider);
      if (usuario == null) {
        store.createUsuario(
          nombre: nombre.text.trim(),
          email: email.text.trim(),
          rolId: rolId,
          rolNombre: _roles[rolId]!,
          organismo: organismo.text.trim(),
        );
      } else {
        store.updateUsuario(
          usuario.id,
          nombre: nombre.text.trim(),
          email: email.text.trim(),
          rolId: rolId,
          rolNombre: _roles[rolId]!,
          organismo: organismo.text.trim(),
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              usuario == null
                  ? 'Usuario creado · activación mock enviada por email.'
                  : 'Usuario actualizado.',
            ),
          ),
        );
      }
    }
    nombre.dispose();
    email.dispose();
    organismo.dispose();
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int count;
  final Color color;

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

class _InspectorCard extends StatelessWidget {
  const _InspectorCard({
    required this.usuario,
    required this.tareas,
    required this.onEdit,
    required this.onToggleState,
  });
  final Usuario usuario;
  final List<Tarea> tareas;
  final VoidCallback onEdit;
  final VoidCallback onToggleState;

  @override
  Widget build(BuildContext context) {
    final pendientes = tareas
        .where((t) => t.estado == TareaEstado.pendiente)
        .length;
    final enCurso = tareas.where((t) => t.estado == TareaEstado.enCurso).length;
    final finalizadas = tareas
        .where((t) => t.estado == TareaEstado.finalizada)
        .length;
    final porSync = tareas
        .where((t) => t.syncEstado == SyncEstado.local)
        .length;
    final progress = tareas.isNotEmpty ? finalizadas / tareas.length : 0.0;
    final initials = _initials(usuario.nombre);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nombre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      usuario.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(
                    label: usuario.estado,
                    color: usuario.estado == 'Activo'
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(
                    label: '${usuario.rolId} · Inspector',
                    color: AppColors.accent,
                  ),
                ],
              ),
              _UserMenu(onEdit: onEdit, onToggleState: onToggleState),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progreso de tareas',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 14,
                      children: [
                        _Dot(
                          label:
                              '$pendientes pendiente${pendientes != 1 ? 's' : ''}',
                          color: AppColors.accent,
                        ),
                        _Dot(
                          label: '$enCurso en curso',
                          color: AppColors.warning,
                        ),
                        _Dot(
                          label:
                              '$finalizadas finalizada${finalizadas != 1 ? 's' : ''}',
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$finalizadas / ${tareas.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (porSync > 0)
                    StatusBadge(
                      label: '$porSync por sincronizar',
                      color: AppColors.warning,
                      icon: Icons.cloud_upload_outlined,
                    )
                  else
                    const StatusBadge(
                      label: 'Sincronizado',
                      color: AppColors.success,
                      icon: Icons.cloud_done_outlined,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            usuario.organismo,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.usuario,
    required this.onEdit,
    required this.onToggleState,
  });
  final Usuario usuario;
  final VoidCallback onEdit;
  final VoidCallback onToggleState;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(usuario.nombre);
    final roleColor = switch (usuario.rolId) {
      'R-01' => AppColors.primary,
      'R-02' => AppColors.accent,
      'R-03' => AppColors.accent,
      'R-04' => AppColors.warning,
      'R-05' => AppColors.primary,
      _ => AppColors.textSecondary,
    };

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: roleColor.withValues(alpha: 0.12),
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 11,
              color: roleColor,
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
              color: roleColor,
            ),
            const SizedBox(height: 4),
            StatusBadge(
              label: usuario.estado,
              color: usuario.estado == 'Activo'
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
          ],
        ),
        _UserMenu(onEdit: onEdit, onToggleState: onToggleState),
      ],
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.onEdit, required this.onToggleState});
  final VoidCallback onEdit;
  final VoidCallback onToggleState;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Acciones de usuario',
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'state') onToggleState();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined, size: 18),
            title: Text('Editar'),
          ),
        ),
        PopupMenuItem(
          value: 'state',
          child: ListTile(
            leading: Icon(Icons.person_off_outlined, size: 18),
            title: Text('Cambiar estado'),
          ),
        ),
      ],
    );
  }
}

String _initials(String nombre) {
  final parts = nombre.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
  return nombre.isNotEmpty ? nombre[0] : '?';
}
