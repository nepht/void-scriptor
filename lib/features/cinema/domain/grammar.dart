/// Sprint 48 — Step 48.16–48.18 Cinematic Grammar, Continuity Rules.
enum GrammarRule {
  shotReverseShot,
  thirtyDegree,
  eyelineMatch,
  ruleOfThirds,
  talkingHeads,
  actionAxis,
}

class ContinuityRule {
  const ContinuityRule({
    required this.id,
    required this.description,
    required this.allowBreak,
  });

  final String id;
  final String description;
  final bool allowBreak;
}

class RuleBreak {
  const RuleBreak({
    required this.id,
    required this.ruleId,
    required this.reason,
    required this.intentional,
  });

  final String id;
  final String ruleId;
  final String reason;
  final bool intentional;
}
