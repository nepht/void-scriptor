// Slice 145.43 friksi #1: application-level action pembuatan link karakter.
// Kontrak:
// - create() persist lewat NovelCharacterLinkRepository.
// - WorkspaceProjectionCache di-invalidasi per novel agar pembaca berikutnya
//   memuat ulang dari database (loader terpanggil lagi).
// - Kegagalan persist menjaga cache tetap valid (tidak ada invalidasi palsu).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/create_novel_character_link_service.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_projection_cache.dart';

void main() {
  late Directory temp;
  late NovelCharacterLinkRepository repo;
  var loaderCalls = 0;
  late WorkspaceProjectionCache cache;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('ws-link-service-');
    final package = await ProjectPackageService(
      rootDirectory: Directory('${temp.path}/proj'),
    ).create(name: 'Link Service');
    final db = await ProjectDatabaseService().open(package.databaseFile.path);
    addTearDown(db.close);
    repo = NovelCharacterLinkRepository(
      database: db,
      projectId: package.projectId,
    );
    loaderCalls = 0;
    cache = WorkspaceProjectionCache(
      loader: (id) async {
        loaderCalls += 1;
        return repo.listForNovel(id);
      },
    );
  });

  tearDown(() async {
    await temp.delete(recursive: true);
  });

  test('create persists link and invalidates projection cache', () async {
    // Prime cache: satu kali load.
    await cache.forNovel('novel-1');
    expect(loaderCalls, 1);

    final service = CreateNovelCharacterLinkService(
      links: repo,
      projections: cache,
    );
    final link = await service.create(
      novelWorkspaceId: 'novel-1',
      characterAssetId: 'char-1',
    );

    expect(link.characterId, 'char-1');
    expect(link.novelWorkspaceId, 'novel-1');
    // Cache di-invalidasi: pembaca berikutnya memuat ulang (loader ke-2).
    final projection = await cache.forNovel('novel-1');
    expect(loaderCalls, 2);
    expect(projection.links, hasLength(1));
    expect(projection.links.single.characterId, 'char-1');
  });

  test('persist failure propagates without invalidating cache', () async {
    await cache.forNovel('novel-1');
    expect(loaderCalls, 1);

    final service = CreateNovelCharacterLinkService(
      links: repo,
      projections: cache,
    );
    // Domain constructor menolak id kosong -> persist gagal sebelum insert.
    await expectLater(
      service.create(novelWorkspaceId: 'novel-1', characterAssetId: '  '),
      throwsArgumentError,
    );
    // Cache tidak di-invalidasi oleh kegagalan.
    await cache.forNovel('novel-1');
    expect(loaderCalls, 1);
  });
}
