import 'package:flutter/material.dart';
import '../../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class EmptyInspector extends StatelessWidget {
  const EmptyInspector({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 32,
            color: context.palette.textMuted,
          ),
          const SizedBox(height: 12),
          const Text('No selection', style: VoidTypography.title),
          const SizedBox(height: 6),
          const Text(
            'Select an asset to inspect its properties.',
            textAlign: TextAlign.center,
            style: VoidTypography.caption,
          ),
        ],
      ),
    ),
  );
}
