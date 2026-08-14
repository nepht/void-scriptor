import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/commands/command_registry.dart';
import 'package:void_scriptor/features/assets/domain/asset_search_query.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/assets/presentation/global_search_overlay.dart';

void main() {
  testWidgets(
    'global overlay searches commands with prefix and submits with enter',
    (tester) async {
      final command = PaletteCommand(
        id: 'new-character',
        label: 'New Character',
        execute: () async {},
      );
      Object? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<Object?>(
                  context: context,
                  builder: (_) => GlobalSearchOverlay(
                    assets: const [],
                    commands: [command],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '> new');
      await tester.pump();
      expect(find.text('New Character'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(result, same(command));
    },
  );

  testWidgets('global overlay searches assets without command prefix', (
    tester,
  ) async {
    const asset = SearchableAsset(
      id: 'weapon',
      projectId: 'p',
      name: 'Void Sword',
      type: AssetType.weapon,
      tags: {'void'},
    );
    await tester.pumpWidget(
      const MaterialApp(home: GlobalSearchOverlay(assets: [asset])),
    );
    expect(find.text('Void Sword'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'void');
    await tester.pump();
    expect(find.text('Void Sword'), findsOneWidget);
  });
}
