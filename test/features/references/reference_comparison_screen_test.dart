import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/references/presentation/reference_comparison_screen.dart';

void main() {
  testWidgets(
    'comparison workspace switches modes and supports narrow layout',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReferenceComparisonScreen(
            referencePath: 'missing-reference.png',
            generatedPath: 'missing-generated.png',
          ),
        ),
      );
      expect(find.text('REFERENCE'), findsOneWidget);
      expect(find.text('GENERATED'), findsOneWidget);
      await tester.tap(find.text('Overlay'));
      await tester.pump();
      expect(find.byType(Slider), findsOneWidget);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    },
  );
}
