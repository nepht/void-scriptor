// Slice 145.43 friksi #1: jalur pembuatan link karakter dari kartu Linked Characters.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_projection_cache.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_projection_card.dart';

void main() {
  Future<Directory> makeTemp(WidgetTester tester, String prefix) async {
    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp(prefix),
    );
    return dir!;
  }

  testWidgets('sukses: aksi membuat link persist dan kartu menampilkannya', (
    tester,
  ) async {
    final temp = await makeTemp(tester, 'ws-link-create-');
    addTearDown(() => temp.delete(recursive: true));
    late NovelCharacterLinkRepository repo;
    final cache = WorkspaceProjectionCache(
      loader: (id) async {
        return repo.listForNovel(id);
      },
    );
    await tester.runAsync(() async {
      final package = await ProjectPackageService(
        rootDirectory: Directory('${temp.path}/proj'),
      ).create(name: 'Link Create');
      final db = await ProjectDatabaseService().open(package.databaseFile.path);
      addTearDown(db.close);
      repo = NovelCharacterLinkRepository(
        database: db,
        projectId: package.projectId,
      );
    });
    var cacheInvalidated = false;
    Future<WorkspaceProjection?> onAdd(String workspaceId) async {
      final now = DateTime.now().toUtc();
      await repo.create(
        NovelCharacterLink(
          linkId: 'link-1',
          novelWorkspaceId: workspaceId,
          characterWorkspaceId: 'character-ws-1',
          characterId: 'character-1',
          mode: LinkMode.reference,
          role: 'Protagonist',
          visibility: 'story',
          createdAt: now,
          updatedAt: now,
        ),
      );
      cache.invalidate(workspaceId);
      cacheInvalidated = true;
      return cache.forNovel(workspaceId);
    }

    // SQLite nyata butuh zone asli — pump awal di dalam runAsync.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              child: WorkspaceProjectionCard(
                projectionFuture: cache.forNovel('novel-1'),
                onTapAddCharacter: onAdd,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
    await tester.pumpAndSettle();
    expect(find.text('No linked characters'), findsOneWidget);
    final addFab = find.byTooltip('Link character');
    expect(addFab, findsOneWidget);
    expect(cacheInvalidated, isFalse);

    await tester.runAsync(() async {
      await tester.tap(addFab);
      await tester.pumpAndSettle();
      // Beri drift/Dart I/O kesempatan menyelesaikan query baru.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();
    });
    await tester.pumpAndSettle();
    expect(cacheInvalidated, isTrue);

    // Tunggu projection segar selesai (real I/O di zone asli).
    await tester.runAsync(() async {
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();
    });
    await tester.pumpAndSettle();

    final shown = await tester.runAsync(() => cache.forNovel('novel-1'));
    expect(shown!.links, hasLength(1));
    expect(shown.links.single.characterId, 'character-1');
    expect(find.text('character-1 · Protagonist'), findsOneWidget);
    expect(find.text('No linked characters'), findsNothing);
  });

  testWidgets('tanpa aksi: hint pemilihan karakter, bukan tombol mati', (
    tester,
  ) async {
    final card = WorkspaceProjectionCard(
      projectionFuture: Future<WorkspaceProjection>.value(
        const WorkspaceProjection(novelWorkspaceId: 'novel-1', links: []),
      ),
      onTapAddCharacter: null,
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: card)));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Link character'), findsNothing);
    expect(
      find.text('Select or create a character to link it here.'),
      findsOneWidget,
    );
  });
}
