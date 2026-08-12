import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_status.dart';
import '../../features/authentication/presentation/forgot_password_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/projects/presentation/create_project_screen.dart';
import '../../features/projects/presentation/project_list_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../shell/void_app_shell.dart';
import 'app_routes.dart';
import 'foundation_route_screen.dart';

GoRouter createAppRouter({String initialLocation = AppRoutes.splash}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      for (final route in AppRoutes.foundationRoutes.entries)
        GoRoute(
          path: route.value,
          builder: (_, __) => route.value == AppRoutes.workspace
              ? const VoidAppShell()
              : FoundationRouteScreen(label: route.key),
        ),
    ],
  );
}

List<RouteBase> _routes({VoidCallback? onLogout}) {
  return [
    GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => LoginScreen(
        onRegister: () => context.go(AppRoutes.register),
        onForgotPassword: () => context.go(AppRoutes.forgotPassword),
      ),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) =>
          RegisterScreen(onBackToLogin: () => context.go(AppRoutes.login)),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) =>
          ForgotPasswordScreen(onBack: () => context.go(AppRoutes.login)),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (_, __) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.projects,
      builder: (_, __) => const ProjectListScreen(),
    ),
    GoRoute(
      path: AppRoutes.createProject,
      builder: (_, __) => const CreateProjectScreen(),
    ),
    GoRoute(
      path: AppRoutes.studioProject,
      builder: (_, state) => VoidAppShell(
        projectId: state.pathParameters['projectId'],
        onLogout: onLogout,
      ),
    ),
    GoRoute(
      path: AppRoutes.studio,
      builder: (_, __) => VoidAppShell(onLogout: onLogout),
    ),
    for (final route in AppRoutes.foundationRoutes.entries)
      if (route.value != AppRoutes.splash &&
          route.value != AppRoutes.dashboard &&
          route.value != AppRoutes.projects &&
          route.value != AppRoutes.workspace)
        GoRoute(
          path: route.value,
          builder: (_, __) => _FoundationRouteLabel(label: route.key),
        ),
    GoRoute(
      path: AppRoutes.workspace,
      builder: (_, __) => VoidAppShell(onLogout: onLogout),
    ),
  ];
}

class _FoundationRouteLabel extends ConsumerWidget {
  const _FoundationRouteLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _FoundationScreen(label: label);
  }
}

class _FoundationScreen extends StatelessWidget {
  const _FoundationScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final path = state.uri.path;
      if (auth.isLoading || auth.valueOrNull?.status == AuthStatus.checking) {
        return path == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final session = auth.valueOrNull;
      if (session == null) return AppRoutes.login;

      final isAuthenticated =
          session.status == AuthStatus.authenticated ||
          session.status == AuthStatus.guest ||
          session.status == AuthStatus.offline;
      final authPage =
          path == AppRoutes.login ||
          path == AppRoutes.register ||
          path == AppRoutes.forgotPassword;

      if (session.status == AuthStatus.unauthenticated) {
        return authPage ? null : AppRoutes.login;
      }
      if (isAuthenticated && (authPage || path == AppRoutes.splash)) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: _routes(
      onLogout: () {
        ref.read(authControllerProvider.notifier).logout();
      },
    ),
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this.ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
