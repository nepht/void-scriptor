import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/end_to_end_worldbuilding_workflow.dart';

void main() {
  test('112.33 runs the complete worldbuilding evidence chain', () {
    final result = const EndToEndWorldbuildingWorkflow().run(
      const WorldbuildingWorkflowInput(
        cultureId: 'culture-void',
        languageId: 'lang-void',
        mapLocationId: 'island-void',
        calendarId: 'calendar-void',
        characterId: 'character-qowner',
        factionId: 'faction-void',
        creatureId: 'creature-ash',
        artifactId: 'artifact-cube',
        loreId: 'lore-origin',
      ),
    );

    expect(result.workflowScript, isNotEmpty);
    expect(result.crossLinks, hasLength(9));
    expect(result.searchResults, contains('lore-origin'));
    expect(
      result.graphResults,
      containsAll(<String>['character-qowner', 'artifact-cube']),
    );
    expect(result.validationResults, isEmpty);
    expect(result.isAccepted, isTrue);
  });

  test('112.33 rejects incomplete cross-domain identity', () {
    expect(
      () => const EndToEndWorldbuildingWorkflow().run(
        const WorldbuildingWorkflowInput(
          cultureId: '',
          languageId: 'lang-void',
          mapLocationId: 'island-void',
          calendarId: 'calendar-void',
          characterId: 'character-qowner',
          factionId: 'faction-void',
          creatureId: 'creature-ash',
          artifactId: 'artifact-cube',
          loreId: 'lore-origin',
        ),
      ),
      throwsArgumentError,
    );
  });
}
