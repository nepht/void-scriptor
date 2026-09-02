import 'dart:io';

import 'package:path/path.dart' as p;

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
    String storyId,
  ) async {
    final hierarchy = await repository.getStoryHierarchy(storyId);
    final buffer = StringBuffer();
    buffer.writeln(hierarchy.story.title);
    buffer.writeln();
    final chapterBreak = '=' * 40;
    var firstChapter = true;
    for (final chapter in hierarchy.chapters) {
      if (!firstChapter) {
        buffer.writeln();
        buffer.writeln(chapterBreak);
        buffer.writeln();
      }
      firstChapter = false;
      buffer.writeln(chapter.title);
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
    final text = await exportStory(repository, storyId);
    await file.writeAsString('$text\n');
    return file;
  }
}
