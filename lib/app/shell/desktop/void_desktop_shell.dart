import 'package:flutter/material.dart';

import '../../../features/explorer/presentation/explorer_panel.dart';
import '../../../features/inspector/presentation/inspector_panel.dart';
import '../../../features/workspace/presentation/workspace_panel.dart';
import 'void_status_bar.dart';
import 'void_top_bar.dart';

class VoidDesktopShell extends StatelessWidget {
  const VoidDesktopShell({super.key, this.onLogout, this.projectId});

  final VoidCallback? onLogout;
  final String? projectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          VoidTopBar(onMenuSelected: (menu) {}, onLogout: onLogout),

          const Expanded(
            child: Row(
              children: [
                ExplorerPanel(),
                Expanded(child: WorkspacePanel()),
                InspectorPanel(),
              ],
            ),
          ),

          const VoidStatusBar(),
        ],
      ),
    );
  }
}
