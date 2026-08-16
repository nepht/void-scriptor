import '../domain/release_channel.dart';
import '../manifest/publish_manifest.dart';

class PublishResult {
  PublishResult({
    required this.stages,
    required this.succeeded,
    this.failedStage,
  });

  final List<String> stages;
  final bool succeeded;
  final String? failedStage;
}

/// Publishing pipeline (Step 36.10–36.12).
class PublishingPipeline {
  const PublishingPipeline({this.buildFails = false});

  final bool buildFails;

  PublishResult run({
    required PublishManifest manifest,
    required ReleaseChannel channel,
  }) {
    final stages = <String>['build'];
    if (buildFails) {
      return PublishResult(
        stages: stages,
        succeeded: false,
        failedStage: 'build',
      );
    }
    stages.add('package');
    stages.add('publish');
    return PublishResult(stages: stages, succeeded: true);
  }
}
