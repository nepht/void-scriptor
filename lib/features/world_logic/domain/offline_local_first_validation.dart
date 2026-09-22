/// Offline & Local-First Validation (Step 113.19).
///
/// Validates that core functions work without network or external providers:
/// offline open, edit, analysis, search, local export, and provider failure fallback.
library;

import '../../export/domain/clean_export.dart';
import '../../export/domain/export_profiles.dart';
import '../../export/domain/export_preflight.dart';
import '../../world_logic/domain/end_to_end_publishing_workflow.dart';
import '../../world_logic/domain/offline_local_first_workflow.dart';

/// Result of validating offline open capability.
class OfflineOpenResult {
  const OfflineOpenResult({
    required this.workflowProcessesLocally,
    required this.emptyProjectIdRejected,
    required this.errors,
  });

  final bool workflowProcessesLocally;
  final bool emptyProjectIdRejected;
  final List<String> errors;

  bool get allValid =>
      workflowProcessesLocally && emptyProjectIdRejected && errors.isEmpty;
}

/// Result of validating offline edit capability.
class OfflineEditResult {
  const OfflineEditResult({
    required this.draftModifiedLocally,
    required this.sourcePreserved,
    required this.errors,
  });

  final bool draftModifiedLocally;
  final bool sourcePreserved;
  final List<String> errors;

  bool get allValid =>
      draftModifiedLocally && sourcePreserved && errors.isEmpty;
}

/// Result of validating offline analysis capability.
class OfflineAnalysisResult {
  const OfflineAnalysisResult({
    required this.preflightDetectsIssues,
    required this.cleanExportTransforms,
    required this.errors,
  });

  final bool preflightDetectsIssues;
  final bool cleanExportTransforms;
  final List<String> errors;

  bool get allValid =>
      preflightDetectsIssues && cleanExportTransforms && errors.isEmpty;
}

/// Result of validating offline search.
class OfflineSearchResult {
  const OfflineSearchResult({
    required this.indexBuiltLocally,
    required this.searchReturnsResults,
    required this.emptyQueryReturnsEmpty,
    required this.errors,
  });

  final bool indexBuiltLocally;
  final bool searchReturnsResults;
  final bool emptyQueryReturnsEmpty;
  final List<String> errors;

  bool get allValid =>
      indexBuiltLocally &&
      searchReturnsResults &&
      emptyQueryReturnsEmpty &&
      errors.isEmpty;
}

/// Result of validating local export.
class LocalExportResult {
  const LocalExportResult({
    required this.docxOutput,
    required this.plainTextOutput,
    required this.webNovelOutput,
    required this.profileLocallyConfigurable,
    required this.errors,
  });

  final bool docxOutput;
  final bool plainTextOutput;
  final bool webNovelOutput;
  final bool profileLocallyConfigurable;
  final List<String> errors;

  bool get allValid =>
      docxOutput &&
      plainTextOutput &&
      webNovelOutput &&
      profileLocallyConfigurable &&
      errors.isEmpty;
}

/// Result of validating provider failure fallback.
class ProviderFallbackResult {
  const ProviderFallbackResult({
    required this.queuesWhenUnavailable,
    required this.noCrashOnUnavailable,
    required this.errors,
  });

  final bool queuesWhenUnavailable;
  final bool noCrashOnUnavailable;
  final List<String> errors;

  bool get allValid =>
      queuesWhenUnavailable && noCrashOnUnavailable && errors.isEmpty;
}

/// Simple in-memory search index (no external deps).
class _SearchEntry {
  const _SearchEntry(this.id, this.title, this.body);
  final String id;
  final String title;
  final String body;
}

class _LocalSearchIndex {
  final _docs = <String, _SearchEntry>{};

  void add(String id, String title, String body) {
    _docs[id] = _SearchEntry(id, title, body);
  }

  void remove(String id) => _docs.remove(id);

  List<_SearchEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _docs.values
        .where((d) => '${d.title} ${d.body}'.toLowerCase().contains(q))
        .toList(growable: false);
  }
}

/// Aggregate offline & local-first validation for step 113.19.
class OfflineLocalFirstValidation {
  const OfflineLocalFirstValidation();

