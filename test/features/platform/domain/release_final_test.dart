import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/domain/release_final.dart';

void main() {
  group('BetaFeedback', () {
    test('holds beta feedback', () {
      final fb = BetaFeedback(
        id: 'bf1',
        category: 'ui',
        message: 'Tombol back tidak terlihat di layar sempit.',
        reportedAt: DateTime.utc(2026, 1, 1),
      );
      expect(fb.category, 'ui');
      expect(fb.message, contains('back'));
    });
  });

  group('ProductMetric', () {
    test('tracks minimal metrics', () {
      const m = ProductMetric(id: 'pm1', name: 'startup_ms', value: 1800);
      expect(m.value, 1800);
      expect(m.unit, 'count');
    });
  });

  group('AtomicSave', () {
    test('writes atomically', () {
      const s = AtomicSave(
        id: 'as1',
        targetPath: '/tmp/project.db',
        tempPath: '/tmp/project.db.tmp',
      );
      expect(s.targetPath, contains('project.db'));
    });
  });

  group('DiskSpaceGuard', () {
    test('blocks when low', () {
      const g = DiskSpaceGuard(
        freeBytes: 1024 * 1024 * 100,
        minimumRequiredBytes: 1024 * 1024 * 500,
      );
      expect(g.isBlocked, isTrue);
    });
  });

  group('PluginApiVersion', () {
    test('holds plugin API version', () {
      const v = PluginApiVersion(major: 1, minor: 0);
      expect(v.major, 1);
      expect(v.isCompatibleWith(1, 0), isTrue);
      expect(v.isCompatibleWith(2, 0), isFalse);
    });
  });

  group('ReleasePlan', () {
    test('holds 1.0 release plan', () {
      const plan = ReleasePlan(
        goldMasterVersion: '1.0.0',
        stagedRolloutPercent: 10,
      );
      expect(plan.goldMasterVersion, '1.0.0');
      expect(plan.stagedRolloutPercent, 10);
    });
  });

  group('PatchBranch', () {
    test('holds patch branch info', () {
      const pb = PatchBranch(
        id: 'pb1',
        baseVersion: '1.0.0',
        branchName: 'release/1.0.1',
      );
      expect(pb.branchName, 'release/1.0.1');
    });
  });
}
