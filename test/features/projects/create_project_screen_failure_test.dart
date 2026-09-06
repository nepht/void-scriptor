import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/projects/presentation/create_project_screen.dart';

void main() {
  testWidgets(
    'create project surfaces storage failure instead of appearing idle',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CreateProjectScreen(
              onCreateProject: ({required name, required description}) async {
                throw const FileSystemException(
                  'Project storage is unavailable',
                );
              },
            ),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Project name'),
        'Void Cube Saga',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create Project'));
      await tester.pump();

      expect(
        find.textContaining('Project storage is unavailable'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(FilledButton, 'Create Project'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
