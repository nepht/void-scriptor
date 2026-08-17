/// Sprint 48 — Step 48.72–48.77 Subtitles, Languages, Translation Memory, Dubbing.
class SubtitleTrack {
  const SubtitleTrack({
    required this.id,
    required this.cinematicId,
    required this.language,
    this.cues = const [],
  });

  final String id;
  final String cinematicId;
  final String language;
  final List<SubtitleCue> cues;
}

class SubtitleCue {
  const SubtitleCue({
    required this.id,
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  final String id;
  final int startMs;
  final int endMs;
  final String text;
}

class DubbingTrack {
  const DubbingTrack({
    required this.id,
    required this.cinematicId,
    required this.language,
    required this.voiceActorId,
  });

  final String id;
  final String cinematicId;
  final String language;
  final String voiceActorId;
}
