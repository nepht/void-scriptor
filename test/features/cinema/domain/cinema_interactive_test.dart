import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/domain/animation.dart';
import 'package:void_scriptor/features/cinema/domain/environment_timeline.dart';
import 'package:void_scriptor/features/cinema/domain/storyboard.dart';
import 'package:void_scriptor/features/cinema/domain/choice.dart';

void main() {
  group('AnimationLayer', () {
    test('holds animation layer constraints', () {
      const layer = AnimationLayer(
        id: 'l1',
        name: 'body',
        priority: 1,
        weight: 0.8,
      );
      expect(layer.name, 'body');
      expect(layer.priority, 1);
      expect(layer.weight, 0.8);
    });
  });

  group('EnvironmentTimeline', () {
    test('holds time-of-day track', () {
      const e = EnvironmentTimeline(
        id: 'e1',
        cinematicId: 'c1',
        timeOfDay: 'dusk',
      );
      expect(e.timeOfDay, 'dusk');
    });
  });

  group('WeatherTrack', () {
    test('holds weather state', () {
      const w = WeatherTrack(
        id: 'w1',
        environmentTimelineId: 'e1',
        condition: 'storm',
      );
      expect(w.condition, 'storm');
    });
  });

  group('Storyboard', () {
    test('holds storyboard metadata', () {
      final sb = Storyboard(
        id: 'sb1',
        cinematicId: 'c1',
        panels: [
          const StoryboardPanel(
            id: 'p1',
            description: 'Wide establishing shot',
            frame: 0,
          ),
        ],
      );
      expect(sb.panels.first.description, contains('establishing'));
    });
  });

  group('ChoiceNode', () {
    test('holds choice with conditions', () {
      const choice = ChoiceNode(
        id: 'cn1',
        prompt: 'Accept the Void?',
        choices: [
          ChoiceOption(
            id: 'o1',
            label: 'Yes',
            consequenceId: 'branch-void',
            condition: 'intent >= 50',
          ),
          ChoiceOption(
            id: 'o2',
            label: 'No',
            consequenceId: 'branch-human',
            condition: 'intent < 50',
          ),
        ],
      );
      expect(choice.choices, hasLength(2));
      expect(choice.choices.first.consequenceId, 'branch-void');
    });
  });

  group('QuickTimeEvent', () {
    test('holds QTE configuration', () {
      const qte = QuickTimeEvent(
        id: 'q1',
        prompt: 'Press SPACE',
        windowMs: 1500,
      );
      expect(qte.windowMs, 1500);
      expect(qte.prompt, contains('SPACE'));
    });
  });
}
