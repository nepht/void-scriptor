import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 45.65 — Merge Preview.
///
/// Sebelum merge: tampilkan diff antar universe + tombol Confirm Merge.
class MergePreviewScreen extends StatelessWidget {
  const MergePreviewScreen({super.key});

  static const _diffs = <(String, String, String)>[
    ('Character', 'Kael (base)', 'Kael (variant)'),
    ('Location', 'North Vale', 'North Vale (rebuilt)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge Preview'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Changes to merge',
                style: VoidTypography.headingMedium.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.md),
              for (final (type, from, to) in _diffs)
                _DiffTile(type: type, from: from, to: to),
              const SizedBox(height: VoidSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Confirm Merge'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiffTile extends StatelessWidget {
  const _DiffTile({required this.type, required this.from, required this.to});

  final String type;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.surface,
      margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
      child: ListTile(
        title: Text(type),
        subtitle: Text('$from  →  $to'),
        leading: const Icon(Icons.compare_arrows),
      ),
    );
  }
}
