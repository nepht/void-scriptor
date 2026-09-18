import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/large_project_workflow.dart';

void main() {
  test('112.37 covers manifest, budgets, storage and failure results', () {
    const input = LargeProjectWorkflowInput(
      projectId: 'large-project-1',
      documentCount: 120,
      entityCount: 240,
      mediaCount: 48,
      timelineClipCount: 600,
      graphRelationCount: 320,
      longDocumentWords: 18000,
    );

    final result = const LargeProjectWorkflow().run(input);

    expect(
      result.datasetManifest,
      containsPair('projectId', 'large-project-1'),
    );
    expect(result.datasetManifest['documents'], 120);
    expect(result.datasetManifest['entities'], 240);
    expect(result.datasetManifest['media'], 48);
    expect(result.datasetManifest['timelineClips'], 600);
    expect(result.datasetManifest['graphRelations'], 320);
    expect(result.latencyResults, contains('document_index:within-budget'));
    expect(result.memoryResults, contains('working_set:bounded'));
    expect(result.storageResults, contains('media_manifest:complete'));
    expect(result.failureResults, contains('missing-media:recoverable'));
    expect(result.isAccepted, isTrue);
  });

  test('112.37 fails closed for an empty dataset identity', () {
    expect(
      () => const LargeProjectWorkflow().run(
        const LargeProjectWorkflowInput(
          projectId: '',
          documentCount: 1,
          entityCount: 1,
          mediaCount: 1,
          timelineClipCount: 1,
          graphRelationCount: 1,
          longDocumentWords: 1,
        ),
      ),
      throwsArgumentError,
    );
  });
}
