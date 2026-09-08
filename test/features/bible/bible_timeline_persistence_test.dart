import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/bible/application/bible_timeline_repository.dart';
import 'package:void_scriptor/features/bible/domain/historical_event.dart';
import 'package:void_scriptor/features/bible/domain/terminology.dart';
import 'package:void_scriptor/features/bible/domain/timeline_era.dart';

void main() {
  test(
    'terminology eras and historical participants survive restart',
    () async {
      final root = await Directory.systemTemp.createTemp('s21-history-');
      addTearDown(() => root.delete(recursive: true));
      final dbPath = '${root.path}/project.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      final first = await service.open(dbPath);
      final repository = BibleTimelineRepository(first);
      await repository.saveTerminology(
        const TerminologyEntryModel(
          id: 'term-1',
          projectId: 'project-1',
          term: 'Void Black',
          definition: 'A rare Void discipline.',
        ),
      );
      await repository.saveEra(
        const TimelineEraModel(
          id: 'era-1',
          projectId: 'project-1',
          name: 'Neo Era',
          orderIndex: 2,
        ),
      );
      await repository.saveHistoricalEvent(
        const HistoricalEventModel(
          id: 'event-1',
          projectId: 'project-1',
          eraId: 'era-1',
          title: 'Fall of Clan Kokuen',
          orderIndex: 1,
        ),
      );
      await repository.saveParticipant(
        const HistoricalEventParticipantModel(
          id: 'participant-1',
          eventId: 'event-1',
          assetId: 'reika-1',
          role: 'survivor',
        ),
      );
      await first.close();

      final second = await service.open(dbPath);
      addTearDown(second.close);
      final reopened = BibleTimelineRepository(second);
      final eras = await reopened.listEras('project-1');
      final participants = await reopened.participantsFor('event-1');

      expect(second.schemaVersion, 60);
      expect(eras.single.name, 'Neo Era');
      expect(participants.single.role, 'survivor');
      expect(participants.single.assetId, 'reika-1');
    },
  );
}
