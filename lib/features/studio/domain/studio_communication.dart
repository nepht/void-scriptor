enum StudioMessageType { task, status, decision, chat }

class StudioMessage {
  const StudioMessage({required this.type, required this.body});
  final StudioMessageType type;
  final String body;
}

class StudioMessageChannel {
  StudioMessageChannel({required this.maxMessages}) : _messages = [];
  final int maxMessages;
  final List<StudioMessage> _messages;
  List<StudioMessage> get messages => List.unmodifiable(_messages);

  bool send(StudioMessage message) {
    if (message.type == StudioMessageType.chat ||
        _messages.length >= maxMessages ||
        message.body.trim().isEmpty) {
      return false;
    }
    _messages.add(message);
    return true;
  }
}

class MeetingOutput {
  const MeetingOutput({required this.decisions, required this.actions});
  final List<String> decisions;
  final List<String> actions;
}

class ProductionMeeting {
  ProductionMeeting(this.title) : _decisions = [], _actions = [];
  final String title;
  final List<String> _decisions;
  final List<String> _actions;
  void addDecision(String value) => _decisions.add(value);
  void addAction(String value) => _actions.add(value);
  MeetingOutput get output => MeetingOutput(
    decisions: List.unmodifiable(_decisions),
    actions: List.unmodifiable(_actions),
  );
}

class DailyStudioBrief {
  const DailyStudioBrief({required this.attentionItems});
  final List<String> attentionItems;
  factory DailyStudioBrief.from(MeetingOutput output) =>
      DailyStudioBrief(attentionItems: output.actions);
}
