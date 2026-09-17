import 'draft_snapshots.dart';
import 'inline_lore_links.dart';
import '../../world_logic/domain/spoiler_safe_manuscript_knowledge_export.dart';

/// Tahap observable pada workflow writer end-to-end.
enum WriterWorkflowPhase {
  planning,
  drafting,
  linking,
  validation,
  revision,
  snapshot,
  cleanExport,
}

/// Hasil workflow writer yang dapat diaudit tanpa bergantung pada UI.
class WriterWorkflowResult {
  WriterWorkflowResult({
    required this.phases,
    required this.linkTargets,
    required this.validationIssues,
    required this.exportedContent,
    required this.currentText,
    required this.recoverCallback,
  });

  final List<WriterWorkflowPhase> phases;
  final List<String> linkTargets;
  final List<String> validationIssues;
  final String exportedContent;
  String currentText;
  final String Function() recoverCallback;
  bool recoveryCreatedBackup = false;

  /// Kembali ke snapshot awal; store membuat backup teks revisi sebelum restore.
  void recoverToSnapshot() {
    currentText = recoverCallback();
    recoveryCreatedBackup = true;
  }
}

/// Menjalankan jalur writer dari rencana sampai clean export.
///
/// Ini adalah orchestration domain untuk bukti end-to-end lokal; persistence
/// database dan native UI tetap berada di layer integrasi masing-masing.
class EndToEndWriterWorkflow {
  const EndToEndWriterWorkflow({
    required this.snapshots,
    required this.exportService,
  });

  final DraftSnapshotStore snapshots;
  final SpoilerSafeExportService exportService;

  WriterWorkflowResult run({
    required String draftId,
    required String plan,
    required String initialDraft,
    required String revision,
    required SpoilerSafeExportRequest exportRequest,
  }) {
    final phases = <WriterWorkflowPhase>[WriterWorkflowPhase.planning];
    final issues = <String>[];
    if (plan.trim().isEmpty) issues.add('plan is empty');

    snapshots.updateCurrent(draftId, initialDraft);
    phases.add(WriterWorkflowPhase.drafting);
    snapshots.captureAuto(draftId);

    final parsed = const InlineLoreLinkParser().parse(initialDraft);
    final targets = [
      for (final segment in parsed)
        if (segment is LoreLinkSegment) segment.displayName,
    ];
    phases.add(WriterWorkflowPhase.linking);
    if (const InlineLoreLinkRenderer().render(parsed) != initialDraft) {
      issues.add('inline link round-trip changed draft');
    }
    phases.add(WriterWorkflowPhase.validation);

    snapshots.updateCurrent(draftId, revision);
    phases.add(WriterWorkflowPhase.revision);
    snapshots.captureManual(
      draftId,
      label: 'writer workflow revision',
      content: revision,
    );
    phases.add(WriterWorkflowPhase.snapshot);

    final preflight = exportService.preflight(exportRequest);
    issues.addAll(preflight.issues);
    final exported = preflight.isReady
        ? exportService.export(exportRequest).content
        : '';
    phases.add(WriterWorkflowPhase.cleanExport);

    return WriterWorkflowResult(
      phases: List.unmodifiable(phases),
      linkTargets: List.unmodifiable(targets),
      validationIssues: List.unmodifiable(issues),
      exportedContent: exported,
      currentText: revision,
      recoverCallback: () {
        snapshots.restoreTo(draftId, index: 0);
        return snapshots.currentOf(draftId)!;
      },
    );
  }
}
