import 'package:void_scriptor/features/spoiler/domain/reader_redaction.dart';
import 'package:void_scriptor/features/world_logic/domain/spoiler_safe_manuscript_knowledge_export.dart';

class BetaReaderSection {
  const BetaReaderSection({
    required this.id,
    required this.text,
    this.spoilerItemId,
  });

  final String id;
  final String text;
  final String? spoilerItemId;
}

class BetaReaderWorkflowInput {
  const BetaReaderWorkflowInput({
    required this.documentId,
    required this.title,
    required this.readerId,
    required this.audienceId,
    required this.currentScene,
    required this.sections,
    required this.comment,
    this.metadata = const <String, String>{},
  });

  final String documentId;
  final String title;
  final String readerId;
  final String audienceId;
  final String currentScene;
  final List<BetaReaderSection> sections;
  final String comment;
  final Map<String, String> metadata;
}

class BetaReaderWorkflowResult {
  const BetaReaderWorkflowResult({
    required this.audienceProfiles,
    required this.redactionResults,
    required this.shareResults,
    required this.commentResults,
    required this.revocationResults,
    required this.leakageTests,
    required this.sanitizedShare,
  });

  final List<String> audienceProfiles;
  final List<String> redactionResults;
  final String shareResults;
  final List<String> commentResults;
  final bool revocationResults;
  final bool leakageTests;
  final String sanitizedShare;

  bool get isAccepted =>
      audienceProfiles.isNotEmpty &&
      redactionResults.isNotEmpty &&
      shareResults.isNotEmpty &&
      commentResults.isNotEmpty &&
      revocationResults &&
      leakageTests &&
      sanitizedShare.isNotEmpty;
}

class EndToEndBetaReaderWorkflow {
  EndToEndBetaReaderWorkflow({required this.redactor});

  final ReaderRedactor redactor;

  BetaReaderWorkflowResult run(BetaReaderWorkflowInput input) {
    _require(input.documentId, 'documentId');
    _require(input.title, 'title');
    _require(input.readerId, 'readerId');
    _require(input.audienceId, 'audienceId');
    _require(input.currentScene, 'currentScene');
    _require(input.comment, 'comment');
    if (!redactor.hasAccess(input.readerId)) {
      throw StateError('reader has no access: ${input.readerId}');
    }
    if (input.sections.isEmpty) {
      throw ArgumentError.value(input.sections, 'sections', 'cannot be empty');
    }

    redactor.grant(readerId: input.readerId, audience: input.audienceId);
    final request = SpoilerSafeExportRequest(
      documentId: input.documentId,
      title: input.title,
      readerId: input.readerId,
      currentScene: input.currentScene,
      format: ExportFormat.encyclopediaJson,
      metadata: input.metadata,
      sections: [
        for (final section in input.sections)
          ExportSection(
            id: section.id,
            title: section.id,
            text: section.text,
            spoilerItemId: section.spoilerItemId,
          ),
      ],
    );
    final preview = redactor.previewAsReader(
      doc: ReaderDocument(
        id: input.documentId,
        title: input.title,
        metadata: input.metadata,
        blocks: [
          for (final section in input.sections)
            ReaderBlock(
              id: section.id,
              text: section.text,
              spoilerItemId: section.spoilerItemId,
            ),
        ],
      ),
      readerId: input.readerId,
      currentScene: input.currentScene,
    );
    final export = SpoilerSafeExportService(redactor: redactor).export(request);
    final sanitized = export.content;
    final leakageFree =
        !sanitized.contains(input.readerId) &&
        !input.metadata.keys.any(sanitized.contains) &&
        !sanitized.contains('metadata');

    redactor.revoke(input.readerId);
    var revoked = false;
    try {
      redactor.previewAsReader(
        doc: const ReaderDocument(id: 'revoked', title: 'revoked', blocks: []),
        readerId: input.readerId,
        currentScene: input.currentScene,
      );
    } on StateError {
      revoked = true;
    }

    return BetaReaderWorkflowResult(
      audienceProfiles: [input.audienceId],
      redactionResults: [for (final block in preview.blocks) block.text],
      shareResults: sanitized,
      commentResults: [input.comment],
      revocationResults: revoked,
      leakageTests: leakageFree,
      sanitizedShare: sanitized,
    );
  }

  static void _require(String value, String field) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, field, 'cannot be empty');
    }
  }
}
