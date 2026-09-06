// Regression for 145.44 "Search indexing" gap: opening the Asset Browser
// route without explicit data must fall back to the live project session
// assets instead of rendering an always-empty list.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/presentation/asset_browser_screen.dart';
import 'package:void_scriptor/features/character_mode/presentation/character_mode_controller.dart';

void main() {
  ProjectDatabase? db;

  setUp(() {
    db = ProjectDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db?.close();
    db = null;
  });

  Future<void> seedAsset({
    required String id,
    required String name,
    required String type,
  }) {
    final database = db!;
    final now = DateTime.fromMillisecondsSinceEpoch(0);
    return database.into(database.assets).insert(
          AssetsCompanion.insert(
            id: id,
            projectId: 'p_test',
            name: name,
            type: type,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> pumpBrowser(WidgetTester tester) => tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectAssetsProvider.overrideWith(
              (ref) => db!.assetDao.getAllAssets(),
            ),
          ],
          child: const MaterialApp(home: AssetBrowserScreen()),
        ),
      );

  testWidgets('asset browser falls back to live project session assets', (
    tester,
  ) async {
    await seedAsset(id: 'a-char', name: 'Qowner', type: 'character');
    await seedAsset(
      id: 'a-prop',
      name: 'Test Story Item — Native Journey',
      type: 'prop',
    );
    await seedAsset(id: 'a-unknown', name: 'Legacy Row', type: 'mystery');

    await pumpBrowser(tester);
    await tester.pumpAndSettle();

    expect(find.text('Qowner'), findsOneWidget);
    expect(find.text('Test Story Item — Native Journey'), findsOneWidget);
    // Rows whose stored type is not in AssetType are skipped, not faked.
    expect(find.text('Legacy Row'), findsNothing);
    expect(find.text('No assets found'), findsNothing);
  });

  testWidgets('asset browser keeps honest empty state for empty project', (
    tester,
  ) async {
    await pumpBrowser(tester);
    await tester.pumpAndSettle();

    expect(find.text('No assets found'), findsOneWidget);
    expect(find.byType(AssetBrowserScreen), findsOneWidget);
  });
}
