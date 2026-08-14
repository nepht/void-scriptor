import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/commands/project_mutation_state.dart';
import '../../../features/explorer/presentation/explorer_panel.dart';
import '../../../features/inspector/presentation/inspector_panel.dart';
import '../../../features/project_resilience/application/project_mutation_runtime.dart';
import '../../../features/projects/presentation/project_persistence_providers.dart';
import '../../../features/workspace/presentation/workspace_panel.dart';
import '../../routing/app_routes.dart';
import 'void_status_bar.dart';
import 'void_top_bar.dart';

class VoidDesktopShell extends ConsumerWidget {
  const VoidDesktopShell({super.key, this.onLogout, this.projectId});

  final VoidCallback? onLogout;
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionProvider).valueOrNull;
    final runtime = session?.mutationRuntime;
    final content = runtime == null
        ? _buildContent(context, null, null)
        : ValueListenableBuilder<ProjectMutationState>(
            valueListenable: runtime.stateNotifier,
            builder: (context, state, child) =>
                _buildContent(context, runtime, state),
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
        child: Focus(autofocus: true, child: content),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectMutationRuntime? runtime,
    ProjectMutationState? state,
  ) {
    return Scaffold(
      body: Column(
        children: [
          VoidTopBar(
            onMenuSelected: (menu) {
              if (menu == 'assets') context.go('/assets');
              if (menu == 'bible') context.go('/bible');
              if (menu == 'resilience') {
                context.go(AppRoutes.projectDiagnostics);
              }
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
          const Expanded(
            child: Row(
              children: [
                ExplorerPanel(),
                Expanded(child: WorkspacePanel()),
                InspectorPanel(),
              ],
            ),
          ),
          VoidStatusBar(
            dirty: state?.isDirty ?? false,
            canUndo: runtime?.bus.canUndo ?? false,
            canRedo: runtime?.bus.canRedo ?? false,
          ),
        ],
      ),
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
