/// Sprint 48 — Step 48.27–48.30 Dialogue Clips, Timing, Lip Sync.
class DialogueClip {
  const DialogueClip({
    required this.id,
    required this.shotId,
    required this.characterId,
    required this.text,
    required this.startSeconds,
    required this.endSeconds,
  });

  final String id;
  final String shotId;
  final String characterId;
  final String text;
  final double startSeconds;
  final double endSeconds;

  double get durationSeconds => endSeconds - startSeconds;
}

class LipSyncFrame {
  const LipSyncFrame({
    required this.timestampMs,
    required this.phoneme,
    required this.intensity,
  });

  final int timestampMs;
  final String phoneme;
  final double intensity;
}
