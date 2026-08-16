import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/publishing/domain/semver.dart';
import 'package:void_scriptor/core/publishing/domain/build_target.dart';
import 'package:void_scriptor/core/publishing/domain/release_channel.dart';
import 'package:void_scriptor/core/publishing/manifest/publish_manifest.dart';
import 'package:void_scriptor/core/publishing/pipeline/publishing_pipeline.dart';

void main() {
  PublishManifest manifest() => PublishManifest(
    version: const SemVer(1, 0, 0),
    changelog: 'release',
    checksum: 'abc',
    artifacts: const {BuildTarget.web: 'web.zip'},
  );

  test('PublishingPipeline runs stages in order', () {
    const pipeline = PublishingPipeline();
    final result = pipeline.run(
      manifest: manifest(),
      channel: ReleaseChannel.stable,
    );
    expect(result.stages, ['build', 'package', 'publish']);
    expect(result.succeeded, isTrue);
  });

  test('PublishingPipeline propagates failure', () {
    const pipeline = PublishingPipeline(buildFails: true);
    final result = pipeline.run(
      manifest: manifest(),
      channel: ReleaseChannel.stable,
    );
    expect(result.succeeded, isFalse);
    expect(result.failedStage, 'build');
  });
}
