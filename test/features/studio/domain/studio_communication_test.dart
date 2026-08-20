import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/studio_communication.dart';

void main() {
  test('uses typed messages and rejects unbounded free-form chat', () {
    final channel = StudioMessageChannel(maxMessages: 2);
    expect(
      channel.send(
        const StudioMessage(type: StudioMessageType.task, body: 'Draft'),
      ),
      isTrue,
    );
    expect(
      channel.send(
        const StudioMessage(type: StudioMessageType.status, body: 'Ready'),
      ),
      isTrue,
    );
    expect(
      channel.send(
        const StudioMessage(type: StudioMessageType.chat, body: 'Again'),
      ),
      isFalse,
    );
    expect(channel.messages.length, 2);
  });

  test('meeting output and daily brief summarize finite attention items', () {
    final meeting = ProductionMeeting('Episode 1')
      ..addDecision('Use the cold open')
      ..addAction('Write scene 1');
    expect(meeting.output.decisions, contains('Use the cold open'));
    expect(
      DailyStudioBrief.from(meeting.output).attentionItems,
      contains('Write scene 1'),
    );
  });
}
