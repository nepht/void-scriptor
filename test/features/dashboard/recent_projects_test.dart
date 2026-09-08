import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/features/dashboard/presentation/widgets/recent_projects.dart';
import 'package:void_scriptor/features/projects/domain/project_model.dart';
import 'package:void_scriptor/features/projects/presentation/project_controller.dart';

class ProjectsFixture extends ProjectController {
  ProjectsFixture(this.items);
  final List<ProjectModel> items;
  @override
  Future<List<ProjectModel>> build() async => items;
}

ProjectModel project(String id, int day) => ProjectModel(
  id: id,
  name: id,
  description: 'A story in progress',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  lastOpenedAt: DateTime(2026, 9, day),
  localPath: '',
  version: '0.1.0',
);

void main() {
  testWidgets('populated library fits narrow screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectControllerProvider.overrideWith(
            () => ProjectsFixture([
              project(
                'A very long novel title that should wrap without overflowing the writing desk',
                7,
              ),
              project('Another story', 1),
            ]),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: Scaffold(
              body: SingleChildScrollView(child: RecentProjects()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continue writing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'continue opens most recently opened project, not first registry entry',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: RecentProjects()),
          ),
          GoRoute(
            path: '/studio/:id',
            builder: (_, state) =>
                Scaffold(body: Text('Opened ${state.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectControllerProvider.overrideWith(
              () =>
                  ProjectsFixture([project('Older', 1), project('Latest', 7)]),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue writing'), findsOneWidget);
      await tester.tap(find.text('Continue writing'));
      await tester.pumpAndSettle();
      expect(find.text('Opened Latest'), findsOneWidget);
    },
  );

  testWidgets('empty library offers creation, not a fake continue action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectControllerProvider.overrideWith(() => ProjectsFixture([])),
        ],
        child: const MaterialApp(home: Scaffold(body: RecentProjects())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continue writing'), findsNothing);
    expect(find.text('Create your first project'), findsOneWidget);
  });
}
