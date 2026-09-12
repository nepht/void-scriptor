import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/features/character/presentation/widgets/character_portrait_card.dart';

/// Character portrait card wiring: the card must render an imported package
/// file when one is bound, call the injected add-portrait action when the
/// production flow is available, and keep the honest guidance snackbar only
/// when no action is bound (never silently swallow the button).
void main() {
  // Smallest valid 1x1 PNG.
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  Future<String> writePortrait(WidgetTester tester, String name) async {
    final dir = await tester.runAsync(() => Directory.systemTemp.createTemp('portrait-card-'));
    final file = File(p.join(dir!.path, name));
    await tester.runAsync(() => file.writeAsBytes(pngBytes));
    addTearDown(() => dir.delete(recursive: true));
    return file.path;
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    String? imagePath,
    Future<void> Function()? onAddPortrait,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 700,
            child: SingleChildScrollView(
              child: CharacterPortraitCard(
                imagePath: imagePath,
                onAddPortrait: onAddPortrait,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders the bound portrait file instead of the empty state', (tester) async {
    final path = await writePortrait(tester, 'portrait.png');
    await pumpCard(tester, imagePath: path);

    expect(find.text('No portrait'), findsNothing);
    final image = tester.widget<Image>(find.byType(Image).last);
    final provider = image.image as FileImage;
    expect(provider.file.path, path);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invokes the bound add-portrait action', (tester) async {
    var calls = 0;
    await pumpCard(tester, onAddPortrait: () async => calls++);

    await tester.tap(find.text('Add Portrait'));
    await tester.pump();
    expect(calls, 1);
    // No snackbar guidance when a real action is wired.
    expect(find.text('Portrait upload is available from the project asset folder.'), findsNothing);
  });

  testWidgets('keeps the honest guidance snackbar without a bound action', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.text('Add Portrait'));
    await tester.pump();
    expect(
      find.text('Portrait upload is available from the project asset folder.'),
      findsOneWidget,
    );
  });
}
