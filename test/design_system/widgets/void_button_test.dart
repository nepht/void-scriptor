import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/design_system/widgets/void_button.dart';

void main() {
  testWidgets('VoidButton merender label dan merespons tap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoidButton(
            label: 'Test Button',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Test Button'), findsOneWidget);
    await tester.tap(find.byType(VoidButton));
    expect(tapped, isTrue);
  });

  // vs-hunt-20260913-loadout run272 (pre-existing overflow surfaced by the
  // narrow-screen ownership regression): VoidButton's icon+label Row used
  // MainAxisSize.min with no flexible child, so a long label overflowed the
  // 390px phone viewport by 74px ('Ekstraksi ciri dari naskah' on the
  // Character Workspace Profile section). Contract: label shrinks with an
  // ellipsis instead of throwing RenderFlex overflow.
  testWidgets(
    'VoidButton ellipsizes a long label instead of overflowing at 390px',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.centerLeft,
              child: VoidButton(
                label: 'Ekstraksi ciri dari naskah yang sangat panjang sekali',
                icon: Icons.auto_awesome,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    },
  );

  // Pilot paralel-fix 2026-09-13 asserts the explicit shrink contract: one
  // line, ellipsis — so the label can never wrap and re-grow the button.
  testWidgets(
    'long label shrinks via single-line ellipsis instead of overflowing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(318, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.centerLeft,
              child: VoidButton(
                label: 'Ekstraksi ciri dari naskah yang sangat panjang sekali',
                icon: Icons.auto_awesome,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    },
  );
}
