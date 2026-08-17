import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 48.65 — Preview Modes.
///
/// Storyboard, Animatic, Low Quality, Real-Time, Final Preview.
class PreviewModesScreen extends StatefulWidget {
  const PreviewModesScreen({super.key});

  @override
  State<PreviewModesScreen> createState() => _PreviewModesScreenState();
}

class _PreviewModesScreenState extends State<PreviewModesScreen> {
  static const _modes = <String>[
    'Storyboard',
    'Animatic',
    'Low Quality',
    'Real-Time',
    'Final Preview',
  ];

  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Modes'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: VoidSpacing.sm,
                runSpacing: VoidSpacing.sm,
                children: [
                  for (var i = 0; i < _modes.length; i++)
                    ChoiceChip(
                      label: Text(_modes[i]),
                      selected: i == _selected,
                      onSelected: (_) => setState(() => _selected = i),
                    ),
                ],
              ),
              const SizedBox(height: VoidSpacing.lg),
              Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.palette.borderSoft),
                ),
                child: Center(
                  child: Text(
                    '${_modes[_selected]} view',
                    style: VoidTypography.headingMedium.copyWith(
                      color: context.palette.textSecondary,
                    ),
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
