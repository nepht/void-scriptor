import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';

void main() {
  group('FeatureFlagRegistry', () {
    test('exposes exactly 13 wave-1 v1.2 flags, all default OFF', () {
      final registry = FeatureFlagRegistry();
      expect(registry.knownFlags.length, 13);
      for (final flag in registry.knownFlags) {
        expect(flag.startsWith('vs12_'), isTrue, reason: flag);
        expect(
          registry.isEnabled(flag),
          isFalse,
          reason: '$flag must default OFF',
        );
      }
      expect(registry.allAtDefaults, isTrue);
    });

    test('enable/disable round trip updates state', () {
      final registry = FeatureFlagRegistry();
      expect(registry.isEnabled('vs12_focus_writing'), isFalse);
      registry.enable('vs12_focus_writing');
      expect(registry.isEnabled('vs12_focus_writing'), isTrue);
      expect(registry.allAtDefaults, isFalse);
      registry.disable('vs12_focus_writing');
      expect(registry.isEnabled('vs12_focus_writing'), isFalse);
      expect(registry.allAtDefaults, isTrue);
    });

    test('unknown flag names are rejected everywhere', () {
      final registry = FeatureFlagRegistry();
      expect(() => registry.isEnabled('vs99_typo'), throwsArgumentError);
      expect(() => registry.enable('vs99_typo'), throwsArgumentError);
      expect(() => registry.disable('vs99_typo'), throwsArgumentError);
    });

    test('resetToDefaults turns everything back OFF', () {
      final registry = FeatureFlagRegistry();
      registry
        ..enable('vs12_plot_board')
        ..enable('vs12_pov')
        ..enable('vs12_export');
      expect(registry.allAtDefaults, isFalse);
      registry.resetToDefaults();
      expect(registry.allAtDefaults, isTrue);
      expect(registry.isEnabled('vs12_plot_board'), isFalse);
    });

    test('instances are independent (no global leakage)', () {
      final a = FeatureFlagRegistry()..enable('vs12_conlang');
      final b = FeatureFlagRegistry();
      expect(b.isEnabled('vs12_conlang'), isFalse);
      expect(a.isEnabled('vs12_conlang'), isTrue);
    });
  });
}
