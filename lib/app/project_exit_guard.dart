import 'dart:ui' show AppExitResponse;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/projects/presentation/project_persistence_providers.dart';

class ProjectExitGuard extends ConsumerStatefulWidget {
  const ProjectExitGuard({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ProjectExitGuard> createState() => _ProjectExitGuardState();
}

class _ProjectExitGuardState extends ConsumerState<ProjectExitGuard> {
  late final AppLifecycleListener _lifecycle;
  Future<AppExitResponse>? _pendingExit;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onExitRequested: _requestExit);
  }

  Future<AppExitResponse> _requestExit() async {
    final pending = _pendingExit;
    if (pending != null) return pending;
    final operation = _closeSession();
    _pendingExit = operation;
    try {
      return await operation;
    } finally {
      _pendingExit = null;
    }
  }

  Future<AppExitResponse> _closeSession() async {
    try {
      // Windows awaits this callback before destroying the engine. A widget's
      // dispose/onDispose callback cannot provide that guarantee.
      await ref.read(projectSessionProvider.notifier).closeProject();
      return AppExitResponse.exit;
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'project shutdown',
          context: ErrorDescription('while closing the active project'),
        ),
      );
      return AppExitResponse.cancel;
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
