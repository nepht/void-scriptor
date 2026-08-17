import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/ai_action_mode.dart';

void main() {
  group('AiActionMode', () {
    test('exposes the seven canonical modes in order', () {
      expect(AiActionMode.values.map((e) => e.label), [
        'ASK',
        'CREATE',
        'EDIT',
        'ANALYZE',
        'PLAN',
        'REVIEW',
        'AUTOMATE',
      ]);
    });

    test('provides example prompts', () {
      expect(AiActionMode.create.example, contains('storyboard'));
      expect(AiActionMode.review.example, contains('canon'));
      expect(AiActionMode.plan.example, contains('production plan'));
    });

    test('parses from label case-insensitively and falls back to ASK', () {
      expect(AiActionMode.fromLabel('create'), AiActionMode.create);
      expect(AiActionMode.fromLabel('REVIEW'), AiActionMode.review);
      expect(AiActionMode.fromLabel('x'), AiActionMode.ask);
    });
  });
}
