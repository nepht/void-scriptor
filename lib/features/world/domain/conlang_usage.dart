/// Kontrak Conlang Usage Consistency (Step 109.19).
///
/// Pemeriksa konsistensi penggunaan bahasa buatan terhadap kamus
/// [ConlangRegistry] (109.17) sebagai domain murni (tanpa DB/UI).
/// Lima kemampuan kanonik sprint_109.json:
/// 1. **dictionary_lookup** — kemunculan istilah kamus dilaporkan dengan
///    referensi kata dan offset;
/// 2. **unknown_term_warning** — ejaan yang menyimpang dari bentuk
///    diketahui diperingatkan beserta saran bentuk terdekat;
/// 3. **variant_awareness** — varian bentuk dihitung sebagai kemunculan
///    kata induknya; salah eja varian disarankan ke varian;
/// 4. **jump_to_occurrence** — offset/panjang/cuplikan verbatim untuk
///    lompatan editor;
/// 5. **user_override** — istilah yang diabaikan pengguna senyap.
///
/// Ekstra konsistensi makna: glos kurung setelah istilah dibandingkan
/// dengan arti kamus; ketidakcocokan diperingatkan.
///
/// Prinsip warisan 109.16: naskah TIDAK PERNAH diubah otomatis — hasil
/// pemeriksaan hanya temuan merujuk entri kamus.
library;

import 'package:void_scriptor/features/world/domain/conlang_registry.dart';

/// Jenis temuan konsistensi penggunaan.
enum ConlangFindingKind {
  /// Istilah kamus dikenali.
  knownTerm,

  /// Ejaan menyimpang dari semua bentuk kata yang diketahui.
  unknownTerm,

  /// Glos kurung tidak cocok dengan arti kamus.
  meaningMismatch,
}

/// Satu temuan pada naskah; selalu verbatim, tanpa teks pengganti.
class ConlangUsageFinding {
  const ConlangUsageFinding({
    required this.kind,
    required this.wordId,
    required this.matchedForm,
    required this.offset,
    required this.length,
    required this.snippet,
    this.suggestions = const <String>[],
    this.expectedMeaning,
    this.foundGloss,
  });

  final ConlangFindingKind kind;

  /// Kata kamus induk yang dirujuk.
  final String wordId;

  /// Bentuk persis seperti muncul di naskah (verbatim).
  final String matchedForm;

  /// Offset karakter awal kemunculan dalam naskah.
  final int offset;

  /// Panjang kemunculan.
  final int length;

  /// Cuplikan naskah persis sepanjang [length].
  final String snippet;

  /// Saran bentuk diketahui terdekat (unknownTerm).
  final List<String> suggestions;

  /// Arti kamus yang diharapkan (meaningMismatch).
  final String? expectedMeaning;

  /// Glos yang ditemukan di naskah (meaningMismatch).
  final String? foundGloss;

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind.name,
    'wordId': wordId,
    'matchedForm': matchedForm,
    'offset': offset,
    'length': length,
    'snippet': snippet,
    'suggestions': <Object?>[...suggestions],
    if (expectedMeaning != null) 'expectedMeaning': expectedMeaning,
    if (foundGloss != null) 'foundGloss': foundGloss,
  };
}

/// Pemeriksa konsistensi penggunaan conlang atas sebuah registri kamus.
/// Stateless terhadap naskah: [check] tidak pernah memutasi apa pun.
class ConlangUsageChecker {
  ConlangUsageChecker({required ConlangRegistry registry})
    : _index = _buildIndex(registry);

  /// bentuk lowercase -> kata induk.
  final Map<String, ConlangWord> _index;

  /// bentuk yang diabaikan pengguna (lowercase).
  final Set<String> _ignored = <String>{};

  static Map<String, ConlangWord> _buildIndex(ConlangRegistry registry) {
    final index = <String, ConlangWord>{};
    for (final word in registry.words()) {
      index[word.term.toLowerCase()] = word;
      for (final variant in word.variants) {
        index[variant.form.toLowerCase()] = word;
      }
    }
    return index;
  }

  /// Mengabaikan bentuk tertentu dari peringatan unknown-term.
  void ignoreTerm(String form) => _ignored.add(form.trim().toLowerCase());

  /// Berhenti mengabaikan bentuk tertentu.
  void unignoreTerm(String form) => _ignored.remove(form.trim().toLowerCase());

