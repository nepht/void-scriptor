import '../data/story_repository_impl.dart';
import '../domain/end_to_end_writer_workflow.dart';
import '../domain/draft_snapshots.dart';
import '../../world_logic/domain/spoiler_safe_manuscript_knowledge_export.dart';

/// Adapter integrasi yang menjalankan orkestrasi writer di atas data scene
/// durable. Domain workflow tetap dapat diuji tanpa database, sementara jalur
/// aplikasi menyimpan draft dan checkpoint melalui repository.
class PersistedWriterWorkflowResult {
  const PersistedWriterWorkflowResult({
    required this.workflow,
    required this.initialSnapshotId,
    required this.initialDraft,
    required this.revision,
  });

  final WriterWorkflowResult workflow;
  final String initialSnapshotId;
  final String initialDraft;
  final String revision;
}

class PersistedWriterWorkflow {
  const PersistedWriterWorkflow({
    required this.repository,
    required this.workflow,
  });

  final StoryRepositoryImpl repository;
  final EndToEndWriterWorkflow workflow;

  Future<PersistedWriterWorkflowResult> run({
    required String sceneId,
    required String plan,
    required String initialDraft,
    required String revision,
    required SpoilerSafeExportRequest exportRequest,
  }) async {
    await repository.saveSceneDraft(sceneId, initialDraft);
    final initialSnapshotId = await repository.captureSceneDraftSnapshot(
      sceneId,
      label: 'writer workflow initial draft',
      kind: DraftSnapshotKind.manual,
    );
    await repository.saveSceneDraft(sceneId, revision);

    final result = workflow.run(
      draftId: sceneId,
      plan: plan,
      initialDraft: initialDraft,
      revision: revision,
      exportRequest: exportRequest,
    );
    return PersistedWriterWorkflowResult(
      workflow: result,
      initialSnapshotId: initialSnapshotId,
      initialDraft: initialDraft,
      revision: revision,
    );
  }
}
