/// Publishing & Clean Export Validation (Step 113.18).
///
/// Validates export profiles, preflight checks, clean rendering across
/// DOCX/plain text/web novel, marker removal determinism, ownership
/// manifest integrity, and watermark policy correctness.
library;

import '../../export/domain/clean_export.dart';
import '../../export/domain/export_preflight.dart';
import '../../export/domain/export_profiles.dart';
import '../../export/domain/export_protection.dart';
import 'end_to_end_publishing_workflow.dart';

/// Result of validating export profiles for all three canonical formats.
class ProfileValidationResult {
  const ProfileValidationResult({
    required this.docxValid,
    required this.plainTextValid,
    required this.webNovelValid,
    required this.presetRoundTrip,
    required this.errors,
  });

  final bool docxValid;
  final bool plainTextValid;
  final bool webNovelValid;
  final bool presetRoundTrip;
  final List<String> errors;

  bool get allValid =>
      docxValid &&
      plainTextValid &&
      webNovelValid &&
      presetRoundTrip &&
      errors.isEmpty;
}

/// Result of validating preflight checks.
class PreflightValidationResult {
  const PreflightValidationResult({
    required this.emptyDocBlocked,
    required this.missingAssetBlocked,
    required this.spoilersDetected,
    required this.cleanDocReady,
    required this.errors,
  });

  final bool emptyDocBlocked;
  final bool missingAssetBlocked;
  final bool spoilersDetected;
  final bool cleanDocReady;
  final List<String> errors;

  bool get allValid =>
      emptyDocBlocked &&
      missingAssetBlocked &&
      spoilersDetected &&
      cleanDocReady &&
      errors.isEmpty;
}

/// Result of validating format rendering.
class FormatRenderResult {
  const FormatRenderResult({
    required this.docxContainsTitle,
    required this.docxContainsChapter,
    required this.plainTextContainsTitle,
    required this.plainTextContainsChapter,
    required this.webNovelContainsTitle,
    required this.webNovelContainsChapter,
    required this.errors,
  });

  final bool docxContainsTitle;
  final bool docxContainsChapter;
  final bool plainTextContainsTitle;
  final bool plainTextContainsChapter;
  final bool webNovelContainsTitle;
  final bool webNovelContainsChapter;
  final List<String> errors;

  bool get allValid =>
      docxContainsTitle &&
      docxContainsChapter &&
      plainTextContainsTitle &&
      plainTextContainsChapter &&
      webNovelContainsTitle &&
      webNovelContainsChapter &&
      errors.isEmpty;
}

/// Result of validating clean export transformation.
class CleanExportValidationResult {
  const CleanExportValidationResult({
    required this.privateNotesRemoved,
    required this.sceneLinksRemoved,
    required this.loreLinksRemoved,
    required this.bareLinksRemoved,
    required this.fingerprintDeterministic,
    required this.errors,
  });

  final bool privateNotesRemoved;
  final bool sceneLinksRemoved;
  final bool loreLinksRemoved;
  final bool bareLinksRemoved;
  final bool fingerprintDeterministic;
  final List<String> errors;

  bool get allValid =>
      privateNotesRemoved &&
      sceneLinksRemoved &&
      loreLinksRemoved &&
      bareLinksRemoved &&
      fingerprintDeterministic &&
      errors.isEmpty;
}

/// Result of validating metadata and protection.
class MetadataValidationResult {
  const MetadataValidationResult({
    required this.manifestDeterministic,
    required this.watermarkAppliedForPreview,
    required this.watermarkSkippedForPrivate,
    required this.ownershipFieldsPresent,
    required this.errors,
  });

  final bool manifestDeterministic;
  final bool watermarkAppliedForPreview;
  final bool watermarkSkippedForPrivate;
  final bool ownershipFieldsPresent;
  final List<String> errors;

