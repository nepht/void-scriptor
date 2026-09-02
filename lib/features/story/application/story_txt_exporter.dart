import 'dart:io';

import 'package:path/path.dart' as p;

import '../../export/domain/export_profiles.dart';
import '../data/story_repository_impl.dart';

/// Plain-text manuscript writer (Sprint 145.35).
///
/// Menghasilkan naskah teks polos tanpa markup Markdown, mempertahankan
/// urutan chapter -> scene dari story hierarchy, dan memisahkan chapter
/// dengan page break ASCII. Draft ditulis verbatim setelah trim sisi
/// luar, tanpa watermark atau penanda lain.
class StoryTxtExporter {
  const StoryTxtExporter();

  Future<String> exportStory(
    StoryRepositoryImpl repository,
    String storyId, {
    ExportProfile? profile,
  }) async {
    final hierarchy = await repository.getStoryHierarchy(storyId);
    final buffer = StringBuffer();
    final fm = profile?.frontMatter;
    if (fm != null) {
      buffer.writeln(fm.title);
      buffer.writeln(fm.author);
      buffer.writeln();
    } else {
      buffer.writeln(hierarchy.story.title);
      buffer.writeln();
    }
    final chapterBreak = '=' * 40;
    var firstChapter = true;
    for (final (chapterIndex, chapter) in hierarchy.chapters.indexed) {
      if (!firstChapter) {
        buffer.writeln();
        buffer.writeln(chapterBreak);
        buffer.writeln();
      }
      firstChapter = false;
      final chapterRules = profile?.chapterRules;
      final displayTitle = chapterRules == null
          ? chapter.title
          : chapterRules.title(chapterIndex + chapterRules.numberingStart);
      buffer.writeln(displayTitle);
      buffer.writeln();
      for (final scene in chapter.scenes) {
        final draft = await repository.getSceneDraft(scene.id);
        if (draft != null && draft.trim().isNotEmpty) {
          buffer.writeln(draft.trim());
          buffer.writeln();
        }
      }
    }
    return buffer.toString().trimRight();
  }

  Future<File> writeExport(
    StoryRepositoryImpl repository,
    String storyId, {
    required Directory exportDirectory,
    String fileName = 'story.txt',
    ExportProfile? profile,
  }) async {
    final safeName = p.basename(fileName);
    if (safeName != fileName || !safeName.endsWith('.txt')) {
      throw ArgumentError.value(
        fileName,
        'fileName',
        'must be a plain text filename',
      );
    }
    await exportDirectory.create(recursive: true);
    final file = File(p.join(exportDirectory.path, safeName));
    final text = await exportStory(repository, storyId, profile: profile);
    await file.writeAsString('$text\n');
    return file;
  }
}
