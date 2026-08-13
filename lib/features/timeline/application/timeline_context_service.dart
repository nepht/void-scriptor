import 'dart:convert';
import '../domain/timeline_model.dart';

class ResolvedTimelineContext {
  const ResolvedTimelineContext({
    required this.timeSeconds,
    required this.activeClipIds,
  });
  final double timeSeconds;
  final List<String> activeClipIds;
}

ResolvedTimelineContext resolveTimelineContext({
  required double timeSeconds,
  required List<TimelineClipModel> clips,
}) => ResolvedTimelineContext(
  timeSeconds: timeSeconds,
  activeClipIds: clips
      .where(
        (clip) =>
            timeSeconds >= clip.startSeconds && timeSeconds < clip.endSeconds,
      )
      .map((clip) => clip.id)
      .toList(),
);

String exportTimelineJson({
  required String sceneId,
  required double durationSeconds,
  required int frameRate,
  required List<Map<String, dynamic>> tracks,
  required List<Map<String, dynamic>> clips,
}) => jsonEncode({
  'sceneId': sceneId,
  'duration': durationSeconds,
  'fps': frameRate,
  'tracks': tracks,
  'clips': clips,
});
