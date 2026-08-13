import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/presentation/ai_generation_gallery_screen.dart';

void main() {
  testWidgets(
    'gallery exposes reference and comparison actions on narrow layout',
    (tester) async {
      var used = false;
      var compared = false;
      tester.view.physicalSize = const Size(390, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: AiGenerationGalleryScreen(
            outputs: const [
              GenerationGalleryItem(
                id: 'output',
                path: 'missing.png',
                outputType: 'image',
              ),
            ],
            onUseAsReference: (_) async => used = true,
            onCompareWithPrimary: (_) async => compared = true,
          ),
        ),
      );
      await tester.tap(find.text('Use as Reference'));
      await tester.tap(find.text('Compare with Primary'));
      expect(used, isTrue);
      expect(compared, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
