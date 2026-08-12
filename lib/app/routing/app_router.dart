import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/adaptive/void_adaptive_scaffold.dart';
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
              ? const VoidAdaptiveScaffold(
                  body: Center(child: Text('Workspace')),
                  desktopSidebar: SizedBox(width: 240, child: Text('Explorer')),
                  mobileNavigation: SizedBox.shrink(),
                )
              : FoundationRouteScreen(label: route.key),
        ),
    ],
  );
}
