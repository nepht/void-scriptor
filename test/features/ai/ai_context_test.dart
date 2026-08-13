import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_context.dart';
import 'package:void_scriptor/features/ai/application/prompt_composer.dart';
import 'package:void_scriptor/features/ai/application/prompt_compiler.dart';
import 'package:void_scriptor/features/ai/application/preservation_prompt_resolver.dart';

void main() {
  const context = AiContext(
    projectId: 'p1',
    characterContexts: [
      AiCharacterContext(
        characterId: 'c1',
        name: 'Qowner',
        modeName: 'Combat Mode',
        identityDescription: 'Adult male void bearer',
        wardrobeDescription: 'Void Combat Outfit',
        weaponDescription: 'Void Dual Dagger',
        preservationRules: ['Face Lock'],
      ),
    ],
    environmentContext: AiEnvironmentContext(
      environmentId: 'e1',
      name: 'Neo Megacity',
      zone: 'Main Street',
      timeOfDay: 'Noon',
      weather: 'Clear',
      lighting: 'Day',
    ),
    sceneContext: AiSceneContext(
      sceneId: 's1',
      title: 'Megacity Landing',
      durationSeconds: 10,
      beats: [
        AiSceneBeat(
          type: 'action',
          content: 'Qowner descends',
          startSeconds: 0,
          durationSeconds: 2,
        ),
      ],
    ),
    timelineContext: AiTimelineContext(
      durationSeconds: 10,
      sections: [
        AiTimelineSection(
          start: 0,
          end: 2,
          entries: ['Camera: Wide', 'Audio: Wind'],
        ),
      ],
    ),
  );

  test(
    'composer builds target-specific sections and options can omit timeline',
    () {
      final document = PromptComposer().compose(
        context: context,
        target: PromptTarget.video,
        options: const AiContextOptions(includeTimeline: false),
      );
      expect(
        document.sections.map((section) => section.title),
        contains('CHARACTER — QOWNER'),
      );
      expect(
        document.sections.map((section) => section.title),
        isNot(contains('TIMELINE')),
      );
    },
  );

  test('compiler orders enabled sections and reports metadata', () {
    final document = PromptComposer().compose(
      context: context,
      target: PromptTarget.image,
    );
    final compiled = PromptCompiler().compile(document);
    expect(
      compiled.text.indexOf('CHARACTER — QOWNER'),
      lessThan(compiled.text.indexOf('ENVIRONMENT')),
    );
    expect(compiled.characters, greaterThan(100));
  });

  test('preservation resolver maps identity locks to rules', () {
    final rules = PreservationPromptResolver().resolve(
      const PreservationLocks(
        faceLock: true,
        hairLock: true,
        bodyLock: false,
        colorLock: true,
        outfitLock: false,
        weaponLock: true,
      ),
    );
    expect(
      rules,
      contains('Preserve exact facial identity and facial proportions.'),
    );
    expect(rules, contains('Preserve weapon geometry and proportions.'));
    expect(rules, isNot(contains('Preserve body proportions and topology.')));
  });
}
