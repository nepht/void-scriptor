import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/features/platform/application/platform_controller.dart';
import 'package:void_scriptor/l10n/app_localizations.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 50.45 — Welcome Experience.
///
/// Pertama kali: Welcome to Void Scriptor
/// [Create Project] [Open Project] [Explore Demo].
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({
    super.key,
    this.onCreateProject,
    this.onOpenProject,
    this.onExploreDemo,
  });

  final VoidCallback? onCreateProject;
  final VoidCallback? onOpenProject;
  final VoidCallback? onExploreDemo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(platformProvider);
    final l10n = AppLocalizations(Localizations.localeOf(context));
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
                  l10n.welcomeTitle,
                  textAlign: TextAlign.center,
                  style: VoidTypography.headingLarge.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: VoidSpacing.xl),
                SizedBox(
                  width: 260,
                  child: FilledButton(
                    onPressed: onCreateProject,
                    child: Text(l10n.createProject),
                  ),
                ),
                const SizedBox(height: VoidSpacing.sm),
                SizedBox(
                  width: 260,
                  child: OutlinedButton(
                    onPressed: onOpenProject,
                    child: Text(l10n.openProject),
                  ),
                ),
                const SizedBox(height: VoidSpacing.sm),
                SizedBox(
                  width: 260,
                  child: TextButton(
                    onPressed: onExploreDemo,
                    child: Text(l10n.exploreDemo),
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
