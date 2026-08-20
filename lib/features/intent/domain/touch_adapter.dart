enum TouchKind { tap, longPress, swipe }

enum TouchIntent { none, select, edit }

class TouchSample {
  const TouchSample({
    required this.targetId,
    required this.kind,
    this.confidence = 1,
  });
  final String targetId;
  final TouchKind kind;
  final double confidence;
}

class VoiceTouchHint {
  const VoiceTouchHint({required this.targetId, required this.command});
  final String targetId;
  final String command;
}

class TouchResult {
  const TouchResult({required this.intent, required this.targetId});
  final TouchIntent intent;
  final String? targetId;
  bool get isActionable => intent != TouchIntent.none && targetId != null;
}

class TouchAdapter {
  const TouchAdapter();

  TouchResult interpret(TouchSample sample) {
    if (sample.confidence < .55) {
      return const TouchResult(intent: TouchIntent.none, targetId: null);
    }
    return TouchResult(
      intent: sample.kind == TouchKind.tap
          ? TouchIntent.select
          : TouchIntent.none,
      targetId: sample.kind == TouchKind.tap ? sample.targetId : null,
    );
  }

  TouchResult combine(TouchSample touch, VoiceTouchHint voice) {
    if (touch.targetId != voice.targetId || !interpret(touch).isActionable) {
      return const TouchResult(intent: TouchIntent.none, targetId: null);
    }
    final intent = voice.command.toLowerCase() == 'edit'
        ? TouchIntent.edit
        : TouchIntent.select;
    return TouchResult(intent: intent, targetId: touch.targetId);
  }
}
