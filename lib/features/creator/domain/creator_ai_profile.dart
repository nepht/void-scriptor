/// Sprint 43 — Step 43.9 Creator AI Profile.
///
/// The AI never automatically uses all creator data as context for every
/// request; retrieval is on-demand per need (see [AiContextLayer]).
enum AIControlLevel { suggest, assist, autonomous }

class CreatorAIProfile {
  const CreatorAIProfile({
    required this.creatorId,
    required this.assistantName,
    this.preferredWorkflows = const [],
    this.enabledAgentIds = const [],
    this.controlLevel = AIControlLevel.suggest,
  });

  final String creatorId;
  final String assistantName;
  final List<String> preferredWorkflows;
  final List<String> enabledAgentIds;
  final AIControlLevel controlLevel;

  CreatorAIProfile copyWith({
    String? assistantName,
    List<String>? preferredWorkflows,
    List<String>? enabledAgentIds,
    AIControlLevel? controlLevel,
  }) {
    return CreatorAIProfile(
      creatorId: creatorId,
      assistantName: assistantName ?? this.assistantName,
      preferredWorkflows: preferredWorkflows ?? this.preferredWorkflows,
      enabledAgentIds: enabledAgentIds ?? this.enabledAgentIds,
      controlLevel: controlLevel ?? this.controlLevel,
    );
  }

  Map<String, dynamic> toJson() => {
    'creatorId': creatorId,
    'assistantName': assistantName,
    'preferredWorkflows': preferredWorkflows,
    'enabledAgentIds': enabledAgentIds,
    'controlLevel': controlLevel.name,
  };

  factory CreatorAIProfile.fromJson(Map<String, dynamic> json) {
    return CreatorAIProfile(
      creatorId: json['creatorId'] as String,
      assistantName: json['assistantName'] as String,
      preferredWorkflows: (json['preferredWorkflows'] as List<dynamic>? ?? [])
          .cast<String>(),
      enabledAgentIds: (json['enabledAgentIds'] as List<dynamic>? ?? [])
          .cast<String>(),
      controlLevel: AIControlLevel.values.firstWhere(
        (v) => v.name == json['controlLevel'],
        orElse: () => AIControlLevel.suggest,
      ),
    );
  }
}
