import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/enterprise/presentation/studio_management_panel.dart';
import 'package:void_scriptor/core/enterprise/presentation/team_member_list.dart';
import 'package:void_scriptor/core/enterprise/presentation/audit_log_view.dart';

void main() {
  testWidgets('StudioManagementPanel shows org and seats', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StudioManagementPanel(
            studioName: 'Void Studio',
            plan: 'enterprise',
            usedSeats: 2,
            maxSeats: 10,
          ),
        ),
      ),
    );
    expect(find.text('Void Studio'), findsOneWidget);
    expect(find.textContaining('enterprise'), findsWidgets);
    expect(find.textContaining('2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TeamMemberList shows members', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TeamMemberList(members: ['alice', 'bob'])),
      ),
    );
    expect(find.text('alice'), findsOneWidget);
    expect(find.text('bob'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AuditLogView shows events', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuditLogView(events: ['u1 create shot-1', 'u2 edit shot-2']),
        ),
      ),
    );
    expect(find.textContaining('create'), findsOneWidget);
    expect(find.textContaining('edit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
