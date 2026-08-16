class AuditEvent {
  const AuditEvent({
    required this.actor,
    required this.action,
    required this.target,
    required this.timestamp,
  });

  final String actor;
  final String action;
  final String target;
  final DateTime timestamp;
}

/// Append-only audit log with ring-buffer cap (Step 37.10–37.12).
class AuditLog {
  AuditLog({required this.capacity});

  final int capacity;
  final List<AuditEvent> _events = [];

  List<AuditEvent> get events => List.unmodifiable(_events);

  void append({
    required String actor,
    required String action,
    required String target,
  }) {
    _events.add(
      AuditEvent(
        actor: actor,
        action: action,
        target: target,
        timestamp: DateTime.now().toUtc(),
      ),
    );
    while (_events.length > capacity) {
      _events.removeAt(0);
    }
  }

  List<AuditEvent> byActor(String actor) =>
      _events.where((e) => e.actor == actor).toList();

  List<AuditEvent> byAction(String action) =>
      _events.where((e) => e.action == action).toList();
}
