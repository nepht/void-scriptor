import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_status.dart';
import '../../core/capabilities/route_capability_guard.dart';
import '../../core/feature_flags/feature_flag_registry.dart';
import '../../features/authentication/presentation/forgot_password_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/account/presentation/account_cloud_center_screen.dart';
import '../../features/settings/presentation/settings_hub_screen.dart';
import '../../features/settings/presentation/storage_locations_screen.dart';
import '../../features/platform/presentation/theme_settings_screen.dart';
import '../../features/content_capabilities/presentation/content_capability_matrix_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/projects/presentation/create_project_screen.dart';
import '../../features/projects/presentation/project_list_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/ai/presentation/ai_prompt_composer_screen.dart';
import '../../features/ai/presentation/ai_provider_workspace_screen.dart';
import '../../features/ai/presentation/ai_generation_queue_screen.dart';
import '../../features/ai/presentation/project_ai_generation_gallery_screen.dart';
import '../../features/ai/presentation/advanced_ai_studio_screen.dart';
import '../../features/ai/domain/prompt_target.dart';
import '../../features/assets/presentation/asset_browser_screen.dart';
import '../../features/references/presentation/project_reference_library_screen.dart';
import '../../features/references/presentation/reference_comparison_screen.dart';
import '../../features/bible/presentation/project_bible_workspace_screen.dart';
import '../../features/production_assets/presentation/production_asset_workspace_screen.dart';
import '../../features/cinematic_production/presentation/cinematic_production_workspace_screen.dart';
import '../../features/project_resilience/presentation/project_resilience_center_screen.dart';
import '../shell/void_app_shell.dart';
import '../shell/desktop/void_desktop_shell.dart';
import '../shell/desktop/collaboration_comments_screen.dart';
import '../../core/security/presentation/project_lock_screen.dart';
import '../../core/security/presentation/security_settings_screen.dart';
import '../../core/plugin/presentation/plugin_manager_screen.dart';
import '../../core/plugin/builtin/demo_plugin.dart';
import '../../core/plugin/domain/plugin_manifest.dart';
import '../../core/render/presentation/render_preview_panel.dart';
import '../../core/animation/presentation/animation_preview_panel.dart';
import '../../core/animation/builtin/demo_animation.dart';
import '../../core/audio_engine/presentation/audio_meter_panel.dart';
import '../../core/virtual_production/presentation/virtual_production_panel.dart';
import '../../core/virtual_production/builtin/demo_virtual_production.dart';
import '../../core/publishing/presentation/publishing_panel.dart';
import '../../core/publishing/builtin/demo_publishing.dart';
import '../../core/enterprise/presentation/studio_management_panel.dart';
import '../../core/enterprise/builtin/demo_studio.dart';
import '../../core/knowledge/presentation/knowledge_engine_panel.dart';
import '../../core/knowledge/builtin/demo_knowledge.dart';
import '../../core/agent/presentation/agent_platform_panel.dart';
import '../../features/studio/presentation/studio_command_center.dart';
import '../../core/creative/presentation/creative_os_panel.dart';
import '../../core/creative/builtin/demo_creative_os.dart';
import '../../core/xr/presentation/xr_studio_panel.dart';
import '../../core/xr/builtin/demo_xr_studio.dart';
import '../../core/metaverse/presentation/metaverse_studio_panel.dart';
import '../../core/metaverse/builtin/demo_metaverse.dart';
import 'app_routes.dart';
import 'foundation_route_screen.dart';

