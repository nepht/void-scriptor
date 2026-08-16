import '../domain/semver.dart';
import '../domain/build_target.dart';
import '../domain/release_channel.dart';
import '../manifest/publish_manifest.dart';

/// Built-in demo publishing setup (Step 36.20).
class DemoPublishing {
  DemoPublishing._();

  static final PublishManifest manifest = PublishManifest(
    version: const SemVer(1, 2, 0),
    changelog: 'Plugin system, rendering, animation, audio engines',
    checksum: 'demo-checksum',
    artifacts: const {
      BuildTarget.web: 'web.zip',
      BuildTarget.desktop: 'windows.zip',
    },
  );

  static const ReleaseChannel channel = ReleaseChannel.stable;
}
