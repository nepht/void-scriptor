import '../../story/domain/canon_status.dart';

class HistoricalEventModel {
  const HistoricalEventModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.orderIndex,
    this.eraId,
    this.description = '',
    this.status = CanonStatus.canon,
  });

  final String id;
  final String projectId;
  final String? eraId;
  final String title;
  final String description;
  final int orderIndex;
  final CanonStatus status;
}

class HistoricalEventParticipantModel {
  const HistoricalEventParticipantModel({
    required this.id,
    required this.eventId,
    required this.assetId,
    this.role = 'participant',
  });

  final String id;
  final String eventId;
  final String assetId;
  final String role;
}
