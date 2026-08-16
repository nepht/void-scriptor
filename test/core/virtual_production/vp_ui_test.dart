import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/virtual_production/presentation/virtual_production_panel.dart';
import 'package:void_scriptor/core/virtual_production/presentation/shot_detail_view.dart';
import 'package:void_scriptor/core/virtual_production/presentation/stage_placement_view.dart';

void main() {
  testWidgets('VirtualProductionPanel shows shot count', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VirtualProductionPanel(
            shotCount: 3,
            takeCount: 5,
            totalDurationSeconds: 12,
          ),
        ),
      ),
    );
    expect(find.text('Virtual Production'), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets);
    expect(find.textContaining('5'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ShotDetailView shows camera and takes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShotDetailView(
            shotName: 'opening',
            cameraLabel: 'Cam A',
            takeCount: 2,
          ),
        ),
      ),
    );
    expect(find.text('opening'), findsOneWidget);
    expect(find.text('Camera: Cam A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StagePlacementView lists actors and lights', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StagePlacementView(actorCount: 2, lightCount: 1)),
      ),
    );
    expect(find.textContaining('2'), findsWidgets);
    expect(find.textContaining('1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
