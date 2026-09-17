import 'dart:convert';

import 'package:void_scriptor/features/spoiler/domain/reader_redaction.dart';

/// Output profiles supported by the safe sharing boundary.
enum ExportFormat { plainText, encyclopediaJson }

/// A manuscript or encyclopedia section before clearance is applied.
class ExportSection {
  const ExportSection({
    required this.id,
    required this.title,
    required this.text,
    this.spoilerItemId,
    this.privateNote = false,
    this.links = const <InternalLink>[],
  });

  final String id;
  final String title;
  final String text;
  final String? spoilerItemId;
  final bool privateNote;
  final List<InternalLink> links;
}

/// Input to a deterministic, reader-scoped export.
class SpoilerSafeExportRequest {
  const SpoilerSafeExportRequest({
    required this.documentId,
    required this.title,
    required this.readerId,
    required this.currentScene,
    required this.format,
    required this.sections,
    this.metadata = const <String, String>{},
  });

  final String documentId;
  final String title;
  final String readerId;
  final String currentScene;
  final ExportFormat format;
  final List<ExportSection> sections;
  final Map<String, String> metadata;
}

class SpoilerSafePreflightReport {
  const SpoilerSafePreflightReport(this.issues);

  final List<String> issues;
  bool get isReady => issues.isEmpty;
}

class SpoilerSafeExportResult {
  const SpoilerSafeExportResult({required this.content, required this.format});

  final String content;
  final ExportFormat format;
}

/// Composes the existing reader redaction contract with clean export formats.
/// Metadata and private notes remain editor-only and never enter output.
class SpoilerSafeExportService {
  const SpoilerSafeExportService({required this.redactor});

  final ReaderRedactor redactor;

  SpoilerSafePreflightReport preflight(SpoilerSafeExportRequest request) {
    final issues = <String>[];
    if (request.documentId.trim().isEmpty) {
      issues.add('document id is empty');
    }
    if (request.title.trim().isEmpty) {
      issues.add('title is empty');
    }
    if (request.readerId.trim().isEmpty) {
      issues.add('reader id is empty');
    }
    if (request.currentScene.trim().isEmpty) {
      issues.add('current scene is empty');
    }
    if (request.sections.isEmpty) {
      issues.add('no exportable sections');
    }
    for (final section in request.sections) {
      if (section.id.trim().isEmpty) issues.add('section id is empty');
      if (section.title.trim().isEmpty) issues.add('section title is empty');
    }
    try {
      final preview = _preview(request);
      if (preview.readerId != request.readerId) {
        issues.add('reader clearance mismatch');
      }
    } on StateError catch (error) {
      issues.add(error.message.toString());
    }
    return SpoilerSafePreflightReport(List.unmodifiable(issues));
  }

  SpoilerSafeExportResult export(SpoilerSafeExportRequest request) {
    final report = preflight(request);
    if (!report.isReady) {
      throw StateError('export preflight failed: ${report.issues.join('; ')}');
    }
    final preview = _preview(request);
    final content = switch (request.format) {
      ExportFormat.plainText => _plainText(preview),
      ExportFormat.encyclopediaJson => _encyclopediaJson(preview),
    };
    return SpoilerSafeExportResult(content: content, format: request.format);
  }

  ReaderPreview _preview(SpoilerSafeExportRequest request) {
    final blocks = <ReaderBlock>[];
    for (final section in request.sections) {
      if (!section.privateNote) {
        blocks.add(
          ReaderBlock(
            id: section.id,
            text: section.text,
            spoilerItemId: section.spoilerItemId,
            links: section.links,
          ),
        );
      }
    }
    return redactor.previewAsReader(
      doc: ReaderDocument(
        id: request.documentId,
        title: request.title,
        blocks: blocks,
        metadata: request.metadata,
      ),
      readerId: request.readerId,
      currentScene: request.currentScene,
    );
  }

  String _plainText(ReaderPreview preview) {
    final buffer = StringBuffer(preview.title);
    for (final block in preview.blocks) {
      buffer
        ..writeln('\n')
        ..writeln(block.text);
      if (block.links.isNotEmpty) {
        buffer.writeln(
          'Links: ${block.links.map((link) => link.label).join(', ')}',
        );
      }
    }
    return buffer.toString();
  }

  String _encyclopediaJson(ReaderPreview preview) =>
      jsonEncode(<String, Object?>{
        'documentId': preview.documentId,
        'title': preview.title,
        'entries': [
          for (final block in preview.blocks)
            <String, Object?>{
              'id': block.id,
              'text': block.text,
              if (block.links.isNotEmpty)
                'links': [for (final link in block.links) link.label],
            },
        ],
      });
}
