import 'package:flutter/material.dart';
import '../../../../design_system/colors/void_colors.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class CharacterPortraitCard extends StatelessWidget {
  const CharacterPortraitCard({super.key, this.imagePath});
  final String? imagePath;
  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Portrait', style: VoidTypography.headingMedium),
        const SizedBox(height: 14),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: VoidColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: VoidColors.borderSoft),
            ),
            child: imagePath == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 42,
                          color: VoidColors.textMuted,
                        ),
                        SizedBox(height: 10),
                        Text('No portrait', style: VoidTypography.caption),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(imagePath!, fit: BoxFit.cover),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add Portrait'),
          ),
        ),
      ],
    ),
  );
}
