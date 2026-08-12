// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../../../../design_system/colors/void_colors.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class ReferencesCard extends StatelessWidget {
  const ReferencesCard({super.key});
  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Primary References',
              style: VoidTypography.headingMedium,
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.add,
                size: 18,
                color: VoidColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _Ref('Face'),
            _Ref('Hair'),
            _Ref('Full Body'),
            _Ref('Outfit'),
            _Ref('Pose'),
            _Ref('Expression'),
          ],
        ),
      ],
    ),
  );
}

class _Ref extends StatelessWidget {
  const _Ref(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    width: 105,
    height: 76,
    alignment: Alignment.bottomCenter,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: VoidColors.surfaceElevated,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: VoidColors.borderSoft),
    ),
    child: Text(label, style: VoidTypography.caption),
  );
}
