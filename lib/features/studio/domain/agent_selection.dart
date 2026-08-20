class StudioAgentProfile {
  const StudioAgentProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.personality,
    required this.authority,
    required this.capabilities,
  });

  final String id;
  final String name;
  final String role;
  final String personality;
  final double authority;
  final Set<String> capabilities;
}

class AgentSelector {
  AgentSelector(Iterable<StudioAgentProfile> agents)
    : _agents = List.unmodifiable(agents);

  final List<StudioAgentProfile> _agents;

  double score(StudioAgentProfile agent, String capability) {
    if (!agent.capabilities.contains(capability)) return 0;
    return 1 + agent.authority;
  }

  StudioAgentProfile? select(String capability, {String? overrideAgentId}) {
    if (overrideAgentId != null) {
      for (final agent in _agents) {
        if (agent.id == overrideAgentId &&
            agent.capabilities.contains(capability)) {
          return agent;
        }
      }
      return null;
    }

    StudioAgentProfile? selected;
    for (final agent in _agents) {
      if (score(agent, capability) > score(selected ?? agent, capability)) {
        selected = agent;
      } else if (selected == null && agent.capabilities.contains(capability)) {
        selected = agent;
      }
    }
    return selected;
  }
}
