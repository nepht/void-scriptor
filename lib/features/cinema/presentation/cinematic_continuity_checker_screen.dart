import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 48.86 — Cinematic Continuity Checker.
///
/// Periksa: Wardrobe, Hair, Weapon, Damage, Blood/Dirt, Time of Day,
/// Weather, Prop Position, Character Position, Lighting.
class CinematicContinuityCheckerScreen extends StatelessWidget {
  const CinematicContinuityCheckerScreen({super.key});

  static const _items = <(String, IconData)>[
    ('Wardrobe', Icons.checkroom_outlined),
    ('Hair', Icons.content_cut_outlined),
    ('Weapon', Icons.gavel_outlined),
    ('Damage', Icons.broken_image_outlined),
    ('Blood/Dirt', Icons.water_drop_outlined),
    ('Time of Day', Icons.wb_twilight_outlined),
    ('Weather', Icons.cloud_outlined),
    ('Prop Position', Icons.inventory_2_outlined),
    ('Character Position', Icons.person_outline),
    ('Lighting', Icons.light_mode_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Continuity Checker'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, icon) in _items)
                Card(
                  color: context.palette.surface,
                  margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
                  child: ListTile(
                    leading: Icon(icon, color: context.palette.primary),
                    title: Text(label),
                    trailing: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
