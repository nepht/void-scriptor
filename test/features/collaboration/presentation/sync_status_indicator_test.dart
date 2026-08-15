import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_models.dart';
import 'package:void_scriptor/features/collaboration/presentation/sync_status_indicator.dart';

void main() {
  testWidgets('shows idle icon for idle state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SyncStatusIndicator(status: SyncStatus())),
      ),
    );
    expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
  });

  testWidgets('shows sync icon for syncing state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SyncStatusIndicator(status: SyncStatus.syncing())),
      ),
    );
    expect(find.byIcon(Icons.sync), findsOneWidget);
  });

  testWidgets('shows error icon for error state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SyncStatusIndicator(
            status: SyncStatus(state: SyncState.error, message: 'boom'),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
