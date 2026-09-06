import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'crash_diagnostics.dart';
import 'startup_recovery_policy.dart';

/// Resolved bootstrap storage locations. [resolve] prefers the platform
/// support directory and degrades through explicit overrides so tests and
/// broken platform channels never block startup (mirrors ProjectPaths).
class BootstrapDirectories {
  final Directory crash;
  final Directory state;

  const BootstrapDirectories({required this.crash, required this.state});

  static BootstrapDirectories under(Directory root) => BootstrapDirectories(
    crash: Directory(p.join(root.path, 'diagnostics', 'crash')),
    state: Directory(p.join(root.path, 'state')),
  );

  static Future<BootstrapDirectories> resolve({
    Future<String?> Function()? supportPath,
  }) async {
    var support = '';
    try {
      support = supportPath != null
          ? (await supportPath()) ?? ''
          : (await getApplicationSupportDirectory()).path;
    } on Object {
      support = '';
    }
    if (support.isEmpty) {
      return BootstrapDirectories.under(
        Directory(p.join(Directory.systemTemp.path, 'VoidScriptor')),
      );
    }
    return BootstrapDirectories.under(
      Directory(p.join(support, 'VoidScriptor')),
    );
  }
}

class _StartupDecision {
  final String mode;
  final int attempt;

  const _StartupDecision(this.mode, this.attempt);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'mode': mode,
    'attempt': attempt,
    'decidedAt': DateTime.now().toUtc().toIso8601String(),
  };
}

class BootstrapHandle {
  final VoidCallback restoreDiagnostics;
  final StartupFailureStore store;
  final StartupRecoveryOutcome lastOutcome;

  /// True when this boot persisted its decision artifact to storage.
  /// Always false for in-memory (web) boots by design.
  final bool stateFileWritten;

  @visibleForTesting
  const BootstrapHandle({
    required this.restoreDiagnostics,
    required this.store,
    required this.lastOutcome,
    this.stateFileWritten = false,
  });
}

/// Sprint 101.3 / 101.9 — production composition of crash capture and the
/// startup-recovery counter. Every boot records one attempt; the caller
/// clears the streak through [BootstrapHandle.store] once the UI is truly
/// up (healthy shutdown semantics).
///
/// [rootOverride] redirects ALL storage under one directory (test seam).
/// Whether the default composition persists boot state to the filesystem.
/// Desktop must remain file-backed; web selects in-memory explicitly.
const bool prepareBootstrapUsesFilesByDefault = true;

/// Composes crash capture + startup-recovery counter.
///
/// On the web target (or [forceInMemory]) everything composes against an
/// in-memory store with no dart:io calls, so the engine can render frame
/// one in a browser. Diagnostics handlers stay untouched there; browser
/// devtools surface uncaught errors natively.
Future<BootstrapHandle> prepareBootstrap({
  Directory? rootOverride,
  @visibleForTesting bool forceInMemory = false,
}) async {
  final inMemory = forceInMemory || kIsWeb;

  BootstrapDirectories? dirs;
  if (!inMemory) {
    dirs = rootOverride != null
        ? BootstrapDirectories.under(rootOverride)
        : await BootstrapDirectories.resolve();
  }

  final restore = inMemory
      ? () {}
      : CrashDiagnostics.attach(CrashDiagnostics(directory: dirs!.crash));

  final store = inMemory
      ? StartupFailureStore.inMemory()
      : StartupFailureStore(
          file: File(p.join(dirs!.state.path, 'startup.json')),
        );
  final outcome = StartupRecoveryPolicy.decide(
    readState: store.read,
    writeState: store.write,
  );

  var persisted = false;
  if (!inMemory) {
    try {
      dirs!.state.createSync(recursive: true);
      File(p.join(dirs.state.path, 'startup-decision.json')).writeAsStringSync(
        jsonEncode(
          _StartupDecision(
            outcome.mode.name,
            outcome.failureCountAfterDecision,
          ).toJson(),
        ),
      );
      persisted = true;
    } on FileSystemException {
      // Monitoring artifacts are best-effort; never block boot.
    }
  }

  return BootstrapHandle(
    restoreDiagnostics: restore,
    store: store,
    lastOutcome: outcome,
    stateFileWritten: persisted,
  );
}
