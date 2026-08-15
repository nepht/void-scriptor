import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/presentation/output_review_panel.dart';

void main() {
  testWidgets('shows approve, reject, and feedback controls', (tester) async {
    var approved = false;
    var rejected = false;
    String? feedback;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutputReviewPanel(
            onApprove: () => approved = true,
            onReject: () => rejected = true,
            onFeedback: (text) => feedback = text,
          ),
        ),
      ),
    );

    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    expect(approved, isTrue);

    await tester.tap(find.text('Reject'));
    expect(rejected, isTrue);

    await tester.enterText(find.byType(TextField), 'needs more light');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(feedback, 'needs more light');
  });
}
