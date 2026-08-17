import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 46.90 — Event Feed.
///
/// Panel berisi timeline event dunia (jam + deskripsi).
class EventFeedScreen extends ConsumerWidget {
  const EventFeedScreen({super.key});

  static const _events = <(String, String)>[
    ('12:31', 'Trade route reopened.'),
    ('11:48', 'Void storm detected.'),
    ('10:22', 'Kokuen patrol entered Region 7.'),
    ('09:41', 'Food price increased 4.2%.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final worldState = ref.watch(worldProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('World Events'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          itemCount: _events.length,
          separatorBuilder: (_, __) => const SizedBox(height: VoidSpacing.sm),
          itemBuilder: (context, index) {
            final (time, desc) = _events[index];
            return _EventTile(time: time, description: desc);
          },
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.time, required this.description});

  final String time;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VoidSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: VoidTypography.label.copyWith(
              color: context.palette.primary,
            ),
          ),
          const SizedBox(width: VoidSpacing.md),
          Expanded(
            child: Text(
              description,
              style: VoidTypography.body.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
