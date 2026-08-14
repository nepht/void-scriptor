import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/features/environment/presentation/environment_workspace_screen.dart';
import 'package:void_scriptor/features/environment/domain/environment_model.dart';

void main() {
  testWidgets(
    'environment workspace renders overview sections on narrow viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EnvironmentWorkspaceScreen(environmentId: 'environment-1'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('LOCATION PREVIEW'), findsOneWidget);
      expect(find.text('ENVIRONMENT INFO'), findsOneWidget);
      expect(find.text('LIGHTING'), findsOneWidget);
      expect(find.text('WEATHER'), findsOneWidget);
      expect(find.text('ZONES'), findsOneWidget);
      expect(find.text('CONTINUITY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'populated environment remains overflow-free and defers unavailable actions',
    (tester) async {
      const environment = EnvironmentModel(
        assetId: 'environment-1',
        projectId: 'project-1',
        name: 'The Extremely Long Megacity Environment Display Name',
        environmentType: 'Dense futuristic exterior production environment',
        location: 'Northern megacity district with an intentionally long name',
        architecture: 'Layered neo-brutalist towers and suspended walkways',
        terrain: 'Multi-level urban terrain',
        notes:
            'A long continuity note that must never force horizontal overflow',
      );
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            environmentWorkspaceProvider(
              'environment-1',
            ).overrideWith((ref) async => environment),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EnvironmentWorkspaceScreen(environmentId: 'environment-1'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(environment.name), findsOneWidget);
      expect(
        find.byTooltip('More environment actions (deferred)'),
        findsOneWidget,
      );
      final action = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('More environment actions (deferred)'),
          matching: find.byType(IconButton),
        ),
      );
      expect(action.onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
