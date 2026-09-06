import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/features/platform/domain/platform_capability.dart';
import 'package:void_scriptor/features/platform/platform_capability_providers.dart';
import 'package:void_scriptor/features/projects/presentation/create_project_screen.dart';

void main() {
  testWidgets('web shows an honest banner and disables the create action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformCapabilitiesProvider.overrideWithValue(
            resolvePlatformCapabilities(isWeb: true),
          ),
        ],
        child: const MaterialApp(home: CreateProjectScreen()),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('belum tersedia di platform ini'),
      findsOneWidget,
    );

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create Project'),
    );
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('native keeps the create action enabled with no banner', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformCapabilitiesProvider.overrideWithValue(
            resolvePlatformCapabilities(isWeb: false),
          ),
        ],
        child: const MaterialApp(home: CreateProjectScreen()),
      ),
    );
    await tester.pump();

    expect(find.textContaining('belum tersedia di Web'), findsNothing);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create Project'),
    );
    expect(button.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
