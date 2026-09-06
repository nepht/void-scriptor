import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/features/account/domain/account_cloud_snapshot.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

void main() {
  final snapshot = AccountCloudSnapshot.localOnly(
    session: const AuthSession.guest(),
  );

  testWidgets('shows honest local and remote capability states', (
    tester,
  ) async {
    var signInRequested = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AccountCloudCenterScreen(
          snapshot: snapshot,
          onSignIn: () => signInRequested = true,
        ),
      ),
    );

    expect(find.text('ACCOUNT & CLOUD CENTER'), findsOneWidget);
    expect(find.text('Guest mode'), findsOneWidget);
    expect(find.text('Local project storage'), findsOneWidget);
    expect(find.text('Available locally'), findsWidgets);
    expect(find.text('Google Drive'), findsOneWidget);
    expect(find.text('Not connected'), findsWidgets);
    expect(find.textContaining('GB of'), findsNothing);

    await tester.tap(find.text('Sign in or connect account'));
    expect(signInRequested, isTrue);
  });

  testWidgets('remains usable on a narrow phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: AccountCloudCenterScreen(snapshot: snapshot)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('ACCOUNT & CLOUD CENTER'), findsOneWidget);
  });
}
