import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/inspector/presentation/widgets/support_relationship_section.dart';

/// Regression coverage for hunt-run157 BUG-07 (Referee REAL BUG, Low): the
/// null-session branch of `_load()` stored `_supports = const []`, so the
/// section rendered the fake empty state "No support relationships yet" —
/// contradicting the section's own contract that failure/not-ready must never
/// masquerade as an empty list. The null-session branch must keep
/// `_supports = null` so the build renders the honest "Loading..." state.
void main() {
  // No ProviderScope override: projectSessionProvider's production build
  // returns null (dashboard state), which is exactly the null-session branch.
  Widget tree() => const ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: SupportRelationshipSection(assetId: 'char-no-session'),
        ),
      ),
    ),
  );

  testWidgets('null session renders loading, never a fake empty list', (
    tester,
  ) async {
    await tester.pumpWidget(tree());
    await tester.pump();
    await tester.pump();

    expect(find.text('No support relationships yet'), findsNothing);
    expect(find.text('Loading...'), findsOneWidget);
  });
}
