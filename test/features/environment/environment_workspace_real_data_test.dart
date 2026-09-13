import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/features/environment/domain/environment_model.dart';
import 'package:void_scriptor/features/environment/domain/environment_workspace_data.dart';
import 'package:void_scriptor/features/environment/presentation/environment_workspace_screen.dart';

/// Regression for vs-hunt-20260913-environment ENV-BUG-002 (Medium) and
/// ENV-BUG-004 (Low): the LIGHTING/WEATHER/ZONES/CONTINUITY cards used to
/// render hardcoded stub values ('Noon', 'Clear', 'Normal', 'No zones yet')
/// regardless of what the project database actually stores, and the info card
/// rendered blank text instead of the '—' fallback for empty strings.
void main() {
  const environment = EnvironmentModel(
    assetId: 'environment-1',
    projectId: 'project-1',
    name: 'Ashfall Basin',
    environmentType: 'landscape',
    location: 'Northern rim',
    architecture: '',
    terrain: '',
    notes: '',
  );

  const data = EnvironmentWorkspaceData(
    weather: EnvironmentWeatherData(
      condition: 'magicalStorm',
      intensity: 0.7,
      visibility: 0.3,
    ),
    lighting: EnvironmentLightingData(
      time: 'goldenHour',
      keyLight: 'Rim-lit dusk key',
      fogDensity: 0.25,
    ),
    zones: ['Caldera Rim', 'Glass Flats'],
    continuityStateName: 'Post-battle rubble',
  );

  Future<void> pumpWorkspace(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          environmentWorkspaceProvider(
            'environment-1',
          ).overrideWith((ref) async => environment),
          environmentWorkspaceDataProvider(
            'environment-1',
          ).overrideWith((ref) async => data),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: EnvironmentWorkspaceScreen(environmentId: 'environment-1'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('lighting and weather cards render persisted profile values', (
    tester,
  ) async {
    await pumpWorkspace(tester);
    expect(find.text('Golden Hour'), findsOneWidget);
    expect(find.text('Rim-lit dusk key'), findsOneWidget);
    expect(find.text('0.25'), findsOneWidget);
    expect(find.text('Magical Storm'), findsOneWidget);
    expect(find.text('0.7'), findsOneWidget);
    expect(find.text('0.3'), findsOneWidget);
    // The old stub values must be gone.
    expect(find.text('Noon'), findsNothing);
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('zones card lists the persisted zone names', (tester) async {
    await pumpWorkspace(tester);
    expect(find.text('Caldera Rim'), findsOneWidget);
    expect(find.text('Glass Flats'), findsOneWidget);
    expect(find.text('No zones yet'), findsNothing);
  });

  testWidgets('continuity card shows the latest persisted state', (
    tester,
  ) async {
    await pumpWorkspace(tester);
    expect(find.text('Post-battle rubble'), findsOneWidget);
    expect(find.text('Normal'), findsNothing);
  });

  testWidgets(
    'empty database values render the dash fallback, not fake defaults',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            environmentWorkspaceProvider(
              'environment-1',
            ).overrideWith((ref) async => environment),
            environmentWorkspaceDataProvider(
              'environment-1',
            ).overrideWith((ref) async => const EnvironmentWorkspaceData()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EnvironmentWorkspaceScreen(environmentId: 'environment-1'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // A genuinely empty database keeps the honest empty-state copy.
      expect(find.text('No zones yet'), findsOneWidget);
      // ENV-BUG-004: empty model strings must never render as blank rows;
      // populated strings still render normally.
      expect(find.text('Northern rim'), findsOneWidget);
      expect(find.text(''), findsNothing);
      expect(find.text('—'), findsAtLeastNWidgets(4));
    },
  );
}
