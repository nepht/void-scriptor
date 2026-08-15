import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/shared/widgets/content_loading_skeleton.dart';

void main() {
  testWidgets('skeleton renders requested row count', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ContentLoadingSkeleton(rows: 3))),
    );

    expect(find.byType(ContentLoadingSkeleton), findsOneWidget);
    expect(find.byType(SkeletonRow), findsNWidgets(3));
  });

  testWidgets('skeleton rows are non-interactive placeholders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ContentLoadingSkeleton(rows: 2))),
    );

    expect(find.byType(GestureDetector), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('skeleton has no overflow at narrow width', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 200, child: ContentLoadingSkeleton(rows: 5)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
