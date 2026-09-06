// Asset Browser create flow: the + action opens a dialog that persists a
// stand-alone asset through the injected hook and the live provider refresh
// shows the new card without a restart.
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
  });

  tearDown(() => database.close());

  Future<void> pumpBrowser(
    WidgetTester tester, {
    required Future<String?> Function({
      required String name,
      required String description,
      required String type,
    })
    onCreateAsset,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectAssetsProvider.overrideWith(
          (ref) => database.assetDao.getAllAssets(),
        ),
      ],
      child: MaterialApp(
        home: AssetBrowserScreen(onCreateAsset: onCreateAsset),
      ),
    ),
  );

  testWidgets('create dialog persists a stand-alone armor asset', (
    tester,
  ) async {
    await pumpBrowser(
      tester,
      onCreateAsset: ({required name, required description, required type}) {
        const id = 'created-armor-1';
        return database.assetDao
            .createStandaloneAsset(
              id: id,
              projectId: 'p_test',
              name: name,
              description: description,
              type: type,
              now: DateTime(2026),
            )
            .then((_) => id);
      },
    );
    await tester.pumpAndSettle();
    expect(find.text('No assets found'), findsOneWidget);

    await tester.tap(find.byKey(const Key('asset-browser-create-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('create-asset-name-field')),
      'Native Armor',
    );
    await tester.enterText(
      find.byKey(const Key('create-asset-description-field')),
      'Dibuat lewat dialog create.',
    );
    await tester.tap(find.byKey(const Key('create-asset-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Native Armor'), findsOneWidget);
    expect(find.text('No assets found'), findsNothing);
  });

  testWidgets('create is disabled while the name is blank', (tester) async {
    await pumpBrowser(
      tester,
      onCreateAsset: ({required name, required description, required type}) {
        fail('creation must not run with a blank name');
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('asset-browser-create-fab')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const Key('create-asset-submit-button')),
          )
          .enabled,
      isFalse,
    );
  });
}
