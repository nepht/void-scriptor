import 'dart:io';

import 'package:path/path.dart' as p;

import '../../export/domain/export_profiles.dart';
import '../data/story_repository_impl.dart';

class StoryMarkdownExporter {
  const StoryMarkdownExporter();

  Future<String> exportStory(
    StoryRepositoryImpl repository,
    String storyId, {
    ExportProfile? profile,
  }) async {
    final hierarchy = await repository.getStoryHierarchy(storyId);
    final fm = profile?.frontMatter;
    final buffer = StringBuffer();
    if (fm != null) {
      buffer.writeln('# ${fm.title}');
      buffer.writeln(fm.author);
      buffer.writeln();
    } else {
      buffer.writeln('# ${hierarchy.story.title}');
      buffer.writeln();
    }
    if (hierarchy.story.synopsis.isNotEmpty) {
      buffer.writeln(hierarchy.story.synopsis);
      buffer.writeln();
    }
    final chapterRules = profile?.chapterRules;
    for (final (chapterIndex, chapter) in hierarchy.chapters.indexed) {
      final displayTitle = chapterRules == null
          ? chapter.title
          : chapterRules.title(chapterIndex + chapterRules.numberingStart);
      buffer.writeln('## $displayTitle');
      buffer.writeln();
      for (final scene in chapter.scenes) {
        buffer.writeln('### ${scene.title}');
        buffer.writeln();
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
    String fileName = 'story.md',
    ExportProfile? profile,
  }) async {
    final safeName = p.basename(fileName);
    if (safeName != fileName || !safeName.endsWith('.md')) {
      throw ArgumentError.value(
        fileName,
        'fileName',
        'must be a Markdown filename',
      );
    }
    await exportDirectory.create(recursive: true);
    final file = File(p.join(exportDirectory.path, safeName));
    await file.writeAsString(
      await exportStory(repository, storyId, profile: profile),
    );
    return file;
  }
}

class StoryMarkdownDocument {
  const StoryMarkdownDocument({required this.title, required this.body});
  final String title;
  final String body;

  String get markdown => '# $title\n\n$body';
}
