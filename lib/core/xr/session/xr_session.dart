enum XrSessionState { idle, starting, running, paused, ended }

/// XR session state machine (Step 41.4–41.6).
class XrSession {
  XrSessionState _state = XrSessionState.idle;

  XrSessionState get state => _state;

  void start() {
    _ensure(XrSessionState.idle, 'start');
    _state = XrSessionState.running;
  }

  void pause() {
    _ensure(XrSessionState.running, 'pause');
    _state = XrSessionState.paused;
  }

  void resume() {
    _ensure(XrSessionState.paused, 'resume');
    _state = XrSessionState.running;
  }

  void end() {
    _ensure(XrSessionState.running, 'end');
    _state = XrSessionState.ended;
  }

  void _ensure(XrSessionState expected, String action) {
    if (_state != expected) {
      throw StateError('Cannot $action from ${_state.name}');
    }
  }
}