  bool get allValid =>
      manifestDeterministic &&
      watermarkAppliedForPreview &&
      watermarkSkippedForPrivate &&
      ownershipFieldsPresent &&
      errors.isEmpty;
}

/// Aggregate publishing & clean export validation for step 113.18.
class PublishingCleanExportValidation {
  const PublishingCleanExportValidation();

  // ---------------------------------------------------------------------------
  // 1. Profile validation
  // ---------------------------------------------------------------------------

  ProfileValidationResult validateProfiles() {
    final errors = <String>[];

    // DOCX default profile
    final docx = ExportProfile.docx();
    if (docx.format != ExportFormat.docx) {
      errors.add('DOCX profile format mismatch');
    }
    if (docx.chapterRules == null) {
      errors.add('DOCX profile missing chapter rules');
    } else {
      final title = docx.chapterRules!.title(1);
      if (!title.contains('1')) {
        errors.add('DOCX chapter title numbering broken');
      }
    }
    if (!docx.sceneBreakMarker.contains('*')) {
      errors.add('DOCX scene break marker invalid');
    }
    if (docx.frontMatter != null) {
      errors.add('DOCX profile should not have front matter by default');
    }

    // Plain text default profile
    final plainText = ExportProfile.plainText();
    if (plainText.format != ExportFormat.plainText) {
      errors.add('PlainText profile format mismatch');
    }
    if (plainText.sceneBreakMarker != '---') {
      errors.add('PlainText scene break marker invalid');
    }

    // Web novel default profile
    final webNovel = ExportProfile.webNovel();
    if (webNovel.format != ExportFormat.webNovel) {
      errors.add('WebNovel profile format mismatch');
    }
    if (!webNovel.sceneBreakMarker.contains('div')) {
      errors.add('WebNovel scene break marker invalid');
    }
    if (webNovel.sceneBreakRules == null) {
      errors.add('WebNovel profile missing scene break rules');
    }

    // Front matter rendering
    docx.setFrontMatter(title: 'Test Novel', author: 'Author X');
    final fmRender = docx.renderFrontMatter();
    if (!fmRender.contains('Test Novel') || !fmRender.contains('Author X')) {
      errors.add('Front matter render broken');
    }

    // Empty front matter renders empty
    final noFm = ExportProfile.plainText();
    if (noFm.renderFrontMatter() != '') {
      errors.add('Empty front matter should render empty string');
    }

    // Preset round-trip: save, load, verify
    final book = ExportPresetBook();
    book.save(name: 'MyDocx', profile: docx);
    book.save(name: 'MyPlain', profile: plainText);
    final names = book.names();
    if (names.length != 2 || names[0] != 'MyDocx' || names[1] != 'MyPlain') {
      errors.add('Preset book listing broken');
    }
    final loaded = book.load('MyDocx');
    if (loaded.format != ExportFormat.docx) {
      errors.add('Preset round-trip format mismatch');
    }
    if (!loaded.sceneBreakMarker.contains('*')) {
      errors.add('Preset round-trip scene break mismatch');
    }

    // Preset overwrite
    book.save(name: 'MyDocx', profile: plainText);
    final overwritten = book.load('MyDocx');
    if (overwritten.format != ExportFormat.plainText) {
      errors.add('Preset overwrite not applied');
    }

    // Preset delete
    book.delete('MyDocx');
    try {
      book.load('MyDocx');
      errors.add('Preset delete did not remove entry');
    } on StateError {
      // expected
    }

    // Preset unknown
    try {
      book.load('NonExistent');
      errors.add('Loading unknown preset should throw');
    } on StateError {
      // expected
    }

    // Chapter numbering start validation
    try {
      docx.setChapterRules(
        numberingStart: -1,
        titlePrefix: 'Ch',
        pageBreakBefore: false,
      );
      errors.add('Negative numbering start should throw');
    } on ArgumentError {
      // expected
    }

    // Empty scene break marker
    try {
      ExportProfile(format: ExportFormat.plainText, sceneBreakMarker: '');
      errors.add('Empty scene break marker should throw');
    } on ArgumentError {
      // expected
    }

    // Front matter with chapter title
    docx.setChapterRules(
      numberingStart: 0,
      titlePrefix: 'Episode',
      pageBreakBefore: false,
    );
    final epTitle = docx.chapterRules!.title(5);
    if (epTitle != 'Episode 5') {
      errors.add('Chapter title prefix+number broken: $epTitle');
    }

    return ProfileValidationResult(
      docxValid: docx.format == ExportFormat.docx,
      plainTextValid: plainText.format == ExportFormat.plainText,
      webNovelValid: webNovel.format == ExportFormat.webNovel,
      presetRoundTrip: true,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Preflight validation
  // ---------------------------------------------------------------------------

  PreflightValidationResult validatePreflight() {
    final errors = <String>[];
    const validator = ExportPreflightValidator();
    final profile = ExportProfile.docx();

    // Empty document should be blocked
    final emptyReport = validator.validate(
      ExportPreflightRequest(
        documentId: 'doc-empty',
        sourceText: '',
        profile: profile,
      ),
    );
    if (emptyReport.isReady) {
      errors.add('Empty document should not pass preflight');
    }
    if (emptyReport.blockingErrors.isEmpty) {
      errors.add('Empty document should have blocking errors');
    }
    final emptyBlocked = emptyReport.blockingErrors.any(
      (e) => e.code == 'empty_document',
    );

    // Missing asset should be blocked
    final missingAssetReport = validator.validate(
      ExportPreflightRequest(
        documentId: 'doc-missing-asset',
        sourceText: 'Some content here',
        profile: profile,
        assets: [
          const ExportAssetRef(
            id: 'img1',
            path: '/images/cover.png',
            exists: false,
          ),
        ],
      ),
    );
    final assetBlocked = missingAssetReport.blockingErrors.any(
      (e) => e.code == 'missing_asset',
    );

    // Spoiler detection
    final spoilerReport = validator.validate(
      ExportPreflightRequest(
        documentId: 'doc-spoiler',
        sourceText: 'Content with spoilers',
        profile: profile,
        unresolvedSpoilerIds: ['spoiler-1', 'spoiler-2'],
      ),
    );
    final spoilerDetected = spoilerReport.warnings.any(
      (e) => e.code == 'unresolved_spoiler',
    );
    if (spoilerReport.blockingErrors.isNotEmpty) {
      errors.add('Spoilers should be warnings, not errors');
    }

    // Clean document should be ready
    final cleanReport = validator.validate(
      ExportPreflightRequest(
        documentId: 'doc-clean',
        sourceText: 'This is a clean manuscript with enough content.',
        profile: profile,
        assets: [
          const ExportAssetRef(
            id: 'img1',
            path: '/images/cover.png',
            exists: true,
          ),
        ],
      ),
    );
    if (!cleanReport.isReady) {
      errors.add('Clean document should pass preflight');
    }
    if (cleanReport.preview.isEmpty) {
      errors.add('Preview should not be empty');
    }
    if (cleanReport.manifest.documentId != 'doc-clean') {
      errors.add('Manifest documentId mismatch');
    }
    if (cleanReport.manifest.format != ExportFormat.docx) {
      errors.add('Manifest format mismatch');
    }
    if (cleanReport.manifest.contentFingerprint.isEmpty) {
      errors.add('Manifest fingerprint should not be empty');
    }

    // Preview character limit
    final longReport = validator.validate(
      ExportPreflightRequest(
        documentId: 'doc-long',
        sourceText: 'A' * 500,
        profile: profile,
        previewCharacterLimit: 50,
      ),
    );
    if (longReport.preview.length > 50) {
      errors.add('Preview should respect character limit');
    }
    if (!longReport.preview.endsWith('…')) {
      errors.add('Preview should end with ellipsis when truncated');
    }

    // Preview limit validation
    try {
      validator.validate(
        ExportPreflightRequest(
          documentId: 'doc-zero-limit',
          sourceText: 'text',
          profile: profile,
          previewCharacterLimit: 0,
        ),
      );
      errors.add('Zero preview limit should throw');
    } on ArgumentError {
      // expected
    }

    return PreflightValidationResult(
      emptyDocBlocked: emptyBlocked,
      missingAssetBlocked: assetBlocked,
      spoilersDetected: spoilerDetected,
      cleanDocReady: cleanReport.isReady,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Format render validation
  // ---------------------------------------------------------------------------

  FormatRenderResult validateFormatRender() {
    final errors = <String>[];
    const workflow = EndToEndPublishingWorkflow();
    const input = PublishingWorkflowInput(
      title: 'The Void Cube',
      author: 'Choirudin',
      chapters: [
        PublishingChapter(
          title: 'Chapter 1: Awakening',
          body: 'The cube pulsed with ancient energy.',
        ),
        PublishingChapter(
          title: 'Chapter 2: Descent',
          body: 'Shadows consumed the lower levels.',
        ),
      ],
    );

    PublishingWorkflowResult result;
    try {
      result = workflow.run(input);
    } catch (e) {
      return FormatRenderResult(
        docxContainsTitle: false,
        docxContainsChapter: false,
        plainTextContainsTitle: false,
        plainTextContainsChapter: false,
        webNovelContainsTitle: false,
        webNovelContainsChapter: false,
        errors: ['Workflow threw: $e'],
      );
    }

    if (!result.isAccepted) {
      errors.add('Workflow result not accepted');
    }
    if (result.outputs.length != 3) {
      errors.add('Expected 3 output formats, got ${result.outputs.length}');
    }

    // DOCX output
    final docxOutput = result.outputs[PublishingFormat.docx] ?? '';
    final docxHasTitle = docxOutput.contains('The Void Cube');
    final docxHasChapter = docxOutput.contains('Chapter 1: Awakening');
    if (!docxHasTitle) errors.add('DOCX missing title');
    if (!docxHasChapter) errors.add('DOCX missing chapter');
    if (!docxOutput.contains('<w:document>')) {
      errors.add('DOCX missing document wrapper');
    }

    // Plain text output
    final plainOutput = result.outputs[PublishingFormat.plainText] ?? '';
    final plainHasTitle = plainOutput.contains('The Void Cube');
    final plainHasChapter = plainOutput.contains('Chapter 1: Awakening');
    if (!plainHasTitle) errors.add('PlainText missing title');
    if (!plainHasChapter) errors.add('PlainText missing chapter');

    // Web novel output
    final webOutput = result.outputs[PublishingFormat.webNovel] ?? '';
    final webHasTitle = webOutput.contains('The Void Cube');
    final webHasChapter = webOutput.contains('Chapter 1: Awakening');
    if (!webHasTitle) errors.add('WebNovel missing title');
    if (!webHasChapter) errors.add('WebNovel missing chapter');
    if (!webOutput.contains('<article>')) {
      errors.add('WebNovel missing article wrapper');
    }

    // Internal marker should be cleaned
    const dirtyInput = PublishingWorkflowInput(
      title: 'Dirty Story',
      author: 'Test',
      chapters: [
        PublishingChapter(
          title: 'Ch 1',
          body: 'Text with [[INTERNAL:note]] and [Link](scene:abc) markers.',
        ),
      ],
    );
    final dirtyResult = workflow.run(dirtyInput);
    final dirtyPlain = dirtyResult.outputs[PublishingFormat.plainText] ?? '';
    if (dirtyPlain.contains('[[INTERNAL:')) {
      errors.add('Internal marker [[INTERNAL:]] not cleaned');
    }
    if (dirtyPlain.contains('scene:abc')) {
      errors.add('Scene link not cleaned from plain text');
    }

    return FormatRenderResult(
      docxContainsTitle: docxHasTitle,
      docxContainsChapter: docxHasChapter,
      plainTextContainsTitle: plainHasTitle,
      plainTextContainsChapter: plainHasChapter,
      webNovelContainsTitle: webHasTitle,
      webNovelContainsChapter: webHasChapter,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Clean export validation
  // ---------------------------------------------------------------------------

  CleanExportValidationResult validateCleanExport() {
    final errors = <String>[];
    const transformer = CleanExportTransformer();

    // Test with all marker types
    const source =
        'Start [[PRIVATE:secret note]] middle '
        '[Link Text](scene:ch1-sc1) end '
        '[[Lore:World Bible]] bare scene:abc123 done.';

    final result = transformer.transform(source);

    if (result.text.contains('[[PRIVATE:')) {
      errors.add('Private notes not removed');
    }
    if (result.text.contains('scene:ch1-sc1')) {
      errors.add('Scene markdown link not removed');
    }
    if (result.text.contains('[[Lore:')) {
      errors.add('Lore link not removed');
    }
    if (result.text.contains('scene:abc123')) {
      errors.add('Bare scene link not removed');
    }
    if (!result.text.contains('Link Text')) {
      errors.add('Link text content should be preserved');
    }
    if (!result.text.contains('Start') || !result.text.contains('end')) {
      errors.add('Non-marker text should be preserved');
    }
    if (result.removedPrivateNotes != 1) {
      errors.add(
        'Expected 1 private note removed, got ${result.removedPrivateNotes}',
      );
    }
    if (result.removedInternalLinks < 2) {
      errors.add(
        'Expected at least 2 internal links removed, '
        'got ${result.removedInternalLinks}',
      );
    }

    // Determinism: same input → same fingerprint
    final result2 = transformer.transform(source);
    if (result.fingerprint != result2.fingerprint) {
      errors.add('Fingerprint not deterministic across runs');
    }
    if (result.text != result2.text) {
      errors.add('Transform output not deterministic across runs');
    }

    // Clean input stays unchanged
    const clean = 'No markers here, just prose.';
    final cleanResult = transformer.transform(clean);
    if (cleanResult.text != clean) {
      errors.add('Clean text should not be modified');
    }
    if (cleanResult.removedInternalLinks != 0) {
      errors.add('Clean text should have 0 removed links');
    }
    if (cleanResult.removedPrivateNotes != 0) {
      errors.add('Clean text should have 0 removed notes');
    }
    if (cleanResult.wasChanged) {
      errors.add('wasChanged should be false for clean text');
    }
    if (!result.wasChanged) {
      errors.add('wasChanged should be true when markers are removed');
    }

    return CleanExportValidationResult(
      privateNotesRemoved: !result.text.contains('[[PRIVATE:'),
      sceneLinksRemoved: !result.text.contains('scene:ch1-sc1'),
      loreLinksRemoved: !result.text.contains('[[Lore:'),
      bareLinksRemoved: !result.text.contains('scene:abc123'),
      fingerprintDeterministic: result.fingerprint == result2.fingerprint,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Metadata & protection validation
  // ---------------------------------------------------------------------------

  MetadataValidationResult validateMetadata() {
    final errors = <String>[];
    const planner = ExportProtectionPlanner();
    final ownership = OwnershipMetadata.validated(
      creatorId: 'user-001',
      projectId: 'proj-void',
      copyrightHolder: 'Choirudin',
      rightsStatement: 'All rights reserved',
    );

    // Ownership manifest fields
    final manifest = ExportOwnershipManifest.create(
      assetId: 'novel-001',
      assetKind: ProtectedAssetKind.novel,
      exportUse: ExportUse.privateMaster,
      exportRevision: '1.0.0',
      contentSha256: 'abc123def456',
      watermarkApplied: false,
      watermarkMode: WatermarkMode.off,
      recipientToken: null,
      ownership: ownership,
    );
    if (manifest.assetId != 'novel-001') {
      errors.add('Manifest assetId mismatch');
    }
    if (manifest.contentSha256 != 'abc123def456') {
      errors.add('Manifest contentSha256 mismatch');
    }
    if (manifest.ownership.creatorId != 'user-001') {
      errors.add('Manifest ownership creatorId mismatch');
    }
    if (manifest.ownership.copyrightHolder != 'Choirudin') {
      errors.add('Manifest ownership copyrightHolder mismatch');
    }
    if (manifest.manifestSha256.isEmpty) {
      errors.add('Manifest SHA-256 should not be empty');
    }

    // Deterministic: same inputs → same manifestSha256
    final manifest2 = ExportOwnershipManifest.create(
      assetId: 'novel-001',
      assetKind: ProtectedAssetKind.novel,
      exportUse: ExportUse.privateMaster,
      exportRevision: '1.0.0',
      contentSha256: 'abc123def456',
      watermarkApplied: false,
      watermarkMode: WatermarkMode.off,
      recipientToken: null,
      ownership: ownership,
    );
    if (manifest.manifestSha256 != manifest2.manifestSha256) {
      errors.add('Ownership manifest not deterministic');
    }

    // JSON round-trip
    final json = manifest.toJson();
    if (json['assetId'] != 'novel-001') {
      errors.add('JSON serialization assetId mismatch');
    }
    if (json['exportUse'] != 'privateMaster') {
      errors.add('JSON serialization exportUse mismatch');
    }
    if (json['watermarkApplied'] != false) {
      errors.add('JSON serialization watermarkApplied mismatch');
    }

    // Watermark: preview use → applied
    final previewRequest = ExportProtectionRequest.validated(
      assetId: 'novel-002',
      kind: ProtectedAssetKind.novel,
      use: ExportUse.publicPreview,
      tier: SubscriptionTier.pro,
      generatedByApp: false,
      contentBytes: [1, 2, 3, 4],
      ownership: ownership,
      exportRevision: '1.0.0',
    );
    final previewPolicy = WatermarkPolicy.validated(
      mode: WatermarkMode.previewOnly,
      style: WatermarkStyle.validated(
        text: 'Preview',
        position: WatermarkPosition.bottomRight,
        opacity: 0.3,
        scalePercent: 50,
      ),
    );
    final previewDecision = planner.plan(previewRequest, previewPolicy);
    if (!previewDecision.applyWatermark) {
      errors.add(
        'Preview export should apply watermark under previewOnly policy',
      );
    }
    if (previewDecision.overlay == null) {
      errors.add('Preview overlay should not be null');
    }

    // Watermark: private master → not applied
    final privateRequest = ExportProtectionRequest.validated(
      assetId: 'novel-003',
      kind: ProtectedAssetKind.novel,
      use: ExportUse.privateMaster,
      tier: SubscriptionTier.pro,
      generatedByApp: false,
      contentBytes: [5, 6, 7, 8],
      ownership: ownership,
      exportRevision: '1.0.0',
    );
    final privateDecision = planner.plan(privateRequest, previewPolicy);
    if (privateDecision.applyWatermark) {
      errors.add('Private master should never have watermark');
    }
    if (privateDecision.overlay != null) {
      errors.add('Private master overlay should be null');
    }

    // Watermark: purchased original → not applied
    final purchaseRequest = ExportProtectionRequest.validated(
      assetId: 'novel-004',
      kind: ProtectedAssetKind.novel,
      use: ExportUse.purchasedOriginal,
      tier: SubscriptionTier.free,
      generatedByApp: false,
      contentBytes: [9, 10],
      ownership: ownership,
      exportRevision: '1.0.0',
    );
    final purchaseDecision = planner.plan(purchaseRequest, previewPolicy);
    if (purchaseDecision.applyWatermark) {
      errors.add('Purchased original should never have watermark');
    }

    // Watermark: always mode → applies even for publishedRelease
    final alwaysPolicy = WatermarkPolicy.validated(
      mode: WatermarkMode.always,
      style: WatermarkStyle.validated(
        text: 'Always',
        position: WatermarkPosition.center,
        opacity: 0.5,
        scalePercent: 30,
      ),
    );
    final publishedRequest = ExportProtectionRequest.validated(
      assetId: 'novel-005',
      kind: ProtectedAssetKind.novel,
      use: ExportUse.publishedRelease,
      tier: SubscriptionTier.pro,
      generatedByApp: false,
      contentBytes: [11, 12],
      ownership: ownership,
      exportRevision: '1.0.0',
    );
    final alwaysDecision = planner.plan(publishedRequest, alwaysPolicy);
    if (!alwaysDecision.applyWatermark) {
      errors.add('Always policy should apply watermark for publishedRelease');
    }

    // Personalized watermark
    final personalizedPolicy = WatermarkPolicy.validated(
      mode: WatermarkMode.always,
      style: WatermarkStyle.validated(
        text: 'Review',
        position: WatermarkPosition.topCenter,
        opacity: 0.4,
        scalePercent: 20,
      ),
      personalizeForRecipient: true,
    );
    final betaRequest = ExportProtectionRequest.validated(
      assetId: 'novel-006',
      kind: ProtectedAssetKind.novel,
      use: ExportUse.betaReview,
      tier: SubscriptionTier.pro,
      generatedByApp: false,
      contentBytes: [13, 14],
      ownership: ownership,
      exportRevision: '1.0.0',
      recipientId: 'reviewer-alpha',
    );
    final personalizedDecision = planner.plan(betaRequest, personalizedPolicy);
    if (!personalizedDecision.applyWatermark) {
      errors.add('Personalized beta review should apply watermark');
    }
    if (personalizedDecision.overlay?.recipientToken == null) {
      errors.add('Personalized overlay should have recipient token');
    }

    // No recipient for personalized → throw
    final orphanRequest = ExportProtectionRequest.validated(
      assetId: 'novel-007',
      kind: ProtectedAssetKind.novel,
      use: ExportUse.betaReview,
      tier: SubscriptionTier.pro,
      generatedByApp: false,
      contentBytes: [15, 16],
      ownership: ownership,
      exportRevision: '1.0.0',
      // no recipientId
    );
    try {
      planner.plan(orphanRequest, personalizedPolicy);
      errors.add('Missing recipient with personalized policy should throw');
    } on ArgumentError {
      // expected
    }

    return MetadataValidationResult(
      manifestDeterministic:
          manifest.manifestSha256 == manifest2.manifestSha256,
      watermarkAppliedForPreview: previewDecision.applyWatermark,
      watermarkSkippedForPrivate: !privateDecision.applyWatermark,
      ownershipFieldsPresent:
          manifest.ownership.creatorId.isNotEmpty &&
          manifest.ownership.copyrightHolder.isNotEmpty &&
          manifest.ownership.rightsStatement.isNotEmpty,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // Aggregate: all six acceptance criteria
  // ---------------------------------------------------------------------------

  Map<String, bool> runAll() {
    final profiles = validateProfiles();
    final preflight = validatePreflight();
    final render = validateFormatRender();
    final clean = validateCleanExport();
    final metadata = validateMetadata();

    return <String, bool>{
      'profile_preset_round_trip': profiles.allValid,
      'preflight_blocks_empty_and_missing': preflight.allValid,
      'clean_export_removes_internal_markers': clean.allValid,
      'format_render_preserves_chapter_structure': render.allValid,
      'ownership_manifest_deterministic': metadata.allValid,
      'watermark_policy_applies_by_use_case':
          metadata.watermarkAppliedForPreview,
    };
  }
}
