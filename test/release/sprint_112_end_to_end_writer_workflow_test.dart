import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/domain/end_to_end_writer_workflow.dart';
import 'package:void_scriptor/features/story/domain/draft_snapshots.dart';
import 'package:void_scriptor/features/spoiler/domain/reader_redaction.dart';
import 'package:void_scriptor/features/spoiler/domain/spoiler_classification.dart';
import 'package:void_scriptor/features/world_logic/domain/spoiler_safe_manuscript_knowledge_export.dart';

void main() {
  test('112.32 executes planning through clean export in canonical order', () {
    final registry = SpoilerRegistry()
      ..addAudience(const SpoilerAudience('beta', SpoilerLevel.clean))
      ..classify('secret', SpoilerLevel.major);
    final exportService = SpoilerSafeExportService(
      redactor: ReaderRedactor(registry: registry)
        ..grant(readerId: 'reader', audience: 'beta'),
    );
    final snapshots = DraftSnapshotStore(
      clock: () => DateTime.utc(2026, 9, 18, 3),
    );
    final workflow = EndToEndWriterWorkflow(
      snapshots: snapshots,
      exportService: exportService,
    );

    final result = workflow.run(
      draftId: 'scene-1',
      plan: 'Plan: reveal the lighthouse secret.',
      initialDraft: 'The [[Lighthouse]] waits.\nA secret remains.',
      revision: 'The [[Lighthouse]] waits.\nThe tide turns.',
      exportRequest: const SpoilerSafeExportRequest(
        documentId: 'novel-1',
        title: 'Ash Coast',
        readerId: 'reader',
        currentScene: 'scene-1',
        format: ExportFormat.plainText,
        sections: [
          ExportSection(id: 'scene-1', title: 'Scene', text: 'Clean prose.'),
        ],
      ),
    );

    expect(result.phases, <WriterWorkflowPhase>[
      WriterWorkflowPhase.planning,
      WriterWorkflowPhase.drafting,
      WriterWorkflowPhase.linking,
      WriterWorkflowPhase.validation,
      WriterWorkflowPhase.revision,
      WriterWorkflowPhase.snapshot,
      WriterWorkflowPhase.cleanExport,
    ]);
    expect(result.linkTargets, <String>['Lighthouse']);
    expect(result.exportedContent, contains('Clean prose.'));
    expect(result.validationIssues, isEmpty);
    expect(snapshots.currentOf('scene-1'), contains('tide turns'));
  });

  test('112.32 recovery restores the revision from its snapshot safely', () {
    final registry = SpoilerRegistry()
      ..addAudience(const SpoilerAudience('beta', SpoilerLevel.clean));
    final workflow = EndToEndWriterWorkflow(
      snapshots: DraftSnapshotStore(clock: () => DateTime.utc(2026, 9, 18, 3)),
      exportService: SpoilerSafeExportService(
        redactor: ReaderRedactor(registry: registry)
          ..grant(readerId: 'reader', audience: 'beta'),
      ),
    );

    final result = workflow.run(
      draftId: 'scene-2',
      plan: 'Plan',
      initialDraft: 'Initial',
      revision: 'Revision',
      exportRequest: const SpoilerSafeExportRequest(
        documentId: 'novel-1',
        title: 'Ash Coast',
        readerId: 'reader',
        currentScene: 'scene-2',
        format: ExportFormat.plainText,
        sections: [ExportSection(id: 's2', title: 'Scene', text: 'Ready.')],
      ),
    );

    result.recoverToSnapshot();
    expect(result.currentText, 'Initial');
    expect(result.recoveryCreatedBackup, isTrue);
  });
}
