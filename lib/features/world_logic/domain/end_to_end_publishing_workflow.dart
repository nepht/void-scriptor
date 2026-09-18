import 'package:void_scriptor/features/export/domain/clean_export.dart';

/// Deterministic, local-only tracer for Sprint 112.36 publishing acceptance.
enum PublishingFormat { docx, plainText, webNovel }

class PublishingChapter {
  const PublishingChapter({required this.title, required this.body});

  final String title;
  final String body;
}

class PublishingWorkflowInput {
  const PublishingWorkflowInput({
    required this.title,
    required this.author,
    required this.chapters,
  });

  final String title;
  final String author;
  final List<PublishingChapter> chapters;
}

class PublishingPreflight {
  const PublishingPreflight({required this.issues});

  final List<String> issues;
  bool get isAccepted => issues.isEmpty;
}

class PublishingWorkflowResult {
  const PublishingWorkflowResult({
    required this.preflight,
    required this.outputs,
  });

  final PublishingPreflight preflight;
  final Map<PublishingFormat, String> outputs;
  bool get isAccepted => preflight.isAccepted && outputs.length == 3;
}

class EndToEndPublishingWorkflow {
  const EndToEndPublishingWorkflow();

  PublishingWorkflowResult run(PublishingWorkflowInput input) {
    final issues = <String>[];
    if (input.title.trim().isEmpty) {
      issues.add('title cannot be empty');
    }
    if (input.author.trim().isEmpty) {
      issues.add('author cannot be empty');
    }
    if (input.chapters.isEmpty) {
      issues.add('at least one chapter is required');
    }
    for (final chapter in input.chapters) {
      if (chapter.title.trim().isEmpty) {
        issues.add('chapter title cannot be empty');
      }
      if (chapter.body.contains('<internal>')) {
        issues.add('internal metadata marker must not enter publishing input');
      }
    }
    if (issues.isNotEmpty) throw ArgumentError(issues.join('; '));

    const clean = CleanExportTransformer();
    final plain = StringBuffer()
      ..writeln(input.title)
      ..writeln(input.author)
      ..writeln();
    final web = StringBuffer()
      ..writeln('<article>')
      ..writeln('<h1>${_escape(input.title)}</h1>')
      ..writeln('<p class="author">${_escape(input.author)}</p>');
    final docx = StringBuffer()
      ..write('<w:document><w:body><w:p>${_xml(input.title)}</w:p>')
      ..write('<w:p>${_xml(input.author)}</w:p>');

    for (final chapter in input.chapters) {
      final body = clean.transform(chapter.body).text;
      plain
        ..writeln(chapter.title)
        ..writeln()
        ..writeln(body)
        ..writeln();
      web
        ..writeln('<section><h2>${_escape(chapter.title)}</h2>')
        ..writeln('<p>${_escape(body)}</p></section>');
      docx
        ..write('<w:p>${_xml(chapter.title)}</w:p>')
        ..write('<w:p>${_xml(body)}</w:p>');
    }
    web.write('</article>');
    docx.write('</w:body></w:document>');

    final outputs = <PublishingFormat, String>{
      PublishingFormat.docx: docx.toString(),
      PublishingFormat.plainText: plain.toString().trimRight(),
      PublishingFormat.webNovel: web.toString(),
    };
    return PublishingWorkflowResult(
      preflight: const PublishingPreflight(issues: <String>[]),
      outputs: Map.unmodifiable(outputs),
    );
  }

  String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  String _xml(String value) => _escape(value);
}
