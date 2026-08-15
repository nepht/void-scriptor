import 'dart:async';

/// Autosave journal (Step 24.33).
///
/// Records the mutation sequence numbers that are pending a durable save. The
/// journal is intentionally in-memory: the durable source of truth is the
/// project database's `mutationSequence` / `savedMutationSequence` markers,
/// and this journal only tracks the in-flight window for the save coordinator.
class AutosaveJournal {
  final List<int> _sequences = [];

  List<int> get entries => List.unmodifiable(_sequences);
  int? get lastSequence => _sequences.isEmpty ? null : _sequences.last;
  bool get pending => _sequences.isNotEmpty;

  void append(int sequence) {
    if (!_sequences.contains(sequence)) _sequences.add(sequence);
  }

  Future<void> clear() async => _sequences.clear();
}

/// Save coordinator (Step 24.35).
///
/// Bridges the mutation runtime's dirty state with debounced autosave. Every
/// mutation marks the coordinator dirty; after the debounce window elapses the
/// pending changes are persisted and journaled. `saveNow` forces an immediate
/// durable save (used before close/quit and migrations).
class SaveCoordinator {
  SaveCoordinator({
    this.autosaveInterval = const Duration(seconds: 2),
    required this._persist,
    Future<void> Function()? journal,
  }) : _journal = journal ?? (() async {});

  final Duration autosaveInterval;
  final Future<void> Function() _persist;
  final Future<void> Function() _journal;

  Timer? _timer;
  bool _dirty = false;
  bool _saving = false;

  bool get isDirty => _dirty;

  void markDirty() {
    _dirty = true;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(autosaveInterval, () => saveNow());
  }

  Future<void> saveNow() async {
    if (!_dirty || _saving) return;
    _saving = true;
    _timer?.cancel();
    try {
      await _persist();
      await _journal();
      _dirty = false;
    } finally {
      _saving = false;
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
    if (_dirty) await saveNow();
  }
}
