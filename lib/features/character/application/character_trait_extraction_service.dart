import '../../../database/project/project_database.dart';
import '../../story/data/story_repository_impl.dart';
import 'character_trait_extractor.dart';

/// One selectable novel (story asset) for the extraction picker.
class NovelOption {
  const NovelOption({required this.storyId, required this.title});
  final String storyId;
  final String title;
}

/// Loads the manuscript excerpt and runs the cited-trait extraction.
///
/// Hard consent gate by design: nothing is sent to any provider until the UI
/// calls [extractProposals] after an explicit user tap, and the result is a
/// proposal set (never an overwrite) that the user ticks field by field.
abstract final class CharacterTraitExtractionService {
  /// Novels (stories) registered in the active project.
  static Future<List<NovelOption>> listNovels(
    ProjectDatabase database,
    String projectId,
  ) async {
    final rows = await (database.select(
      database.stories,
    )..where((t) => t.projectId.equals(projectId))).get();
    return [
      for (final row in rows)
        NovelOption(storyId: row.assetId, title: row.title),
    ];
  }

  /// Builds a chapter-annotated manuscript excerpt for [characterName].
  ///
  /// Only chapters whose text mentions the character are included, which
  /// keeps the payload minimal: the excerpt stops at [maxChars]. Returns an
  /// empty string when the character appears in no scene draft.
  static Future<String> buildManuscript(
    ProjectDatabase database, {
    required String projectId,
    required String storyId,
    required String characterName,
    int maxChars = 24000,
  }) async {
    final repository = StoryRepositoryImpl(
      database: database,
      projectId: projectId,
    );
    final hierarchy = await repository.getStoryHierarchy(storyId);
    final needle = characterName.toLowerCase();
    final buffer = StringBuffer();
    for (final (chapterIndex, chapter) in hierarchy.chapters.indexed) {
      final sceneTexts = <String>[];
      for (final scene in chapter.scenes) {
        final draft = await repository.getSceneDraft(scene.id);
        if (draft != null && draft.trim().isNotEmpty) {
          sceneTexts.add(draft.trim());
        }
      }
      if (sceneTexts.isEmpty) continue;
      final chapterText = sceneTexts.join('\n\n');
      if (!chapterText.toLowerCase().contains(needle)) continue;
      // Nomor bab eksplisit di header: prompt meminta sitasi "chapter":N dan
      // angka ini yang harus dipakai model supaya kutipan dapat diverifikasi.
      buffer.writeln('== Chapter ${chapterIndex + 1}: ${chapter.title} ==');
      buffer.writeln(chapterText);
      buffer.writeln();
      if (buffer.length >= maxChars) break;
    }
    final excerpt = buffer.toString().trim();
    return excerpt.length > maxChars
        ? '${excerpt.substring(0, maxChars)}\n[...]'
        : excerpt;
  }

  /// One-shot extraction: builds the strict-JSON prompt, sends it through the
  /// runtime's direct text call, and parses the reply into proposals.
  ///
  /// Throws when the provider errors or the reply violates the citation
  /// contract; callers must surface the failure instead of retrying silently.
  static Future<TraitProposalResult> extractProposals({
    required Future<String> Function(String prompt) generate,
    required String characterName,
    required String manuscript,
  }) async {
    final prompt = CharacterTraitExtractor.buildExtractionPrompt(
      characterName: characterName,
      manuscript: manuscript,
    );
    final raw = await generate(prompt);
    return CharacterTraitExtractor.parseProposals(raw);
  }
}
