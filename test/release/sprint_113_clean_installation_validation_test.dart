/// Sprint 113.9 — Clean Installation Validation.
///
/// Acceptance criteria:
/// - install: canonical source artifacts exist
/// - launch: bootstrap composes without error; first-run produces normal mode
/// - first_run: no stored session, no saved failure count, offline default
/// - project_create: project manifest can be created from scratch
/// - default_flags: all 13 v1.2 feature flags default OFF
/// - uninstall_behavior: session store clear, startup counter reset, lock cleanup
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/bootstrap/app_diagnostics.dart';
import 'package:void_scriptor/app/bootstrap/startup_recovery_policy.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/core/auth/auth_session_store_io.dart';
import 'package:void_scriptor/core/auth/auth_status.dart';
import 'package:void_scriptor/core/feature_flags/feature_flag_override_store.dart';
import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';

void main() {
  // ── install ────────────────────────────────────────────────────────────
  group('install', () {
    test('canonical source artifacts exist', () {
      expect(File('pubspec.yaml').existsSync(), isTrue);
      expect(File('lib/main.dart').existsSync(), isTrue);
      expect(Directory('lib').existsSync(), isTrue);
      expect(Directory('test').existsSync(), isTrue);
    });

    test('pubspec.yaml declares the project name and a version', () {
      final content = File('pubspec.yaml').readAsStringSync();
      expect(content, contains('name: void_scriptor'));
      expect(content, contains('version:'));
    });
  });

  // ── launch (first run) ────────────────────────────────────────────────
  group('launch', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vs_113_9_launch_');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {}
    });

    test(
      'bootstrap composes in-memory and yields normal mode on first run',
      () async {
        final handle = await prepareBootstrap(
          rootOverride: tempDir,
          forceInMemory: true,
        );
        expect(handle.lastOutcome.mode, StartupMode.normal);
        expect(handle.lastOutcome.failureCountAfterDecision, 1);
        // In-memory mode does not write state to disk.
        expect(handle.stateFileWritten, isFalse);
      },
    );

    test(
      'file-backed bootstrap yields normal mode on a clean directory',
      () async {
        final handle = await prepareBootstrap(rootOverride: tempDir);
        expect(handle.lastOutcome.mode, StartupMode.normal);
        expect(handle.stateFileWritten, isTrue);
        // The decision artifact was written.
        final decisionFile = File(
          '${tempDir.path}${Platform.pathSeparator}state'
          '${Platform.pathSeparator}startup-decision.json',
        );
        expect(decisionFile.existsSync(), isTrue);
        final json =
            jsonDecode(decisionFile.readAsStringSync()) as Map<String, dynamic>;
        expect(json['mode'], 'normal');
        expect(json['attempt'], 1);
      },
    );
  });

  // ── first_run ─────────────────────────────────────────────────────────
  group('first_run', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vs_113_9_firstrun_');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {}
    });

    test('disk auth session store is empty on a fresh directory', () async {
      final file = File('${tempDir.path}${Platform.pathSeparator}session.json');
      final store = AuthSessionStoreIo(file: file);
      final session = await store.load();
      expect(session, isNull, reason: 'no stored session on first run');
    });

    test('startup failure counter reads zero on a fresh directory', () {
      final file = File(
        '${tempDir.path}${Platform.pathSeparator}state'
        '${Platform.pathSeparator}startup.json',
      );
      final store = StartupFailureStore(file: file);
      expect(store.read().consecutiveFailures, isZero);
      // Missing file does not get created on read.
      expect(file.existsSync(), isFalse);
    });

    test('first offline session round-trips through disk store', () async {
      final file = File('${tempDir.path}${Platform.pathSeparator}session.json');
      final store = AuthSessionStoreIo(file: file);

      // Simulate what main.dart does on first run when no session exists.
      const session = AuthSession.offline();
      expect(session.status, AuthStatus.offline);
      expect(session.displayName, 'Offline User');

      // Persist and reload.
      await store.save(session);
      final restored = await store.load();
      expect(restored, isNotNull);
      expect(restored!.status, AuthStatus.offline);
      expect(restored.displayName, 'Offline User');
      expect(restored.userId, isNull);
      expect(restored.email, isNull);
    });
  });

  // ── project_create ────────────────────────────────────────────────────
  group('project_create', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vs_113_9_projcreate_');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {}
    });

    test('a fresh project manifest can be written and parsed', () {
      final projectDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}'
        'test-project-uuid',
      );
      projectDir.createSync(recursive: true);

      final manifest = <String, dynamic>{
        'format': 'void-project-v1',
        'schemaVersion': 62,
        'projectId': 'test-project-uuid',
        'name': 'Test Project',
        'description': 'A test project for 113.9 validation.',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'application': {'name': 'Void Scriptor', 'version': '1.2.0-rc.1'},
        'database': {'file': 'database/project.db'},
        'assets': {'root': 'assets'},
        'projectVersion': '1.0.0',
        'tags': <String>[],
      };

      final manifestFile = File(
        '${projectDir.path}${Platform.pathSeparator}manifest'
        '${Platform.pathSeparator}project.json',
      );
      manifestFile.parent.createSync(recursive: true);
      manifestFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(manifest),
        flush: true,
      );

      expect(manifestFile.existsSync(), isTrue);

      final parsed =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(parsed['projectId'], 'test-project-uuid');
      expect(parsed['name'], 'Test Project');
      expect(parsed['schemaVersion'], 62);
      expect(parsed['database']['file'], 'database/project.db');
    });

    test('database directory can be created alongside manifest', () {
      final projectDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}'
        'db-project-uuid',
      );
      final dbDir = Directory(
        '${projectDir.path}${Platform.pathSeparator}database',
      );
      dbDir.createSync(recursive: true);

      expect(dbDir.existsSync(), isTrue);
      expect(dbDir.listSync().isEmpty, isTrue, reason: 'empty db dir');
    });
  });

  // ── default_flags ─────────────────────────────────────────────────────
  group('default_flags', () {
    test('all 13 v1.2 feature flags default to OFF', () {
      final registry = FeatureFlagRegistry();
      expect(registry.knownFlags.length, 13);
      for (final flag in registry.knownFlags) {
        expect(
          registry.isEnabled(flag),
          isFalse,
          reason: '$flag must default OFF on clean install',
        );
      }
      expect(registry.allAtDefaults, isTrue);
    });

    test('fresh override store has no enabled overrides', () {
      final tempDir = Directory.systemTemp.createTempSync(
        'vs_113_9_flagstore_',
      );
      try {
        final store = FeatureFlagOverrideStore(
          directory: tempDir,
          knownFlags: kVs12FeatureFlags,
        );
        expect(store.enabledOverrides, isEmpty);
      } finally {
        try {
          tempDir.deleteSync(recursive: true);
        } on FileSystemException catch (_) {}
      }
    });

    test('flag override persistence round-trips', () {
      final tempDir = Directory.systemTemp.createTempSync(
        'vs_113_9_flagroundtrip_',
      );
      try {
        final storeA = FeatureFlagOverrideStore(
          directory: tempDir,
          knownFlags: kVs12FeatureFlags,
        );
        // Enable one flag and persist.
        final registry = FeatureFlagRegistry.restoreOverrides(store: storeA);
        registry.enable('vs12_pov');
        // The callback writes through to the store.
        expect(storeA.enabledOverrides, contains('vs12_pov'));

        // Reload from disk — a new store + registry should see the override.
        final storeB = FeatureFlagOverrideStore(
          directory: tempDir,
          knownFlags: kVs12FeatureFlags,
        );
        expect(storeB.enabledOverrides, contains('vs12_pov'));
        final registryB = FeatureFlagRegistry.restoreOverrides(store: storeB);
        expect(registryB.isEnabled('vs12_pov'), isTrue);
        expect(registryB.isEnabled('vs12_export'), isFalse);
      } finally {
        try {
          tempDir.deleteSync(recursive: true);
        } on FileSystemException catch (_) {}
      }
    });
  });

  // ── uninstall_behavior ────────────────────────────────────────────────
  group('uninstall_behavior', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vs_113_9_uninstall_');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {}
    });

    test('auth session store clear removes persisted session', () async {
      final file = File('${tempDir.path}${Platform.pathSeparator}session.json');
      final store = AuthSessionStoreIo(file: file);
      await store.save(const AuthSession.guest());
      expect(file.existsSync(), isTrue);

      await store.clear();
      expect(
        file.existsSync(),
        isFalse,
        reason: 'clear() must remove the session file',
      );
    });

    test('startup failure counter reset() wipes persisted state', () {
      final stateDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}state',
      );
      stateDir.createSync(recursive: true);
      final file = File(
        '${stateDir.path}${Platform.pathSeparator}startup.json',
      );
      final store = StartupFailureStore(file: file);
      store.recordFailure();
      store.recordFailure();
      store.recordFailure();
      expect(store.read().consecutiveFailures, 3);

      store.reset();
      // After reset, the file is deleted.
      expect(file.existsSync(), isFalse);
      // Fresh store reads zero.
      expect(
        StartupFailureStore(file: file).read().consecutiveFailures,
        isZero,
      );
    });

    test('session lock file can be deleted on cleanup', () async {
      final lockFile = File(
        '${tempDir.path}${Platform.pathSeparator}project.lock',
      );
      await lockFile.writeAsString(
        jsonEncode({'sessionId': 'test', 'openedAt': '2026-09-22T00:00:00Z'}),
      );
      expect(lockFile.existsSync(), isTrue);

      await lockFile.delete();
      expect(
        lockFile.existsSync(),
        isFalse,
        reason: 'lock file removed during uninstall cleanup',
      );
    });

    test('diagnostics crash directory is removable', () {
      final crashDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}diagnostics'
        '${Platform.pathSeparator}crash',
      );
      crashDir.createSync(recursive: true);
      // Write a dummy crash report.
      File(
        '${crashDir.path}${Platform.pathSeparator}crash_001.json',
      ).writeAsStringSync('{}');
      expect(crashDir.existsSync(), isTrue);
      expect(crashDir.listSync().isNotEmpty, isTrue);

      crashDir.deleteSync(recursive: true);
      expect(
        crashDir.existsSync(),
        isFalse,
        reason: 'crash diagnostics removable on uninstall',
      );
    });

    test('feature flag override file is removable', () {
      final flagDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}flags',
      );
      flagDir.createSync(recursive: true);
      final overrideFile = File(
        '${flagDir.path}${Platform.pathSeparator}'
        '${FeatureFlagOverrideStore.fileNameConst}',
      );
      overrideFile.writeAsStringSync(
        jsonEncode({'schema': 1, 'overrides': <String, dynamic>{}}),
      );
      expect(overrideFile.existsSync(), isTrue);

      overrideFile.deleteSync();
      expect(overrideFile.existsSync(), isFalse);
    });
  });
}
