/// Struktur satu hunk export: judul heading, opsional children (level
/// berikutnya), dan opsional baris konten (untuk hunk daun berisi draft).
class FidelityHunk {
  const FidelityHunk({required this.title, this.children, this.lines});
  final String title;
  final List<FidelityHunk>? children;
  final List<String>? lines;
}

/// Hasil verifikasi fidelity satu format export.
class FidelityReport {
  const FidelityReport({required this.failures});
  final List<String> failures;
  bool get ok => failures.isEmpty;
}

/// Matriks fidelity export 145.24: memverifikasi output Markdown dan DOCX
/// terhadap struktur hunk novel yang diharapkan.
///
/// Validator meniru pola eksak exporter (bukan regex longgar):
///   markdown: '# title', blank, [synopsis, blank], lalu per bab
///             '## title', blank, per scene '### title', blank,
///             baris draft (blank internal dipertahankan), blank;
///             trailing blank dihilangkan (trimRight exporter).
///   docx:     paragraf berurut Title/synopsis/Heading1/Heading2/Normal
///             dengan teks yang sudah di-unescape dari XML.
///
/// Prasyarat yang diperiksa (no-break 145.24):
///   1. judul story muncul sekali, di posisi pertama;
///   2. hunk terstruktur [chapter -> [scene -> [draft-line]]];
///   3. urutan mengikuti ordering yang diberikan pemanggil (dari database);
///   4. tidak ada kehilangan konten (setiap baris draft hadir utuh).
class StoryExportFidelity {
  const StoryExportFidelity();

  FidelityReport markdownReport(
    String markdown, {
    required String expectTitle,
    String? expectSynopsis,
    required List<FidelityHunk> expectHunks,
  }) {
    final failures = <String>[];
    final lines = markdown.split('\n');
    final expected = _buildMarkdownLines(
      expectTitle,
      expectSynopsis,
      expectHunks,
    );

    final titleCount = expectTitle.allMatches(markdown).length;
    if (titleCount != 1) {
      failures.add('judul story muncul $titleCount kali (harus tepat 1)');
    }
    if (lines.length != expected.length) {
      failures.add(
        'markdown: jumlah baris ${lines.length} != harapan ${expected.length}',
      );
    }
    for (var i = 0; i < expected.length && i < lines.length; i++) {
      if (lines[i] != expected[i]) {
        failures.add(
          'markdown: baris ${i + 1} = "${lines[i]}" != "${expected[i]}"',
        );
      }
    }
    return FidelityReport(failures: failures);
  }

  List<String> _buildMarkdownLines(
    String title,
    String? synopsis,
    List<FidelityHunk> hunks,
  ) {
    final out = <String>['# $title', ''];
    if (synopsis != null && synopsis.isNotEmpty) {
      out.add(synopsis);
      out.add('');
    }
    for (final chapter in hunks) {
      out.add('## ${chapter.title}');
      out.add('');
      final scenes = chapter.children ?? const <FidelityHunk>[];
      for (final scene in scenes) {
        out.add('### ${scene.title}');
        out.add('');
        final lines = scene.lines;
        if (lines != null) {
          for (final line in lines) {
            out.add(line);
          }
          out.add('');
        }
      }
    }
    while (out.isNotEmpty && out.last.isEmpty) {
      out.removeLast();
    }
    return out;
  }

  FidelityReport docxReport(
    String documentXml, {
    required String expectTitle,
    String? expectSynopsis,
    required List<FidelityHunk> expectHunks,
  }) {
    final failures = <String>[];
    final paragraphs = _parseParagraphs(documentXml);

    final titleCount = expectTitle.allMatches(documentXml).length;
    if (titleCount != 1) {
      failures.add('judul story muncul $titleCount kali (harus tepat 1)');
    }

    final expected = <_DocxParagraph>[
      _DocxParagraph(style: 'Title', text: expectTitle),
      if (expectSynopsis != null)
        _DocxParagraph(style: null, text: expectSynopsis),
    ];
    void collect(List<FidelityHunk> nodes) {
      for (final node in nodes) {
        final style = node.lines == null ? 'Heading1' : 'Heading2';
        expected.add(_DocxParagraph(style: style, text: node.title));
        final lines = node.lines;
        if (lines != null) {
          for (final line in lines) {
            expected.add(_DocxParagraph(style: null, text: line));
          }
        }
        final children = node.children;
        if (children != null) collect(children);
      }
    }

    collect(expectHunks);
    for (var i = 0; i < expected.length && i < paragraphs.length; i++) {
      final want = expected[i];
      final got = paragraphs[i];
      if (got.style != want.style || got.text != want.text) {
        failures.add(
          'docx: paragraf ${i + 1} = (style: ${got.style}, '
          'text: "${got.text}") tidak sama dengan '
          '(style: ${want.style}, text: "${want.text}")',
        );
      }
    }
    if (paragraphs.length != expected.length) {
      failures.add(
        'docx: jumlah paragraf ${paragraphs.length} != '
        'harapan ${expected.length}',
      );
    }
    return FidelityReport(failures: failures);
  }

  List<_DocxParagraph> _parseParagraphs(String documentXml) {
    final result = <_DocxParagraph>[];
    final pattern = RegExp('<w:p>(.*?)</w:p>', dotAll: true);
    for (final match in pattern.allMatches(documentXml)) {
      final body = match.group(1)!;
      final styleMatch = RegExp(
        r'<w:pStyle w:val="([^"]+)"/>',
      ).firstMatch(body);
      final textMatches = RegExp(
        r'<w:t[^>]*>(.*?)</w:t>',
        dotAll: true,
      ).allMatches(body).map((m) => m.group(1)!).toList();
      result.add(
        _DocxParagraph(
          style: styleMatch?.group(1),
          text: _unescape(textMatches.join()),
        ),
      );
    }
    return result;
  }

  String _unescape(String value) => value
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");
}

class _DocxParagraph {
  const _DocxParagraph({required this.style, required this.text});
  final String? style;
  final String text;
}