GoRouter createAppRouter({
  String initialLocation = AppRoutes.splash,
  Set<String> allowedCapabilities = const <String>{},
}) {
  final guard = RouteCapabilityGuard(flags: FeatureFlagRegistry());
  for (final capability in allowedCapabilities) {
    guard.allowCapability(capability);
  }
  return GoRouter(
    redirect: (context, state) => guard.redirectFor(state.uri.path),
    initialLocation: initialLocation,
    routes: [
      for (final route in AppRoutes.foundationRoutes.entries)
        GoRoute(
          path: route.value,
          builder: (context, __) => switch (route.value) {
            AppRoutes.workspace => const ProviderScope(child: VoidAppShell()),
            AppRoutes.aiStudio => AdvancedAiStudioScreen(
              onOpenImageGenerator: () =>
                  context.push(AppRoutes.aiImageGenerator),
              onOpenVideoGenerator: () =>
                  context.push(AppRoutes.aiVideoGenerator),
            ),
            AppRoutes.collaborationComments =>
              const CollaborationCommentsScreen(),
            AppRoutes.accountCloud => const ProviderScope(
              child: VoidDesktopShell(content: AccountCloudCenterScreen()),
            ),
            AppRoutes.security => const SecuritySettingsScreen(),
            AppRoutes.securityLock => const ProjectLockScreen(
              projectName: 'Proyek',
            ),
            _ => FoundationRouteScreen(label: route.key),
          },
        ),
      GoRoute(
        path: AppRoutes.aiImageGenerator,
        builder: (_, __) => const AiGenerationQueueScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiVideoGenerator,
        builder: (_, __) =>
            const AiGenerationQueueScreen(mediaTarget: PromptTarget.video),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.storageLocations,
        builder: (_, __) => const StorageLocationsScreen(),
      ),
      for (final alias in AppRoutes.foundationAliases.entries)
        GoRoute(
          path: alias.key,
          builder: (_, __) => AppRoutes.settings == alias.value
              ? const ThemeSettingsScreen()
              : const SettingsHubScreen(),
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
      GoRoute(
        path: AppRoutes.contentCapabilities,
        builder: (_, __) => const ContentCapabilityMatrixScreen(),
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
      GoRoute(
        path: AppRoutes.plugins,
        builder: (_, __) => PluginManagerScreen(
          plugins: [PluginDescriptor(manifest: DemoPlugin().manifest)],
        ),
      ),
      GoRoute(
        path: AppRoutes.render,
        builder: (_, __) => const RenderPreviewPanel(
          drawCalls: 0,
          culledCount: 0,
          width: 320,
          height: 180,
        ),
      ),
      GoRoute(
        path: AppRoutes.animation,
        builder: (_, __) => AnimationPreviewPanel(
          currentTime: 0,
          durationSeconds: DemoAnimation.bounce.durationSeconds,
          trackCount: DemoAnimation.bounce.tracks.length,
        ),
      ),
      GoRoute(
        path: AppRoutes.audio,
        builder: (_, __) => const AudioMeterPanel(rmsDb: -18, gainDb: -6),
      ),
      GoRoute(
        path: AppRoutes.virtualProduction,
        builder: (_, __) => VirtualProductionPanel(
          shotCount: DemoVirtualProduction.shotList.shots.length,
          takeCount: 0,
          totalDurationSeconds: DemoVirtualProduction.shotList.totalDuration,
        ),
      ),
      GoRoute(
        path: AppRoutes.publishing,
        builder: (_, __) => PublishingPanel(
          channelCount: 3,
          latestVersion: DemoPublishing.manifest.version.toString(),
        ),
      ),
      GoRoute(
        path: AppRoutes.enterpriseStudio,
        builder: (_, __) => StudioManagementPanel(
          studioName: DemoStudio.registry.studio.name,
          plan: DemoStudio.registry.studio.plan,
          usedSeats: DemoStudio.registry.seats.usedSeats,
          maxSeats: DemoStudio.registry.seats.maxSeats,
        ),
      ),
      GoRoute(
        path: AppRoutes.knowledge,
        builder: (_, __) => KnowledgeEnginePanel(
          entityCount: DemoKnowledge.graph.entityCount,
          relationCount: DemoKnowledge.graph.relationCount,
        ),
      ),
      GoRoute(
        path: AppRoutes.agents,
        builder: (_, __) =>
            const AgentPlatformPanel(agentCount: 2, runningCount: 0),
      ),
      GoRoute(
        path: AppRoutes.studioCommandCenter,
        builder: (_, __) => StudioCommandCenter(
          studioName: DemoStudio.registry.studio.name,
          plan: DemoStudio.registry.studio.plan,
          usedSeats: DemoStudio.registry.seats.usedSeats,
          maxSeats: DemoStudio.registry.seats.maxSeats,
          agentCount: 2,
          runningCount: 0,
          taskCount: 0,
          activeMode: 'Overview',
        ),
      ),
      GoRoute(
        path: AppRoutes.creativeOs,
        builder: (_, __) => CreativeOsPanel(
          briefCount: 1,
          stage: DemoCreativeOs.pipeline.currentStage.name,
        ),
      ),
      GoRoute(
        path: AppRoutes.xrStudio,
        builder: (_, __) => XrStudioPanel(
          sessionState: DemoXrStudio.session.state.name,
          anchorCount: DemoXrStudio.scene.anchorCount,
        ),
      ),
      GoRoute(
        path: AppRoutes.metaverse,
        builder: (_, __) => MetaverseStudioPanel(
          worldCount: DemoMetaverse.registry.worldCount,
          zoneCount: DemoMetaverse.registry.zoneCount,
        ),
      ),
    ],
  );
}

List<RouteBase> _routes({VoidCallback? onLogout}) {
  return [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, _) =>
          SplashScreen(onComplete: () => context.go(AppRoutes.dashboard)),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => LoginScreen(
        onRegister: () => context.go(
          state.uri.queryParameters['from'] == 'account-cloud'
              ? '${AppRoutes.register}?from=account-cloud'
              : AppRoutes.register,
        ),
        onForgotPassword: () => context.go(
          state.uri.queryParameters['from'] == 'account-cloud'
              ? '${AppRoutes.forgotPassword}?from=account-cloud'
              : AppRoutes.forgotPassword,
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => RegisterScreen(
        onBackToLogin: () => context.go(
          state.uri.queryParameters['from'] == 'account-cloud'
              ? '${AppRoutes.login}?from=account-cloud'
              : AppRoutes.login,
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => ForgotPasswordScreen(
        onBack: () => context.go(
          state.uri.queryParameters['from'] == 'account-cloud'
              ? '${AppRoutes.login}?from=account-cloud'
              : AppRoutes.login,
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (_, __) =>
          VoidAppShell(content: const DashboardScreen(), onLogout: onLogout),
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
      path: AppRoutes.enterpriseStudio,
      builder: (_, __) => StudioManagementPanel(
        studioName: DemoStudio.registry.studio.name,
        plan: DemoStudio.registry.studio.plan,
        usedSeats: DemoStudio.registry.seats.usedSeats,
        maxSeats: DemoStudio.registry.seats.maxSeats,
      ),
    ),
    GoRoute(
      path: AppRoutes.knowledge,
      builder: (_, __) => KnowledgeEnginePanel(
        entityCount: DemoKnowledge.graph.entityCount,
        relationCount: DemoKnowledge.graph.relationCount,
      ),
    ),
    GoRoute(
      path: AppRoutes.agents,
      builder: (_, __) =>
          const AgentPlatformPanel(agentCount: 2, runningCount: 0),
    ),
    GoRoute(
      path: AppRoutes.creativeOs,
      builder: (_, __) => CreativeOsPanel(
        briefCount: 1,
        stage: DemoCreativeOs.pipeline.currentStage.name,
      ),
    ),
    GoRoute(
      path: AppRoutes.xrStudio,
      builder: (_, __) => XrStudioPanel(
        sessionState: DemoXrStudio.session.state.name,
        anchorCount: DemoXrStudio.scene.anchorCount,
      ),
    ),
    GoRoute(
      path: AppRoutes.metaverse,
      builder: (_, __) => MetaverseStudioPanel(
        worldCount: DemoMetaverse.registry.worldCount,
        zoneCount: DemoMetaverse.registry.zoneCount,
      ),
    ),
    for (final route in AppRoutes.foundationRoutes.entries)
      if (route.value != AppRoutes.splash &&
          route.value != AppRoutes.dashboard &&
          route.value != AppRoutes.projects &&
          route.value != AppRoutes.workspace &&
          route.value != AppRoutes.aiStudio &&
          route.value != AppRoutes.collaborationComments &&
          route.value != AppRoutes.accountCloud &&
          route.value != AppRoutes.security &&
          route.value != AppRoutes.securityLock)
        GoRoute(
          path: route.value,
          builder: (_, __) => _FoundationRouteLabel(label: route.key),
        ),
    GoRoute(
      path: AppRoutes.aiStudio,
      builder: (context, __) => AdvancedAiStudioScreen(
        onOpenImageGenerator: () => context.push(AppRoutes.aiImageGenerator),
        onOpenVideoGenerator: () => context.push(AppRoutes.aiVideoGenerator),
      ),
    ),
    GoRoute(
      path: AppRoutes.aiImageGenerator,
      builder: (_, __) => const AiGenerationQueueScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiVideoGenerator,
      builder: (_, __) =>
          const AiGenerationQueueScreen(mediaTarget: PromptTarget.video),
    ),
    GoRoute(
      path: AppRoutes.collaborationComments,
      builder: (_, __) => const CollaborationCommentsScreen(),
    ),
    GoRoute(
      path: AppRoutes.accountCloud,
      builder: (_, __) => const ProviderScope(
        child: VoidDesktopShell(content: AccountCloudCenterScreen()),
      ),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (_, __) => const SettingsHubScreen(),
    ),
    GoRoute(
      path: AppRoutes.storageLocations,
      builder: (_, __) => const StorageLocationsScreen(),
    ),
    for (final alias in AppRoutes.foundationAliases.entries)
      GoRoute(
        path: alias.key,
        builder: (_, __) => AppRoutes.settings == alias.value
            ? const ThemeSettingsScreen()
            : const SettingsHubScreen(),
      ),
    GoRoute(
      path: AppRoutes.security,
      builder: (_, __) => const SecuritySettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.securityLock,
      builder: (_, __) => const ProjectLockScreen(projectName: 'Proyek'),
    ),
    GoRoute(
      path: AppRoutes.workspace,
      builder: (_, __) => VoidAppShell(onLogout: onLogout),
    ),
    GoRoute(
      path: AppRoutes.studio,
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
    GoRoute(
      path: AppRoutes.contentCapabilities,
      builder: (_, __) => const ContentCapabilityMatrixScreen(),
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
    GoRoute(
      path: AppRoutes.plugins,
      builder: (_, __) => PluginManagerScreen(
        plugins: [PluginDescriptor(manifest: DemoPlugin().manifest)],
      ),
    ),
    GoRoute(
      path: AppRoutes.render,
      builder: (_, __) => const RenderPreviewPanel(
        drawCalls: 0,
        culledCount: 0,
        width: 320,
        height: 180,
      ),
    ),
    GoRoute(
      path: AppRoutes.animation,
      builder: (_, __) => AnimationPreviewPanel(
        currentTime: 0,
        durationSeconds: DemoAnimation.bounce.durationSeconds,
        trackCount: DemoAnimation.bounce.tracks.length,
      ),
    ),
    GoRoute(
      path: AppRoutes.audio,
      builder: (_, __) => const AudioMeterPanel(rmsDb: -18, gainDb: -6),
    ),
    GoRoute(
      path: AppRoutes.virtualProduction,
      builder: (_, __) => VirtualProductionPanel(
        shotCount: DemoVirtualProduction.shotList.shots.length,
        takeCount: 0,
        totalDurationSeconds: DemoVirtualProduction.shotList.totalDuration,
      ),
    ),
    GoRoute(
      path: AppRoutes.publishing,
      builder: (_, __) => PublishingPanel(
        channelCount: 3,
        latestVersion: DemoPublishing.manifest.version.toString(),
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
  for (final entry in {
    AppRoutes.projectDiagnostics: ProjectResilienceView.diagnostics,
    AppRoutes.projectRepair: ProjectResilienceView.repair,
    AppRoutes.projectBackups: ProjectResilienceView.backups,
    AppRoutes.projectExport: ProjectResilienceView.export,
    AppRoutes.projectImport: ProjectResilienceView.import,
    AppRoutes.projectStorage: ProjectResilienceView.storage,
    AppRoutes.projectCache: ProjectResilienceView.cache,
    AppRoutes.projectTrash: ProjectResilienceView.trash,
  }.entries)
    GoRoute(
      path: entry.key,
      builder: (_, __) => ProjectResilienceWorkspaceScreen(view: entry.value),
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
  final routeGuard = RouteCapabilityGuard(flags: FeatureFlagRegistry());

  return GoRouter(
    initialLocation: '${AppRoutes.splash}?intro=1',
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final path = state.uri.path;
      final capabilityRedirect = routeGuard.redirectFor(path);
      if (capabilityRedirect != null) return capabilityRedirect;
      final startupIntro =
          path == AppRoutes.splash && state.uri.queryParameters['intro'] == '1';
      if (startupIntro) return null;
      if ((auth.isLoading && auth.valueOrNull == null) ||
          auth.valueOrNull?.status == AuthStatus.checking) {
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
      final accountAuthFlow =
          authPage && state.uri.queryParameters['from'] == 'account-cloud';

      if (session.status == AuthStatus.unauthenticated) {
        return authPage ? null : AppRoutes.login;
      }
      if (isAuthenticated && (authPage || path == AppRoutes.splash)) {
        if (accountAuthFlow && session.status != AuthStatus.authenticated) {
          return null;
        }
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
