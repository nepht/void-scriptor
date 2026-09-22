/// Test for Data Integrity Validation (Step 113.25).
/// Validates: id_checks, link_checks, index_checks, timeline_checks,
/// alias_checks, and checksum_results by driving the real subsystems
/// (UUID identity + project manifest, AssetRelations DAO, SQLite FTS5
/// search index, timeline creation/restart, GoRouter foundation aliases,
/// HMAC integrity manifest).
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/search/search_index_service.dart';
import 'package:void_scriptor/core/security/application/integrity_manifest.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/timeline/application/create_timeline_service.dart';
import 'package:void_scriptor/features/world_logic/domain/data_integrity_validation.dart';

void main() {
  late Directory tempRoot;
  final validator = DataIntegrityValidator();

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('hermes-11325-');
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('113.25 Data Integrity Validation', () {
    // 1. Stable IDs: UUID uniqueness/format + manifest ID round-trip stability.
    test('stable ids are unique and survive a manifest round-trip', () async {
      final ids = <String>{for (var i = 0; i < 500; i++) const Uuid().v4()};
      final uuidUnique = ids.length == 500;
      final uuidFormat = ids.every(
        (id) => RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
          r'[0-9a-f]{12}$',
        ).hasMatch(id),
      );

      final package = await ProjectPackageService(
        rootDirectory: Directory('${tempRoot.path}/id-pkg'),
      ).create(name: 'ID Fixture');
      final manifestText = await package.manifestFile.readAsString();
      final decoded = jsonDecode(manifestText) as Map<String, dynamic>;
      final reencoded = jsonEncode(jsonDecode(jsonEncode(decoded)));
      final roundTripStable =
          decoded['projectId'] == package.projectId &&
          (jsonDecode(reencoded) as Map<String, dynamic>)['projectId'] ==
              package.projectId;

      final passed = uuidUnique && uuidFormat && roundTripStable;
      validator.recordCheck(
        IntegrityCheck(
          area: IntegrityArea.id,
          description: 'UUID v4 unik + ID proyek stabil di manifest',
          passed: passed,
          detail:
              'unique=$uuidUnique format=$uuidFormat roundTrip=$roundTripStable',
        ),
      );
      expect(uuidUnique, isTrue);
      expect(uuidFormat, isTrue);
      expect(roundTripStable, isTrue);
    });

    // 2. Links: relation resolves both ways; unlink never deletes the source.
    test('links resolve and unlink keeps the source asset', () async {
      final database = ProjectDatabase(NativeDatabase.memory());
      await database.initialize();
      addTearDown(database.close);

      for (final id in ['asset-a', 'asset-b']) {
        await database.assetDao.createStandaloneAsset(
          id: id,
          projectId: 'project-1',
          name: id,
          type: 'prop',
          now: DateTime(2026),
        );
      }
      await database.assetDao.addRelation(
        id: 'rel-1',
        sourceAssetId: 'asset-a',
        targetAssetId: 'asset-b',
        relationType: 'references',
      );

      final outgoing = await database.relationDao.getOutgoingRelations(
        'asset-a',
      );
      final incoming = await database.relationDao.getIncomingRelations(
        'asset-b',
      );
      final resolves =
          outgoing.length == 1 &&
          outgoing.single.targetAssetId == 'asset-b' &&
          incoming.single.sourceAssetId == 'asset-a';

      await database.relationDao.deleteRelation('rel-1');
      final unlinked = (await database.relationDao.getOutgoingRelations(
        'asset-a',
      )).isEmpty;
      final sourceSurvived =
          (await database.assetDao.getById('asset-a')) != null;

      final passed = resolves && unlinked && sourceSurvived;
      validator.recordCheck(
        IntegrityCheck(
          area: IntegrityArea.link,
          description:
              'relasi ter-resolve dua arah; unlink tidak menghapus sumber',
          passed: passed,
          detail:
              'resolves=$resolves unlinked=$unlinked sourceSurvived=$sourceSurvived',
        ),
      );
      expect(resolves, isTrue);
      expect(unlinked, isTrue);
      expect(sourceSurvived, isTrue);
    });

    // 3. Index: FTS5 upsert idempotent and remove keeps search consistent.
    test('search index upsert and remove stay consistent', () async {
      final database = ProjectDatabase(NativeDatabase.memory());
      await database.initialize();
      addTearDown(database.close);
      final index = SqliteSearchIndex(database);
      const document = SearchDocument(
        entityId: 'doc-1',
        entityType: 'story',
        title: 'Integrity Prologue',
        body: 'cross-link integrity survives restart',
      );

      await index.upsert(document);
      final firstHit = await index.search('integrity');
      await index.upsert(document);
      final afterUpsert = await index.search('integrity');
      await index.remove(document.entityId);
      final afterRemove = await index.search('integrity');

      final consistent =
          firstHit.length == 1 &&
          afterUpsert.length == 1 &&
          afterRemove.isEmpty;
      validator.recordCheck(
        IntegrityCheck(
          area: IntegrityArea.searchIndex,
          description:
              'FTS5: upsert -> search ketemu, upsert idempoten, remove bersih',
          passed: consistent,
          detail:
              'first=${firstHit.length} upsert=${afterUpsert.length} '
              'remove=${afterRemove.length}',
        ),
      );
      expect(firstHit.single.entityId, 'doc-1');
      expect(afterUpsert, hasLength(1));
      expect(afterRemove, isEmpty);
    });

    // 4. Timelines: clip points at a real beat and survives restart.
    test('timeline clip links to its beat and survives restart', () async {
      final paths = ProjectPaths(rootDirectory: tempRoot);
      final databaseService = ProjectDatabaseService();
      final dbPath = (await paths.database('project-1')).path;
      await databaseService.create(dbPath);
      final first = await databaseService.open(dbPath);
      final storyService = CreateStoryService(database: first, paths: paths);
      final storyId = await storyService.createStory(
        projectId: 'project-1',
        title: 'Integrity Arc',
      );
      final chapterId = await storyService.createChapter(
        storyId: storyId,
        title: 'Chapter One',
        chapterNumber: 1,
      );
      final sceneId = await storyService.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Opening',
        sceneNumber: 1,
        estimatedDurationSeconds: 10,
      );
      final beatId = await storyService.addBeat(
        sceneId: sceneId,
        content: 'Descend',
        startSecond: 0,
        durationSeconds: 2,
      );
      final timelineService = CreateTimelineService(database: first);
      final timelineId = await timelineService.ensureTimelineForScene(
        projectId: 'project-1',
        sceneId: sceneId,
      );
      final clips = await timelineService.getClips(timelineId);
      final linked =
          clips.single.sourceId == beatId && clips.single.durationSeconds == 2;

      await first.close();
      final second = await databaseService.open(dbPath);
      addTearDown(second.close);
      final restarted = CreateTimelineService(database: second);
      final persistedClips = await restarted.getClips(timelineId);
      final persisted =
          persistedClips.single.sourceId == beatId &&
          (await restarted.getTracks(timelineId)).isNotEmpty;

      final passed = linked && persisted;
      validator.recordCheck(
        IntegrityCheck(
          area: IntegrityArea.timeline,
          description:
              'clip.sourceId -> beat nyata; timeline bertahan setelah restart',
          passed: passed,
          detail:
              'linked=$linked persisted=$persisted '
              'tracks=${(await restarted.getTracks(timelineId)).length}',
        ),
      );
      expect(linked, isTrue);
      expect(persisted, isTrue);
    });

    // 5. Aliases: legacy alias paths are registered and target canonicals.
    test('foundation aliases are registered and target canonical routes', () {
      final router = createAppRouter(initialLocation: AppRoutes.settings);
      final paths = router.configuration.routes
          .whereType<GoRoute>()
          .map((route) => route.path)
          .toSet();

      expect(AppRoutes.foundationAliases, isNotEmpty);
      var allValid = true;
      for (final alias in AppRoutes.foundationAliases.entries) {
        allValid =
            allValid &&
            alias.key.startsWith('/') &&
            alias.value.startsWith('/') &&
            alias.key != alias.value &&
            paths.contains(alias.key) &&
            paths.contains(alias.value);
      }
      final knownMapping =
          AppRoutes.foundationAliases['/theme-settings'] == AppRoutes.settings;

      validator.recordCheck(
        IntegrityCheck(
          area: IntegrityArea.alias,
          description:
              'alias terdaftar di router dan menunjuk route kanonis terdaftar',
          passed: allValid && knownMapping,
          detail:
              'aliases=${AppRoutes.foundationAliases.length} '
              'registered=$allValid knownMapping=$knownMapping',
        ),
      );
      expect(allValid, isTrue);
      expect(knownMapping, isTrue);
    });

    // 6. Checksums: HMAC manifest verifies clean, detects post-sign tamper.
    test('integrity manifest verifies clean and detects tampering', () async {
      final dir = Directory('${tempRoot.path}/media-manifest');
      await dir.create(recursive: true);
      await File('${dir.path}/cover.png').writeAsString('bytes-a');
      await File('${dir.path}/page.txt').writeAsString('bytes-b');
      final key = await const Pbkdf2KeyDeriver().derive(
        passphrase: 'integrity-11325',
        salt: const [9, 9, 9, 9, 1, 2, 3, 4],
        iterations: 4,
        length: 32,
      );
      const integrity = HmacIntegrity();
      const manifest = IntegrityManifest();

      final entries = await manifest.build(dir, key, integrity: integrity);
      final cleanVerified = await manifest.verify(
        dir,
        entries,
        key,
        integrity: integrity,
      );
      validator.recordChecksum(
        ChecksumResult(
          label: 'clean-directory-verify',
          integrityHeld: cleanVerified,
          detail: '${entries.length} file ter-sign dan ter-verify TRUE',
        ),
      );

      await File('${dir.path}/cover.png').writeAsString('tampered');
      final tamperDetected = !await manifest.verify(
        dir,
        entries,
        key,
        integrity: integrity,
      );
      validator.recordChecksum(
        ChecksumResult(
          label: 'post-sign-tamper-detect',
          integrityHeld: tamperDetected,
          detail: 'modifikasi setelah signing terdeteksi (verify FALSE)',
        ),
      );

      expect(cleanVerified, isTrue);
      expect(tamperDetected, isTrue);
    });

    // 7. Decision: blocked before recording, pass after all six groups.
    test('decision is blocked empty and pass with all six groups', () {
      final empty = DataIntegrityValidator();
      expect(empty.report().decision, DataIntegrityDecision.blocked);

      final report = validator.report();
      expect(report.checksFor(IntegrityArea.id), isNotEmpty);
      expect(report.checksFor(IntegrityArea.link), isNotEmpty);
      expect(report.checksFor(IntegrityArea.searchIndex), isNotEmpty);
      expect(report.checksFor(IntegrityArea.timeline), isNotEmpty);
      expect(report.checksFor(IntegrityArea.alias), isNotEmpty);
      expect(report.checksumResults, isNotEmpty);
      expect(report.decision, DataIntegrityDecision.pass);
    });

    // 8. Decision: any failed check, unverified checksum, or missing group.
    test('failed check or missing group flips the decision to fail', () {
      final withFailure = DataIntegrityValidator();
      for (final area in IntegrityArea.all) {
        withFailure.recordCheck(
          IntegrityCheck(
            area: area,
            description: 'x',
            passed: area != IntegrityArea.alias,
            detail: 'x',
          ),
        );
      }
      withFailure.recordChecksum(
        const ChecksumResult(label: 'x', integrityHeld: true, detail: 'x'),
      );
      expect(withFailure.report().decision, DataIntegrityDecision.fail);

      final missingGroup = DataIntegrityValidator();
      for (final area in IntegrityArea.all) {
        if (area == IntegrityArea.timeline) continue;
        missingGroup.recordCheck(
          IntegrityCheck(
            area: area,
            description: 'x',
            passed: true,
            detail: 'x',
          ),
        );
      }
      missingGroup.recordChecksum(
        const ChecksumResult(label: 'x', integrityHeld: true, detail: 'x'),
      );
      expect(missingGroup.report().decision, DataIntegrityDecision.fail);

      final unverifiedChecksum = DataIntegrityValidator();
      for (final area in IntegrityArea.all) {
        unverifiedChecksum.recordCheck(
          IntegrityCheck(
            area: area,
            description: 'x',
            passed: true,
            detail: 'x',
          ),
        );
      }
      unverifiedChecksum.recordChecksum(
        const ChecksumResult(
          label: 'x',
          integrityHeld: false,
          detail: 'manifest gagal',
        ),
      );
      expect(unverifiedChecksum.report().decision, DataIntegrityDecision.fail);
    });

    // 9. Manifest & required-evidence contract.
    group('manifest', () {
      const manifestPath =
          'docs/planning/v1.2/sprint_113_data_integrity_validation.json';

      test('manifest exists with canonical step 113.25', () {
        final file = File(manifestPath);
        expect(file.existsSync(), isTrue, reason: 'missing manifest');
        final document =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(document['canonical_step'], '113.25');
        expect(document['title'], 'Data Integrity Validation');
      });

      test('manifest declares all six required evidence groups', () {
        final document =
            jsonDecode(File(manifestPath).readAsStringSync())
                as Map<String, dynamic>;
        final evidence = document['required_evidence'] as Map<String, dynamic>;
        for (final key in [
          'id_checks',
          'link_checks',
          'index_checks',
          'timeline_checks',
          'alias_checks',
          'checksum_results',
        ]) {
          expect(
            evidence.containsKey(key),
            isTrue,
            reason: 'required_evidence missing $key',
          );
        }
        expect(document['limits'], contains('DEFERRED'));
      });
    });
  });
}
