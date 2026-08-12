import 'package:flutter/material.dart';

import '../adaptive/void_breakpoints.dart';
import 'desktop/void_desktop_shell.dart';
import 'mobile/void_mobile_shell.dart';

class VoidAppShell extends StatelessWidget {
  const VoidAppShell({super.key, this.onLogout, this.projectId});

  final VoidCallback? onLogout;
  final String? projectId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < VoidBreakpoints.tablet) {
          return VoidMobileShell(onLogout: onLogout, projectId: projectId);
        }

        return VoidDesktopShell(onLogout: onLogout, projectId: projectId);
      },
    );
  }
}
