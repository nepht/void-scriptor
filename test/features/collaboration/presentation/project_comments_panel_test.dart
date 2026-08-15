import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/collaboration/domain/collaborator.dart';
import 'package:void_scriptor/features/collaboration/presentation/project_comments_panel.dart';

void main() {
  final comments = [
    ProjectComment(
      id: '1',
      projectId: 'p1',
      authorId: 'u1',
      targetType: 'character',
      targetId: 'c1',
      body: 'Love the silhouette',
      createdAt: DateTime.utc(2026, 8, 16),
    ),
    ProjectComment(
      id: '2',
      projectId: 'p1',
      authorId: 'u2',
      targetType: 'character',
      targetId: 'c1',
      body: 'Maybe add a cape',
      createdAt: DateTime.utc(2026, 8, 16, 1),
    ),
  ];

  testWidgets('renders comments and posts new ones', (tester) async {
    String? posted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectCommentsPanel(
            comments: comments,
            onPost: (body) => posted = body,
          ),
        ),
      ),
    );
    expect(find.text('Love the silhouette'), findsOneWidget);
    expect(find.text('Maybe add a cape'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Great work');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(posted, 'Great work');
  });
}
