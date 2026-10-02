import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/persistence/project_open_service.dart'
    show SensitiveTermsSink;
import '../../core/security/application/secret_scanner.dart';

/// Secret-scrubbing patterns (101.17 diagnostic_redaction). Anything that
/// looks like a credential must never reach disk, even inside an error
/// message or stack trace.
///
/// These two are CONTEXTUAL — they only match a credential that is introduced
/// by a label or a scheme word, so they stay local to this file:
///
/// 117.39: both were `replaceFirstMapped`, so only the FIRST match of each
/// pattern was ever redacted. A message carrying two credentials of the same
/// class — the normal shape of a real upstream error — had its second
/// credential written to disk in full. A redaction guard that stops after the
/// first hit protects nothing after it. Both now replace every occurrence.
final RegExp _bearerHeaderPattern = RegExp(
  r'\bbearer\s+\S+',
  caseSensitive: false,
);
final RegExp _labeledSecretPattern = RegExp(
  r'\b(api[_-]?key|apikey|token|password|passwd|secret|authorization)'
  r'\s*[:=]\s*\S+',
  caseSensitive: false,
);

/// Replaces secret-looking material with [REDACTED].
///
/// Every occurrence of every pattern is replaced, not just the first: a
/// second credential in the same message is still a credential.
///
/// SHAPE-based credentials are NOT re-listed here. This file used to carry its
/// own copy of the provider-token patterns, and the copy drifted away from the
/// canonical [SecretScanner]: it demanded a DASH separator, so the real GitHub
/// formats (`ghp_`, `github_pat_` — underscore) and Slack tokens (`xoxb-…`)
/// never matched, and it had no `AKIA` family at all. A credential named by our
/// own archive guard was therefore not even a candidate for redaction in the
/// crash sink. The canonical scanner is now the single source of truth, so this
/// surface can never drift from it again.
String _redactSecrets(String text) {
  var out = text;
  out = out.replaceAll(_bearerHeaderPattern, '[REDACTED]');
  out = out.replaceAll(_labeledSecretPattern, '[REDACTED]');
  for (final credential in const SecretScanner().scan(out)) {
    if (credential.isEmpty) continue;
    // Escape: real credentials routinely contain regex metacharacters
    // (base64/JWT bodies do), so the match must be treated literally.
    out = out.replaceAll(RegExp(RegExp.escape(credential)), '[REDACTED]');
  }
  return out;
}

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
    return CrashSignature(_redactSecrets(firstLine.trim()));
  }

  @override
  bool operator ==(Object other) =>
      other is CrashSignature && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'CrashSignature($value)';
}

class CrashDiagnostics implements SensitiveTermsSink {
  final Directory directory;

  /// Sprint 102 / C1 — injected story-content terms captured from the active
  /// project. Creative text is arbitrary, so it cannot be pattern-matched;
  /// instead the app supplies the exact titles/names that must never reach a
  /// diagnostic artifact. Empty list = behavior unchanged.
  ///
  /// Backing storage is mutable via [updateSensitiveTerms] because the sink
  /// is constructed during bootstrap, before any project session opens.
  final List<String> _sensitiveTerms;

  List<String> get sensitiveTerms => List.unmodifiable(_sensitiveTerms);

  static int _sequence = 0;

  CrashDiagnostics({
    required this.directory,
    List<String> sensitiveTerms = const [],
  }) : _sensitiveTerms = List.of(sensitiveTerms);

  /// Replaces the active story-term set (used by project-session wiring when
  /// the opened project changes).
  @override
  void updateSensitiveTerms(List<String> terms) {
    _sensitiveTerms
      ..clear()
      ..addAll(terms);
  }

  /// Replaces every occurrence of an injected story term (case-insensitive)
  /// with [STORY].
  String _redactStoryContent(String text) {
    var out = text;
    for (final term in sensitiveTerms) {
      if (term.isEmpty) continue;
      out = out.replaceAll(
        RegExp(RegExp.escape(term), caseSensitive: false),
        '[STORY]',
      );
    }
    return out;
  }

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
        message: _redactStoryContent(_redactSecrets(error.toString())),
        signature: _redactStoryContent(CrashSignature.of(error, stack).value),
        stack: _redactStoryContent(_redactSecrets(stack?.toString() ?? '')),
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

  /// Data deletion (101.17): removes every captured artifact inside
  /// [directory]. Best-effort like the rest of the sink — a file that
  /// cannot be deleted must not crash the caller.
  void purge() {
    try {
      if (!directory.existsSync()) return;
      for (final entity in directory.listSync()) {
        try {
          entity.deleteSync(recursive: true);
        } on FileSystemException {
          // Ignore individual failures: purge is best-effort.
        }
      }
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
