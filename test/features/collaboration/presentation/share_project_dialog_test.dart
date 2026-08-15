import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/collaboration/domain/collaborator.dart';
import 'package:void_scriptor/features/collaboration/presentation/share_project_dialog.dart';

void main() {
  testWidgets('shows role picker and invite button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ShareProjectDialog(onInvite: (email, role) {}),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Share Project'), findsOneWidget);
    expect(find.text('Invite'), findsOneWidget);
  });

  testWidgets('invite callback receives chosen role', (tester) async {
    String? invitedEmail;
    CollaboratorRole? invitedRole;
    await tester.pumpWidget(
      MaterialApp(
        home: ShareProjectDialog(
          onInvite: (email, role) {
            invitedEmail = email;
            invitedRole = role;
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'a@b.com');
    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();
    expect(invitedEmail, 'a@b.com');
    expect(invitedRole, CollaboratorRole.viewer); // default role
  });
}