  /// Memeriksa naskah tanpa mengubahnya; temuan urut berdasarkan offset.
  List<ConlangUsageFinding> check(String manuscript) {
    final findings = <ConlangUsageFinding>[];
    var i = 0;
    while (i < manuscript.length) {
      final codeUnit = manuscript.codeUnitAt(i);
      if (!_isFormChar(codeUnit)) {
        i++;
        continue;
      }
      var j = i;
      while (j < manuscript.length && _isFormChar(manuscript.codeUnitAt(j))) {
        j++;
      }
      // Apostrof di ujung bukan bagian dari bentuk.
      while (j > i && manuscript.codeUnitAt(j - 1) == 0x27) {
        j--;
      }
      final raw = manuscript.substring(i, j);
      final lower = raw.toLowerCase();
      final knownWord = _index[lower];
      if (knownWord != null) {
        findings.add(
          ConlangUsageFinding(
            kind: ConlangFindingKind.knownTerm,
            wordId: knownWord.id,
            matchedForm: raw,
            offset: i,
            length: raw.length,
            snippet: raw,
          ),
        );
        _collectGloss(
          findings: findings,
          manuscript: manuscript,
          word: knownWord,
          formStart: i,
          formEnd: j,
        );
      } else if (!_ignored.contains(lower)) {
        final suggestion = _nearestKnown(lower);
        if (suggestion != null) {
          findings.add(
            ConlangUsageFinding(
              kind: ConlangFindingKind.unknownTerm,
              wordId: suggestion.$2.id,
              matchedForm: raw,
              offset: i,
              length: raw.length,
              snippet: raw,
              suggestions: <String>[suggestion.$1],
            ),
          );
        }
      }
      i = j;
    }
    return findings;
  }

  void _collectGloss({
    required List<ConlangUsageFinding> findings,
    required String manuscript,
    required ConlangWord word,
    required int formStart,
    required int formEnd,
  }) {
    var k = formEnd;
    while (k < manuscript.length && manuscript[k] == ' ') {
      k++;
    }
    if (k >= manuscript.length || manuscript[k] != '(') {
      return;
    }
    final close = manuscript.indexOf(')', k + 1);
    if (close == -1) {
      return;
    }
    final gloss = manuscript.substring(k + 1, close).trim();
    if (gloss.isEmpty) {
      return;
    }
    if (gloss.toLowerCase() == word.meaning.trim().toLowerCase()) {
      return;
    }
    findings.add(
      ConlangUsageFinding(
        kind: ConlangFindingKind.meaningMismatch,
        wordId: word.id,
        matchedForm: manuscript.substring(formStart, formEnd),
        offset: formStart,
        length: formEnd - formStart,
        snippet: manuscript.substring(formStart, formEnd),
        expectedMeaning: word.meaning,
        foundGloss: gloss,
      ),
    );
  }

  static bool _isFormChar(int codeUnit) =>
      (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7A) ||
      codeUnit == 0x27;

  /// Bentuk diketahui berjarak edit 1 terdekat; null bila tak ada.
  (String, ConlangWord)? _nearestKnown(String lower) {
    String? bestForm;
    ConlangWord? bestWord;
    var bestDistance = 2;
    for (final entry in _index.entries) {
      final distance = _editDistanceAtMostOne(entry.key, lower);
      if (distance != null && distance < bestDistance) {
        bestDistance = distance;
        bestForm = entry.key;
        bestWord = entry.value;
      }
    }
    if (bestForm == null || bestWord == null) return null;
    return (bestForm, bestWord);
  }

  /// Jarak edit dibatasi maksimum 1; null bila lebih dari itu.
  static int? _editDistanceAtMostOne(String a, String b) {
    if (a == b) return 0;
    final la = a.length;
    final lb = b.length;
    if ((la - lb).abs() > 1) return null;
    if (la == lb) {
      var diff = 0;
      for (var k = 0; k < la; k++) {
        if (a[k] != b[k]) {
          diff++;
          if (diff > 1) return null;
        }
      }
      return diff;
    }
    final shorter = la < lb ? a : b;
    final longer = la < lb ? b : a;
    var si = 0;
    var skipped = false;
    for (var li = 0; li < longer.length; li++) {
      if (si < shorter.length && shorter[si] == longer[li]) {
        si++;
        continue;
      }
      if (skipped) return null;
      skipped = true;
    }
    return 1;
  }
}
