import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 50.45 — Welcome Experience.
///
/// Pertama kali: Welcome to Void Scriptor
/// [Create Project] [Open Project] [Explore Demo].
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(VoidSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 56,
                  color: context.palette.primary,
                ),
                const SizedBox(height: VoidSpacing.lg),
                Text(
                  'Welcome to Void Scriptor',
                  textAlign: TextAlign.center,
                  style: VoidTypography.headingLarge.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: VoidSpacing.xl),
                SizedBox(
                  width: 260,
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Create Project'),
                  ),
                ),
                const SizedBox(height: VoidSpacing.sm),
                SizedBox(
                  width: 260,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Open Project'),
                  ),
                ),
                const SizedBox(height: VoidSpacing.sm),
                SizedBox(
                  width: 260,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Explore Demo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
