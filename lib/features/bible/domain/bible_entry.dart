import '../../story/domain/canon_status.dart';

enum BibleEntryType {
  overview,
  canonRule,
  faction,
  species,
  location,
  technology,
  powerSystem,
  terminology,
  historicalEvent,
  lore,
  era,
}

class BibleEntry {
  const BibleEntry({
    required this.id,
    required this.projectId,
    required this.type,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.status = CanonStatus.canon,
    this.tags = const [],
  });

  final String id;
  final String projectId;
  final BibleEntryType type;
  final String title;
  final String content;
  final CanonStatus status;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
}
