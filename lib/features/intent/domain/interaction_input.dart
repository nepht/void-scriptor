enum InteractionInputType {
  voice,
  gesture,
  gaze,
  stylus,
  touch,
  keyboard,
  context,
  bci,
}

class InteractionEvent {
  InteractionEvent({
    required this.id,
    required this.type,
    required String payload,
    double confidence = 1,
    DateTime? timestamp,
  }) : payload = _requirePayload(payload),
       confidence = confidence.clamp(0, 1).toDouble(),
       timestamp = timestamp ?? DateTime.now().toUtc();

  final String id;
  final InteractionInputType type;
  final String payload;
  final double confidence;
  final DateTime timestamp;

  static String _requirePayload(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ArgumentError.value(value, 'payload');
    return normalized;
  }
}

class NormalizedInput {
  const NormalizedInput({
    required this.eventId,
    required this.type,
    required this.text,
    required this.confidence,
    required this.sourceTimestamp,
  });

  factory NormalizedInput.fromEvent(InteractionEvent event) => NormalizedInput(
    eventId: event.id,
    type: event.type,
    text: event.payload.toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
    confidence: event.confidence,
    sourceTimestamp: event.timestamp,
  );

  final String eventId;
  final InteractionInputType type;
  final String text;
  final double confidence;
  final DateTime sourceTimestamp;
}
