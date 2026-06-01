import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/tarea.dart';
import '../../../core/state/demo_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  bool _syncing = false;
  bool _syncDone = false;
  int _autoSyncCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // RF-031 paso 7: auto-sync al detectar conectividad estable.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoSync());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _checkAutoSync() {
    final store = ref.read(demoStoreProvider);
    final hasPending = store.inspectorTasks
        .any((t) => t.syncEstado == SyncEstado.local);
    if (!store.offlineMode && hasPending && !_syncing) {
      setState(() => _autoSyncCountdown = 5);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        if (_autoSyncCountdown <= 1) {
          timer.cancel();
          setState(() => _autoSyncCountdown = 0);
          _doSync();
        } else {
          setState(() => _autoSyncCountdown--);
        }
      });
    }
  }

  Future<void> _doSync() async {
    _countdownTimer?.cancel();
    setState(() {
      _syncing = true;
      _syncDone = false;
      _autoSyncCountdown = 0;
    });
    await ref.read(demoStoreProvider).syncPending();
    if (mounted) {
      setState(() {
        _syncing = false;
        _syncDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // RF-031/RF-033: sincronizacion manual y estados por relevamiento.
    final store = ref.watch(demoStoreProvider);
    final inspectorTasks = store.inspectorTasks;
    final pending = inspectorTasks
        .where((task) => task.syncEstado == SyncEstado.local)
        .toList();
    final sincronizando = inspectorTasks
        .where((task) => task.syncEstado == SyncEstado.sincronizando)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_autoSyncCountdown > 0 && !_syncing) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_outlined, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Conectividad detectada — sincronizando automáticamente en $_autoSyncCountdown s.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _countdownTimer?.cancel();
                    setState(() => _autoSyncCountdown = 0);
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (_syncDone && pending.isEmpty && sincronizando.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_done_outlined, color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sincronización completada — todos los datos están en el servidor.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ] else if (pending.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.upload_outlined, color: AppColors.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${pending.length} relevamiento${pending.length != 1 ? 's' : ''} guardado${pending.length != 1 ? 's' : ''} localmente y listo${pending.length != 1 ? 's' : ''} para sincronizar.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    _syncing
                        ? Icons.sync
                        : (_syncDone && pending.isEmpty
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_upload_outlined),
                    color: _syncing
                        ? AppColors.accent
                        : (_syncDone && pending.isEmpty
                              ? AppColors.success
                              : AppColors.textSecondary),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estado de sincronización',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (_syncing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _syncing
                    ? 'Subiendo datos al servidor...'
                    : pending.isEmpty
                    ? 'Todo sincronizado. No hay datos pendientes.'
                    : '${pending.length} relevamiento${pending.length != 1 ? 's' : ''} pendiente${pending.length != 1 ? 's' : ''} en este dispositivo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: (_syncing || pending.isEmpty) ? null : _doSync,
                icon: _syncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync, size: 16),
                label: Text(
                  _syncing
                      ? 'Sincronizando...'
                      : pending.isEmpty
                      ? 'Todo al día'
                      : 'Sincronizar ahora',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: pending.isEmpty && !_syncing
                      ? AppColors.success
                      : AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final task in inspectorTasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.titulo,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.direccion,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            StatusBadge.tarea(task.estado),
                            StatusBadge.sync(task.syncEstado),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (task.syncEstado == SyncEstado.local) ...[
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _syncing
                          ? null
                          : () => ref.read(demoStoreProvider).syncTask(task.id),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 15),
                      label: const Text('Subir'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ] else if (task.syncEstado == SyncEstado.sincronizando) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
