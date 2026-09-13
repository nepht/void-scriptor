import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/project/project_database.dart';
import '../domain/story_model.dart';
import '../domain/draft_snapshots.dart';
import '../../character/domain/character_quick_ref.dart';

class StoryHierarchy {
  const StoryHierarchy({
    required this.story,
    required this.arcs,
    required this.chapters,
    required this.scenes,
  });
  final StoryModel story;
  final List<StoryArcNode> arcs;
  final List<StoryChapterNode> chapters;
  final List<StorySceneNode> scenes;
}

class StoryArcNode {
  const StoryArcNode(this.id, this.title, this.chapters);
  final String id;
  final String title;
  final List<StoryChapterNode> chapters;
}

class StoryChapterNode {
  const StoryChapterNode(this.id, this.title, this.scenes);
  final String id;
  final String title;
  final List<StorySceneNode> scenes;
}

class StorySceneNode {
  const StorySceneNode(
    this.id,
    this.title,
    this.characters,
    this.environment,
    this.beats,
  );
  final String id;
  final String title;
  final List<SceneCharacter> characters;
  final SceneEnvironmentContext? environment;
  final List<SceneBeat> beats;
}

class NovelSearchResult {
  const NovelSearchResult({
    required this.sceneId,
    required this.sceneTitle,
    required this.chapterTitle,
    required this.matchCount,
  });
  final String sceneId;
  final String sceneTitle;
  final String chapterTitle;
  final int matchCount;
}

class StoryRepositoryImpl {
  StoryRepositoryImpl({required this.database, required this.projectId});
  final ProjectDatabase database;
  final String projectId;

  /// vs-hunt-20260912-autosave BUG-8 (Medium): dulu select-then-insert
  /// tanpa transaction — dua penulis paralel sama-sama melihat null lalu
  /// yang kedua kena SqliteException PK-collision ('<scene>_draft').
  /// Upsert atomik menutup window TOCTOU (id deterministik per scene).
  Future<void> saveSceneDraft(String sceneId, String content) async {
    await database
        .into(database.sceneBeats)
        .insertOnConflictUpdate(
          SceneBeatsCompanion.insert(
            id: '${sceneId}_draft',
            sceneId: sceneId,
            beatType: const Value('draft'),
            content: content,
          ),
        );
  }

  Future<String?> getSceneDraft(String sceneId) async {
    final draft =
        await (database.select(database.sceneBeats)..where(
              (row) =>
                  row.sceneId.equals(sceneId) & row.beatType.equals('draft'),
            ))
            .getSingleOrNull();
    return draft?.content;
  }

  /// Retention limit per scene; cache dari project_metadata agar batas
  /// tidak hilang saat resolver me-rebuild repository (bug-hunt-20260912
  /// BUG-10 Medium). Nilai ditulis durable via insertSceneDraftSnapshot.
  final Map<String, int> _retentionCache = <String, int>{};

