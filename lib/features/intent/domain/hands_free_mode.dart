class HandsFreeMode {
  bool _enabled = false;

  bool get isEnabled => _enabled;

  bool setEnabled(bool enabled) {
    _enabled = enabled;
    return _enabled;
  }

  bool accept(String command, {bool confirmed = false}) {
    if (!_enabled) return false;

    const destructive = {'delete', 'remove', 'destroy'};
    if (destructive.contains(command)) return confirmed;

    return command.trim().isNotEmpty;
  }
}
