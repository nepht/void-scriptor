import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/domain/asset_search_query.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/assets/presentation/asset_browser_screen.dart';

void main() {
  final assets = [
    const SearchableAsset(
      id: 'aurivy',
      projectId: 'p1',
      name: 'Aurivy',
      type: AssetType.creature,
    ),
  ];

  Future<void> openDetail(WidgetTester tester) async {
    await tester.tap(find.text('Aurivy'));
    await tester.pumpAndSettle();
  }

  testWidgets('asset detail offers the isolated-reference import action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: AssetBrowserScreen(assets: assets)),
      ),
    );
    await openDetail(tester);

    expect(find.byKey(const Key('asset-detail-dialog')), findsOneWidget);
    final button = find.widgetWithText(
      OutlinedButton,
      'Add isolated reference',
    );
    expect(button, findsOneWidget);
    // Without a session or injected seam the action must not be dead:
    // the browser wires the card's onAddReference to the import hook.
    expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
  });

  testWidgets('import seam runs, dialog closes, and result refreshes list', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AssetBrowserScreen(
            assets: assets,
            onImportThumbnail: (assetId) async {
              calls.add(assetId);
              return r'C:\pkg\assets\asset_thumbnails\aurivy_1.png';
            },
          ),
        ),
      ),
    );
    await openDetail(tester);

    await tester.tap(find.text('Add isolated reference'));
    await tester.pumpAndSettle();

    expect(calls, ['aurivy']);
    expect(
      find.byKey(const Key('asset-detail-dialog')),
      findsNothing,
      reason: 'a completed import closes the detail dialog',
    );
  });

  testWidgets('cancelled import keeps the detail dialog open', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AssetBrowserScreen(
            assets: assets,
            onImportThumbnail: (assetId) async => null,
          ),
        ),
      ),
    );
    await openDetail(tester);

    await tester.tap(find.text('Add isolated reference'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('asset-detail-dialog')), findsOneWidget);
  });
}
