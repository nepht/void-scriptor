import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/presentation/advanced_ai_studio_screen.dart';

void main() {
  testWidgets('shows composer, output, review, and usage sections', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AdvancedAiStudioScreen()));

    expect(find.text('Advanced AI Studio'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Output'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Usage'), findsOneWidget);
  });

  testWidgets('opens image and video generator workspaces', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: AdvancedAiStudioScreen(
          onOpenImageGenerator: () => opened.add('image'),
          onOpenVideoGenerator: () => opened.add('video'),
        ),
      ),
    );

    await tester.tap(find.text('Image Generator'));
    await tester.tap(find.text('Video Generator'));
    expect(opened, ['image', 'video']);
  });
}
