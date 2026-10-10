import 'package:flutter/material.dart';

import 'package:void_scriptor/design_system/typography/void_typography.dart';

import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class VoidStatusBar extends StatelessWidget {
  const VoidStatusBar({
    super.key,
    this.dirty = false,
    this.canUndo = false,
    this.canRedo = false,
    this.cloudConnected = false,
    this.aiConnected = false,
  });

  final bool dirty;
  final bool canUndo;
  final bool canRedo;
  final bool cloudConnected;
  final bool aiConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.palette.panel,
        border: Border(top: BorderSide(color: context.palette.borderSoft)),
      ),
      child: Row(
        children: [
          const _Status(label: 'Local', active: true),
          _Status(label: 'Cloud', active: cloudConnected),
          _Status(label: 'AI', active: aiConnected),
          _Status(label: 'Undo', active: canUndo),
          _Status(label: 'Redo', active: canRedo),
          _Status(label: 'Dirty', active: dirty),
          const Spacer(),
          Text(
            'Void Scriptor Studio 0.1 Alpha',
            style: VoidTypography.statusBar.copyWith(
              color: context.palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: ${active ? 'Active' : 'Inactive'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          children: [
            Icon(
              Icons.circle,
              size: 6,
              color: active
                  ? context.palette.success
                  : context.palette.textDisabled,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: context.palette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
