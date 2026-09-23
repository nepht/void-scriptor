import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/presentation/widgets/character_design_sheet_layout.dart';

void main() {
  for (final width in [390.0, 900.0, 1400.0]) {
    testWidgets('design sheet fits $width with real content regions', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CharacterDesignSheetLayout(
                summary: SizedBox(key: Key('summary'), height: 100),
                turnaround: SizedBox(height: 240),
                details: SizedBox(height: 160),
                portrait: SizedBox(key: Key('portrait'), height: 400),
                references: SizedBox(height: 140),
              ),
            ),
          ),
        ),
      );
      final summary = tester.getRect(find.byKey(const Key('summary')));
      final portrait = tester.getRect(find.byKey(const Key('portrait')));
      if (width >= 820) {
        expect(portrait.left, greaterThan(summary.right));
        expect(portrait.top, summary.top);
        // The approved reference reserves about two thirds of the canvas for
        // the technical sheet and one third for the portrait rail.
        expect(summary.width / portrait.width, closeTo(2, .05));
      } else {
        expect(portrait.top, greaterThan(summary.bottom));
        expect(portrait.width, summary.width);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'desktop overview fits every result region in one visible panel',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 620));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CharacterDesignSheetLayout(
              summary: SizedBox(key: Key('summary'), height: 160),
              turnaround: SizedBox(key: Key('turnaround'), height: 360),
              details: SizedBox(key: Key('details'), height: 220),
              portrait: SizedBox(key: Key('portrait'), height: 600),
              closeUpDetail: SizedBox(key: Key('close-up'), height: 180),
            ),
          ),
        ),
      );

      final viewport = tester.getRect(find.byType(Scaffold));
      for (final key in const [
        'summary',
        'turnaround',
        'details',
        'portrait',
        'close-up',
      ]) {
        final region = tester.getRect(find.byKey(Key(key)));
        expect(region.left, greaterThanOrEqualTo(viewport.left));
        expect(region.top, greaterThanOrEqualTo(viewport.top));
        expect(region.right, lessThanOrEqualTo(viewport.right));
        expect(region.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));
      }
      expect(tester.takeException(), isNull);
    },
  );
}
