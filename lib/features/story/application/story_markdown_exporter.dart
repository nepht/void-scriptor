import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/story_repository_impl.dart';

class StoryMarkdownExporter {
  const StoryMarkdownExporter();

  Future<String> exportStory(
    StoryRepositoryImpl repository,
    String storyId,
  ) async {
    final hierarchy = await repository.getStoryHierarchy(storyId);
    final buffer = StringBuffer('# ${hierarchy.story.title}\n\n');
    if (hierarchy.story.synopsis.isNotEmpty) {
      buffer.writeln(hierarchy.story.synopsis);
      buffer.writeln();
    }
    for (final chapter in hierarchy.chapters) {
      buffer.writeln('## ${chapter.title}');
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
    await file.writeAsString(await exportStory(repository, storyId));
    return file;
  }
}

class StoryMarkdownDocument {
  const StoryMarkdownDocument({required this.title, required this.body});
  final String title;
  final String body;

  String get markdown => '# $title\n\n$body';
}
