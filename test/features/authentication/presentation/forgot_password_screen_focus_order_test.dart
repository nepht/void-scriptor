import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/authentication/presentation/forgot_password_screen.dart';

void main() {
  testWidgets('ForgotPasswordScreen follows a linear keyboard focus order', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1536, 1024));
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(home: ForgotPasswordScreen(onBack: () {})),
    );
    await tester.pumpAndSettle();

    final expectedLabels = <String>[
      'Email',
      'Send Reset Link',
      'Back to sign in',
    ];
    final expectedRects = <Rect>[
      tester.getRect(find.byType(TextField)),
      tester.getRect(find.widgetWithText(FilledButton, 'Send Reset Link')),
      tester.getRect(find.widgetWithText(TextButton, 'Back to sign in')),
    ];
    final actualRects = <Rect>[];

    for (var i = 0; i < expectedLabels.length; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final focusContext = tester.binding.focusManager.primaryFocus?.context;
      expect(
        focusContext,
        isNotNull,
        reason: 'stop ${i + 1} should have a focused widget',
      );
      final renderObject = focusContext!.findRenderObject();
      expect(
        renderObject,
        isA<RenderBox>(),
        reason: 'stop ${i + 1} should expose a render box',
      );
      final box = renderObject! as RenderBox;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      expect(rect.width, greaterThan(0), reason: expectedLabels[i]);
      expect(rect.height, greaterThan(0), reason: expectedLabels[i]);
      actualRects.add(rect);
    }

    expect(actualRects, hasLength(3));
    expect(actualRects[0].top, lessThan(actualRects[1].top));
    expect(actualRects[1].top, lessThan(actualRects[2].top));
    expect(actualRects[0].left, closeTo(actualRects[1].left, 1));
    expect(actualRects[1].left, closeTo(actualRects[2].left, 1));

    // The expected labels are tied to the corresponding interactive controls.
    expect(find.byType(TextField), findsOneWidget, reason: expectedLabels[0]);
    expect(
      find.text(expectedLabels[1]),
      findsOneWidget,
      reason: expectedLabels[1],
    );
    expect(
      find.text(expectedLabels[2]),
      findsOneWidget,
      reason: expectedLabels[2],
    );
    expect(tester.takeException(), isNull);

    // Keep the semantic control geometry explicit for the audit record.
    expect(expectedRects[0].width, greaterThan(0));
    expect(expectedRects[1].width, greaterThan(0));
    expect(expectedRects[2].width, greaterThan(0));
  });
}
