import 'package:flutter/material.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class SceneBeatEditor extends StatelessWidget {
  const SceneBeatEditor({
    super.key,
    required this.beats,
    required this.onReordered,
    required this.onDelete,
  });
  final List<SceneBeatEditorItem> beats;
  final ValueChanged<List<SceneBeatEditorItem>> onReordered;
  final ValueChanged<SceneBeatEditorItem> onDelete;
  @override
  Widget build(BuildContext context) => ReorderableListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: beats.length,
    onReorderItem: (oldIndex, newIndex) {
      final next = [...beats];
      final item = next.removeAt(oldIndex);
      next.insert(newIndex, item);
      onReordered(next);
    },
    itemBuilder: (context, index) {
      final beat = beats[index];
      final start = beat.startSecond == null
          ? '--'
          : beat.startSecond!.toStringAsFixed(1).padLeft(4, '0');
      return Card(
        key: ValueKey(beat.id),
        color: context.palette.panelSecondary,
        child: ListTile(
          leading: Text(
            start,
            style: TextStyle(
              color: context.palette.primaryBright,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          title: Text(
            beat.content,
            style: TextStyle(color: context.palette.textPrimary),
          ),
          subtitle: Text(
            '${beat.beatType.toUpperCase()}  ·  ${beat.durationSeconds?.toStringAsFixed(1) ?? '—'} sec',
            style: TextStyle(color: context.palette.textMuted, fontSize: 11),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => onDelete(beat),
          ),
        ),
      );
    },
  );
}

class SceneBeatEditorItem {
  const SceneBeatEditorItem({
    required this.id,
    required this.content,
    required this.beatType,
    this.startSecond,
    this.durationSeconds,
  });
  final String id;
  final String content;
  final String beatType;
  final double? startSecond;
  final double? durationSeconds;
}
