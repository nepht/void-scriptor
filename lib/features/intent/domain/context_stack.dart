typedef IntentClock = DateTime Function();

class IntentContext {
  const IntentContext({
    required this.id,
    required this.value,
    this.ttl,
    this.createdAt,
  });

  final String id;
  final String value;
  final Duration? ttl;
  final DateTime? createdAt;

  bool isExpired(DateTime now) {
    final created = createdAt;
    final lifetime = ttl;
    return created != null &&
        lifetime != null &&
        !now.isBefore(created.add(lifetime));
  }
}

class IntentContextStack {
  IntentContextStack({IntentClock? clock}) : _clock = clock ?? DateTime.now;

  final IntentClock _clock;
  final List<IntentContext> _contexts = [];

  void push(IntentContext context) {
    final timestamped = context.createdAt == null
        ? IntentContext(
            id: context.id,
            value: context.value,
            ttl: context.ttl,
            createdAt: _clock(),
          )
        : context;
    _contexts.removeWhere((item) => item.id == timestamped.id);
    _contexts.add(timestamped);
  }

  Iterable<IntentContext> get active =>
      _contexts.reversed.where((context) => !context.isExpired(_clock()));

  IntentContext? get current => active.isEmpty ? null : active.first;

  int expire() {
    final before = _contexts.length;
    _contexts.removeWhere((context) => context.isExpired(_clock()));
    return before - _contexts.length;
  }
}
