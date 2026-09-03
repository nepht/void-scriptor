// Sprint 145.39 — Non-Core Preservation and Disablement.
//
// Persistence override flag: status enable/disable pengguna untuk flag
// vs12_* harus bertahan lintas restart proses. Registry in-memory tetap
// menjadi satu-satunya primitive runtime; store terpisah (JSON atomic
// tmp-rename) membaca override saat startup dan menulis saat berubah.
// Unknown flags ditolak di store sebagaimana di registry (no silent fixup).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/feature_flags/feature_flag_override_store.dart';
import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('hermes_vs_flagstore');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows flush race: biarkan OS membereskan, file sementara.
    }
  });

  group('FeatureFlagOverrideStore file contract', () {
    test('missing file means empty overrides (clean first boot)', () {
      final store = FeatureFlagOverrideStore(
        directory: tempDir,
        knownFlags: kVs12FeatureFlags,
      );

      expect(store.enabledOverrides, isEmpty);
      expect(store.fileName, 'feature_flag_overrides.json');
    });

    test('unknown flag in file is dropped, not applied (no silent fixup)', () {
      final file = File('${tempDir.path}/feature_flag_overrides.json');
      file.writeAsStringSync(
        jsonEncode({
          'schema': 1,
          'overrides': {'vs12_export': true, 'vs99_typo': true},
        }),
      );

      final store = FeatureFlagOverrideStore(
        directory: tempDir,
        knownFlags: kVs12FeatureFlags,
      );

      expect(store.enabledOverrides, ['vs12_export']);
    });

    test('atomic write: no .tmp residue after a successful save', () {
      final store = FeatureFlagOverrideStore(
        directory: tempDir,
        knownFlags: kVs12FeatureFlags,
      );

      store.saveOverrides(['vs12_export']);

      expect(
        tempDir.listSync().any((e) => e.path.endsWith('.tmp')),
        isFalse,
        reason: 'atomic tmp-rename must leave no residue',
      );
    });

    test('round trip: save then reload keeps enabled set', () {
      final store = FeatureFlagOverrideStore(
        directory: tempDir,
        knownFlags: kVs12FeatureFlags,
      );

      store.saveOverrides(['vs12_export', 'vs12_pov']);
      final reloaded = FeatureFlagOverrideStore(
        directory: tempDir,
        knownFlags: kVs12FeatureFlags,
      );

      expect(reloaded.enabledOverrides, ['vs12_export', 'vs12_pov']);
    });
  });

  group('FeatureFlagRegistry persistence wiring', () {
    test('restoreOverrides applies persisted set at construction', () {
      final file = File('${tempDir.path}/feature_flag_overrides.json');
      file.writeAsStringSync(
        jsonEncode({
          'schema': 1,
          'overrides': {'vs12_export': true},
        }),
      );

      final registry = FeatureFlagRegistry.restoreOverrides(
        store: FeatureFlagOverrideStore(
          directory: tempDir,
          knownFlags: kVs12FeatureFlags,
        ),
      );

      expect(registry.isEnabled('vs12_export'), isTrue);
      expect(registry.isEnabled('vs12_lore_links'), isFalse);
    });

    test('registry change persists; new process instance observes it', () {
      final store = FeatureFlagOverrideStore(
        directory: tempDir,
        knownFlags: kVs12FeatureFlags,
      );
      final registry = FeatureFlagRegistry.restoreOverrides(store: store);

      registry.enable('vs12_focus_writing');
      // Simulasi proses baru: registry lain membaca store yang sama.
      final registry2 = FeatureFlagRegistry.restoreOverrides(store: store);

      expect(registry2.isEnabled('vs12_focus_writing'), isTrue);
      expect(registry2.isEnabled('vs12_export'), isFalse);
    });

    test('disable persists removal across instances', () {
      final store = FeatureFlagOverrideStore(
        directory: tempDir,
        knownFlags: kVs12FeatureFlags,
      );
      final registry = FeatureFlagRegistry.restoreOverrides(store: store)
        ..enable('vs12_export');

      registry.disable('vs12_export');
      final registry2 = FeatureFlagRegistry.restoreOverrides(store: store);

      expect(registry2.isEnabled('vs12_export'), isFalse);
    });

    test('override restore survives a fresh process restart (full cycle)', () {
      final store = FeatureFlagOverrideStore(
        directory: tempDir,
        knownFlags: kVs12FeatureFlags,
      );
      final first = FeatureFlagRegistry.restoreOverrides(store: store)
        ..enable('vs12_moodboard');

      expect(first.isEnabled('vs12_moodboard'), isTrue);

      // Restart proses: instance baru, hanya file yang membawa state.
      final second = FeatureFlagRegistry.restoreOverrides(
        store: FeatureFlagOverrideStore(
          directory: tempDir,
          knownFlags: kVs12FeatureFlags,
        ),
      );

      expect(second.isEnabled('vs12_moodboard'), isTrue);
      expect(second.allAtDefaults, isFalse);
    });
  });
}
