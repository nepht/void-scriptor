import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/design_system/widgets/void_button.dart';

// Regression: pilot paralel-fix 2026-09-13. VoidButton's icon+label Row used
// to demand more width than a narrow (mobile) viewport offers, so any
// long-labelled button threw 'RenderFlex overflowed ... on the right' instead
// of shrinking its label (character_section_ownership_test, 390px surface).
void main() {
  Widget host(Widget child, double width) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    ),
  );

  testWidgets(
    'long label shrinks via ellipsis instead of overflowing at 318px',
    (tester) async {
      await tester.pumpWidget(
        host(
          VoidButton(
            label: 'Ekstraksi ciri dari naskah yang sangat panjang sekali',
            icon: Icons.auto_awesome,
            onPressed: () {},
          ),
          318,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    },
  );

  testWidgets('short label renders unchanged', (tester) async {
    await tester.pumpWidget(
      host(VoidButton(label: 'Simpan', onPressed: () {}), 600),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Simpan'), findsOneWidget);
  });
}
