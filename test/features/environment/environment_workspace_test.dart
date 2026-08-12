import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/features/environment/presentation/environment_workspace_screen.dart';

void main() {
  testWidgets(
    'environment workspace renders overview sections on narrow viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EnvironmentWorkspaceScreen(environmentId: 'environment-1'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('LOCATION PREVIEW'), findsOneWidget);
      expect(find.text('ENVIRONMENT INFO'), findsOneWidget);
      expect(find.text('LIGHTING'), findsOneWidget);
      expect(find.text('WEATHER'), findsOneWidget);
      expect(find.text('ZONES'), findsOneWidget);
      expect(find.text('CONTINUITY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