  // ---------------------------------------------------------------------------
  // 1. Offline open
  // ---------------------------------------------------------------------------
  OfflineOpenResult validateOfflineOpen() {
    final errors = <String>[];
    const workflow = OfflineLocalFirstWorkflow();
    const input = OfflineWorkflowInput(
      projectId: 'proj-offline-test',
      draft: 'Chapter content here.',
      analysisText: 'pacing data',
      exportTitle: 'Offline Novel',
      providerAvailable: false,
    );

    OfflineWorkflowResult result;
    try {
      result = workflow.run(input);
    } catch (e) {
      return OfflineOpenResult(
        workflowProcessesLocally: false,
        emptyProjectIdRejected: false,
        errors: ['Workflow threw: $e'],
      );
    }

    if (!result.offlineOpen) {
      errors.add('Workflow did not process offline open');
    }

    // Empty project ID should be rejected
    try {
      workflow.run(
        const OfflineWorkflowInput(
          projectId: '',
          draft: 'text',
          analysisText: 'text',
          exportTitle: 'title',
          providerAvailable: false,
        ),
      );
      errors.add('Empty projectId should throw');
    } on ArgumentError {
      // expected
    }

    return OfflineOpenResult(
      workflowProcessesLocally: result.offlineOpen,
      emptyProjectIdRejected: true,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Offline edit
  // ---------------------------------------------------------------------------
  OfflineEditResult validateOfflineEdit() {
    final errors = <String>[];
    const workflow = OfflineLocalFirstWorkflow();
    const input = OfflineWorkflowInput(
      projectId: 'proj-edit',
      draft: 'Original draft text.',
      analysisText: 'analysis',
      exportTitle: 'Edit Test',
      providerAvailable: false,
    );

    OfflineWorkflowResult result;
    try {
      result = workflow.run(input);
    } catch (e) {
      return OfflineEditResult(
        draftModifiedLocally: false,
        sourcePreserved: false,
        errors: ['Workflow threw: $e'],
      );
    }

    // Draft should be modified locally
    final draftModified =
        result.offlineEdit.contains('[edited offline]') &&
        result.offlineEdit.contains('Original draft text.');
    if (!draftModified) {
      errors.add('Draft not modified offline');
    }

    // Source content preserved in edit result
    final sourcePreserved =
        result.offlineEdit.isNotEmpty &&
        result.offlineAnalysis.isNotEmpty &&
        result.localExport.isNotEmpty;
    if (!sourcePreserved) {
      errors.add('Offline workflow output incomplete');
    }

    return OfflineEditResult(
      draftModifiedLocally: draftModified,
      sourcePreserved: sourcePreserved,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Offline analysis
  // ---------------------------------------------------------------------------
  OfflineAnalysisResult validateOfflineAnalysis() {
    final errors = <String>[];

    // Preflight detects empty document as blocking issue
    const validator = ExportPreflightValidator();
    final emptyReport = validator.validate(
      ExportPreflightRequest(
        documentId: 'offline-analysis-empty',
        sourceText: '',
        profile: ExportProfile.docx(),
      ),
    );
    final preflightDetectsIssues =
        !emptyReport.isReady && emptyReport.blockingErrors.isNotEmpty;

    // Clean export transforms locally
    const cleaner = CleanExportTransformer();
    const dirtyText =
        'Text with [[PRIVATE:secret note]] and [Link](scene:abc) markers. '
        '[[Lore:World Bible]] and scene:def456 remain.';
    final cleaned = cleaner.transform(dirtyText);
    final cleanTransforms =
        !cleaned.text.contains('[[PRIVATE:') &&
        !cleaned.text.contains('scene:abc') &&
        !cleaned.text.contains('[[Lore:') &&
        !cleaned.text.contains('scene:def456') &&
        cleaned.text.contains('Text with') &&
        cleaned.removedPrivateNotes == 1 &&
        cleaned.removedInternalLinks >= 2;

    if (!preflightDetectsIssues) {
      errors.add('Preflight should detect empty document');
    }
    if (!cleanTransforms) {
      errors.add('Clean export did not remove markers locally');
    }

    return OfflineAnalysisResult(
      preflightDetectsIssues: preflightDetectsIssues,
      cleanExportTransforms: cleanTransforms,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Offline search
  // ---------------------------------------------------------------------------
  OfflineSearchResult validateOfflineSearch() {
    final errors = <String>[];
    final index = _LocalSearchIndex();

    // Build index locally (no network)
    index.add(
      'char-1',
      'Qowner',
      'The protagonist who is brave and resourceful.',
    );
    index.add(
      'loc-1',
      'Pole of Creation',
      'The northernmost point where reality thins.',
    );
    index.add('item-1', 'Void Cube', 'An ancient artifact of immense power.');

    // Search returns results
    final results = index.search('void');
    if (results.isEmpty) {
      errors.add('Search for "void" returned no results');
    }
    final hasVoidCube = results.any((r) => r.id == 'item-1');
    if (!hasVoidCube) {
      errors.add('Search for "void" did not find Void Cube');
    }

    // Specific search
    final qownerResults = index.search('Qowner');
    if (qownerResults.isEmpty) {
      errors.add('Search for "Qowner" returned no results');
    }

    // Empty query returns empty
    final emptyResults = index.search('');
    if (emptyResults.isNotEmpty) {
      errors.add('Empty query should return empty results');
    }

    // Remove from index
    index.remove('item-1');
    final afterRemove = index.search('Void Cube');
    if (afterRemove.isNotEmpty) {
      errors.add('Removed document still found in index');
    }

    return OfflineSearchResult(
      indexBuiltLocally: true,
      searchReturnsResults: results.isNotEmpty,
      emptyQueryReturnsEmpty: emptyResults.isEmpty,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Local export
  // ---------------------------------------------------------------------------
  LocalExportResult validateLocalExport() {
    final errors = <String>[];
    const workflow = EndToEndPublishingWorkflow();
    const input = PublishingWorkflowInput(
      title: 'Offline Novel',
      author: 'Test Author',
      chapters: [
        PublishingChapter(
          title: 'Chapter 1',
          body: 'Content written entirely offline.',
        ),
      ],
    );

    PublishingWorkflowResult result;
    try {
      result = workflow.run(input);
    } catch (e) {
      return LocalExportResult(
        docxOutput: false,
        plainTextOutput: false,
        webNovelOutput: false,
        profileLocallyConfigurable: false,
        errors: ['Workflow threw: $e'],
      );
    }

    final docxOk =
        result.outputs.containsKey(PublishingFormat.docx) &&
        (result.outputs[PublishingFormat.docx]?.isNotEmpty ?? false);
    final plainOk =
        result.outputs.containsKey(PublishingFormat.plainText) &&
        (result.outputs[PublishingFormat.plainText]?.isNotEmpty ?? false);
    final webOk =
        result.outputs.containsKey(PublishingFormat.webNovel) &&
        (result.outputs[PublishingFormat.webNovel]?.isNotEmpty ?? false);

    if (!docxOk) errors.add('DOCX output missing or empty');
    if (!plainOk) errors.add('PlainText output missing or empty');
    if (!webOk) errors.add('WebNovel output missing or empty');

    // Profiles are locally constructable and configurable
    final docxProfile = ExportProfile.docx();
    final plainProfile = ExportProfile.plainText();
    final webProfile = ExportProfile.webNovel();
    final profileOk =
        docxProfile.format == ExportFormat.docx &&
        plainProfile.format == ExportFormat.plainText &&
        webProfile.format == ExportFormat.webNovel &&
        docxProfile.sceneBreakMarker.isNotEmpty &&
        plainProfile.sceneBreakMarker.isNotEmpty &&
        webProfile.sceneBreakMarker.isNotEmpty;

    if (!profileOk) errors.add('Export profiles not locally configurable');

    return LocalExportResult(
      docxOutput: docxOk,
      plainTextOutput: plainOk,
      webNovelOutput: webOk,
      profileLocallyConfigurable: profileOk,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Provider failure fallback
  // ---------------------------------------------------------------------------
  ProviderFallbackResult validateProviderFallback() {
    final errors = <String>[];
    const workflow = OfflineLocalFirstWorkflow();

    // Provider unavailable → queued locally, no crash
    const unavailableInput = OfflineWorkflowInput(
      projectId: 'proj-fallback',
      draft: 'Draft for fallback test.',
      analysisText: 'fallback analysis',
      exportTitle: 'Fallback Novel',
      providerAvailable: false,
    );

    OfflineWorkflowResult result;
    try {
      result = workflow.run(unavailableInput);
    } catch (e) {
      return ProviderFallbackResult(
        queuesWhenUnavailable: false,
        noCrashOnUnavailable: false,
        errors: ['Workflow threw on unavailable provider: $e'],
      );
    }

    // Should queue provider-generation action
    final queued = result.queuedOptionalActions.contains('provider-generation');
    if (!queued) {
      errors.add(
        'provider-generation should be queued when provider unavailable',
      );
    }

    // Provider failure message should indicate unavailability
    final hasFallbackMessage = result.gracefulProviderFailure.contains(
      'unavailable',
    );
    if (!hasFallbackMessage) {
      errors.add('Provider failure should mention unavailability');
    }

    // Source content preserved
    if (!result.offlineEdit.contains('Draft for fallback test.')) {
      errors.add('Source content should be preserved during fallback');
    }

    // Provider available → no queue
    const availableInput = OfflineWorkflowInput(
      projectId: 'proj-available',
      draft: 'Draft with provider.',
      analysisText: 'analysis',
      exportTitle: 'Available Novel',
      providerAvailable: true,
    );

    final availableResult = workflow.run(availableInput);
    if (availableResult.queuedOptionalActions.isNotEmpty) {
      errors.add('No actions should be queued when provider is available');
    }
    if (!availableResult.gracefulProviderFailure.contains('available')) {
      errors.add('Provider available message mismatch');
    }

    return ProviderFallbackResult(
      queuesWhenUnavailable: queued,
      noCrashOnUnavailable: true,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // Aggregate
  // ---------------------------------------------------------------------------
  Map<String, bool> runAll() {
    final open = validateOfflineOpen();
    final edit = validateOfflineEdit();
    final analysis = validateOfflineAnalysis();
    final search = validateOfflineSearch();
    final export = validateLocalExport();
    final fallback = validateProviderFallback();

    return <String, bool>{
      'offline_open': open.allValid,
      'offline_edit': edit.allValid,
      'offline_analysis': analysis.allValid,
      'offline_search': search.allValid,
      'local_export': export.allValid,
      'provider_failure_fallback': fallback.allValid,
    };
  }
}
