import 'package:flutter/material.dart';
import '../../../../design_system/colors/void_colors.dart';
import '../../../../design_system/typography/void_typography.dart';

class EmptyInspector extends StatelessWidget {
  const EmptyInspector({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined, size: 32, color: VoidColors.textMuted),
          SizedBox(height: 12),
          Text('No selection', style: VoidTypography.title),
          SizedBox(height: 6),
          Text(
            'Select an asset to inspect its properties.',
            textAlign: TextAlign.center,
            style: VoidTypography.caption,
          ),
        ],
      ),
    ),
  );
}
