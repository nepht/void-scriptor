/// Kontrak POV Knowledge Boundary (Step 109.34).
///
/// Batas pengetahuan karakter pada titik waktu tertentu sebagai
/// domain murni (tanpa DB/UI), satu modul dengan POV Lock 109.33.
/// Lima kemampuan kanonik sprint_109.json:
/// 1. **knowledge_events** — peristiwa belajar terekam kronologis;
/// 2. **timeline_query** — kueri memotong garis waktu tepat;
/// 3. **source_reference** — tiap pengetahuan membawa sumber;
/// 4. **uncertain_knowledge** — dugaan tak dihitung tahu pasti namun
///    tetap terlacak;
/// 5. **secret_handling** — fakta rahasia tersembunyi sampai titik
///    bocornya.
library;

/// Titik waktu pada garis waktu adegan.
class KnowledgeTime {
  const KnowledgeTime.scene(this.sceneId) : chapterId = null;

  const KnowledgeTime.chapter(this.chapterId) : sceneId = null;

  final String? sceneId;
  final String? chapterId;

  /// Urutan pembanding dalam satu proyek dan satu tipe waktu: digit
  /// akhir id dibandingkan sebagai angka sehingga 'sc-2' mendahului
  /// 'sc-10' (konvensi repo `'sc-<angka>'` tidak menjamin urutan
  /// leksikografis tanpa nol-padding); tanpa digit akhir, urutan
  /// leksikografis dipakai. Campuran scene vs chapter tidak memiliki
  /// ordinal bersama dan ditolak [UnsupportedError] alih-alih
  /// menghasilkan angka palsu
  /// (vs-hunt-20260914-content CT-BUG-06).
  int compareTo(KnowledgeTime other) {
    final a = sceneId ?? chapterId ?? '';
    final b = other.sceneId ?? other.chapterId ?? '';
    if ((sceneId == null) != (other.sceneId == null)) {
      throw UnsupportedError(
        'cannot order scene time against chapter time: $a vs $b',
      );
    }
    final ta = RegExp(r'^(.*?)(\d+)$').firstMatch(a);
    final tb = RegExp(r'^(.*?)(\d+)$').firstMatch(b);
    if (ta != null && tb != null) {
      final byPrefix = ta.group(1)!.compareTo(tb.group(1)!);
      if (byPrefix != 0) return byPrefix;
      final byNumber = int.parse(
        ta.group(2)!,
      ).compareTo(int.parse(tb.group(2)!));
      if (byNumber != 0) return byNumber;
      return a.compareTo(b);
    }
    return a.compareTo(b);
  }

  @override
  String toString() => sceneId ?? chapterId ?? '';
}

/// Jenis sumber pengetahuan.
enum KnowledgeSourceKind { conversation, observation, document, rumor }

/// Rujukan sumber satu peristiwa belajar.
class KnowledgeSource {
  const KnowledgeSource({required this.kind, required this.reference});

  final KnowledgeSourceKind kind;
  final String reference;
}

/// Tingkat keyakinan atas sebuah fakta.
enum Certainty { known, suspected }

/// Satu peristiwa belajar.
class KnowledgeEvent {
  const KnowledgeEvent({
    required this.characterId,
    required this.factId,
    required this.at,
    this.source,
    this.certainty = Certainty.known,
  });

  final String characterId;
  final String factId;
  final KnowledgeTime at;
  final KnowledgeSource? source;
  final Certainty certainty;

  bool get isSuspected => certainty == Certainty.suspected;
}

/// Ledger batas pengetahuan; murni domain.
class KnowledgeLedger {
  final List<KnowledgeEvent> _events = <KnowledgeEvent>[];

  /// Fakta rahasia -> titik bocornya.
  final Map<String, KnowledgeTime> _secretLeaks = <String, KnowledgeTime>{};

  /// Merekam peristiwa belajar; duplikat persis (karakter+fakta+titik)
  /// ditolak [StateError] agar riwayat tetap bersih.
  void learn({
    required String characterId,
    required String factId,
    required KnowledgeTime at,
    KnowledgeSource? source,
    Certainty certainty = Certainty.known,
  }) {
    final duplicate = _events.any(
      (e) =>
          e.characterId == characterId &&
          e.factId == factId &&
          e.at.compareTo(at) == 0,
    );
    if (duplicate) {
      throw StateError('duplicate knowledge event');
    }
    _events.add(
      KnowledgeEvent(
        characterId: characterId,
        factId: factId,
        at: at,
        source: source,
        certainty: certainty,
      ),
    );
  }

  /// Menyatakan fakta rahasia beserta titik bocornya;
  /// deklarasi ganda [StateError].
  void declareSecret({
    required String factId,
    required KnowledgeTime leakedAt,
  }) {
    if (_secretLeaks.containsKey(factId)) {
      throw StateError('secret already declared: $factId');
    }
    _secretLeaks[factId] = leakedAt;
  }

  /// Peristiwa belajar satu karakter hingga [at], urut garis waktu.
  ///
  /// Dugaan ([Certainty.suspected]) hanya ikut bila
  /// [includeSuspected] bernilai true.
  List<KnowledgeEvent> factsKnownBy(
    String characterId, {
    required KnowledgeTime at,
    bool includeSuspected = false,
  }) {
    final found = <KnowledgeEvent>[
      for (final e in _events)
        if (e.characterId == characterId &&
            e.at.compareTo(at) <= 0 &&
            (includeSuspected || !e.isSuspected))
          e,
    ]..sort((a, b) => a.at.compareTo(b.at));
    return List.unmodifiable(found);
  }

  /// True bila karakter benar-benar tahu fakta pada [at]; dugaan
  /// tidak dihitung.
  bool knows(
    String characterId, {
    required String factId,
    required KnowledgeTime at,
  }) {
    return _events.any(
      (e) =>
          e.characterId == characterId &&
          e.factId == factId &&
          !e.isSuspected &&
          e.at.compareTo(at) <= 0,
    );
  }

  /// True bila fakta rahasia sudah boleh terlihat pada [at]; fakta
  /// bukan rahasia selalu tampak.
  bool isSecretVisible(String factId, {required KnowledgeTime at}) {
    final leakAt = _secretLeaks[factId];
    if (leakAt == null) return true;
    return leakAt.compareTo(at) <= 0;
  }
}
