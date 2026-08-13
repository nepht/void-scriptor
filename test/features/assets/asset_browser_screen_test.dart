import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
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
}
