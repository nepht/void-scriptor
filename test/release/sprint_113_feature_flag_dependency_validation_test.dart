// Sprint 113.13 — Feature Flag Dependency Validation.
//
// Required evidence: default_matrix, dependency_matrix, enable_disable,
// kill_switch, state_preservation, graceful_fallback.
//
// Validates that:
// 1. All 13 v1.2 flags default to OFF
// 2. No cross-flag dependencies exist (all independent)
// 3. Enable/disable works correctly per flag
// 4. Kill-switch forces all flags OFF and blocks isEnabled
// 5. State can be persisted and restored via override store
// 6. Unknown flags throw ArgumentError; missing file returns clean defaults

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/feature_flags/feature_flag_override_store.dart';
import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';
import 'package:void_scriptor/features/world_logic/domain/feature_flag_dependency_validation.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('hermes-flags-113_13_');
  });

  tearDown(() {
    try {
      root.deleteSync(recursive: true);
    } on FileSystemException catch (_) {}
  });

  // ── manifest_validation ─────────────────────────────────────────────
  group('manifest_validation', () {
    test('domain class validates the manifest structure', () {
      final result = FeatureFlagDependencyValidation.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });

    test('manifest has all required evidence sections', () {
      final file = File(FeatureFlagDependencyValidation.manifestPath);
      expect(file.existsSync(), isTrue);

      final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(doc['canonical_step'], '113.13');
      expect(doc['default_matrix'], isNotNull);
      expect(doc['kill_switch'], isNotNull);
    });
  });

  // ── default_matrix ──────────────────────────────────────────────────
  group('default_matrix', () {
    test('fresh registry has all 13 flags at default OFF', () {
      final registry = FeatureFlagRegistry();
      expect(registry.knownFlags.length, 13);
      expect(registry.enabledFlags, isEmpty);
      expect(registry.allAtDefaults, isTrue);
      expect(registry.killSwitchActive, isFalse);
    });

    test('every known flag is disabled by default', () {
      final registry = FeatureFlagRegistry();
      for (final flag in registry.knownFlags) {
        expect(
          registry.isEnabled(flag),
          isFalse,
          reason: '$flag should be OFF',
        );
      }
    });
  });

  // ── dependency_matrix ───────────────────────────────────────────────
  group('dependency_matrix', () {
    test('no cross-flag dependencies: enabling one does not affect others', () {
      final registry = FeatureFlagRegistry();
      registry.enable('vs12_lore_links');

      expect(registry.isEnabled('vs12_lore_links'), isTrue);

      for (final flag in registry.knownFlags) {
        if (flag == 'vs12_lore_links') continue;
        expect(
          registry.isEnabled(flag),
          isFalse,
          reason: '$flag should not be affected by enabling vs12_lore_links',
        );
      }
    });

    test('disabling one flag does not affect others', () {
      final registry = FeatureFlagRegistry();
      registry.enable('vs12_lore_links');
      registry.enable('vs12_contradictions');
      registry.disable('vs12_lore_links');

      expect(registry.isEnabled('vs12_lore_links'), isFalse);
      expect(registry.isEnabled('vs12_contradictions'), isTrue);
    });
  });

  // ── enable_disable ──────────────────────────────────────────────────
  group('enable_disable', () {
    test('enable makes flag available', () {
      final registry = FeatureFlagRegistry();
      registry.enable('vs12_voice_interview');
      expect(registry.isEnabled('vs12_voice_interview'), isTrue);
      expect(registry.enabledFlags, contains('vs12_voice_interview'));
    });

    test('disable removes flag', () {
      final registry = FeatureFlagRegistry();
      registry.enable('vs12_voice_interview');
      registry.disable('vs12_voice_interview');
      expect(registry.isEnabled('vs12_voice_interview'), isFalse);
      expect(registry.enabledFlags, isNot(contains('vs12_voice_interview')));
    });

    test('enable is idempotent', () {
      final registry = FeatureFlagRegistry();
      registry.enable('vs12_conlang');
      registry.enable('vs12_conlang');
      expect(registry.isEnabled('vs12_conlang'), isTrue);
      expect(registry.enabledFlags.where((f) => f == 'vs12_conlang').length, 1);
    });

    test('unknown flag throws ArgumentError', () {
      final registry = FeatureFlagRegistry();
      expect(
        () => registry.enable('nonexistent_flag'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => registry.isEnabled('nonexistent_flag'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ── kill_switch ─────────────────────────────────────────────────────
  group('kill_switch', () {
    test('engage clears all flags', () {
      final registry = FeatureFlagRegistry();
      registry.enable('vs12_lore_links');
      registry.enable('vs12_pov');
      registry.engageKillSwitch();

      expect(registry.killSwitchActive, isTrue);
      expect(registry.enabledFlags, isEmpty);
      expect(registry.allAtDefaults, isTrue);
    });

    test('isEnabled returns false during kill-switch', () {
      final registry = FeatureFlagRegistry();
      registry.enable('vs12_lore_links');
      registry.engageKillSwitch();

      expect(registry.isEnabled('vs12_lore_links'), isFalse);
    });

    test('disengage resets to defaults', () {
      final registry = FeatureFlagRegistry();
      registry.enable('vs12_lore_links');
      registry.engageKillSwitch();
      registry.disengageKillSwitch();

      expect(registry.killSwitchActive, isFalse);
      expect(registry.allAtDefaults, isTrue);
      expect(registry.isEnabled('vs12_lore_links'), isFalse);
    });

    test('explicit enable clears kill-switch', () {
      final registry = FeatureFlagRegistry();
      registry.engageKillSwitch();
      expect(registry.killSwitchActive, isTrue);

      registry.enable('vs12_export');
      expect(registry.killSwitchActive, isFalse);
      expect(registry.isEnabled('vs12_export'), isTrue);
    });

    test('engage is idempotent', () {
      final registry = FeatureFlagRegistry();
      registry.engageKillSwitch();
      registry.engageKillSwitch();
      expect(registry.killSwitchActive, isTrue);
      expect(registry.enabledFlags, isEmpty);
    });

    test('resetToDefaults clears kill-switch and flags', () {
      final registry = FeatureFlagRegistry();
      registry.enable('vs12_pacing');
      registry.engageKillSwitch();
      registry.resetToDefaults();

      expect(registry.killSwitchActive, isFalse);
      expect(registry.allAtDefaults, isTrue);
    });
  });

  // ── state_preservation ──────────────────────────────────────────────
  group('state_preservation', () {
    test('persistence round-trip via override store', () {
      final store = FeatureFlagOverrideStore(
        directory: root,
        knownFlags: kVs12FeatureFlags,
      );

      final registry = FeatureFlagRegistry.restoreOverrides(store: store);
      registry.enable('vs12_lore_links');
      registry.enable('vs12_pov');

      // Create a fresh registry from the same store directory.
      final store2 = FeatureFlagOverrideStore(
        directory: root,
        knownFlags: kVs12FeatureFlags,
      );
      final registry2 = FeatureFlagRegistry.restoreOverrides(store: store2);

      expect(registry2.isEnabled('vs12_lore_links'), isTrue);
      expect(registry2.isEnabled('vs12_pov'), isTrue);
      expect(registry2.isEnabled('vs12_conlang'), isFalse);
    });

    test('unknown flags dropped on load', () async {
      final file = File(
        '${root.path}${Platform.pathSeparator}feature_flag_overrides.json',
      );
      await file.writeAsString(
        '{"schema": 1, "overrides": {"unknown_xyz": true, "vs12_pacing": true}}',
      );

      final store = FeatureFlagOverrideStore(
        directory: root,
        knownFlags: kVs12FeatureFlags,
      );
      final registry = FeatureFlagRegistry.restoreOverrides(store: store);

      expect(registry.isEnabled('vs12_pacing'), isTrue);
      expect(
        () => registry.isEnabled('unknown_xyz'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('corrupt override file returns clean defaults', () async {
      final file = File(
        '${root.path}${Platform.pathSeparator}feature_flag_overrides.json',
      );
      await file.writeAsString('NOT VALID JSON {{{');

      final store = FeatureFlagOverrideStore(
        directory: root,
        knownFlags: kVs12FeatureFlags,
      );
      final registry = FeatureFlagRegistry.restoreOverrides(store: store);

      expect(registry.allAtDefaults, isTrue);
      expect(registry.enabledFlags, isEmpty);
    });

    test('missing override file returns clean defaults', () {
      final store = FeatureFlagOverrideStore(
        directory: root,
        knownFlags: kVs12FeatureFlags,
      );
      final registry = FeatureFlagRegistry.restoreOverrides(store: store);

      expect(registry.allAtDefaults, isTrue);
      expect(registry.enabledFlags, isEmpty);
    });
  });

  // ── graceful_fallback ───────────────────────────────────────────────
  group('graceful_fallback', () {
    test('unknown flag throws ArgumentError on enable', () {
      final registry = FeatureFlagRegistry();
      expect(
        () => registry.enable('totally_unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('unknown flag throws ArgumentError on disable', () {
      final registry = FeatureFlagRegistry();
      expect(
        () => registry.disable('totally_unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('unknown flag throws ArgumentError on isEnabled', () {
      final registry = FeatureFlagRegistry();
      expect(
        () => registry.isEnabled('totally_unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('override store rejects unknown flag on save', () {
      final store = FeatureFlagOverrideStore(
        directory: root,
        knownFlags: kVs12FeatureFlags,
      );
      expect(
        () => store.saveOverrides(['vs12_pacing', 'unknown_flag']),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('override store accepts only known flags', () {
      final store = FeatureFlagOverrideStore(
        directory: root,
        knownFlags: kVs12FeatureFlags,
      );
      store.saveOverrides(['vs12_pacing', 'vs12_export']);
      expect(
        store.enabledOverrides,
        containsAll(['vs12_pacing', 'vs12_export']),
      );
      expect(store.enabledOverrides.length, 2);
    });
  });
}
