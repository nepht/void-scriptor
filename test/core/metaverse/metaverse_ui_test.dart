import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/metaverse/presentation/metaverse_studio_panel.dart';
import 'package:void_scriptor/core/metaverse/presentation/world_list.dart';
import 'package:void_scriptor/core/metaverse/presentation/zone_list.dart';

void main() {
  testWidgets('MetaverseStudioPanel shows world and zone count', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MetaverseStudioPanel(worldCount: 2, zoneCount: 5)),
      ),
    );
    expect(find.text('Metaverse Studio'), findsOneWidget);
    expect(find.text('Worlds: 2'), findsOneWidget);
    expect(find.text('Zones: 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WorldList shows worlds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WorldList(worlds: ['Void Cube', 'Frozen North'])),
      ),
    );
    expect(find.text('Void Cube'), findsOneWidget);
    expect(find.text('Frozen North'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ZoneList shows zones', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ZoneList(zones: ['Frozen Pole', 'Volcanic Sea'])),
      ),
    );
    expect(find.text('Frozen Pole'), findsOneWidget);
    expect(find.text('Volcanic Sea'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
