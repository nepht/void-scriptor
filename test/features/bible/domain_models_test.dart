import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/domain/bible_domain_models.dart';
import 'package:void_scriptor/features/bible/domain/canon_status.dart';

void main() {
  group('Sprint 21 domain models', () {
    test('FactionModel preserves identity, collections, and canon status in JSON', () {
      final model = FactionModel(
        id: 'f1',
        name: 'The Archivists',
        description: 'Keepers of forbidden records',
        goals: const ['Preserve history'],
        members: const ['c1'],
        territories: const ['The Vault'],
        canonStatus: CanonStatus.canonical,
      );

      final restored = FactionModel.fromJson(model.toJson());

      expect(restored, model);
      expect(restored.canonStatus, CanonStatus.canonical);
      expect(restored.goals, ['Preserve history']);
    });

    test('simple entity models round trip with defaults', () {
      expect(SpeciesModel.fromJson(SpeciesModel(id: 's1', name: 'Auralith').toJson()), SpeciesModel(id: 's1', name: 'Auralith'));
      expect(TechnologyModel.fromJson(TechnologyModel(id: 't1', name: 'Null Drive').toJson()), TechnologyModel(id: 't1', name: 'Null Drive'));
      expect(PowerSystemModel.fromJson(PowerSystemModel(id: 'ps1', name: 'Resonance').toJson()), PowerSystemModel(id: 'ps1', name: 'Resonance'));
      expect(PowerAbilityModel.fromJson(PowerAbilityModel(id: 'pa1', name: 'Echo Step', powerSystemId: 'ps1').toJson()), PowerAbilityModel(id: 'pa1', name: 'Echo Step', powerSystemId: 'ps1'));
      expect(TerminologyEntryModel.fromJson(TerminologyEntryModel(id: 'term1', term: 'The Veil', definition: 'A boundary').toJson()), TerminologyEntryModel(id: 'term1', term: 'The Veil', definition: 'A boundary'));
      expect(TimelineEraModel.fromJson(TimelineEraModel(id: 'era1', name: 'First Age').toJson()), TimelineEraModel(id: 'era1', name: 'First Age'));
      expect(HistoricalEventParticipantModel.fromJson(HistoricalEventParticipantModel(id: 'participant1', eventId: 'event1', entityId: 'f1', role: 'Instigator').toJson()), HistoricalEventParticipantModel(id: 'participant1', eventId: 'event1', entityId: 'f1', role: 'Instigator'));
      expect(HistoricalEventModel.fromJson(HistoricalEventModel(id: 'event1', title: 'The Sundering').toJson()), HistoricalEventModel(id: 'event1', title: 'The Sundering'));
    });

    test('HistoricalEventModel round trips typed participants and date', () {
      final event = HistoricalEventModel(
        id: 'event1',
        title: 'The Sundering',
        date: DateTime.utc(2200, 4, 5),
        eraId: 'era1',
        participants: [
          HistoricalEventParticipantModel(
            id: 'participant1',
            eventId: 'event1',
            entityId: 'f1',
            role: 'Instigator',
          ),
        ],
      );

      expect(HistoricalEventModel.fromJson(event.toJson()), event);
    });
  });
}
