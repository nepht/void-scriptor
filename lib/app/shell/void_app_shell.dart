import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adaptive/void_breakpoints.dart';
import '../../features/projects/presentation/project_persistence_providers.dart';
import 'desktop/void_desktop_shell.dart';
import 'mobile/void_mobile_shell.dart';

class VoidAppShell extends ConsumerStatefulWidget {
  const VoidAppShell({super.key, this.onLogout, this.projectId});

  final VoidCallback? onLogout;
  final String? projectId;

  @override
  ConsumerState<VoidAppShell> createState() => _VoidAppShellState();
}

class _VoidAppShellState extends ConsumerState<VoidAppShell> {
  @override
  void initState() {
    super.initState();
    _openProject(widget.projectId);
  }

  @override
  void didUpdateWidget(covariant VoidAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _openProject(widget.projectId);
    }
  }

  void _openProject(String? projectId) {
    if (projectId == null) return;
    Future<void>.microtask(() async {
      if (!mounted) return;
      await ref.read(projectSessionProvider.notifier).openProject(projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < VoidBreakpoints.tablet) {
          return VoidMobileShell(
            onLogout: widget.onLogout,
            projectId: widget.projectId,
          );
        }

        return VoidDesktopShell(
          onLogout: widget.onLogout,
          projectId: widget.projectId,
        );
      },
    );
  }
}
