import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 50.108 — About Screen.
///
/// VOID SCRIPTOR — Version 1.0.0, Build XXXXX,
/// Licenses, Privacy, Open Source Notices, Check for Updates.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _links = <(String, IconData)>[
    ('Licenses', Icons.gavel_outlined),
    ('Privacy', Icons.privacy_tip_outlined),
    ('Open Source Notices', Icons.code_outlined),
    ('Check for Updates', Icons.update_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: context.palette.primary,
                    ),
                    const SizedBox(height: VoidSpacing.md),
                    Text(
                      'VOID SCRIPTOR',
                      style: VoidTypography.headingLarge.copyWith(
                        color: context.palette.textPrimary,
                      ),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: VoidTypography.caption.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                    Text(
                      'Build 20260817',
                      style: VoidTypography.caption.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VoidSpacing.lg),
              for (final (label, icon) in _links)
                Card(
                  color: context.palette.surface,
                  margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
                  child: ListTile(
                    leading: Icon(icon, color: context.palette.primary),
                    title: Text(label),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
