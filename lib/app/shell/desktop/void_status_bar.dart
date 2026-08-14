import 'package:flutter/material.dart';

import '../../../design_system/colors/void_colors.dart';

class VoidStatusBar extends StatelessWidget {
  const VoidStatusBar({
    super.key,
    this.dirty = false,
    this.canUndo = false,
    this.canRedo = false,
  });

  final bool dirty;
  final bool canUndo;
  final bool canRedo;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: VoidColors.panel,
        border: Border(top: BorderSide(color: VoidColors.borderSoft)),
      ),
      child: Row(
        children: [
          const _Status(label: 'Local', active: true),
          const _Status(label: 'Cloud'),
          const _Status(label: 'AI', active: true),
          _Status(label: 'Undo', active: canUndo),
          _Status(label: 'Redo', active: canRedo),
          _Status(label: 'Dirty', active: dirty),
          const Spacer(),
          const Text(
            'Void Scriptor 0.1 Alpha',
            style: TextStyle(color: VoidColors.textMuted, fontSize: 10),
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
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: active ? VoidColors.success : VoidColors.textDisabled,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: VoidColors.textMuted),
          ),
        ],
      ),
    );
  }
}
