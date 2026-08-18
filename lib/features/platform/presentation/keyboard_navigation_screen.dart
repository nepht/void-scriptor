import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/features/platform/application/platform_controller.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 50.35 — Keyboard Navigation.
///
/// Semua fungsi utama dapat digunakan via keyboard:
/// Tab, Shift+Tab, Enter, Escape, Arrow Keys, Shortcuts.
class KeyboardNavigationScreen extends ConsumerWidget {
  const KeyboardNavigationScreen({super.key});

  static const _shortcuts = <(String, String)>[
    ('Tab', 'Move focus'),
    ('Shift+Tab', 'Move focus back'),
    ('Enter', 'Activate'),
    ('Escape', 'Close / Cancel'),
    ('Arrow Keys', 'Navigate'),
    ('Ctrl+S', 'Save'),
    ('Ctrl+Z', 'Undo'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(platformProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyboard Navigation'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shortcuts',
                style: VoidTypography.headingMedium.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.md),
              for (final (key, action) in _shortcuts)
                _ShortcutRow(keyLabel: key, action: action),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.keyLabel, required this.action});

  final String keyLabel;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VoidSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VoidSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: context.palette.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              keyLabel,
              style: VoidTypography.label.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: VoidSpacing.md),
          Expanded(
            child: Text(
              action,
              style: VoidTypography.body.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