  Future<int?> _retentionLimitFor(String sceneId) async {
    if (_retentionCache.containsKey(sceneId)) {
      return _retentionCache[sceneId];
    }
    final key = 'draft_retention:$sceneId';
    final row = await (database.select(
      database.projectMetadata,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    final limit = int.tryParse(row?.value ?? '');
    if (limit != null && limit > 0) _retentionCache[sceneId] = limit;
    return limit;
  }

  Future<void> _persistRetentionLimit(String sceneId, int limit) async {
    _retentionCache[sceneId] = limit;
    await database
        .into(database.projectMetadata)
        .insertOnConflictUpdate(
          ProjectMetadataCompanion.insert(
            key: 'draft_retention:$sceneId',
            value: limit.toString(),
          ),
        );
  }

  Future<StorySceneNode?> getScene(String sceneId) async {
    final scene = await database.storyDao.getScene(sceneId);
    if (scene == null) return null;
    return StorySceneNode(
      scene.id,
      scene.title,
      await database.storyDao.getSceneCharacters(scene.id),
      await database.storyDao.getSceneEnvironment(scene.id),
      await database.storyDao.getSceneBeats(scene.id),
    );
  }

  /// Judul cerita untuk heading workspace (input 145.43). Query ringan
  /// terpisah dari hierarchy penuh; null saat story tidak ditemukan.
  Future<String?> getStoryTitle(String storyId) async {
    final story = await database.storyDao.getStory(storyId);
    if (story == null || story.projectId != projectId) {
      return null;
    }
    return story.title;
  }

  Future<StoryHierarchy> getStoryHierarchy(String storyId) async {
    final story = await database.storyDao.getStory(storyId);
    if (story == null || story.projectId != projectId) {
      throw StateError('Story not found');
    }
    final arcs = await database.storyDao.getArcs(storyId);
    final chapters = await database.storyDao.getChapters(storyId);
    final scenes = await database.storyDao.getScenes(storyId);
    final sceneNodes = <StorySceneNode>[];
    for (final scene in scenes) {
      sceneNodes.add(
        StorySceneNode(
          scene.id,
          scene.title,
          await database.storyDao.getSceneCharacters(scene.id),
          await database.storyDao.getSceneEnvironment(scene.id),
          await database.storyDao.getSceneBeats(scene.id),
        ),
      );
    }
    // bug-hunt-run128 BUG-14: lookup Map menggantikan nested linear scan
    // O(C*S^2); sceneNodes dibangun 1:1 dari scenes (dan chapterNodes dari
    // chapters), sehingga kegagalan lookup tidak mungkin terjadi.
    final sceneChapterById = {
      for (final scene in scenes) scene.id: scene.chapterId,
    };
    final chapterArcById = {
      for (final chapter in chapters) chapter.id: chapter.arcId,
    };
    final chapterNodes = chapters
        .map(
          (chapter) => StoryChapterNode(
            chapter.id,
            chapter.title,
            sceneNodes
                .where((s) => sceneChapterById[s.id] == chapter.id)
                .toList(),
          ),
        )
        .toList();
    final arcNodes = arcs
        .map(
          (arc) => StoryArcNode(
            arc.id,
            arc.title,
            chapterNodes.where((c) => chapterArcById[c.id] == arc.id).toList(),
          ),
        )
        .toList();
    return StoryHierarchy(
      story: StoryModel(
        assetId: story.assetId,
        projectId: story.projectId,
        title: story.title,
        synopsis: story.synopsis,
        genre: story.genre,
        status: story.status,
        notes: story.notes,
      ),
      arcs: arcNodes,
      chapters: chapterNodes,
      scenes: sceneNodes,
    );
  }

  /// Pencarian novel lintas scene untuk langkah 145.24: mencocokkan query
  /// (case-insensitive, di-trim) terhadap judul scene, judul bab, dan isi
  /// draft/beat scene. Hasil unik per scene, tersegmen per chapter, terurut
  /// mengikuti chapter lalu scene (sortOrder). Query kosong tidak mencari.
  Future<List<NovelSearchResult>> searchNovel(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const <NovelSearchResult>[];

    final storyIds = await (database.select(
      database.stories,
    )..where((t) => t.projectId.equals(projectId))).get();
    if (storyIds.isEmpty) return const <NovelSearchResult>[];

    final matches = <String, NovelSearchResult>{};
    for (final story in storyIds) {
      final chapters = await database.storyDao.getChapters(story.assetId);
      for (final chapter in chapters) {
        final scenes = await database.storyDao.getScenesByChapter(chapter.id);
        // BUG-15 (bug-hunt-run128): judul bab adalah string satu chapter,
        // bukan per scene — hit judul bab dihitung sekali dan ditambahkan
        // ke baris scene pertama agar matchCount tidak menggelembung
        // sebanyak jumlah scene.
        final chapterTitleCount = chapter.title.toLowerCase().contains(needle)
            ? 1
            : 0;
        var isFirstScene = true;
        for (final scene in scenes) {
          var count = 0;
          if (scene.title.toLowerCase().contains(needle)) count++;
          if (isFirstScene) count += chapterTitleCount;
          final beats = await database.storyDao.getSceneBeats(scene.id);
          for (final beat in beats) {
            if (beat.content.toLowerCase().contains(needle)) count++;
          }
          if (count > 0) {
            final existing = matches[scene.id];
            matches[scene.id] = NovelSearchResult(
              sceneId: scene.id,
              sceneTitle: scene.title,
              chapterTitle: chapter.title,
              matchCount: existing == null
                  ? count
                  : existing.matchCount + count,
            );
          }
          isFirstScene = false;
        }
      }
    }
    return matches.values.toList(growable: false);
  }

  /// Quick reference karakter pada suatu adegan (Step 145.25): fakta
  /// profil canon dari Characters + notes identitas + role keanggotaan
  /// scene, dirangkai jadi kartu ringkas per karakter.
  Future<List<CharacterQuickRef>> quickReferenceForScene(String sceneId) async {
    final members = await database.storyDao.getSceneCharacters(sceneId);
    final result = <CharacterQuickRef>[];
    for (final member in members) {
      final character = await database.characterDao.getCharacter(
        member.characterId,
      );
      if (character == null) continue;
      final identity = await database.characterDao.getIdentity(
        character.assetId,
      );
      final rows = <String>[
        character.biography,
        character.personality,
        if (character.gender.isNotEmpty) 'Gender: ${character.gender}',
        if (character.age != null) 'Age: ${character.age}',
        if (character.heightCm != null) 'Height: ${character.heightCm} cm',
        'Hair: ${character.hair}',
        'Eyes: ${character.eyes}',
        'Skin: ${character.skin}',
        if (character.voice.isNotEmpty) 'Voice: ${character.voice}',
        if (identity != null && identity.notes.trim().isNotEmpty)
          identity.notes.trim(),
      ].where((row) => row.trim().isNotEmpty).toList(growable: false);
      result.add(
        CharacterQuickRef(
          characterId: character.assetId,
          name: character.displayName,
          alias: character.alias.isEmpty ? null : character.alias,
          compactDescription: rows.join('\n'),
          role: member.role,
        ),
      );
    }
    return result;
  }

  /// Snapshot persistence draft (Step 145.24) — kontrak DraftSnapshotStore.
  Future<String> captureSceneDraftSnapshot(
    String sceneId, {
    required String label,
    DraftSnapshotKind kind = DraftSnapshotKind.manual,
  }) async {
    final draft = await getSceneDraft(sceneId);
    if (draft == null) {
      throw StateError('no draft content for scene $sceneId');
    }
    final id = const Uuid().v4();
    final dbKind = kind.name;
    await database.storyDao.insertSceneDraftSnapshot(
      SceneDraftSnapshotsCompanion.insert(
        id: id,
        sceneId: sceneId,
        projectId: projectId,
        kind: dbKind,
        content: draft,
        label: label,
        createdAt: DateTime.now(),
      ),
    );
    await _enforceRetention(sceneId);
    return id;
  }

  Future<void> _enforceRetention(String sceneId) async {
    final limit = await _retentionLimitFor(sceneId);
    if (limit == null || limit <= 0) return;
    final all = await database.storyDao.getSceneDraftSnapshots(sceneId);
    if (all.length <= limit) return;
    // Prune target = non-backup tertua dulu (restoreBackup adalah satu-
    // satunya salinan teks pra-restore — no-silent-loss menang atas batas
    // jumlah; pola sama dengan arah fix BUG-11 referee). Tie-breaker
    // rowid (BUG-9): createdAt identik saat clock mundur tak lagi
    // menentukan siapa yang dipangkas.
    var excess = all.length - limit;
    final toDelete = <String>[];
    for (final s in all) {
      if (excess <= 0) break;
      if (s.kind == 'restoreBackup') continue;
      toDelete.add(s.id);
      excess--;
    }
    if (toDelete.isEmpty) return;
    await database.storyDao.deleteSceneDraftSnapshotByIds(toDelete);
  }

  Future<List<SceneDraftSnapshot>> getSceneDraftSnapshots(
    String sceneId, {
    String? snapshotId,
    DraftSnapshotKind? kind,
  }) async {
    final all = await database.storyDao.getSceneDraftSnapshots(sceneId);
    var result = all;
    if (snapshotId != null) {
      result = result.where((s) => s.id == snapshotId).toList();
    }
    if (kind != null) {
      result = result.where((s) => _kindFromDb(s.kind) == kind).toList();
    }
    return result;
  }

  /// vs-hunt-20260912-autosave BUG-20 (Low): kind tak dikenal TIDAK lagi
  /// dilapaskan diam-diam ke restoreBackup (menyembunyikan korupsi/migration
  /// typo dan salah melindungi baris dari prune). Null = tidak kompatibel
  /// dengan filter enum apa pun; tampilan tetap memakai string DB mentah.
  DraftSnapshotKind? _kindFromDb(String dbKind) {
    switch (dbKind) {
      case 'auto':
        return DraftSnapshotKind.auto;
      case 'manual':
        return DraftSnapshotKind.manual;
      case 'restoreBackup':
        return DraftSnapshotKind.restoreBackup;
      default:
        return null;
    }
  }

  Future<String> restoreSceneDraftSnapshot(
    String sceneId, {
    required String snapshotId,
  }) async {
    final snapshots = await database.storyDao.getSceneDraftSnapshots(sceneId);
    if (!snapshots.any((s) => s.id == snapshotId)) {
      throw StateError(
        'snapshot $snapshotId tidak ditemukan di scene $sceneId '
        '(mungkin sudah dipangkas retensi)',
      );
    }
    final target = snapshots.firstWhere((s) => s.id == snapshotId);
    final current = await getSceneDraft(sceneId);
    if (current != null) {
      // backup current draft before restore
      await database.storyDao.insertSceneDraftSnapshot(
        SceneDraftSnapshotsCompanion.insert(
          id: const Uuid().v4(),
          sceneId: sceneId,
          projectId: projectId,
          kind: 'restoreBackup',
          content: current,
          label: 'cadangan sebelum pulih',
          createdAt: DateTime.now(),
        ),
      );
    }
    await saveSceneDraft(sceneId, target.content);
    return target.content;
  }

  /// Menetapkan batas retensi snapshot untuk satu scene dan memangkas
  /// pelanggaran yang sudah ada. Batas diterapkan juga pada capture berikutnya.
  Future<void> setDraftSnapshotRetention(
    String sceneId, {
    required int maxSnapshots,
  }) async {
    if (maxSnapshots <= 0) {
      throw ArgumentError('maxSnapshots must be positive');
    }
    // vs-hunt-20260912-autosave BUG-10 (Medium): batas disimpan durable di
    // project_metadata (bukan map per-instance) — resolver me-rebuild
    // repository tiap build; setelah restart/prune berikutnya limit masih
    // berlaku.
    await _persistRetentionLimit(sceneId, maxSnapshots);
    await _enforceRetention(sceneId);
  }
}
