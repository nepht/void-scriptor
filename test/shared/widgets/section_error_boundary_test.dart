import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/shared/widgets/section_error_boundary.dart';

void main() {
  testWidgets('renders fallback when future fails', (tester) async {
    final completer = Completer<String>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionErrorBoundary<String>(
            future: completer.future,
            builder: (data) => Text(data),
            fallback: const Text('Section failed'),
          ),
        ),
      ),
    );

    completer.completeError(StateError('boom'));
    await tester.pumpAndSettle();
    expect(find.text('Section failed'), findsOneWidget);
  });

  testWidgets('renders content on success', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionErrorBoundary<String>(
            future: Future<String>.value('All good'),
            builder: (data) => Text(data),
            fallback: const Text('Section failed'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('All good'), findsOneWidget);
    expect(find.text('Section failed'), findsNothing);
  });

  testWidgets('shows loading skeleton while pending', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionErrorBoundary<String>(
            future: Future<String>.value('done'),
            builder: (data) => Text(data),
            fallback: const Text('Section failed'),
          ),
        ),
      ),
    );

    expect(find.text('Section failed'), findsNothing);
    expect(find.text('done'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('done'), findsOneWidget);
  });
}
