import 'agent_definition.dart';

/// Agent working memory + turn log (Step 39.5).
class AgentMemory {
  final Map<String, String> _working = {};
  final List<AgentTurn> _turns = [];

  void set(String key, String value) => _working[key] = value;

  String? get(String key) => _working[key];

  void appendTurn({required String role, required String content}) =>
      _turns.add(AgentTurn(role: role, content: content));

  List<AgentTurn> get turns => List.unmodifiable(_turns);
}
