import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/routing/app_router.dart';

void main() {
  test('Sprint 23 cinematic routes are registered', () {
    final router = createAppRouter(
      initialLocation: AppRoutes.cinematicProduction,
    );
    expect(
      router.configuration.routes.whereType<GoRoute>().map(
        (route) => route.path,
      ),
      contains(AppRoutes.cinematicProduction),
    );
  });
}
