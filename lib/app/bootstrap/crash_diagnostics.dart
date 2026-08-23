import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Sprint 101.3 / 101.8 / 101.9 — post-release crash capture.
///
/// Every captured error is written as one structured JSON file under the
/// injected diagnostics directory. Capture must NEVER throw: a failing
/// diagnostics sink must not turn a recoverable error into a hard crash.
class CrashLogEntry {
  final String id;
  final String kind;
  final String message;
  final String signature;
  final String stack;
  final String zone;
  final String occurredAt;

  const CrashLogEntry({
    required this.id,
    required this.kind,
    required this.message,
    required this.signature,
    required this.stack,
    this.zone = 'root',
    required this.occurredAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'kind': kind,
    'message': message,
    'signature': signature,
    'stack': stack,
    'zone': zone,
    'occurredAt': occurredAt,
  };

  String toJsonString() => jsonEncode(toJson());

  factory CrashLogEntry.fromJsonString(String source) {
    final map = jsonDecode(source);
    if (map is! Map<String, dynamic>) {
      throw const FormatException('crash log entry is not a JSON object');
    }
    return CrashLogEntry(
      id: map['id'] as String? ?? '',
      kind: map['kind'] as String? ?? 'unknown',
      message: map['message'] as String? ?? '',
      signature: map['signature'] as String? ?? '',
      stack: map['stack'] as String? ?? '',
      zone: map['zone'] as String? ?? 'root',
      occurredAt: map['occurredAt'] as String? ?? '',
    );
  }
}

/// Groups crashes into actionable buckets (101.8): identical error type +
/// first message line share one signature regardless of stack trace noise.
class CrashSignature {
  final String value;

  const CrashSignature(this.value);

  factory CrashSignature.of(Object error, StackTrace? stack) {
    final text = error.toString();
    final newlineIndex = text.indexOf('\n');
    final firstLine = newlineIndex >= 0
        ? text.substring(0, newlineIndex)
        : text;
    return CrashSignature(firstLine.trim());
  }

  @override
  bool operator ==(Object other) =>
      other is CrashSignature && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'CrashSignature($value)';
}

class CrashDiagnostics {
  final Directory directory;

  static int _sequence = 0;

  CrashDiagnostics({required this.directory});

  void handleFlutterError(FlutterErrorDetails details) {
    _capture(
      kind: 'flutter_error',
      error: details.exception,
      stack: details.stack,
    );
  }

  void handleZoneError(Object error, StackTrace stack, {String zone = 'root'}) {
    _capture(kind: 'zone_error', error: error, stack: stack, zone: zone);
  }

  void _capture({
    required String kind,
    required Object error,
    StackTrace? stack,
    String zone = 'root',
  }) {
    try {
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      final now = DateTime.now().toUtc();
      final stamp = now.microsecondsSinceEpoch;
      _sequence += 1;
      final entry = CrashLogEntry(
        id: '$stamp-$_sequence',
        kind: kind,
        message: error.toString(),
        signature: CrashSignature.of(error, stack).value,
        stack: stack?.toString() ?? '',
        zone: zone,
        occurredAt: now.toIso8601String(),
      );
      File(
        '${directory.path}${Platform.pathSeparator}'
        '${kind.replaceAll('_', '-')}-$stamp-$_sequence.json',
      ).writeAsStringSync(entry.toJsonString(), flush: true);
    } catch (_) {
      // Swallow diagnostics failures by design (see class doc).
    }
  }

  /// Installs global handlers and returns a closure restoring the previous
  /// handlers exactly (safe to chain multiple installs).
  static VoidCallback attach(CrashDiagnostics diagnostics) {
    final previousFlutterOnError = FlutterError.onError;
    final previousDispatcherOnError = PlatformDispatcher.instance.onError;

    FlutterError.onError = diagnostics.handleFlutterError;
    PlatformDispatcher.instance.onError = (error, stack) {
      diagnostics.handleZoneError(error, stack);
      return true;
    };

    return () {
      FlutterError.onError = previousFlutterOnError;
      PlatformDispatcher.instance.onError = previousDispatcherOnError;
    };
  }
}
