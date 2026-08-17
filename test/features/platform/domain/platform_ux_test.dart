import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/domain/accessibility.dart';
import 'package:void_scriptor/features/platform/domain/onboarding.dart';
import 'package:void_scriptor/features/platform/domain/settings.dart';
import 'package:void_scriptor/features/platform/domain/diagnostics.dart';

void main() {
  group('AccessibilityState', () {
    test('holds a11y preferences', () {
      const a = AccessibilityState(reduceMotion: true, highContrast: false);
      expect(a.reduceMotion, isTrue);
      expect(a.highContrast, isFalse);
    });
  });

  group('OnboardingStep', () {
    test('holds first-run config', () {
      const step = OnboardingStep(id: 'os1', name: 'welcome', skippable: true);
      expect(step.skippable, isTrue);
    });
  });

  group('DemoProject', () {
    test('holds demo project info', () {
      const demo = DemoProject(id: 'dp1', name: 'Void Cube: Demo', sizeMb: 24);
      expect(demo.sizeMb, 24);
    });
  });

  group('SettingsGroup', () {
    test('holds setting definitions', () {
      const group = SettingsGroup(
        id: 'sg1',
        name: 'AI',
        settings: ['model', 'temperature'],
      );
      expect(group.settings, hasLength(2));
    });
  });

  group('UpdateChannel', () {
    test('exposes update channels ordered', () {
      expect(UpdateChannel.values.map((e) => e.name), [
        'stable',
        'beta',
        'dev',
        'canary',
      ]);
    });
  });

  group('DiagnosticReport', () {
    test('holds diagnostic info', () {
      final r = DiagnosticReport(
        id: 'dr1',
        generatedAt: DateTime.utc(2026, 1, 1),
        osInfo: 'Windows 11',
        appVersion: '1.0.0',
      );
      expect(r.osInfo, contains('Windows'));
      expect(r.appVersion, '1.0.0');
    });
  });

  group('LogLevel', () {
    test('exposes log levels', () {
      expect(LogLevel.values.map((e) => e.name), [
        'debug',
        'info',
        'warn',
        'error',
        'fatal',
      ]);
    });
  });

  group('CrashMarker', () {
    test('detects previous crash', () {
      const m = CrashMarker(
        id: 'cm1',
        lastSessionCrashed: true,
        version: '1.0.0',
      );
      expect(m.lastSessionCrashed, isTrue);
      expect(m.shouldSuggestSafeMode, isTrue);
    });
  });
}
