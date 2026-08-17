import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 47.63 — HUD Designer.
///
/// Daftar elemen HUD: Health, Energy, Ability, Weapon, Minimap,
/// Quest, Interaction, Boss Health.
class HudDesignerScreen extends StatelessWidget {
  const HudDesignerScreen({super.key});

  static const _hudItems = <(String, IconData)>[
    ('Health', Icons.favorite_outline),
    ('Energy', Icons.bolt_outlined),
    ('Ability', Icons.auto_awesome_outlined),
    ('Weapon', Icons.gavel_outlined),
    ('Minimap', Icons.map_outlined),
    ('Quest', Icons.flag_outlined),
    ('Interaction', Icons.touch_app_outlined),
    ('Boss Health', Icons.dangerous_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HUD Designer'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HUD',
                style: VoidTypography.headingLarge.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.md),
              for (final (label, icon) in _hudItems)
                _HudTile(label: label, icon: icon),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudTile extends StatelessWidget {
  const _HudTile({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.surface,
      margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: context.palette.primary),
        title: Text(label),
        trailing: Switch(value: true, onChanged: (_) {}),
      ),
    );
  }
}
