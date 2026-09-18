import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/end_to_end_simulation_workflow.dart';

void main() {
  test(
    '112.34 propagates one event through world systems and is replayable',
    () {
      const input = SimulationWorkflowInput(
        eventId: 'eruption-1',
        eventDescription: 'The northern volcano erupts.',
        originLocationId: 'volcano-north',
        destinationLocationId: 'harbor-east',
        factionId: 'ash-court',
        affectedCharacterId: 'qowner',
        commodityId: 'obsidian',
        technologyId: 'seismic-warning',
        storyId: 'chapter-3',
        tick: 12,
      );

      final first = const EndToEndSimulationWorkflow().run(input);
      final replay = const EndToEndSimulationWorkflow().run(input);

      expect(first.seedEvent.id, 'eruption-1');
      expect(
        first.simulationResults,
        containsAll(<String>[
          'travel:volcano-north->harbor-east',
          'location:harbor-east',
          'diplomacy:ash-court',
          'economy:obsidian',
          'rumor:eruption-1',
          'technology:seismic-warning',
        ]),
      );
      expect(first.storyQueries, contains('chapter-3'));
      expect(first.explanations, contains('event:eruption-1'));
      expect(first.replayResults, replay.simulationResults);
      expect(first.replayResults, replay.replayResults);
      expect(first.isAccepted, isTrue);
    },
  );

  test('112.34 fails closed when a required story identity is empty', () {
    expect(
      () => const EndToEndSimulationWorkflow().run(
        const SimulationWorkflowInput(
          eventId: 'eruption-1',
          eventDescription: 'The northern volcano erupts.',
          originLocationId: 'volcano-north',
          destinationLocationId: 'harbor-east',
          factionId: 'ash-court',
          affectedCharacterId: 'qowner',
          commodityId: 'obsidian',
          technologyId: 'seismic-warning',
          storyId: '',
          tick: 12,
        ),
      ),
      throwsArgumentError,
    );
  });
}
