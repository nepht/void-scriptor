import 'dart:convert';
import 'dart:io';

/// Sprint 101.9 — startup recovery decision engine.
///
/// The policy decides a [StartupMode] from the persisted consecutive-failure
/// streak; the [StartupFailureStore] is the only part that touches disk.
/// Ladder: normal → safe → recovery; a healthy shutdown clears the streak.
enum StartupMode { normal, safe, recovery }

class StartupFailureState {
  final int consecutiveFailures;

  const StartupFailureState({this.consecutiveFailures = 0});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'consecutiveFailures': consecutiveFailures,
  };

  factory StartupFailureState.fromJsonString(String source) {
    final map = jsonDecode(source);
    if (map is! Map<String, dynamic>) {
      throw const FormatException('startup state is not a JSON object');
    }
    return StartupFailureState(
      consecutiveFailures: (map['consecutiveFailures'] as num?)?.toInt() ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());
}

class StartupRecoveryOutcome {
  final StartupMode mode;

  /// Failure count after the decision was applied (the decision itself
  /// records the current attempt).
  final int failureCountAfterDecision;

  /// True from the fourth consecutive failure onward: the UI should offer
  /// the diagnostic mode entry point.
  final bool suggestDiagnostics;

  const StartupRecoveryOutcome({
    required this.mode,
    required this.failureCountAfterDecision,
    this.suggestDiagnostics = false,
  });
}

class StartupRecoveryPolicy {
  static const int _safeThreshold = 2;
  static const int _recoveryThreshold = 3;
  static const int _diagnosticsThreshold = 3;

  /// Pure decision: reads the persisted streak through [readState], records
  /// the current attempt through [writeState], and returns the mode.
  ///
  /// Injectable read/write keeps this deterministic under test and lets the
  /// wiring layer decide the storage location.
  static StartupRecoveryOutcome decide({
    required StartupFailureState Function() readState,
    required void Function(StartupFailureState state) writeState,
  }) {
    final previous = readState();
    final count = previous.consecutiveFailures + 1;
    writeState(StartupFailureState(consecutiveFailures: count));

    final mode = count >= _recoveryThreshold
        ? StartupMode.recovery
        : count >= _safeThreshold
        ? StartupMode.safe
        : StartupMode.normal;

    return StartupRecoveryOutcome(
      mode: mode,
      failureCountAfterDecision: count,
      suggestDiagnostics: count > _diagnosticsThreshold,
    );
  }
}

/// Persistence backends for [StartupFailureStore]: file-backed on
/// desktop/mobile, closure-backed in memory on the web target where
/// dart:io operations throw UnsupportedError at runtime.
typedef StateExists = bool Function();
typedef StateRead = String Function();
typedef StateWrite = void Function(String contents);
typedef StateDelete = void Function();

class StartupFailureStore {
  final File file;

  final StateExists? _exists;
  final StateRead? _readText;
  final StateWrite? _writeText;
  final StateDelete? _delete;

  /// File-backed backend (desktop/mobile default).
  StartupFailureStore({required this.file})
    : _exists = null,
      _readText = null,
      _writeText = null,
      _delete = null;

  /// In-memory backend for web boots: identical semantics, no filesystem.
  factory StartupFailureStore.inMemory() {
    String? payload;
    return StartupFailureStore._injected(
      File('startup.json'),
      () => payload != null,
      () => payload ?? '',
      (contents) => payload = contents,
      () => payload = null,
    );
  }

  const StartupFailureStore._injected(
    this.file,
    this._exists,
    this._readText,
    this._writeText,
    this._delete,
  );

  StartupFailureState read() {
    try {
      final existsResult = _exists != null ? _exists() : file.existsSync();
      if (!existsResult) {
        return const StartupFailureState();
      }
      final source = _readText != null ? _readText() : file.readAsStringSync();
      return StartupFailureState.fromJsonString(source);
    } on FormatException {
      return const StartupFailureState();
    } on FileSystemException {
      return const StartupFailureState();
    }
  }

  void write(StartupFailureState state) {
    try {
      if (_writeText != null) {
        _writeText(state.toJsonString());
        return;
      }
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(state.toJsonString(), flush: true);
    } on FileSystemException {
      // Persistence of the counter must never block startup.
    }
  }

  void recordFailure() => write(
    StartupFailureState(consecutiveFailures: read().consecutiveFailures + 1),
  );

  /// A healthy shutdown clears the streak (101.9 contract).
  void recordHealthyShutdown() => write(const StartupFailureState());

  /// Wipes the persisted state entirely - the configuration_reset mode.
  void reset() {
    try {
      if (_delete != null) {
        _delete();
        return;
      }
      if (file.existsSync()) file.deleteSync();
    } on FileSystemException {
      // Ignore: reset is best-effort.
    }
  }
}
