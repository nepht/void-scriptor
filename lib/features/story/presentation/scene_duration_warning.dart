import 'package:flutter/material.dart';
import '../domain/scene_timeline.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class SceneDurationWarning extends StatelessWidget {
  const SceneDurationWarning({super.key, required this.validation});
  final SceneTimelineValidation validation;
  @override
  Widget build(BuildContext context) {
    if (!validation.isMismatch) return const SizedBox.shrink();
    return Card(
      color: context.palette.warning.withValues(alpha: 0.15),
      child: ListTile(
        leading: Icon(
          Icons.warning_amber_outlined,
          color: context.palette.warning,
        ),
        title: Text(
          'Scene duration mismatch',
          style: TextStyle(color: context.palette.warning),
        ),
        subtitle: Text(
          'Scene: ${validation.sceneDurationSeconds!.toStringAsFixed(1)} sec · Beats: ${validation.totalBeatDuration.toStringAsFixed(1)} sec',
          style: TextStyle(color: context.palette.textSecondary),
        ),
      ),
    );
  }
}
