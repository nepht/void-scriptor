import 'package:flutter/material.dart';
import '../domain/scene_timeline.dart';
import '../../../design_system/colors/void_colors.dart';

class SceneDurationWarning extends StatelessWidget {
  const SceneDurationWarning({super.key, required this.validation});
  final SceneTimelineValidation validation;
  @override
  Widget build(BuildContext context) {
    if (!validation.isMismatch) return const SizedBox.shrink();
    return Card(
      color: VoidColors.warning.withValues(alpha: 0.15),
      child: ListTile(
        leading: const Icon(
          Icons.warning_amber_outlined,
          color: VoidColors.warning,
        ),
        title: const Text(
          'Scene duration mismatch',
          style: TextStyle(color: VoidColors.warning),
        ),
        subtitle: Text(
          'Scene: ${validation.sceneDurationSeconds!.toStringAsFixed(1)} sec · Beats: ${validation.totalBeatDuration.toStringAsFixed(1)} sec',
          style: const TextStyle(color: VoidColors.textSecondary),
        ),
      ),
    );
  }
}
