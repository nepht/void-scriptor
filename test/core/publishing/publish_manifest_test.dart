import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/publishing/domain/semver.dart';
import 'package:void_scriptor/core/publishing/domain/build_target.dart';
import 'package:void_scriptor/core/publishing/manifest/publish_manifest.dart';

void main() {
  test('PublishManifest holds fields', () {
    final manifest = PublishManifest(
      version: const SemVer(1, 0, 0),
      changelog: 'Initial release',
      checksum: 'abc123',
      artifacts: const {BuildTarget.web: 'web.zip'},
    );
    expect(manifest.version.toString(), '1.0.0');
    expect(manifest.changelog, 'Initial release');
    expect(manifest.artifacts, hasLength(1));
  });

  test('PublishManifest serializes to JSON and back', () {
    final manifest = PublishManifest(
      version: const SemVer(2, 1, 0),
      changelog: 'New features',
      checksum: 'def456',
      artifacts: const {BuildTarget.desktop: 'desktop.zip'},
    );
    final json = manifest.toJson();
    final restored = PublishManifest.fromJson(json);
    expect(restored.version.toString(), '2.1.0');
    expect(restored.changelog, 'New features');
    expect(restored.artifacts[BuildTarget.desktop], 'desktop.zip');
  });

  test('PublishManifest validation requires changelog', () {
    expect(
      () => PublishManifest(
        version: const SemVer(1, 0, 0),
        changelog: '',
        checksum: 'abc',
        artifacts: const {},
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
