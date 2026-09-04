import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/application/creator_studio_controller.dart';
import 'package:void_scriptor/features/creator/domain/creator_metrics.dart';
import 'package:void_scriptor/features/creator/presentation/dashboard_metrics_screen.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(
    overrides: [
      creatorStudioProvider.overrideWith(
        () => CreatorStudioController(demo: true),
      ),
    ],
    child: MaterialApp(home: child),
  );

  testWidgets('menampilkan 8 metrik dashboard', (tester) async {
    await tester.pumpWidget(wrap(const DashboardMetricsScreen()));
    expect(find.text('Active Projects'), findsOneWidget);
    expect(find.text('Published Works'), findsOneWidget);
    expect(find.text('Portfolio Views'), findsOneWidget);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Collaborations'), findsOneWidget);
    expect(find.text('Asset Sales'), findsOneWidget);
    expect(find.text('AI Usage'), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);
  });

  testWidgets('menampilkan nilai metrik dari provider', (tester) async {
    await tester.pumpWidget(wrap(const DashboardMetricsScreen()));
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1.2k'), findsOneWidget);
    expect(find.text('1.8 GB'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const DashboardMetricsScreen()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('update provider mengubah UI metrik', (tester) async {
    final container = ProviderContainer(
      overrides: [
        creatorStudioProvider.overrideWith(
          () => CreatorStudioController(demo: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DashboardMetricsScreen()),
      ),
    );
    expect(find.text('12'), findsOneWidget);
    container
        .read(creatorStudioProvider.notifier)
        .updateMetrics(
          const CreatorMetrics(
            activeProjects: 42,
            publishedWorks: 7,
            portfolioViews: 500,
            aiUsage: 10,
            storageBytes: 2048,
          ),
        );
    await tester.pump();
    expect(find.text('42'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });
}
