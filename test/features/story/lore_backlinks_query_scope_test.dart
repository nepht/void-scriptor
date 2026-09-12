import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/bible/application/lore_backlink_service.dart';

/// vs-hunt-20260913-bible BUG-1 (Medium): LoreBacklinkService.collectSources
/// selected the ENTIRE sceneBeats table with no scene filter, so every
/// integrity scan backlinked by `titles.containsKey` after reading all rows
/// (and a foreign beat whose sceneId collided with a local scene would leak
/// into results). The query must be bounded to the project's own scene ids,
/// mirroring retargetOccurrences.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late String dbPath;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('bible-bug1-scope-');
    dbPath = '${root.path}${Platform.pathSeparator}project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final plain = await service.open(dbPath);
    addTearDown(plain.close);

    await plain
        .into(plain.stories)
        .insert(
          StoriesCompanion.insert(
            assetId: 'story-1',
            projectId: 'project-1',
            title: 'Saga Api',
          ),
        );
    await plain
        .into(plain.storyScenes)
        .insert(
          StoryScenesCompanion.insert(
            id: 'scene-1',
            storyId: 'story-1',
            chapterId: 'ch-1',
            title: 'Pembukaan',
            sceneNumber: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await plain
        .into(plain.sceneBeats)
        .insert(
          SceneBeatsCompanion.insert(
            id: 'beat-local',
            sceneId: 'scene-1',
            content: '[[Api]] menyala.',
          ),
        );

    // Foreign project data in the same database: its beat must never be
    // scanned, and its content marker lets the interceptor prove it was not
    // read into Dart (see WHERE-bounded assertion below).
    await plain
        .into(plain.stories)
        .insert(
          StoriesCompanion.insert(
            assetId: 'story-2',
            projectId: 'project-2',
            title: 'Lain',
          ),
        );
    await plain
        .into(plain.storyScenes)
        .insert(
          StoryScenesCompanion.insert(
            id: 'scene-foreign',
            storyId: 'story-2',
            chapterId: 'ch-9',
            title: 'Asing',
            sceneNumber: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await plain
        .into(plain.sceneBeats)
        .insert(
          SceneBeatsCompanion.insert(
            id: 'beat-foreign',
            sceneId: 'scene-foreign',
            content: '[[Api]] asing yang tak boleh ikut terbaca penuh.',
          ),
        );
  });

  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      root.deleteSync(recursive: true);
    } on FileSystemException {
      // sqlite handle still draining; disposable temp dir, safe to leave.
    }
  });

  test(
    'BUG-1: collectSources bounds the sceneBeats SELECT with a WHERE filter',
    () async {
      final counts = _SceneBeatsStatementRecorder();
      final database = ProjectDatabase(
        NativeDatabase(File(dbPath)).interceptWith(counts),
      );
      await database.initialize();
      addTearDown(database.close);

      const service = LoreBacklinkService();
      final sources = await service.collectSources(database, 'project-1');

      // Behavior pin: local scene still resolved, foreign scene absent.
      expect(sources.keys, ['scene-1']);
      expect(sources['scene-1']!.targets, ['Api']);

      expect(
        counts.unboundedSceneBeatsSelects,
        0,
        reason:
            'BUG-1: collectSources must not SELECT the whole scene_beats '
            'table; scope the query to the project scene ids like '
            'retargetOccurrences does.',
      );
      expect(
        counts.boundedSceneBeatsSelects,
        greaterThan(0),
        reason:
            'collectSources must read beats through a WHERE-bounded '
            'scene_id query.',
      );
      expect(
        counts.sawForeignSceneIdInArgs,
        isFalse,
        reason:
            'The bounded query must carry only project-1 scene ids as '
            'parameters.',
      );
    },
  );
}

class _SceneBeatsStatementRecorder extends QueryInterceptor {
  int unboundedSceneBeatsSelects = 0;
  int boundedSceneBeatsSelects = 0;
  bool sawForeignSceneIdInArgs = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('"scene_beats"') &&
        statement.trimLeft().toUpperCase().startsWith('SELECT')) {
      if (statement.contains('WHERE')) {
        boundedSceneBeatsSelects++;
        if (args.contains('scene-foreign')) {
          sawForeignSceneIdInArgs = true;
        }
      } else {
        unboundedSceneBeatsSelects++;
      }
    }
    return super.runSelect(executor, statement, args);
  }
}
