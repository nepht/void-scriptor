import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/dashboard/application/dashboard_snapshot_provider.dart';
import 'package:void_scriptor/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:void_scriptor/features/dashboard/presentation/widgets/statistics_panel.dart';

void main() {
  testWidgets('does not show fabricated statistics without an open project', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSnapshotProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: Scaffold(body: StatisticsPanel())),
      ),
    );
    await tester.pump();

    expect(
      find.text('Open a project to calculate statistics.'),
      findsOneWidget,
    );
    expect(find.text('12'), findsNothing);
    expect(find.text('27'), findsNothing);
    expect(find.text('324'), findsNothing);
  });

  testWidgets('renders measured statistics supplied by the active project', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSnapshotProvider.overrideWith(
            (ref) async => const DashboardSnapshot(
              projects: 1,
              characters: 2,
              wardrobes: 3,
              weapons: 4,
              environments: 5,
              assets: 6,
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: StatisticsPanel())),
      ),
    );
    await tester.pump();

    for (final value in ['2', '3', '4', '5', '6']) {
      expect(find.text(value), findsOneWidget);
    }
  });
}
