import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 43.15 — Portfolio Builder.
///
/// Creator dapat mengambil hasil langsung dari project:
/// PROJECT → SELECT WORK → PORTFOLIO ENTRY → CUSTOMIZE → PUBLISH.
class PortfolioBuilderScreen extends StatelessWidget {
  const PortfolioBuilderScreen({super.key});

  static const steps = <_PortfolioStep>[
    _PortfolioStep('Project', Icons.folder_copy_outlined),
    _PortfolioStep('Select Work', Icons.checklist_outlined),
    _PortfolioStep('Portfolio Entry', Icons.add_card_outlined),
    _PortfolioStep('Customize', Icons.tune_outlined),
    _PortfolioStep('Publish', Icons.publish_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Builder'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final crossAxisCount = wide ? 5 : 1;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(VoidSpacing.lg),
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: VoidSpacing.md,
                crossAxisSpacing: VoidSpacing.md,
                childAspectRatio: wide ? 1.6 : 3.2,
                children: [
                  for (final s in steps) _StepCard(step: s, wide: wide),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PortfolioStep {
  const _PortfolioStep(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.wide});

  final _PortfolioStep step;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VoidSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(step.icon, color: context.palette.primary, size: 22),
            const SizedBox(width: VoidSpacing.sm),
            Text(
              step.label,
              style: VoidTypography.body.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
