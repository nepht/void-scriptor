import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/domain/privacy.dart';
import 'package:void_scriptor/features/platform/domain/performance.dart';
import 'package:void_scriptor/features/platform/domain/backup.dart';
import 'package:void_scriptor/features/platform/domain/help.dart';

void main() {
  group('PrivacyDashboard', () {
    test('holds privacy toggles', () {
      const p = PrivacyDashboard(
        id: 'pd1',
        localOnlyMode: true,
        telemetryEnabled: false,
      );
      expect(p.localOnlyMode, isTrue);
      expect(p.telemetryEnabled, isFalse);
    });
  });

  group('MemoryBaseline', () {
    test('tracks memory budget', () {
      const m = MemoryBaseline(baselineMb: 480, budgetMb: 600);
      expect(m.utilization, 0.8);
      expect(m.withinBudget, isTrue);
    });
  });

  group('BackupPolicy', () {
    test('holds backup defaults', () {
      const b = BackupPolicy(automaticBackups: true, intervalHours: 24);
      expect(b.automaticBackups, isTrue);
      expect(b.intervalHours, 24);
    });
  });

  group('HealthCheck', () {
    test('evaluates system health', () {
      const h = HealthCheck(
        id: 'h1',
        checks: {'storage': true, 'db': true, 'cache': false},
      );
      expect(h.allPassed, isFalse);
    });
  });

  group('HelpArticle', () {
    test('holds help article', () {
      const a = HelpArticle(
        id: 'ha1',
        title: 'Membuat Proyek',
        content: 'Langkah-langkah membuat proyek baru.',
        tags: ['proyek', 'panduan'],
      );
      expect(a.title, 'Membuat Proyek');
      expect(a.tags, contains('proyek'));
    });
  });

  group('AboutInfo', () {
    test('holds about screen data', () {
      const about = AboutInfo(
        version: '1.0.0',
        buildNumber: '2026.08.17',
        thirdPartyLicenses: ['flutter', 'riverpod', 'drift'],
      );
      expect(about.version, '1.0.0');
      expect(about.thirdPartyLicenses, hasLength(3));
    });
  });

  group('BugSeverity', () {
    test('exposes severities', () {
      expect(BugSeverity.values.map((e) => e.name), [
        'blocker',
        'critical',
        'major',
        'minor',
        'cosmetic',
      ]);
    });
  });
}
