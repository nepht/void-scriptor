import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:drift/drift.dart' show Value;
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/character/application/create_character_service.dart';
import 'package:void_scriptor/features/environment/application/create_environment_service.dart';
import 'package:void_scriptor/features/environment/domain/environment_type.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

/// 145.27 prioritas #3 (lanjutan): objective canonical menuntut enam
/// prioritas sebagai surface nyata — Characters, Locations, Factions,
/// Timeline, Relationship Map, dan Lore Notes. Run60 menutup
/// Factions/Timeline/Lore Notes; slice ini menuntut Locations (katalog
/// environment proyek) dan Relationship Map (relasi antar karakter)
/// dirender oleh WorldbuildingBody dari data proyek nyata, bukan chrome.
void main() {
  Future<Directory> makeTemp(WidgetTester tester, String prefix) async {
    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp(prefix),
    );
    return dir!;
  }

  testWidgets(
    'worldbuilding body renders Locations and Relationship Map from live project data',
    (tester) async {
      final temp = await makeTemp(tester, 'wb-loc-');
      addTearDown(() {
        if (temp.existsSync()) temp.deleteSync(recursive: true);
      });
      final session = await tester.runAsync(() async {
        final package = await ProjectPackageService(
          rootDirectory: Directory('${temp.path}/pkg'),
        ).create(name: 'Worldbuilding Locations');
        return ProjectSessionManager().open(package);
      });
      final liveSession = session!;
      addTearDown(liveSession.close);

      // Seed nyata: dua karakter terhubung relasi ally_of + satu lokasi.
      final paths = ProjectPaths(rootDirectory: Directory('${temp.path}/data'));
      final db = liveSession.database;
      final projectId = liveSession.manifest.id;
      final sora = await tester.runAsync(
        () => CreateCharacterService(
          database: db,
          paths: paths,
        ).create(projectId: projectId, name: 'Sora'),
      );
      final riku = await tester.runAsync(
        () => CreateCharacterService(
          database: db,
          paths: paths,
        ).create(projectId: projectId, name: 'Riku'),
      );
      await tester.runAsync(() async {
        await db
            .into(db.assetRelations)
            .insert(
              AssetRelationsCompanion.insert(
                id: 'rel-wb-1',
                projectId: Value(projectId),
                sourceAssetId: sora!,
                targetAssetId: riku!,
                relationType: 'ally_of',
              ),
            );
      });
      await tester.runAsync(
        () => CreateEnvironmentService(database: db, paths: paths).create(
          projectId: projectId,
          name: 'Kota Kabut',
          type: EnvironmentType.city,
        ),
      );

      // Jalur produksi: Explorer menulis workspaceIntentProvider bertipe
      // tanpa selection record; resolver menampilkan body worldbuilding.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(
              () => _FixedSession(liveSession),
            ),
            projectPathsProvider.overrideWithValue(paths),
            selectionProvider.overrideWith(_EmptySelection.new),
            workspaceIntentProvider.overrideWith(
              (ref) => (projectId, AssetType.faction),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
        ),
      );
      await tester.pumpAndSettle();

      // Data dimuat via IO async nyata; tunggu sampai katalog terlihat.
      await tester.runAsync(() async {
        for (var i = 0; i < 50; i++) {
          if (find.text('Kota Kabut').evaluate().isNotEmpty) return;
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pumpAndSettle();

      expect(find.byType(WorldbuildingBody), findsOneWidget);
      // Section Locations dengan data environment proyek (nama lokasi
      // juga tampil di katalog lore, sama seperti preseden faksi run60).
      expect(find.text('Locations'), findsOneWidget);
      expect(find.text('Kota Kabut'), findsWidgets);
      // Section Relationship Map dengan relasi antar karakter.
      expect(find.text('Relationship Map'), findsOneWidget);
      expect(find.text('Sora'), findsWidgets);
      expect(find.text('Riku'), findsWidgets);
      expect(find.text('ally_of'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FixedSession extends ProjectSessionController {
  _FixedSession(this._session);

  final ProjectSession _session;

  @override
  Future<ProjectSession?> build() async => _session;
}

/// Selection kosong: intent murni menentukan body (tanpa record terpilih).
class _EmptySelection extends SelectionController {
  @override
  SelectionModel? build() => null;
}
