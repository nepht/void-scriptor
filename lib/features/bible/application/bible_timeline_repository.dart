import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../../../database/project/tables/bible_timeline.dart' as schema;
import '../domain/historical_event.dart' as event_domain;
import '../domain/terminology.dart' as terminology_domain;
import '../domain/timeline_era.dart' as era_domain;

part 'bible_timeline_repository.g.dart';

@DriftAccessor(
  tables: [
    schema.TerminologyEntries,
    schema.TimelineEras,
    schema.HistoricalEvents,
    schema.HistoricalEventParticipants,
  ],
)
class BibleTimelineRepository extends DatabaseAccessor<ProjectDatabase>
    with _$BibleTimelineRepositoryMixin {
  BibleTimelineRepository(super.database);

  Future<void> saveTerminology(terminology_domain.TerminologyEntryModel item) =>
      into(terminologyEntries).insertOnConflictUpdate(
        TerminologyEntriesCompanion.insert(
          id: item.id,
          projectId: item.projectId,
          term: item.term,
          definition: item.definition,
          category: Value(item.category),
          alternateTerms: Value(item.alternateTerms),
          caseSensitive: Value(item.caseSensitive),
        ),
      );

  Future<void> saveEra(era_domain.TimelineEraModel item) =>
      into(timelineEras).insertOnConflictUpdate(
        TimelineErasCompanion.insert(
          id: item.id,
          projectId: item.projectId,
          name: item.name,
          description: Value(item.description),
          orderIndex: item.orderIndex,
          startLabel: Value(item.startLabel),
          endLabel: Value(item.endLabel),
        ),
      );

  Future<void> saveHistoricalEvent(event_domain.HistoricalEventModel item) =>
      into(historicalEvents).insertOnConflictUpdate(
        HistoricalEventsCompanion.insert(
          id: item.id,
          projectId: item.projectId,
          eraId: Value(item.eraId),
          title: item.title,
          description: Value(item.description),
          orderIndex: item.orderIndex,
          canonStatus: Value(item.status.name),
        ),
      );

  Future<void> saveParticipant(
    event_domain.HistoricalEventParticipantModel item,
  ) => into(historicalEventParticipants).insertOnConflictUpdate(
    HistoricalEventParticipantsCompanion.insert(
      id: item.id,
      eventId: item.eventId,
      assetId: item.assetId,
      role: Value(item.role),
    ),
  );

  Future<List<era_domain.TimelineEraModel>> listEras(String projectId) async {
    final rows =
        await (select(timelineEras)
              ..where((item) => item.projectId.equals(projectId))
              ..orderBy([(item) => OrderingTerm(expression: item.orderIndex)]))
            .get();
    return rows
        .map(
          (row) => era_domain.TimelineEraModel(
            id: row.id,
            projectId: row.projectId,
            name: row.name,
            description: row.description,
            orderIndex: row.orderIndex,
            startLabel: row.startLabel,
            endLabel: row.endLabel,
          ),
        )
        .toList(growable: false);
  }

  Future<List<event_domain.HistoricalEventParticipantModel>> participantsFor(
    String eventId,
  ) async {
    final rows = await (select(
      historicalEventParticipants,
    )..where((item) => item.eventId.equals(eventId))).get();
    return rows
        .map(
          (row) => event_domain.HistoricalEventParticipantModel(
            id: row.id,
            eventId: row.eventId,
            assetId: row.assetId,
            role: row.role,
          ),
        )
        .toList(growable: false);
  }
}
