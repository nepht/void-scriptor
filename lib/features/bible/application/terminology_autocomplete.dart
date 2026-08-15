import '../domain/terminology.dart';

/// Terminology autocomplete (Step 21.41).
///
/// The composer needs fast, prefix-based suggestions so writers see the
/// correct in-world spelling. Matching is case-insensitive unless a term is
/// flagged `caseSensitive`, and alternate spellings/aliases are searched too.
class TerminologyAutocomplete {
  const TerminologyAutocomplete();

  List<TerminologyEntryModel> suggest(
    Iterable<TerminologyEntryModel> entries, {
    required String query,
    int limit = 8,
  }) {
    final needle = query.trim();
    if (needle.isEmpty) return const [];

    final scored = <({TerminologyEntryModel entry, int score})>[];
    for (final entry in entries) {
      final score = _score(entry, needle);
      if (score > 0) scored.add((entry: entry, score: score));
    }
    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore == 0 ? a.entry.term.compareTo(b.entry.term) : byScore;
    });
    return scored.take(limit).map((item) => item.entry).toList(growable: false);
  }

  int _score(TerminologyEntryModel entry, String needle) {
    final term = entry.term;
    final alternates = entry.alternateTerms
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    if (entry.caseSensitive) {
      if (term.startsWith(needle)) return 100;
      if (term.contains(needle)) return 50;
      for (final alt in alternates) {
        if (alt.startsWith(needle)) return 90;
        if (alt.contains(needle)) return 40;
      }
      return 0;
    }

    final lowerTerm = term.toLowerCase();
    final lowerNeedle = needle.toLowerCase();
    if (lowerTerm.startsWith(lowerNeedle)) return 100;
    if (lowerTerm.contains(lowerNeedle)) return 50;
    for (final alt in alternates) {
      final lowerAlt = alt.toLowerCase();
      if (lowerAlt.startsWith(lowerNeedle)) return 90;
      if (lowerAlt.contains(lowerNeedle)) return 40;
    }
    return 0;
  }
}
