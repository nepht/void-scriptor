import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/xr/presentation/xr_studio_panel.dart';
import 'package:void_scriptor/core/xr/presentation/spatial_anchor_list.dart';
import 'package:void_scriptor/core/xr/presentation/xr_session_view.dart';

void main() {
  testWidgets('XrStudioPanel shows session state and anchor count', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: XrStudioPanel(sessionState: 'running', anchorCount: 5),
        ),
      ),
    );
    expect(find.text('XR Studio'), findsOneWidget);
    expect(find.text('Session: running'), findsOneWidget);
    expect(find.textContaining('5'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SpatialAnchorList shows anchors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SpatialAnchorList(anchors: ['Anchor 1', 'Anchor 2']),
        ),
      ),
    );
    expect(find.text('Anchor 1'), findsOneWidget);
    expect(find.text('Anchor 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('XrSessionView shows state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: XrSessionView(state: 'paused')),
      ),
    );
    expect(find.text('State: paused'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
