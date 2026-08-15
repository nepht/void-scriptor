import 'dart:async';

import 'search_document.dart';

/// Incremental search index update queue (Step 26.33) with work coalescing
/// (Step 26.74).
///
/// Repeated updates to the same entity within [window] collapse to a single
/// document (latest wins) so the search index is written once instead of on
/// every keystroke.
class SearchIndexQueue {
  SearchIndexQueue({this.window = const Duration(milliseconds: 250)});

  final Duration window;

  final Map<String, SearchDocument> _pending = {};
  Timer? _timer;
  Future<void> Function(List<SearchDocument> documents)? _sink;
  bool _flushing = false;

  Future<void> start(
    Future<void> Function(List<SearchDocument> documents) sink,
  ) async {
    _sink = sink;
  }

  void enqueue(SearchDocument document) {
    _pending[document.entityId] = document;
    _timer?.cancel();
    _timer = Timer(window, () {
      unawaited(flush());
    });
  }

  Future<void> flush() async {
    if (_flushing || _pending.isEmpty) return;
    _flushing = true;
    _timer?.cancel();
    final batch = _pending.values.toList(growable: false);
    _pending.clear();
    try {
      await _sink?.call(batch);
    } finally {
      _flushing = false;
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    await flush();
  }
}
