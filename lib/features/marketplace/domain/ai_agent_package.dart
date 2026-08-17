/// Sprint 44 — Step 44.7 AI Agent Store, 44.8 Agent Package, 44.9 Agent Manifest.
class AIAgentPackage {
  AIAgentPackage({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.capabilities,
    this.description,
    this.manifestVersion = 1,
  }) {
    if (capabilities.length > 5) {
      throw ArgumentError('An agent cannot have more than 5 capabilities');
    }
  }

  final String id;
  final String name;
  final String version;
  final String author;
  final String? description;
  final Set<String> capabilities;
  final int manifestVersion;

  AIAgentPackage copyWith({
    String? name,
    String? version,
    String? author,
    String? description,
    Set<String>? capabilities,
    int? manifestVersion,
  }) {
    return AIAgentPackage(
      id: id,
      name: name ?? this.name,
      version: version ?? this.version,
      author: author ?? this.author,
      description: description ?? this.description,
      capabilities: capabilities ?? this.capabilities,
      manifestVersion: manifestVersion ?? this.manifestVersion,
    );
  }
}

/// Step 44.10 Agent Capability Manifest.
class AgentCapabilityManifest {
  const AgentCapabilityManifest({required this.capabilities});

  final List<AgentCapabilityDefinition> capabilities;
}

class AgentCapabilityDefinition {
  const AgentCapabilityDefinition({
    required this.id,
    required this.label,
    this.description,
  });

  final String id;
  final String label;
  final String? description;
}

/// Step 44.11 Agent Installation, 44.12 Agent Permission Screen.
enum AgentInstallationState {
  notInstalled,
  downloading,
  installed,
  permissionPending,
  active,
}

enum AgentPermission {
  readProjectData,
  writeProjectData,
  accessAiProvider,
  accessFileSystem,
  sendNotifications,
}
