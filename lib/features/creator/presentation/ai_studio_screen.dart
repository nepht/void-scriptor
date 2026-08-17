import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Sprint 43 — Step 43.8 Personal AI Studio screen.
///
/// Renders the AI control level, context layers, action modes and cost guard
/// sections (steps 43.9–43.14 domain models) as a responsive dashboard.
class AiStudioScreen extends StatelessWidget {
  const AiStudioScreen({super.key});

  static const List<({String label, IconData icon})> _controls = [
    (label: 'Manual', icon: Icons.touch_app_outlined),
    (label: 'Assisted', icon: Icons.assistant_outlined),
    (label: 'Autonomous', icon: Icons.auto_fix_high_outlined),
  ];

  static const List<({String label, IconData icon})> _layers = [
    (label: 'Global', icon: Icons.public_outlined),
    (label: 'Project', icon: Icons.folder_copy_outlined),
    (label: 'Workspace', icon: Icons.dashboard_outlined),
    (label: 'Document', icon: Icons.description_outlined),
    (label: 'Selection', icon: Icons.highlight_alt_outlined),
  ];

  static const List<({String label, IconData icon})> _modes = [
    (label: 'Ask', icon: Icons.help_outline),
    (label: 'Create', icon: Icons.add_circle_outline),
    (label: 'Edit', icon: Icons.edit_outlined),
    (label: 'Analyze', icon: Icons.analytics_outlined),
    (label: 'Plan', icon: Icons.account_tree_outlined),
    (label: 'Review', icon: Icons.rate_review_outlined),
    (label: 'Automate', icon: Icons.auto_awesome_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(VoidSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI STUDIO', style: VoidTypography.displayMedium),
                  const SizedBox(height: 6),
                  const Text(
                    'Your personal AI: control level, context, actions and cost.',
                    style: VoidTypography.body,
                  ),
                  const SizedBox(height: 28),
                  _Section(
                    title: 'AI Control Level',
                    wide: wide,
                    children: [
                      for (final c in _controls)
                        _OptionCard(label: c.label, icon: c.icon),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'Context Layers',
                    wide: wide,
                    children: [
                      for (final l in _layers)
                        _OptionCard(label: l.label, icon: l.icon),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'Action Modes',
                    wide: wide,
                    children: [
                      for (final m in _modes)
                        _OptionCard(label: m.label, icon: m.icon),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _Section(
                    title: 'Cost Guard',
                    wide: false,
                    children: [
                      _InfoRow(
                        label: 'Daily Limit',
                        value: '1,000 credits',
                        icon: Icons.calendar_today_outlined,
                      ),
                      _InfoRow(
                        label: 'Model Budget',
                        value: 'Standard',
                        icon: Icons.tune_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.wide,
    required this.children,
  });

  final String title;
  final bool wide;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: VoidTypography.headingMedium),
        const SizedBox(height: 12),
        if (wide)
          Wrap(
            spacing: VoidSpacing.md,
            runSpacing: VoidSpacing.md,
            children: children,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in children) ...[
                c,
                const SizedBox(height: VoidSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(VoidSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.palette.primaryBright),
          const SizedBox(width: 10),
          Flexible(child: Text(label, style: VoidTypography.body)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoidSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.palette.primaryBright),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: VoidTypography.body)),
          const SizedBox(width: 16),
          Text(value, style: VoidTypography.title),
        ],
      ),
    );
  }
}
