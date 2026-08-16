import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/audio_engine/presentation/audio_meter_panel.dart';
import 'package:void_scriptor/core/audio_engine/presentation/automation_curve_editor.dart';
import 'package:void_scriptor/core/audio_engine/presentation/bus_controls_panel.dart';

void main() {
  testWidgets('AudioMeterPanel shows RMS and gain', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AudioMeterPanel(rmsDb: -18, gainDb: -6)),
      ),
    );
    expect(find.text('Audio Meter'), findsOneWidget);
    expect(find.textContaining('-18'), findsWidgets);
    expect(find.textContaining('-6'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AutomationCurveEditor renders points', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AutomationCurveEditor(pointCount: 3, segmentCount: 2),
        ),
      ),
    );
    expect(find.textContaining('3'), findsWidgets);
    expect(find.textContaining('2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BusControlsPanel lists buses', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BusControlsPanel(busNames: ['music', 'dialogue'])),
      ),
    );
    expect(find.text('music'), findsOneWidget);
    expect(find.text('dialogue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
