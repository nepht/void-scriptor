import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/app/shell/desktop/void_top_bar.dart';
import 'package:void_scriptor/app/shell/mobile/void_mobile_shell.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';

void main() {
  testWidgets('desktop navigation exposes the ordered Core destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: VoidTopBar(onMenuSelected: _noop)),
        ),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Characters'), findsNothing);
    expect(find.text('World'), findsNothing);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('AI Studio'), findsOneWidget);
    expect(find.text('Backup & Export'), findsOneWidget);

    final selected = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: VoidTopBar(onMenuSelected: selected.add)),
        ),
      ),
    );
    await tester.tap(find.text('Dashboard'));
    await tester.tap(find.text('Projects'));
    await tester.tap(find.text('Search'));
    expect(selected, ['dashboard', 'novels', 'search']);
  });

  test('top bar destinations map to Explorer asset focus', () {
    expect(explorerAssetTypeForMenu('novels'), AssetType.story);
    expect(explorerAssetTypeForMenu('characters'), AssetType.character);
    expect(explorerAssetTypeForMenu('world'), AssetType.environment);
    expect(explorerAssetTypeForMenu('workspace'), isNull);
  });

  testWidgets(
    'mobile navigation keeps Core primary and optional tools folded',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: VoidMobileShell())),
      );

      final navigation = find.byType(NavigationBar);
      expect(
        find.descendant(of: navigation, matching: find.text('Dashboard')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navigation, matching: find.text('Novels')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navigation, matching: find.text('Write')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navigation, matching: find.text('Characters')),
        findsOneWidget,
      );

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.text('World'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Backup & Export'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Optional tools'), findsOneWidget);
      expect(find.text('AI Studio'), findsOneWidget);
    },
  );
}

void _noop(String _) {}
