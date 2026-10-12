import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:void_scriptor/features/dashboard/presentation/widgets/cinematic_project_hero.dart';
import 'package:void_scriptor/features/projects/domain/project_model.dart';
import 'package:void_scriptor/features/projects/presentation/project_controller.dart';

class _ProjectsFixture extends ProjectController {
  _ProjectsFixture(this.items);

  final List<ProjectModel> items;

  @override
  Future<List<ProjectModel>> build() async => items;
}

ProjectModel _project({required String id, String? thumbnailPath}) {
  return ProjectModel(
    id: id,
    name: 'The Last Observatory',
    description: 'A quiet story about a city that remembers the stars.',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    lastOpenedAt: DateTime(2026, 9, 7),
    localPath: '',
    version: '0.1.0',
    thumbnailPath: thumbnailPath,
  );
}

Widget _app(List<ProjectModel> projects, {required Size size}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: CinematicProjectHero()),
      ),
      GoRoute(
        path: '/studio/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Opened ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/projects/create',
        builder: (_, _) => const Scaffold(body: Text('Create project')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      projectControllerProvider.overrideWith(() => _ProjectsFixture(projects)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: size),
        child: child!,
      ),
    ),
  );
}

void main() {
  testWidgets('renders a full-bleed featured project with a real action', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app([_project(id: 'observatory')], size: const Size(1440, 900)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dashboard-cinematic-hero')),
      findsOneWidget,
    );
    expect(find.text('The Last Observatory'), findsOneWidget);
    expect(find.text('Continue writing'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('dashboard-cinematic-hero')))
          .width,
      1440,
    );
    await tester.tap(find.text('Continue writing'));
    await tester.pumpAndSettle();
    expect(find.text('Opened observatory'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reflows the hero and keeps an honest empty action on narrow view',
    (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(const [], size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.text('A place for your next chapter'), findsOneWidget);
      expect(find.text('Create your first project'), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('dashboard-cinematic-hero')))
            .width,
        390,
      );
      await tester.tap(find.text('Create your first project'));
      await tester.pumpAndSettle();
      expect(find.text('Create project'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
