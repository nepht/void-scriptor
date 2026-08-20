enum CancelGesture { escape, secondTap, swipeAway }

enum DeviceCapability {
  touch,
  gaze,
  voice,
  bci;

  bool supports(String input) {
    const map = {
      DeviceCapability.touch: {'tap', 'longPress', 'swipe'},
      DeviceCapability.gaze: {'dwell'},
      DeviceCapability.voice: {'command'},
      DeviceCapability.bci: {'signal'},
    };
    return map[this]!.contains(input);
  }
}

class InputSafetyPolicy {
  InputSafetyPolicy({Map<String, double>? thresholds})
    : _thresholds = Map.unmodifiable(thresholds ?? const {});

  final Map<String, double> _thresholds;
  String? _pendingCommand;
  String? get pendingCommand => _pendingCommand;

  bool allow(
    String command, {
    required double confidence,
    required bool deliberate,
    bool confirmed = false,
  }) {
    if (!deliberate) return false;
    final threshold = _thresholds[command] ?? .7;
    if (confidence < threshold) return false;
    const destructive = {'delete', 'remove', 'destroy'};
    return !destructive.contains(command) || confirmed;
  }

  void beginPending(String command) => _pendingCommand = command;

  bool cancel(CancelGesture gesture) {
    if (_pendingCommand == null) return false;
    _pendingCommand = null;
    return true;
  }
}
