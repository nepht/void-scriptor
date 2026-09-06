// Asset detail dialog: tapping an asset card opens a dialog with the
// IsolatedAssetReferenceCard (checkerboard area + description) per the
// isolated visual reference contract; Close returns to the browser.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/presentation/asset_browser_screen.dart';
import 'package:void_scriptor/features/character_mode/presentation/character_mode_controller.dart';

void main() {
  late ProjectDatabase database;

  setUp(() async {
    database = ProjectDatabase(NativeDatabase.memory());
    await database.initialize();
    await database.assetDao.createStandaloneAsset(
      id: 'asset-detail-1',
      projectId: 'project-1',
      name: 'Test Armor — Detail',
      description: 'Deskripsi detail untuk verifikasi visual reference.',
      type: 'armor',
      now: DateTime(2026),
    );
  });

  tearDown(() => database.close());

  Future<void> pumpBrowser(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectAssetsProvider.overrideWith(
          (ref) => database.assetDao.getAllAssets(),
        ),
      ],
      child: const MaterialApp(home: AssetBrowserScreen()),
    ),
  );

  testWidgets('tapping an asset card opens the detail dialog', (tester) async {
    await pumpBrowser(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test Armor — Detail'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('asset-detail-dialog')), findsOneWidget);
    expect(find.text('Test Armor — Detail'), findsWidgets);
    expect(
      find.text('Deskripsi detail untuk verifikasi visual reference.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('isolated-reference-image-area')),
      findsOneWidget,
    );
  });

  testWidgets('detail dialog close returns to the browser', (tester) async {
    await pumpBrowser(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Armor — Detail'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('asset-detail-close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('asset-detail-dialog')), findsNothing);
  });
}
