import 'package:flutter/material.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class RecentAssets extends StatelessWidget {
  const RecentAssets({super.key});

  @override
  Widget build(BuildContext context) {
    return VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Assets', style: VoidTypography.headingMedium),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 500 ? 3 : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: columns == 1 ? 4.8 : 1.4,
                children: const [
                  _AssetTile(icon: Icons.person_outline, label: 'Qowner'),
                  _AssetTile(
                    icon: Icons.checkroom_outlined,
                    label: 'Void Coat',
                  ),
                  _AssetTile(
                    icon: Icons.auto_fix_high_outlined,
                    label: 'Dual Dagger',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      decoration: BoxDecoration(
        color: context.palette.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.palette.borderSoft),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: context.palette.primaryBright),
          const SizedBox(height: 8),
          Text(label, style: VoidTypography.caption),
        ],
      ),
    );
  }
}
