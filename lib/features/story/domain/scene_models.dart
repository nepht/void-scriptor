class SceneBeatModel {
  const SceneBeatModel({
    required this.id,
    required this.sceneId,
    required this.content,
    this.beatType = 'action',
    this.startSecond,
    this.durationSeconds,
  });
  final String id;
  final String sceneId;
  final String content;
  final String beatType;
  final double? startSecond;
  final double? durationSeconds;
}

class SceneModel {
  const SceneModel({
    required this.id,
    required this.storyId,
    required this.chapterId,
    required this.title,
    required this.sceneNumber,
    this.summary = '',
    this.sceneType = 'standard',
    this.estimatedDurationSeconds,
  });
  final String id;
  final String storyId;
  final String chapterId;
  final String title;
  final int sceneNumber;
  final String summary;
  final String sceneType;
  final double? estimatedDurationSeconds;
}
