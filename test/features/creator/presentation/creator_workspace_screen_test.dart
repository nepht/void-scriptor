import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/application/creator_studio_controller.dart';
import 'package:void_scriptor/features/creator/domain/creator_workspace_section.dart';
import 'package:void_scriptor/features/creator/presentation/creator_workspace_screen.dart';

void main() {
  testWidgets('menampilkan 9 seksi workspace dari provider', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CreatorWorkspaceScreen()),
      ),
    );

    for (final s in CreatorWorkspaceSection.values) {
      expect(find.text(s.label), findsOneWidget);
    }
  });

  testWidgets('menyorot seksi aktif dari provider', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(creatorStudioProvider.notifier)
        .setSection(CreatorWorkspaceSection.portfolio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CreatorWorkspaceScreen()),
      ),
    );
    await tester.pump(); 

    final cardFinder = find.ancestor(
      of: find.text('Portfolio'),
      matching: find.byType(Card),
    );
    final card = tester.widget<Card>(cardFinder);
    expect(card.elevation, 4);
  });

  testWidgets('tap pada card memanggil setSection', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CreatorWorkspaceScreen()),
      ),
    );

    expect(
      container.read(creatorStudioProvider).activeSection,
      CreatorWorkspaceSection.myProjects,
    );

    await tester.tap(find.text('My Worlds'));
    await tester.pump();

    expect(
      container.read(creatorStudioProvider).activeSection,
      CreatorWorkspaceSection.myWorlds,
    );
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CreatorWorkspaceScreen()),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
