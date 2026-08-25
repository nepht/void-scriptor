import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/bible/application/create_lore_entity_service.dart';
import 'package:void_scriptor/features/bible/application/worldbuilding_repository.dart';
import 'package:void_scriptor/features/bible/domain/species.dart';
import 'package:void_scriptor/features/story/domain/lore_link_suggester.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('LoreLinkSuggester', () {
    const catalog = [
      LoreEntityRef(
        id: 'sp-1',
        name: 'Api',
        kind: 'species',
        detail: 'Elemen api purba',
      ),
      LoreEntityRef(
        id: 'tc-1',
        name: 'Kapal Api',
        kind: 'technology',
        detail: 'Kapal pelayar lava',
      ),
      LoreEntityRef(
        id: 'ps-1',
        name: 'Air Hidup',
        kind: 'powerSystem',
        detail: 'Kekuatan penyembuh',
      ),
    ];

    test('ranks prefix matches above substring matches', () {
      final result = const LoreLinkSuggester().suggest(catalog, query: 'Ap');

      expect(result.first.name, 'Api');
      expect(result.map((e) => e.name), contains('Kapal Api'));
    });

    test('matches case-insensitively', () {
      final result = const LoreLinkSuggester().suggest(catalog, query: 'air');

      expect(result.single.name, 'Air Hidup');
    });

    test('empty query suggests nothing', () {
      expect(const LoreLinkSuggester().suggest(catalog, query: ''), isEmpty);
      expect(const LoreLinkSuggester().suggest(catalog, query: '   '), isEmpty);
    });

    test('respects the limit', () {
      final many = List.generate(
        12,
        (i) => LoreEntityRef(id: 'x-$i', name: 'Naga $i', kind: 'species'),
      );
      final result = const LoreLinkSuggester(
        limit: 5,
      ).suggest(many, query: 'Na');

      expect(result.length, 5);
    });

    test('dedupes by normalized name keeping the first occurrence', () {
      const duplicated = [
        LoreEntityRef(id: 'a', name: 'Void Cube', kind: 'bible'),
        LoreEntityRef(id: 'b', name: '  void   cube ', kind: 'species'),
      ];

      final result = const LoreLinkSuggester().suggest(
        duplicated,
        query: 'void',
      );

      expect(result.length, 1);
      expect(result.single.id, 'a');
    });

    test('exactMatchOf detects a completed name case-insensitively', () {
      const suggester = LoreLinkSuggester();

      expect(suggester.exactMatchOf(catalog, query: 'api')?.id, 'sp-1');
      expect(suggester.exactMatchOf(catalog, query: 'API ')?.id, 'sp-1');
      expect(suggester.exactMatchOf(catalog, query: 'Api Purba'), isNull);
    });
  });

  group('lore link menu in StoryWorkspaceScreen', () {
    const catalog = [
      LoreEntityRef(
        id: 'sp-1',
        name: 'Api',
        kind: 'species',
        detail: 'Elemen api purba',
      ),
      LoreEntityRef(
        id: 'tc-1',
        name: 'Kapal Api',
        kind: 'technology',
        detail: 'Kapal pelayar lava',
      ),
    ];

    Future<void> pumpEditor(
      WidgetTester tester, {
      Future<List<LoreEntityRef>> Function()? loadLoreCatalog,
      Future<LoreEntityRef> Function(String name)? onCreateLoreEntity,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryWorkspaceScreen(
              storyId: 'story-1',
              loadLoreCatalog: loadLoreCatalog,
              onCreateLoreEntity: onCreateLoreEntity,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
    }

    TextField draftField(WidgetTester tester) => tester.widget<TextField>(
      find.descendant(
        of: find.byType(StoryWorkspaceScreen),
        matching: find.byType(TextField),
      ),
    );

    testWidgets('typing [[query opens the suggestion menu', (tester) async {
      await pumpEditor(tester, loadLoreCatalog: () async => catalog);

      await tester.enterText(find.byType(TextField), 'Kisah [[Ap');
      await tester.pump();

      expect(find.text('Api'), findsWidgets);
      expect(find.text('Kapal Api'), findsWidgets);
    });

    testWidgets('keyboard navigation highlights and accepts with Enter', (
      tester,
    ) async {
      await pumpEditor(tester, loadLoreCatalog: () async => catalog);

      await tester.enterText(find.byType(TextField), '[[Ap');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      // Highlight kedua = Kapal Api; preview mengikuti highlight.
      expect(find.textContaining('Kapal pelayar lava'), findsWidgets);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      final controller = draftField(tester).controller!;
      expect(controller.text, '[[Kapal Api]]');
      expect(controller.selection.baseOffset, '[[Kapal Api]]'.length);
      expect(find.text('Kapal Api'), findsNothing);
    });

    testWidgets('escape closes the menu without inserting anything', (
      tester,
    ) async {
      await pumpEditor(tester, loadLoreCatalog: () async => catalog);

      await tester.enterText(find.byType(TextField), '[[Ap');
      await tester.pump();
      expect(find.text('Api'), findsWidgets);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('Api'), findsNothing);
      expect(draftField(tester).controller!.text, '[[Ap');
    });

    testWidgets('duplicate query warns instead of offering creation', (
      tester,
    ) async {
      await pumpEditor(tester, loadLoreCatalog: () async => catalog);

      await tester.enterText(find.byType(TextField), '[[Api');
      await tester.pump();

      expect(find.textContaining('sudah ada di lore'), findsWidgets);
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('create_entity inserts a link for a brand-new name', (
      tester,
    ) async {
      var createdName = '';
      await pumpEditor(
        tester,
        loadLoreCatalog: () async => catalog,
        onCreateLoreEntity: (name) async {
          createdName = name;
          return const LoreEntityRef(
            id: 'new-1',
            name: 'Naga Salju',
            kind: 'bible',
          );
        },
      );

      await tester.enterText(find.byType(TextField), 'musim [[Naga Salju');
      await tester.pump();

      // Editor berada di bawah lipatan scroll layar pada viewport tes;
      // angkat ke area atas agar menu overlay punya ruang dan bisa di-tap.
      // Catatan: TextField multiline punya Scrollable internal, jadi ambil
      // Scrollable TERLUAR secara eksplisit.
      final dyCreate = tester.getTopLeft(find.byType(TextField)).dy;
      if (dyCreate > 280) {
        await tester.drag(
          find.byType(Scrollable).first,
          Offset(0, 280 - dyCreate),
        );
        await tester.pump();
      }

      await tester.tap(find.textContaining('Buat entitas'));
      await tester.pump();

      expect(createdName, 'Naga Salju');
      final controller = draftField(tester).controller!;
      expect(controller.text, 'musim [[Naga Salju]]');
      expect(find.textContaining('Buat entitas'), findsNothing);
    });

    testWidgets('focus preview shows highlighted entity, hover switches it', (
      tester,
    ) async {
      await pumpEditor(tester, loadLoreCatalog: () async => catalog);

      await tester.enterText(find.byType(TextField), '[[Ap');
      await tester.pump();

      // Focus preview: item pertama tampil tanpa pointer sama sekali.
      expect(find.textContaining('Elemen api purba'), findsWidgets);

      // Angkat editor ke area atas viewport agar koordinat pointer valid;
      // pakai Scrollable terluar (TextField multiline punya internal).
      final dyHover = tester.getTopLeft(find.byType(TextField)).dy;
      if (dyHover > 200) {
        await tester.drag(
          find.byType(Scrollable).first,
          Offset(0, 200 - dyHover),
        );
        await tester.pump();
      }

      final tile = find.text('Kapal Api').last;
      final rect = tester.getRect(tile);
      final gesture = await tester.startGesture(
        rect.center,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      // Pointer mouse hadir di atas tile tanpa dilepas: hover aktif,
      // belum ada tap karena tidak ada up.
      expect(find.textContaining('Kapal pelayar lava'), findsWidgets);
      expect(find.textContaining('Elemen api purba'), findsNothing);

      await gesture.cancel();
    });

    testWidgets('without a catalog loader the lore menu never renders', (
      tester,
    ) async {
      await pumpEditor(tester);

      await tester.enterText(find.byType(TextField), '[[Ap');
      await tester.pump();

      expect(find.text('Api'), findsNothing);
      expect(find.textContaining('Buat entitas'), findsNothing);
    });
  });

  group('CreateLoreEntityService', () {
    late Directory root;
    late ProjectDatabase database;

    setUp(() async {
      root = Directory(
        '${Directory.systemTemp.path}/s109-lore-${DateTime.now().microsecondsSinceEpoch}',
      );
      await root.create(recursive: true);
      final paths = ProjectPaths(rootDirectory: root);
      final service = ProjectDatabaseService();
      final dbPath = (await paths.database('project-1')).path;
      await service.create(dbPath);
      database = await service.open(dbPath);
    });

    tearDown(() async {
      await database.close();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      root.deleteSync(recursive: true);
    });

    test(
      'persists a new lore entity as a Bible entry and trims the name',
      () async {
        const service = CreateLoreEntityService();

        final created = await service.create(
          database,
          projectId: 'project-1',
          name: '  Naga Salju  ',
        );

        expect(created.name, 'Naga Salju');
        expect(created.id, isNotEmpty);

        final reloaded = await service.loadCatalog(database, 'project-1');
        expect(reloaded.map((e) => e.name), contains('Naga Salju'));
      },
    );

    test('rejects blank names', () async {
      const service = CreateLoreEntityService();

      await expectLater(
        service.create(database, projectId: 'project-1', name: '   '),
        throwsArgumentError,
      );
    });

    test(
      'detects duplicates across worldbuilding and bible catalogs',
      () async {
        final worldbuilding = WorldbuildingRepository(database);
        await worldbuilding.saveSpecies(
          SpeciesModel(
            assetId: const Uuid().v4(),
            projectId: 'project-1',
            name: 'Ratu Angin',
            description: 'Penguasa badai timur',
          ),
        );

        const service = CreateLoreEntityService();

        expect(
          service.findExistingName(database, 'project-1', 'ratu angin'),
          completion('Ratu Angin'),
        );
        expect(
          service.findExistingName(database, 'project-1', 'tidak ada'),
          completion(isNull),
        );

        await expectLater(
          service.create(database, projectId: 'project-1', name: 'Ratu Angin'),
          throwsStateError,
        );
      },
    );
  });
}
