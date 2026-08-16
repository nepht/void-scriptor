import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/publishing/presentation/publishing_panel.dart';
import 'package:void_scriptor/core/publishing/presentation/publish_manifest_view.dart';
import 'package:void_scriptor/core/publishing/presentation/release_channel_selector.dart';

void main() {
  testWidgets('PublishingPanel shows channels and latest', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PublishingPanel(channelCount: 3, latestVersion: '1.2.0'),
        ),
      ),
    );
    expect(find.text('Publishing'), findsOneWidget);
    expect(find.textContaining('1.2.0'), findsWidgets);
    expect(find.textContaining('3'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PublishManifestView shows version and changelog', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PublishManifestView(version: '2.0.0', changelog: 'Big update'),
        ),
      ),
    );
    expect(find.text('2.0.0'), findsOneWidget);
    expect(find.text('Big update'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReleaseChannelSelector lists channels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReleaseChannelSelector(channels: ['alpha', 'beta', 'stable']),
        ),
      ),
    );
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
    expect(find.text('stable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
