class ToolbarContext {
  const ToolbarContext({required this.targetId, required this.intent});

  final String targetId;
  final String intent;
}

class ToolbarAction {
  const ToolbarAction({
    required this.command,
    required this.targetId,
    this.isDestructive = false,
  });

  final String command;
  final String targetId;
  final bool isDestructive;

  @override
  bool operator ==(Object other) =>
      other is ToolbarAction &&
      other.command == command &&
      other.targetId == targetId &&
      other.isDestructive == isDestructive;

  @override
  int get hashCode => Object.hash(command, targetId, isDestructive);
}

class AdaptiveToolbar {
  List<ToolbarAction> actionsFor(ToolbarContext context) {
    switch (context.intent) {
      case 'edit':
        return [
          ToolbarAction(command: 'save', targetId: context.targetId),
          ToolbarAction(command: 'undo', targetId: context.targetId),
        ];
      case 'select':
        return [ToolbarAction(command: 'edit', targetId: context.targetId)];
      default:
        return const [];
    }
  }
}
