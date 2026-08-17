import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/creator_ai_profile.dart';

void main() {
  group('AIControlLevel', () {
    test('exposes the three canonical levels in order', () {
      expect(AIControlLevel.values.map((e) => e.name), [
        'suggest',
        'assist',
        'autonomous',
      ]);
    });
  });

  group('CreatorAIProfile', () {
    test('holds assistant identity and control level', () {
      const profile = CreatorAIProfile(
        creatorId: 'creator-1',
        assistantName: 'Scribe',
        preferredWorkflows: ['storyboard', 'canon-check'],
        enabledAgentIds: ['agent-1'],
        controlLevel: AIControlLevel.assist,
      );
      expect(profile.assistantName, 'Scribe');
      expect(profile.controlLevel, AIControlLevel.assist);
      expect(profile.preferredWorkflows, ['storyboard', 'canon-check']);
    });

    test('copyWith updates fields', () {
      const profile = CreatorAIProfile(
        creatorId: 'creator-1',
        assistantName: 'Scribe',
      );
      final updated = profile.copyWith(
        assistantName: 'Oracle',
        controlLevel: AIControlLevel.autonomous,
      );
      expect(updated.assistantName, 'Oracle');
      expect(updated.controlLevel, AIControlLevel.autonomous);
      expect(updated.creatorId, 'creator-1');
    });

    test('toJson/fromJson roundtrip with defaults', () {
      const profile = CreatorAIProfile(
        creatorId: 'creator-1',
        assistantName: 'Scribe',
      );
      final restored = CreatorAIProfile.fromJson(profile.toJson());
      expect(restored.creatorId, profile.creatorId);
      expect(restored.assistantName, profile.assistantName);
      expect(restored.controlLevel, AIControlLevel.suggest);
      expect(restored.enabledAgentIds, isEmpty);
    });
  });
}
