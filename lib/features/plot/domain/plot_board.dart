/// Kontrak Plot Board Data Model (Step 109.25).
///
/// Model data papan alur cerita sebagai domain murni (tanpa DB/UI).
/// Empat outputs kanonik sprint_109.json:
/// 1. **board_schema** — papan milik satu project, memuat kartu dengan
///    seluruh dimensi cerita;
/// 2. **card_schema** — kartu plot berstatus, tautan bab/adegan/arc/POV,
///    label pacing, dan roundtrip JSON deterministik;
/// 3. **ordering_contract** — urutan papan eksplisit; reorder
///    deterministik dan tervalidasi;
/// 4. **story_sync_contract** — proyeksi sinkron dikelompokkan per bab
///    dengan urutan adegan; kartu tanpa bab dilaporkan terpisah.
library;

/// Status pengerjaan sebuah kartu plot.
enum PlotCardStatus {
  /// Ide mentah belum dikerjakan.
  idea,

  /// Sedang ditulis.
  drafting,

  /// Menunggu/masih revisi.
  revision,

  /// Selesai.
  done,
}

/// Satu kartu plot pada papan.
class PlotCard {
  const PlotCard({
    required this.id,
    required this.title,
    required this.status,
    this.chapterId,
    this.sceneId,
    this.arcId,
    this.povCharacterId,
    this.pacingLabel,
  });

  final String id;
  final String title;
  final PlotCardStatus status;

  /// Bab yang dikaitkan (null = kartu kolam ide).
  final String? chapterId;

  /// Adegan dalam bab.
  final String? sceneId;

  /// Arc cerita pemilik benang merah.
  final String? arcId;

  /// Tokoh POV adegan.
  final String? povCharacterId;

  /// Label pacing bebas (lambat/cepat/dsb).
  final String? pacingLabel;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'status': status.name,
    'chapterId': chapterId,
    'sceneId': sceneId,
    'arcId': arcId,
    'povCharacterId': povCharacterId,
    'pacingLabel': pacingLabel,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlotCard &&
          other.id == id &&
          other.title == title &&
          other.status == status &&
          other.chapterId == chapterId &&
          other.sceneId == sceneId &&
          other.arcId == arcId &&
          other.povCharacterId == povCharacterId &&
          other.pacingLabel == pacingLabel;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    status,
    chapterId,
    sceneId,
    arcId,
    povCharacterId,
    pacingLabel,
  );

  static PlotCard fromJson(Map<String, Object?> json) => PlotCard(
    id: json['id']! as String,
    title: json['title']! as String,
    status: PlotCardStatus.values.byName(json['status']! as String),
    chapterId: json['chapterId'] as String?,
    sceneId: json['sceneId'] as String?,
    arcId: json['arcId'] as String?,
    povCharacterId: json['povCharacterId'] as String?,
    pacingLabel: json['pacingLabel'] as String?,
  );
}

/// Satu bab pada proyeksi sinkron cerita.
class StorySyncChapter {
  const StorySyncChapter({
    required this.chapterId,
    required this.cardIds,
    required this.sceneIds,
  });

  final String chapterId;
  final List<String> cardIds;
  final List<String> sceneIds;
}

/// Proyeksi sinkron papan ke struktur cerita.
class StorySyncProjection {
  const StorySyncProjection({
    required this.chapters,
    required this.unlinkedCardIds,
  });

  /// Bab urut kemunculan pertama di papan.
  final List<StorySyncChapter> chapters;

  /// Kartu tanpa bab (kolam ide) tidak masuk sinkronisasi.
  final List<String> unlinkedCardIds;
}

/// Papan plot satu project; murni domain.
class PlotBoard {
  PlotBoard({required this.projectId});

  /// Project pemilik papan.
  final String projectId;

  final Map<String, PlotCard> _cards = <String, PlotCard>{};
  final List<String> _order = <String>[];

  /// Kartu urut papan saat ini.
  List<PlotCard> get cards =>
      List.unmodifiable(_order.map((id) => _cards[id]!));

  int get cardCount => _order.length;

  /// Menambah kartu baru; judul wajib non-kosong ([ArgumentError]) dan id
  /// wajib unik ([StateError]).
  void addCard(PlotCard card) {
    if (card.title.trim().isEmpty) {
      throw ArgumentError('card title must not be blank');
    }
    if (_cards.containsKey(card.id)) {
      throw StateError('duplicate card id: ${card.id}');
    }
    _cards[card.id] = card;
    _order.add(card.id);
  }

  /// Memindahkan kartu ke posisi papan eksplisit; deterministik.
  void moveCard(String cardId, {required int toIndex}) {
    if (!_cards.containsKey(cardId)) {
      throw StateError('unknown card: $cardId');
    }
    if (toIndex < 0 || toIndex >= _order.length) {
      throw RangeError.index(toIndex, _order, 'toIndex');
    }
    _order
      ..remove(cardId)
      ..insert(toIndex, cardId);
  }

  /// Proyeksi sinkron: bab urut kemunculan, adegan urut papan.
  StorySyncProjection storySyncProjection() {
    final chapterOrder = <String>[];
    final byChapter = <String, List<PlotCard>>{};
    final unlinked = <String>[];
    for (final card in cards) {
      final chapterId = card.chapterId;
      if (chapterId == null) {
        unlinked.add(card.id);
        continue;
      }
      if (!byChapter.containsKey(chapterId)) {
        byChapter[chapterId] = <PlotCard>[];
        chapterOrder.add(chapterId);
      }
      byChapter[chapterId]!.add(card);
    }
    return StorySyncProjection(
      chapters: List.unmodifiable(<StorySyncChapter>[
        for (final chapterId in chapterOrder)
          StorySyncChapter(
            chapterId: chapterId,
            cardIds: List.unmodifiable(byChapter[chapterId]!.map((c) => c.id)),
            sceneIds: List.unmodifiable(<String>[
              for (final card in byChapter[chapterId]!)
                if (card.sceneId != null) card.sceneId!,
            ]),
          ),
      ]),
      unlinkedCardIds: List.unmodifiable(unlinked),
    );
  }
}
