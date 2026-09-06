import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/inspector/presentation/inspector_resolver.dart';
import 'package:void_scriptor/features/story/presentation/story_inspector.dart';
import 'package:void_scriptor/features/story/domain/story_model.dart';

void main() {
  testWidgets('inspector resolver shows empty state without selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: InspectorResolver())),
    );

    expect(find.text('No selection'), findsOneWidget);
    expect(
      find.text('Select an asset to inspect its properties.'),
      findsOneWidget,
    );
  });

  testWidgets('inspector resolver switches to typed asset inspector', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: InspectorResolver())),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(InspectorResolver)),
    );
    container
        .read(selectionProvider.notifier)
        .select(
          const SelectionModel(
            assetId: 'weapon-1',
            assetType: AssetType.weapon,
          ),
        );
    await tester.pump();

    expect(find.text('Weapon'), findsOneWidget);
    expect(find.text('weapon-1'), findsOneWidget);
  });

  testWidgets('story selection resolves to story inspector', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storyInspectorProvider('story-1').overrideWith(
            (ref) async => const StoryModel(
              assetId: 'story-1',
              projectId: 'project-1',
              title: 'The Neon Rain',
              status: 'In Progress',
              synopsis: 'A story synopsis.',
            ),
          ),
        ],
        child: const MaterialApp(home: InspectorResolver()),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(InspectorResolver)),
    );
    container
        .read(selectionProvider.notifier)
        .select(
          const SelectionModel(assetId: 'story-1', assetType: AssetType.story),
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(StoryInspector), findsOneWidget);
    expect(find.text('Story · story-1'), findsOneWidget);
    expect(find.text('The Neon Rain'), findsOneWidget);
    expect(find.text('Status\nIn Progress'), findsOneWidget);
    expect(find.text('A story synopsis.'), findsOneWidget);
  });
}
