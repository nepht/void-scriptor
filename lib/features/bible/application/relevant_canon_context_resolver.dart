import '../domain/bible_entry.dart';
import '../../story/domain/canon_status.dart';

class RelevantCanonContextResolver {
  List<BibleEntry> resolve(
    Iterable<BibleEntry> entries, {
    required String projectId,
    Set<String> entityIds = const {},
    Set<String> tags = const {},
    Set<BibleEntryType> types = const {},
    bool includeDraft = true,
    bool includeAlternate = true,
    bool includeDeprecated = false,
    int limit = 24,
  }) {
    final normalizedTags = tags.map(_normalize).toSet();
    final scored = <({BibleEntry entry, int score, int index})>[];
    var index = 0;
    for (final entry in entries) {
      if (entry.projectId != projectId) {
        index++;
        continue;
      }
      if (types.isNotEmpty && !types.contains(entry.type)) {
        index++;
        continue;
      }
      if (!_statusIncluded(
        entry.status,
        includeDraft: includeDraft,
        includeAlternate: includeAlternate,
        includeDeprecated: includeDeprecated,
      )) {
        index++;
        continue;
      }
      final entryTags = entry.tags.map(_normalize).toSet();
      final entityMatch = entityIds.any(
        (id) => entry.id == id || entryTags.contains(_normalize(id)),
      );
      final tagMatch = normalizedTags.intersection(entryTags).isNotEmpty;
      final global =
          entry.type == BibleEntryType.overview ||
          entry.type == BibleEntryType.canonRule;
      if (!entityMatch && !tagMatch && !global) {
        index++;
        continue;
      }
      scored.add((
        entry: entry,
        score:
            (entityMatch ? 100 : 0) +
            (tagMatch ? 50 : 0) +
            (global ? 25 : 0) +
            (entry.status == CanonStatus.canon ? 10 : 0),
        index: index,
      ));
      index++;
    }
    scored.sort((a, b) {
      final score = b.score.compareTo(a.score);
      return score == 0 ? a.index.compareTo(b.index) : score;
    });
    return scored.take(limit).map((item) => item.entry).toList(growable: false);
  }

  bool _statusIncluded(
    CanonStatus status, {
    required bool includeDraft,
    required bool includeAlternate,
    required bool includeDeprecated,
  }) => switch (status) {
    CanonStatus.canon || CanonStatus.whatIf => true,
    CanonStatus.draft => includeDraft,
    CanonStatus.alternate => includeAlternate,
    CanonStatus.deprecated => includeDeprecated,
  };

  String _normalize(String value) => value.trim().toLowerCase();
}
