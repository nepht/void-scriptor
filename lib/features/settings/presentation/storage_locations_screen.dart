import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/custom_storage_location.dart';
import '../../projects/presentation/project_persistence_providers.dart';

/// Durasi pesan hasil mutasi storage. vs-hunt-20260913-shell-settings BUG-06:
/// 300 ms membuat pesan "berhasil/gagal" lenyap hampir seketika; pesan hasil
/// aksi wajib bertahan minimal selama default Material (4 detik) agar
/// pengguna sempat membacanya.
const Duration _kResultSnackDuration = Duration(seconds: 4);

/// Storage location settings (roadmap 145.38 Core settings; plan 2026-09-11
/// Task 4 step 1: expose the production store mutations that had no caller).
///
/// Surfaces the REAL [CustomStorageLocationStore] state and wires three
/// working paths that previously lived only in domain tests:
/// set active location, relink, and a read-only probe. No invented values:
/// every number comes from the store or the probe result, and a failed
/// mutation is reported with the typed reason the store itself raises.
class StorageLocationsScreen extends ConsumerStatefulWidget {
  const StorageLocationsScreen({super.key, this.healthProbe});

  /// Seam for deterministic tests; production leaves it null and the store
  /// uses its own [DefaultStorageProbe].
  final StorageHealthProbe? healthProbe;

  @override
  ConsumerState<StorageLocationsScreen> createState() =>
      _StorageLocationsScreenState();
}

class _StorageLocationsScreenState
    extends ConsumerState<StorageLocationsScreen> {
  final TextEditingController _setActive = TextEditingController();
  final TextEditingController _relink = TextEditingController();
  final TextEditingController _probe = TextEditingController();

  CustomStorageLocationState? _state;
  String? _probeResult;
  String? _relinkResult;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _setActive.dispose();
    _relink.dispose();
    _probe.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final store = await ref.read(customStorageStoreProvider.future);
    final next = await store.load();
    if (!mounted) return;
    setState(() => _state = next);
  }

  Future<void> _mutate(
    String label,
    Future<void> Function(CustomStorageLocationStore store) action, {
    TextEditingController? clearOnSuccess,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final store = await ref.read(customStorageStoreProvider.future);
      await action(store);
      clearOnSuccess?.clear();
      await _refresh();
      messenger.showSnackBar(
        SnackBar(
          content: Text('$label berhasil.'),
          duration: _kResultSnackDuration,
        ),
      );
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$label gagal: $error'),
          duration: _kResultSnackDuration,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitRelink() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final store = await ref.read(customStorageStoreProvider.future);
      await store.relinkLocation(_relink.text, health: widget.healthProbe);
      _relink.clear();
      await _refresh();
      if (!mounted) return;
      setState(
        () => _relinkResult = 'Relink selesai. Lokasi aktif diperbarui.',
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Relink lokasi berhasil.'),
          duration: _kResultSnackDuration,
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _relinkResult = 'Relink gagal: $error');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Relink lokasi gagal: $error'),
          duration: _kResultSnackDuration,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runProbe() async {
    if (_busy) return;
    final location = _probe.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi lokasi yang ingin diuji.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await CustomStorageLocation.probe(
        location,
        health: widget.healthProbe,
      );
      if (!mounted) return;
      setState(() {
        _probeResult =
            'writable: ${result.writable} · gratis: '
            '${_formatBytes(result.freeBytes)} · ${result.reason.name}';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _probeResult = 'Probe gagal: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Locations'),
        actions: [
          IconButton(
            key: const ValueKey('storage-refresh'),
            tooltip: 'Muat ulang status penyimpanan',
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statusCard(state),
            const SizedBox(height: 16),
            _actionCard(
              title: 'Set lokasi aktif',
              fieldKey: const ValueKey('storage-set-active-field'),
              buttonKey: const ValueKey('storage-set-active-submit'),
              controller: _setActive,
              onSubmit: () => _mutate(
                'Set lokasi aktif',
                (store) => store.setActiveLocation(
                  _setActive.text,
                  health: widget.healthProbe,
                ),
                clearOnSuccess: _setActive,
              ),
            ),
            const SizedBox(height: 16),
            _actionCard(
              title: 'Relink lokasi',
              fieldKey: const ValueKey('storage-relink-field'),
              buttonKey: const ValueKey('storage-relink-submit'),
              controller: _relink,
              onSubmit: _submitRelink,
              result: _relinkResult,
              resultKey: const ValueKey('storage-relink-result'),
            ),
            const SizedBox(height: 16),
            _actionCard(
              title: 'Probe lokasi (read-only)',
              fieldKey: const ValueKey('storage-probe-field'),
              buttonKey: const ValueKey('storage-probe-run'),
              controller: _probe,
              onSubmit: _runProbe,
              result: _probeResult,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(CustomStorageLocationState? state) {
    final active = state?.activeLocation;
    final lines = <Widget>[
      const Text('Lokasi penyimpanan kustom'),
      const SizedBox(height: 8),
      if (state == null)
        const Text('Memuat status penyimpanan...')
      else if (active == null)
        const Text('Belum ada lokasi kustom aktif')
      else ...[
        Text(active),
        const SizedBox(height: 4),
        Text('Status: ${state.status.name}'),
      ],
      if (state != null && state.boundProjectId != null) ...[
        const SizedBox(height: 4),
        Text('Proyek terikat: ${state.boundProjectId}'),
      ],
    ];
    return Card(
      key: const ValueKey('storage-status-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines,
        ),
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required Key fieldKey,
    required Key buttonKey,
    required TextEditingController controller,
    required VoidCallback onSubmit,
    String? result,
    Key? resultKey,
  }) {
    final palette = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final field = TextField(
                  key: fieldKey,
                  controller: controller,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Path absolut',
                    border: OutlineInputBorder(),
                  ),
                );
                final button = FilledButton(
                  key: buttonKey,
                  onPressed: _busy ? null : onSubmit,
                  child: Text(_busy ? 'Memproses...' : 'Jalankan'),
                );
                if (constraints.maxWidth < 420) {
                  return Column(
                    children: [field, const SizedBox(height: 8), button],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: 8),
                    button,
                  ],
                );
              },
            ),
            if (result != null) ...[
              const SizedBox(height: 8),
              Text(
                result,
                key: resultKey,
                style: TextStyle(color: palette.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
