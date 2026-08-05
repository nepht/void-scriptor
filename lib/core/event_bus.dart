// Void Scriptor Event Bus — v1.0.0
// StatusBar feedback live + AiPanel aiRefresh via event-driven architecture.

import 'dart:async';

/// Typed event class for the Void Scriptor event bus.
class VoidEvent<T> {
  final String type;
  final T? payload;
  final DateTime timestamp;

  VoidEvent(this.type, {this.payload}) : timestamp = DateTime.now();
}

/// Simple event bus with stream-based subscription.
class VoidEventBus {
  final _controller = StreamController<VoidEvent<dynamic>>.broadcast();

  Stream<VoidEvent<dynamic>> get events => _controller.stream;

  void emit<T>(String type, {T? payload}) {
    _controller.add(VoidEvent<T>(type, payload: payload));
  }

  void dispose() {
    _controller.close();
  }
}

// Global event bus instance
final eventBus = VoidEventBus();

// --- Common event types ---
class VoidEvents {
  static const modeChanged = 'mode_changed';
  static const themeChanged = 'theme_changed';
  static const characterUpdated = 'character_updated';
  static const aiRefresh = 'ai_refresh';
  static const statusMessage = 'status_message';
  static const dockLayoutChanged = 'dock_layout_changed';
  static const chapterSaved = 'chapter_saved';
  static const assetImported = 'asset_imported';
}
