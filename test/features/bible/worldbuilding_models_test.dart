import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/domain/faction.dart';
import 'package:void_scriptor/features/bible/domain/power_system.dart';
import 'package:void_scriptor/features/bible/domain/species.dart';
import 'package:void_scriptor/features/bible/domain/technology.dart';
import 'package:void_scriptor/features/bible/domain/timeline_era.dart';
import 'package:void_scriptor/features/bible/domain/historical_event.dart';
import 'package:void_scriptor/features/bible/domain/terminology.dart';

void main() {
  test('worldbuilding models preserve their structured fields', () {
    const faction = FactionModel(
      assetId: 'faction-1',
      projectId: 'project-1',
      name: 'Clan Kokuen',
      ideology: 'Preserve the Void',
      status: 'destroyed',
      headquarters: 'Mountain Region',
    );
    const species = SpeciesModel(
      assetId: 'species-1',
      projectId: 'project-1',
      name: 'Voidborn',
      origin: 'The Abyss',
      lifespan: 'Unknown',
    );
    const technology = TechnologyModel(
      assetId: 'technology-1',
      projectId: 'project-1',
      name: 'Void Drive',
      category: 'transport',
      creator: 'Neo Labs',
      limitations: 'Requires a living core',
    );
    const power = PowerSystemModel(
      assetId: 'power-1',
      projectId: 'project-1',
      name: 'Void Black',
      source: 'Abyssal',
      rules: 'Cannot be artificially reproduced',
      limitations: 'Costs memories',
      visualLanguage: 'Black and silver',
    );
    const era = TimelineEraModel(
      id: 'era-1',
      projectId: 'project-1',
      name: 'Neo Megacity Era',
      orderIndex: 3,
      startLabel: 'Year 300',
      endLabel: 'Year 420',
    );

    expect(faction.ideology, 'Preserve the Void');
    expect(species.origin, 'The Abyss');
    expect(technology.limitations, 'Requires a living core');
    expect(power.visualLanguage, 'Black and silver');
    expect(era.orderIndex, 3);

    const term = TerminologyEntryModel(
      id: 'term-1',
      projectId: 'project-1',
      term: 'Void Black',
      definition: 'A rare Void discipline.',
      alternateTerms: 'Black Void',
    );
    const event = HistoricalEventModel(
      id: 'event-1',
      projectId: 'project-1',
      title: 'Fall of Clan Kokuen',
      eraId: 'era-1',
      orderIndex: 4,
    );
    const participant = HistoricalEventParticipantModel(
      id: 'participant-1',
      eventId: 'event-1',
      assetId: 'character-reika',
      role: 'survivor',
    );
    expect(term.alternateTerms, 'Black Void');
    expect(event.eraId, 'era-1');
    expect(participant.role, 'survivor');
  });
}
