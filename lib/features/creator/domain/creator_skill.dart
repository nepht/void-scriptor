/// Sprint 43 — Step 43.21 Skill Profile, 43.22 Skill Evidence.
class CreatorSkill {
  const CreatorSkill({
    required this.creatorId,
    required this.skillId,
    required this.level,
    this.experience = 0.0,
    this.verified = false,
  });

  final String creatorId;
  final String skillId;
  final int level;
  final double experience;
  final bool verified;

  CreatorSkill copyWith({int? level, double? experience, bool? verified}) {
    return CreatorSkill(
      creatorId: creatorId,
      skillId: skillId,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      verified: verified ?? this.verified,
    );
  }
}
