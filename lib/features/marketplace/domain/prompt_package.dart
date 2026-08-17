/// Sprint 44 — Step 44.13 Prompt Marketplace.
class PromptPackage {
  const PromptPackage({
    required this.id,
    required this.title,
    required this.promptText,
    required this.target,
    this.description,
    this.tags = const [],
    this.exampleOutputs = const [],
  });

  final String id;
  final String title;
  final String promptText;
  final String target;
  final String? description;
  final List<String> tags;
  final List<String> exampleOutputs;
}

/// Step 44.14 Workflow Marketplace.
class WorkflowPackage {
  const WorkflowPackage({
    required this.id,
    required this.title,
    required this.description,
    required this.workflowSteps,
    this.inputSchema,
    this.outputSchema,
  });

  final String id;
  final String title;
  final String description;
  final List<WorkflowStep> workflowSteps;
  final String? inputSchema;
  final String? outputSchema;
}

class WorkflowStep {
  const WorkflowStep({
    required this.order,
    required this.action,
    this.inputMapping,
    this.outputMapping,
  });

  final int order;
  final String action;
  final Map<String, String>? inputMapping;
  final Map<String, String>? outputMapping;
}

/// Step 44.15 Review System, 44.16 Rating System.
class MarketplaceReview {
  const MarketplaceReview({
    required this.id,
    required this.itemId,
    required this.creatorId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  final String id;
  final String itemId;
  final String creatorId;
  final double rating;
  final String? comment;
  final DateTime? createdAt;
}
