import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/agent_permission_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan daftar permission', (tester) async {
    await tester.pumpWidget(wrap(const AgentPermissionScreen()));
    expect(find.text('File Access'), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);
    expect(find.text('AI Provider'), findsOneWidget);
  });

  testWidgets('menampilkan tombol aksi', (tester) async {
    await tester.pumpWidget(wrap(const AgentPermissionScreen()));
    expect(find.text('Allow All'), findsOneWidget);
    expect(find.text('Deny Optional'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const AgentPermissionScreen()));
    expect(tester.takeException(), isNull);
  });
}
