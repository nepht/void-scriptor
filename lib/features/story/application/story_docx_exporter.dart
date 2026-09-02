import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../export/domain/export_profiles.dart';
import '../data/story_repository_impl.dart';

class StoryDocxExporter {
  const StoryDocxExporter();

  Future<File> writeExport(
    StoryRepositoryImpl repository,
    String storyId, {
    required Directory exportDirectory,
    String fileName = 'story.docx',
    ExportProfile? profile,
  }) async {
    final safeName = p.basename(fileName);
    if (safeName != fileName || !safeName.endsWith('.docx')) {
      throw ArgumentError.value(
        fileName,
        'fileName',
        'must be a DOCX filename',
      );
    }
    final hierarchy = await repository.getStoryHierarchy(storyId);
    final fm = profile?.frontMatter;
    final docTitle = fm?.title ?? hierarchy.story.title;
    final paragraphs = <String>[_paragraph(docTitle, style: 'Title')];
    if (fm != null) {
      paragraphs.add(_paragraph(fm.author));
    }
    if (hierarchy.story.synopsis.isNotEmpty) {
      paragraphs.add(_paragraph(hierarchy.story.synopsis));
    }
    final chapterRules = profile?.chapterRules;
    for (final (chapterIndex, chapter) in hierarchy.chapters.indexed) {
      final displayTitle = chapterRules == null
          ? chapter.title
          : chapterRules.title(chapterIndex + chapterRules.numberingStart);
      paragraphs.add(_paragraph(displayTitle, style: 'Heading1'));
      for (final scene in chapter.scenes) {
        paragraphs.add(_paragraph(scene.title, style: 'Heading2'));
        final draft = await repository.getSceneDraft(scene.id);
        if (draft != null && draft.trim().isNotEmpty) {
          paragraphs.addAll(
            draft.trim().split(RegExp(r'\r?\n')).map(_paragraph),
          );
        }
      }
    }
    final document = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>${paragraphs.join()}<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/></w:sectPr></w:body></w:document>''';
    final archive = Archive();
    void add(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    final creator = fm?.author ?? '';
    final coreXml = _coreProperties(title: docTitle, creator: creator);
    add('[Content_Types].xml', _contentTypes);
    add('_rels/.rels', _rootRels);
    add('docProps/core.xml', coreXml);
    add('word/_rels/document.xml.rels', _documentRels);
    add('word/document.xml', document);
    add('word/styles.xml', _styles);
    await exportDirectory.create(recursive: true);
    final output = File(p.join(exportDirectory.path, safeName));
    await output.writeAsBytes(ZipEncoder().encode(archive));
    return output;
  }

  String _coreProperties({required String title, required String creator}) {
    final creatorXml = creator.isEmpty
        ? ''
        : '<dc:creator>${_escape(creator)}</dc:creator>';
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<cp:coreProperties '
        'xmlns:cp="http://schemas.openxmlformats.org/package/2006/'
        'metadata/core-properties" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/">'
        '<dc:title>${_escape(title)}</dc:title>$creatorXml'
        '</cp:coreProperties>';
  }

  String _paragraph(String text, {String? style}) {
    final safe = _escape(text);
    final styleXml = style == null
        ? ''
        : '<w:pPr><w:pStyle w:val="$style"/></w:pPr>';
    return '<w:p>$styleXml<w:r><w:t xml:space="preserve">$safe</w:t></w:r></w:p>';
  }

  String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

const _contentTypes =
    '''<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/></Types>''';
const _rootRels =
    '''<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/></Relationships>''';
const _documentRels =
    '''<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>''';
const _styles =
    '''<?xml version="1.0" encoding="UTF-8"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style><w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/></w:style><w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/></w:style><w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/></w:style></w:styles>''';

class StoryDocxDocument {
  const StoryDocxDocument({required this.title, required this.body});
  final String title;
  final String body;
}
