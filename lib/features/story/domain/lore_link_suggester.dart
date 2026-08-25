/// Referensi entitas lore untuk autocomplete tautan inline (Step 109.10).
///
/// Satu entitas bisa berasal dari Species, Technologies, PowerSystems, atau
/// BibleEntries; [kind] menandai asalnya dan [detail] dipakai preview.
class LoreEntityRef {
  const LoreEntityRef({
    required this.id,
    required this.name,
    required this.kind,
    this.detail = '',
  });

  final String id;
  final String name;
  final String kind;
  final String detail;

  /// Nama dinormalisasi: huruf kecil, rangkaian spasi dipipihkan satu spasi.
  /// Dipakai untuk dedupe katalog dan pencocokan exact-match.
  static String normalizeName(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Pencari saran tautan lore dari sebuah katalog entitas.
///
/// Skor deterministik: exact > prefix > substring, lalu nama alfabetis.
/// Katalog di-dedupe berdasarkan nama ternormalisasi (kemunculan pertama
/// menang), sehingga entitas yang sama dari dua sumber tidak muncul ganda.
class LoreLinkSuggester {
  const LoreLinkSuggester({this.limit = 8});

  final int limit;

  List<LoreEntityRef> suggest(
    Iterable<LoreEntityRef> catalog, {
    required String query,
  }) {
    final needle = LoreEntityRef.normalizeName(query);
    if (needle.isEmpty) return const <LoreEntityRef>[];

    final seen = <String>{};
    final scored = <({LoreEntityRef entity, int score, String name})>[];
    for (final entity in catalog) {
      final name = LoreEntityRef.normalizeName(entity.name);
      if (name.isEmpty || !seen.add(name)) continue;

      final score = _scoreOf(name, needle);
      if (score > 0) scored.add((entity: entity, score: score, name: name));
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore == 0 ? a.name.compareTo(b.name) : byScore;
    });

    return scored
        .take(limit)
        .map((item) => item.entity)
        .toList(growable: false);
  }

  /// Entitas dengan nama persis sama (case-insensitive, spasi dipipihkan),
  /// atau null bila tidak ada — dasar untuk duplicate warning.
  LoreEntityRef? exactMatchOf(
    Iterable<LoreEntityRef> catalog, {
    required String query,
  }) {
    final needle = LoreEntityRef.normalizeName(query);
    for (final entity in catalog) {
      if (LoreEntityRef.normalizeName(entity.name) == needle) return entity;
    }
    return null;
  }

  static int _scoreOf(String name, String needle) {
    if (name == needle) return 300;
    if (name.startsWith(needle)) return 200;
    if (name.contains(needle)) return 100;
    return 0;
  }
}

/// Utilitas sintaks untuk menemukan query tautan aktif pada posisi caret.
class LoreLinkSyntax {
  const LoreLinkSyntax._();

  /// Mengembalikan isi tautan yang sedang diketik pada [caret], atau null
  /// bila caret tidak berada tepat setelah pembuka `[[` yang belum tertutup.
  /// Hasil '' berarti pembuka baru selesai diketik tanpa isi. `\[[` yang
  /// di-escape, badan memuat baris baru, atau sudah ada penutup `]]`
  /// mengembalikan null.
  static String? activeQueryAt(String text, int caret) {
    final end = caret < 0 ? 0 : (caret > text.length ? text.length : caret);
    for (var start = end - 1; start >= 0; start--) {
      final code = text.codeUnitAt(start);
      if (code == 0x0A || code == 0x0D) return null;
      final isOpener =
          code == 0x5B &&
          start + 1 < text.length &&
          text.codeUnitAt(start + 1) == 0x5B;
      if (!isOpener) continue;
      if (start > 0 && text.codeUnitAt(start - 1) == 0x5C) return null;
      final body = text.substring(start + 2, end);
      if (body.contains(']]')) return null;
      return body;
    }
    return null;
  }
}
