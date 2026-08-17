import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/release/domain/release.dart';
import 'package:void_scriptor/features/release/domain/release_validation.dart';

void main() {
  group('Release', () {
    test('creates release with status', () {
      const r = Release(
        id: 'r1',
        projectId: 'p1',
        version: '1.2.0',
        status: ReleaseStatus.draft,
      );
      expect(r.version, '1.2.0');
      expect(r.status, ReleaseStatus.draft);
    });

    test('semver compare', () {
      const v1 = Release(
        id: 'a',
        projectId: 'p',
        version: '1.2.0',
        status: ReleaseStatus.draft,
      );
      const v2 = Release(
        id: 'b',
        projectId: 'p',
        version: '1.10.0',
        status: ReleaseStatus.draft,
      );
      expect(v1.compareSemverTo(v2), lessThan(0));
    });
  });

  group('ReleaseStatus', () {
    test('exposes statuses', () {
      expect(ReleaseStatus.values.map((e) => e.name), [
        'draft',
        'validating',
        'ready',
        'published',
        'archived',
        'failed',
      ]);
    });
  });

  group('ReleaseValidation', () {
    test('holds validation levels', () {
      const v = ReleaseValidation(
        releaseId: 'r1',
        level: ValidationLevel.buildCheck,
      );
      expect(v.level, ValidationLevel.buildCheck);
      expect(v.passed, isFalse);
    });

    test('passes after validation', () {
      const v = ReleaseValidation(
        releaseId: 'r1',
        level: ValidationLevel.buildCheck,
      );
      final ok = v.markPassed();
      expect(ok.passed, isTrue);
    });
  });

  group('ValidationLevel', () {
    test('exposes levels in order', () {
      expect(ValidationLevel.values.map((e) => e.name), [
        'metadataCheck',
        'buildCheck',
        'runtimeSmoke',
        'contentIntegrity',
        'certification',
      ]);
    });
  });
}
