import 'dart:async';

/// Single-isolate async mutex: [run] serializes asynchronous critical
/// sections in FIFO order.
///
/// Persistence read-modify-write flows (project registry load/upsert/
/// remove, atomic writes) must not interleave at await points; a plain
/// read-modify-write without this lock loses updates when two callers
/// overlap between their load and their save. This mutex guards the
/// in-process window only — cross-process durability is a separate
/// concern and stays out of scope here.
class AsyncMutex {
  Future<void>? _tail;

  /// Whether a [run] section is currently executing (or queued behind
  /// an executing one).
  bool get isLocked => _tail != null;

  /// Runs [section] after every previously queued section completes,
  /// propagating either its result or its error without blocking the
  /// queue for later callers.
  Future<T> run<T>(Future<T> Function() section) {
    final previous = _tail;
    final gate = Completer<void>();
    _tail = gate.future;
    final Future<T> result = previous == null
        ? section()
        : previous.then((_) => section());
    unawaited(
      result.then(
        (_) => _release(gate),
        onError: (Object _, StackTrace __) => _release(gate),
      ),
    );
    return result;
  }

  void _release(Completer<void> gate) {
    if (identical(_tail, gate.future)) _tail = null;
    gate.complete();
  }
}
