import 'package:flutter/material.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class TurnaroundCard extends StatelessWidget {
  const TurnaroundCard({super.key});
  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Turnaround', style: VoidTypography.headingMedium),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            final count = c.maxWidth >= 650 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: count,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: .72,
              children: const [
                _Slot('Front'),
                _Slot('Side'),
                _Slot('Back'),
                _Slot('3/4'),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _Slot extends StatelessWidget {
  const _Slot(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.palette.surfaceElevated,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: context.palette.borderSoft),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.accessibility_new, color: context.palette.textMuted),
        const SizedBox(height: 8),
        Text(label, style: VoidTypography.caption),
      ],
    ),
  );
}
