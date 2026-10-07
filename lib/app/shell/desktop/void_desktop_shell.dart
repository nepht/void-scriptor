import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/commands/project_mutation_state.dart';
import '../../../core/domain/asset_type.dart';
import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../../../features/explorer/presentation/explorer_panel.dart';
import '../../../features/inspector/presentation/inspector_panel.dart';
import '../../../features/project_resilience/application/project_mutation_runtime.dart';
import '../../../features/projects/presentation/project_persistence_providers.dart';
import '../../../features/workspace/presentation/global_search_sheet.dart';
import '../../../features/workspace/application/global_search_launcher.dart';
import '../../../features/workspace/presentation/workspace_panel.dart';
import '../../../features/workspace_layout/application/workspace_tab_controller.dart';
import '../../../features/workspace_layout/presentation/workspace_layout_shell.dart';
import '../../../features/workspace_layout/presentation/workspace_tab_bar.dart';
import '../../routing/app_routes.dart';
import 'void_top_bar.dart';

/// vs-hunt-20260913-shell-settings BUG-02 (REAL Low, kontrak 145.37):
/// Klik tab yang sudah menjadi destinasi aktif tidak boleh menumpuk halaman
/// identik di stack navigasi (shell desktop tidak punya tombol back untuk
/// destinasi dalam-shell). Destinasi berbeda tetap di-push agar affordance
/// back AppBar bawaan sub-destination (Settings/Assets/Backups) dipertahankan.
void _pushDistinctRoute(BuildContext context, String route) {
  final current = GoRouterState.of(context).matchedLocation;
  if (current == route) return;
  context.push(route);
}

class VoidDesktopShell extends ConsumerWidget {
  const VoidDesktopShell({
    super.key,
    this.content,
    this.onLogout,
    this.projectId,
    this.topBarHeight = 32,
  });

  final Widget? content;
  final VoidCallback? onLogout;
  final String? projectId;

  /// Route-level chrome override. The account reference visual uses 52px;
  /// all other desktop routes retain the compact 32px default.
  final double topBarHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionProvider).value;
    final runtime = session?.mutationRuntime;
    final renderedContent = runtime == null
        ? _buildContent(context, ref, null, null, content)
        : ValueListenableBuilder<ProjectMutationState>(
            valueListenable: runtime.stateNotifier,
            builder: (context, state, child) =>
                _buildContent(context, ref, runtime, state, content),
          );
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
            const UndoMutationIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyZ,
        ): const RedoMutationIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
            const RedoMutationIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            const SaveProjectIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ):
            const UndoMutationIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.meta,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyZ,
        ): const RedoMutationIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS):
            const SaveProjectIntent(),
      },
      child: Actions(
        actions: {
          UndoMutationIntent: CallbackAction<UndoMutationIntent>(
            onInvoke: (_) {
              unawaited(runtime?.bus.undo());
              return null;
            },
          ),
          RedoMutationIntent: CallbackAction<RedoMutationIntent>(
            onInvoke: (_) {
              unawaited(runtime?.bus.redo());
              return null;
            },
          ),
          SaveProjectIntent: CallbackAction<SaveProjectIntent>(
            onInvoke: (_) {
              unawaited(session?.save());
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: renderedContent),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ProjectMutationRuntime? runtime,
    ProjectMutationState? state,
    Widget? suppliedContent,
  ) {
    final session = ref.watch(projectSessionProvider).value;
    return Scaffold(
      body: Column(
        children: [
          VoidTopBar(
            height: topBarHeight,
            saveState: state,
            projectContext: session == null
                ? null
                : ProjectContextSummary(
                    projectId: session.manifest.id,
                    projectName: session.manifest.name,
                  ),
            onMenuSelected: (menu) {
              final assetType = explorerAssetTypeForMenu(menu);
              if (assetType != null) {
                if (session == null) {
                  context.go(AppRoutes.projects);
                  return;
                }
                focusExplorerAsset(ref, assetType);
                _pushDistinctRoute(context, AppRoutes.workspace);
                return;
              }
              final route = switch (menu) {
                'dashboard' => AppRoutes.dashboard,
                'novels' => AppRoutes.projects,
                'write' => AppRoutes.workspace,
                'search' => AppRoutes.assets,
                'backup-export' =>
                  session == null
                      ? AppRoutes.projects
                      : AppRoutes.projectBackups,
                'settings' => AppRoutes.settings,
                'assets' => AppRoutes.assets,
                'bible' =>
                  session == null ? AppRoutes.projects : AppRoutes.bible,
                'ai' => AppRoutes.aiStudio,
                'ai-image-generator' => AppRoutes.aiImageGenerator,
                'ai-video-generator' => AppRoutes.aiVideoGenerator,
                'content-capabilities' => AppRoutes.contentCapabilities,
                'resilience' =>
                  session == null
                      ? AppRoutes.projects
                      : AppRoutes.projectDiagnostics,
                'account-cloud' => AppRoutes.accountCloud,
                _ => null,
              };
              if (route != null) _pushDistinctRoute(context, route);
            },
            onOpenSearch: session == null
                ? null
                : () {
                    showGlobalSearchSheet(
                      context,
                      launcher: GlobalSearchLauncher(
                        database: session.database,
                      ),
                      projectId: session.manifest.id,
                      // BUG-02 (hunt-20260910): route faction hits through the
                      // shared selectionProvider (same typed SelectionModel as
                      // Explorer) so the resolver opens the faction branch.
                      onSelectFaction: (factionId, factionName) {
                        ref
                            .read(selectionProvider.notifier)
                            .select(
                              SelectionModel(
                                assetId: factionId,
                                assetType: AssetType.faction,
                                projectId: session.manifest.id,
                              ),
                            );
                      },
                    );
                  },
            onLogout: onLogout,
            canUndo: runtime?.bus.canUndo ?? false,
            canRedo: runtime?.bus.canRedo ?? false,
            onUndo: runtime == null
                ? null
                : () => unawaited(runtime.bus.undo()),
            onRedo: runtime == null
                ? null
                : () => unawaited(runtime.bus.redo()),
          ),
          Expanded(
            child:
                suppliedContent ??
                const WorkspaceLayoutShell(
                  explorer: ExplorerPanel(),
                  workspace: Column(
                    children: [
                      _WorkspaceTabStrip(),
                      Expanded(child: WorkspacePanel()),
                    ],
                  ),
                  inspector: InspectorPanel(),
                ),
          ),
          // 115.37 (Choi, 2026-09-27): status bar dihapus. Konten di atasnya
          // (Expanded) sekarang mengisi sisa tinggi, dan tinggi yang dibebaskan
          // itu menjadi ruang kerja tambahan, bukan ruang kosong.
        ],
      ),
    );
  }
}

class _WorkspaceTabStrip extends ConsumerWidget {
  const _WorkspaceTabStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceTabsProvider);
    if (state.tabs.isEmpty) return const SizedBox.shrink();
    final notifier = ref.read(workspaceTabsProvider.notifier);
    return WorkspaceTabBar(
      tabs: state.tabs,
      activeTabId: state.activeTabId,
      onSelect: notifier.activate,
      onClose: notifier.close,
      onCloseOthers: notifier.closeOthers,
    );
  }
}

class UndoMutationIntent extends Intent {
  const UndoMutationIntent();
}

class RedoMutationIntent extends Intent {
  const RedoMutationIntent();
}

class SaveProjectIntent extends Intent {
  const SaveProjectIntent();
}
