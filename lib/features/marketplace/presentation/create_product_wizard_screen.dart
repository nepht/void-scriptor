import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 44.31 — Create Product Wizard.
///
/// Flow: Details → Pricing → Files → Review.
class CreateProductWizardScreen extends StatefulWidget {
  const CreateProductWizardScreen({super.key});

  @override
  State<CreateProductWizardScreen> createState() =>
      _CreateProductWizardScreenState();
}

class _CreateProductWizardScreenState extends State<CreateProductWizardScreen> {
  int _step = 0;

  static const _steps = <String>['Details', 'Pricing', 'Files', 'Review'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Product'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    _StepChip(
                      label: _steps[i],
                      active: i == _step,
                      done: i < _step,
                    ),
                ],
              ),
              const SizedBox(height: VoidSpacing.lg),
              Text(
                'Step ${_step + 1}: ${_steps[_step]}',
                style: VoidTypography.headingMedium.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: VoidSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          if (_step < _steps.length - 1) {
                            _step++;
                          }
                        });
                      },
                      child: Text(
                        _step == _steps.length - 1 ? 'Finish' : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.active,
    required this.done,
  });

  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VoidSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: done
            ? context.palette.primary.withValues(alpha: 0.2)
            : active
            ? context.palette.primary
            : context.palette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: VoidTypography.caption.copyWith(
          color: done || active
              ? context.palette.textPrimary
              : context.palette.textSecondary,
        ),
      ),
    );
  }
}
