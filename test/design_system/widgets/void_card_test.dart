import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/design_system/widgets/void_card.dart';

void main() {
  testWidgets('VoidCard merender child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: const VoidCard(child: Text('Hello Card'))),
    );
    expect(find.text('Hello Card'), findsOneWidget);
  });
}
