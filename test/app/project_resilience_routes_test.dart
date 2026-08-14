import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';

void main() {
  test('all project resilience routes are registered', () {
    final router = createAppRouter(
      initialLocation: AppRoutes.projectDiagnostics,
    );
    final paths = router.configuration.routes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toSet();
    expect(
      paths,
      containsAll({
        AppRoutes.projectDiagnostics,
        AppRoutes.projectRepair,
        AppRoutes.projectBackups,
        AppRoutes.projectExport,
        AppRoutes.projectImport,
        AppRoutes.projectStorage,
        AppRoutes.projectCache,
        AppRoutes.projectTrash,
      }),
    );
  });
}
