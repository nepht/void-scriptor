import 'dart:async';

class DebouncedAutosave {
  DebouncedAutosave({this.delay = const Duration(milliseconds: 1500)});
  final Duration delay;
  Timer? _timer;
  void schedule(Future<void> Function() save) {
    _timer?.cancel();
    _timer = Timer(delay, save);
  }

  void dispose() => _timer?.cancel();
}
