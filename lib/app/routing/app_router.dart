import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/adaptive/adaptive_app_shell.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/routing/foundation_route_screen.dart';

GoRouter createAppRouter({String initialLocation = AppRoutes.splash}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      for (final route in AppRoutes.foundationRoutes.entries)
        GoRoute(
          path: route.value,
          builder: (context, state) => route.value == AppRoutes.workspace
              ? const AdaptiveAppShell()
              : FoundationRouteScreen(label: route.key),
        ),
    ],
  );
}
