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
import '../../features/ai/presentation/ai_prompt_composer_screen.dart';
import '../../features/ai/presentation/ai_provider_workspace_screen.dart';
import '../../features/ai/presentation/ai_generation_queue_screen.dart';
import '../../features/ai/presentation/project_ai_generation_gallery_screen.dart';
import '../../features/assets/presentation/asset_browser_screen.dart';
import '../../features/references/presentation/project_reference_library_screen.dart';
import '../../features/references/presentation/reference_comparison_screen.dart';
import '../../features/bible/presentation/project_bible_workspace_screen.dart';
import '../../features/production_assets/presentation/production_asset_workspace_screen.dart';
import '../../features/cinematic_production/presentation/cinematic_production_workspace_screen.dart';
import '../../features/project_resilience/presentation/project_resilience_center_screen.dart';
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
              ? const ProviderScope(child: VoidAppShell())
              : FoundationRouteScreen(label: route.key),
        ),
      GoRoute(
        path: AppRoutes.assets,
        builder: (_, __) => const AssetBrowserScreen(),
      ),
      GoRoute(
        path: AppRoutes.references,
        builder: (_, __) => const ProjectReferenceLibraryScreen(),
      ),
      GoRoute(
        path: AppRoutes.bible,
        builder: (_, __) => const ProjectBibleWorkspaceScreen(),
      ),
      ..._productionAssetRoutes(),
      _cinematicProductionRoute(),
      _productionValidationRoute(),
      ..._resilienceRoutes(),
      GoRoute(
        path: '${AppRoutes.references}/compare',
        builder: (_, state) => ReferenceComparisonScreen(
          referencePath: state.uri.queryParameters['reference'] ?? '',
          generatedPath: state.uri.queryParameters['generated'] ?? '',
        ),
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
    GoRoute(
      path: AppRoutes.aiComposer,
      builder: (_, __) => const AiPromptComposerScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiHistory,
      builder: (_, __) => const AiGenerationQueueScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiGallery,
      builder: (_, __) => const ProjectAiGenerationGalleryScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiProviders,
      builder: (_, __) => const AiProviderWorkspaceScreen(),
    ),
    GoRoute(
      path: AppRoutes.assets,
      builder: (_, __) => const AssetBrowserScreen(),
    ),
    GoRoute(
      path: AppRoutes.references,
      builder: (_, __) => const ProjectReferenceLibraryScreen(),
    ),
    GoRoute(
      path: AppRoutes.bible,
      builder: (_, __) => const ProjectBibleWorkspaceScreen(),
    ),
    ..._productionAssetRoutes(),
    _cinematicProductionRoute(),
    _productionValidationRoute(),
    ..._resilienceRoutes(),
    GoRoute(
      path: '${AppRoutes.references}/compare',
      builder: (_, state) => ReferenceComparisonScreen(
        referencePath: state.uri.queryParameters['reference'] ?? '',
        generatedPath: state.uri.queryParameters['generated'] ?? '',
      ),
    ),
  ];
}

GoRoute _cinematicProductionRoute() => GoRoute(
  path: AppRoutes.cinematicProduction,
  builder: (context, _) => CinematicProductionWorkspaceScreen(
    onImportAudio: () => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audio import siap melalui Audio Import Service.'),
      ),
    ),
    onOpenValidation: () => context.go(AppRoutes.productionValidation),
  ),
);
GoRoute _productionValidationRoute() => GoRoute(
  path: AppRoutes.productionValidation,
  builder: (_, __) =>
      ProductionValidationCenterScreen(issues: const [], onRefresh: () {}),
);
List<RouteBase> _resilienceRoutes() => [
  GoRoute(
    path: AppRoutes.projectDiagnostics,
    builder: (_, __) => const ProjectResilienceCenterScreen(
      title: 'Project Diagnostics',
      items: ['Manifest', 'Database', 'Portable Status'],
    ),
  ),
  GoRoute(
    path: AppRoutes.projectRepair,
    builder: (_, __) => const ProjectResilienceCenterScreen(
      title: 'Project Repair',
      items: ['Missing Files', 'Orphan Files', 'Broken References'],
    ),
  ),
  GoRoute(
    path: AppRoutes.projectBackups,
    builder: (_, __) => const ProjectResilienceCenterScreen(
      title: 'Project Backups',
      items: ['Automatic', 'Manual', 'Pre-Migration'],
    ),
  ),
  GoRoute(
    path: AppRoutes.projectExport,
    builder: (_, __) => const ProjectResilienceCenterScreen(
      title: 'Project Export',
      items: ['Portable Archive', 'Assets', 'Database'],
    ),
  ),
];

List<RouteBase> _productionAssetRoutes() => [
  for (final entry in {
    AppRoutes.creatures: ProductionAssetKind.creature,
    AppRoutes.vehicles: ProductionAssetKind.vehicle,
    AppRoutes.props: ProductionAssetKind.prop,
  }.entries) ...[
    GoRoute(
      path: entry.key,
      builder: (_, __) => ProductionAssetWorkspaceScreen(kind: entry.value),
    ),
    GoRoute(
      path: '${entry.key}/:id',
      builder: (_, state) => ProductionAssetWorkspaceScreen(
        kind: entry.value,
        assetId: state.pathParameters['id'],
      ),
    ),
  ],
];

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
