import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/features/assets/application/asset_repository.dart';
import 'package:void_scriptor/features/assets/application/asset_view_preference_store.dart';
import 'package:void_scriptor/features/assets/domain/asset_search_query.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/assets/presentation/asset_browser_screen.dart';

void main() {
  final assets = [
    const SearchableAsset(
      id: 'qowner',
      projectId: 'p1',
      name: 'Qowner',
      type: AssetType.character,
      tags: {'void'},
      favorite: true,
    ),
    const SearchableAsset(
      id: 'sword',
      projectId: 'p1',
      name: 'Void Sword',
      type: AssetType.weapon,
      tags: {'void', 'combat'},
    ),
  ];

  testWidgets('asset browser filters, switches view, and selects asset', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: AssetBrowserScreen(assets: assets)),
      ),
    );
    expect(find.text('Qowner'), findsOneWidget);
    expect(find.text('Void Sword'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'sword');
    await tester.pump();
    expect(find.text('Qowner'), findsNothing);
    expect(find.text('Void Sword'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.view_list));
    await tester.pump();
    expect(find.byType(ListTile), findsOneWidget);
    await tester.tap(find.text('Void Sword'));
    expect(
      ProviderScope.containerOf(
        tester.element(find.byType(AssetBrowserScreen)),
      ).read(selectionProvider)?.assetId,
      'sword',
    );
  });

  testWidgets('asset browser supports favorite filter and narrow viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: AssetBrowserScreen(assets: assets)),
      ),
    );
    await tester.tap(find.text('Favorites'));
    await tester.pump();
    expect(find.text('Qowner'), findsOneWidget);
    expect(find.text('Void Sword'), findsNothing);
  });

  testWidgets('asset browser applies search syntax filters', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: AssetBrowserScreen(assets: assets)),
      ),
    );
    await tester.enterText(
      find.byType(TextField),
      'type:weapon tag:void favorite:true',
    );
    await tester.pump();
    expect(find.text('Void Sword'), findsNothing);
    expect(find.text('No assets found'), findsOneWidget);
  });

  testWidgets('asset view preference survives screen recreation', (
    tester,
  ) async {
    final preferences = InMemoryAssetViewPreferenceStore();

    Future<void> pumpBrowser() => tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AssetBrowserScreen(
            assets: assets,
            viewPreferenceStore: preferences,
          ),
        ),
      ),
    );

    await pumpBrowser();
    await tester.tap(find.byIcon(Icons.view_list));
    await tester.pump();
    expect(await preferences.load(), AssetViewMode.list);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpBrowser();
    await tester.pump();
    expect(find.byType(ListTile), findsNWidgets(assets.length));
  });

  testWidgets('long press multi-select bulk tags selected assets durably', (
    tester,
  ) async {
    final repository = InMemoryAssetRepository();
    for (final asset in assets) {
      await repository.saveAsset(asset);
    }
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AssetBrowserScreen(
            assets: assets,
            repository: repository,
            viewPreferenceStore: InMemoryAssetViewPreferenceStore(),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Qowner'));
    await tester.tap(find.text('Void Sword'));
    await tester.tap(find.text('Add tag'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('bulk-tag-field')), ' Hero ');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(await repository.tagsFor('qowner'), ['hero']);
    expect(await repository.tagsFor('sword'), ['hero']);
    expect(find.text('2 selected'), findsNothing);
  });
}
