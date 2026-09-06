enum EmergentSignalKind { alert, resource }

enum EmergentActionKind { flee, gather, guard, observe }

class EmergentAgent {
  const EmergentAgent({
    required this.id,
    required this.energy,
    required this.alertness,
  });

  final String id;
  final double energy;
  final double alertness;

  EmergentAgent copyWith({double? energy, double? alertness}) => EmergentAgent(
    id: id,
    energy: energy ?? this.energy,
    alertness: alertness ?? this.alertness,
  );
}

class EmergentSignal {
  const EmergentSignal({required this.sourceId, required this.kind});

  final String sourceId;
  final EmergentSignalKind kind;
}

class EmergentAction {
  const EmergentAction({required this.agentId, required this.kind});

  final String agentId;
  final EmergentActionKind kind;
}

class EmergentStepResult {
  const EmergentStepResult({
    required this.actions,
    required this.nextAgents,
    required this.trace,
  });

  final List<EmergentAction> actions;
  final List<EmergentAgent> nextAgents;
  final List<String> trace;
}

class EmergentBehaviorEngine {
  const EmergentBehaviorEngine({this.maxActionsPerStep = 100});

  final int maxActionsPerStep;

  EmergentStepResult step({
    required List<EmergentAgent> agents,
    required List<EmergentSignal> signals,
  }) {
    final signalByAgent = <String, EmergentSignalKind>{
      for (final signal in signals) signal.sourceId: signal.kind,
    };
    final actions = <EmergentAction>[];
    final nextAgents = <EmergentAgent>[];
    final trace = <String>[];
    final limit = maxActionsPerStep < 0 ? 0 : maxActionsPerStep;

    for (final agent in agents) {
      if (actions.length >= limit) break;
      final kind = _actionFor(agent, signalByAgent[agent.id]);
      actions.add(EmergentAction(agentId: agent.id, kind: kind));
      trace.add('${agent.id}:${_label(kind)}');
      nextAgents.add(
        agent.copyWith(energy: (agent.energy - _energyCost(kind)).clamp(0, 1)),
      );
    }

    return EmergentStepResult(
      actions: List.unmodifiable(actions),
      nextAgents: List.unmodifiable(nextAgents),
      trace: List.unmodifiable(trace),
    );
  }

  EmergentActionKind _actionFor(
    EmergentAgent agent,
    EmergentSignalKind? signal,
  ) {
    if (signal == EmergentSignalKind.alert) return EmergentActionKind.flee;
    if (signal == EmergentSignalKind.resource) return EmergentActionKind.gather;
    if (agent.alertness >= .6) return EmergentActionKind.guard;
    return EmergentActionKind.observe;
  }

  double _energyCost(EmergentActionKind kind) => switch (kind) {
    EmergentActionKind.flee => .2,
    EmergentActionKind.gather => .1,
    EmergentActionKind.guard => .05,
    EmergentActionKind.observe => .01,
  };

  String _label(EmergentActionKind kind) => switch (kind) {
    EmergentActionKind.flee => 'alert',
    EmergentActionKind.gather => 'resource',
    EmergentActionKind.guard => 'guard',
    EmergentActionKind.observe => 'observe',
  };
}
