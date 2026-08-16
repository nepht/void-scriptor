import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/publishing/domain/semver.dart';
import 'package:void_scriptor/core/publishing/domain/build_target.dart';
import 'package:void_scriptor/core/publishing/domain/release_channel.dart';
import 'package:void_scriptor/core/publishing/manifest/publish_manifest.dart';
import 'package:void_scriptor/core/publishing/record/publish_record.dart';
import 'package:void_scriptor/core/publishing/distribution/distribution_manager.dart';

void main() {
  PublishManifest manifest(String v) => PublishManifest(
    version: SemVer.parse(v),
    changelog: 'release $v',
    checksum: 'c$v',
    artifacts: const {BuildTarget.web: 'web.zip'},
  );

  test('PublishRecord holds metadata', () {
    final record = PublishRecord(
      id: 'r1',
      manifest: manifest('1.0.0'),
      channel: ReleaseChannel.stable,
      state: PublishState.published,
    );
    expect(record.channel, ReleaseChannel.stable);
    expect(record.state, PublishState.published);
  });

  test('DistributionManager publishes and gets latest per channel', () {
    final manager = DistributionManager();
    manager.publish(
      id: 'r1',
      manifest: manifest('1.0.0'),
      channel: ReleaseChannel.stable,
    );
    manager.publish(
      id: 'r2',
      manifest: manifest('1.1.0'),
      channel: ReleaseChannel.stable,
    );
    final latest = manager.latestFor(ReleaseChannel.stable);
    expect(latest!.manifest.version.toString(), '1.1.0');
  });

  test('DistributionManager channels are isolated', () {
    final manager = DistributionManager();
    manager.publish(
      id: 'r1',
      manifest: manifest('1.0.0'),
      channel: ReleaseChannel.alpha,
    );
    manager.publish(
      id: 'r2',
      manifest: manifest('2.0.0'),
      channel: ReleaseChannel.beta,
    );
    expect(
      manager.latestFor(ReleaseChannel.alpha)!.manifest.version.toString(),
      '1.0.0',
    );
    expect(
      manager.latestFor(ReleaseChannel.beta)!.manifest.version.toString(),
      '2.0.0',
    );
  });
}
