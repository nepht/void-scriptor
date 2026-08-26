/// Kontrak Character Moodboard Workspace (Step 109.28).
///
/// Papan referensi visual kanonis per tokoh sebagai domain murni
/// (tanpa DB/UI). Lima kemampuan kanonik sprint_109.json:
/// 1. **local_media** — item media lokal tervalidasi (path non-kosong,
///    id unik);
/// 2. **categories** — kategori mengelompokkan dan memfilter item;
/// 3. **annotations** — anotasi kronologis jam-suntik per item;
/// 4. **source_credit** — kredit sumber opsional, ikut roundtrip JSON;
/// 5. **missing_file_state** — file hilang ditandai, dilaporkan,
///    dipertahankan lewat roundtrip, dan bisa pulih.
library;

/// Satu item referensi visual pada moodboard tokoh.
class MoodboardItem {
  const MoodboardItem({
    required this.id,
    required this.filePath,
    required this.category,
    this.sourceCredit,
    this.isMissing = false,
  });

  final String id;

  /// Path media LOKAL (bukan URL jaringan) — Novel Workspace hanya
  /// menyimpan link; Character Workspace menyimpan kanonis.
  final String filePath;
  final String category;

  /// Kredit sumber bebas (pembuat gambar, lisensi, dsb).
  final String? sourceCredit;

  /// True bila berkas fisik tidak ditemukan saat pemeriksaan terakhir.
  final bool isMissing;

  MoodboardItem withMissing({required bool missing}) => MoodboardItem(
    id: id,
    filePath: filePath,
    category: category,
    sourceCredit: sourceCredit,
    isMissing: missing,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'filePath': filePath,
    'category': category,
    'sourceCredit': sourceCredit,
    'isMissing': isMissing,
  };

  static MoodboardItem fromJson(Map<String, Object?> json) => MoodboardItem(
    id: json['id']! as String,
    filePath: json['filePath']! as String,
    category: json['category']! as String,
    sourceCredit: json['sourceCredit'] as String?,
    isMissing: (json['isMissing'] as bool?) ?? false,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodboardItem &&
          other.id == id &&
          other.filePath == filePath &&
          other.category == category &&
          other.sourceCredit == sourceCredit &&
          other.isMissing == isMissing;

  @override
  int get hashCode =>
      Object.hash(id, filePath, category, sourceCredit, isMissing);
}

/// Satu anotasi berwaktu pada sebuah item.
class MoodboardAnnotation {
  const MoodboardAnnotation({required this.text, required this.at});

  final String text;
  final DateTime at;
}

/// Moodboard satu tokoh; murni domain.
class CharacterMoodboard {
  CharacterMoodboard({required this.characterId, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Tokoh pemilik moodboard.
  final String characterId;

  final DateTime Function() _clock;
  final Map<String, MoodboardItem> _items = <String, MoodboardItem>{};

  /// Item urut penambahan.
  List<MoodboardItem> get items => List.unmodifiable(_items.values.toList());

  /// Kategori unik urut kemunculan pertama.
  List<String> get categories {
    final seen = <String>{};
    for (final item in _items.values) {
      seen.add(item.category);
    }
    return List.unmodifiable(seen);
  }

  /// Item dalam satu kategori, urut penambahan.
  List<MoodboardItem> itemsInCategory(String category) =>
      List.unmodifiable(_items.values.where((i) => i.category == category));

  /// Menambah item; path kosong ([ArgumentError]) dan id duplikat
  /// ([StateError]) ditolak.
  void addItem(MoodboardItem item) {
    if (item.filePath.trim().isEmpty) {
      throw ArgumentError('file path must not be blank');
    }
    if (_items.containsKey(item.id)) {
      throw StateError('duplicate item id: ${item.id}');
    }
    _items[item.id] = item;
  }

  /// Menambahkan anotasi berwaktu ke item; [StateError] bila tak ada.
  void annotate(String itemId, String text) {
    _require(itemId);
    _annotations
        .putIfAbsent(itemId, () => <MoodboardAnnotation>[])
        .add(MoodboardAnnotation(text: text, at: _clock()));
  }

  final Map<String, List<MoodboardAnnotation>> _annotations =
      <String, List<MoodboardAnnotation>>{};

  /// Anotasi satu item kronologis.
  List<MoodboardAnnotation> annotationsOf(String itemId) {
    _require(itemId);
    return List.unmodifiable(_annotations[itemId] ?? const []);
  }

  /// Menandai item sebagai berkas hilang.
  void markMissing(String itemId) => _setMissing(itemId, true);

  /// Menandai item kembali tersedia.
  void markPresent(String itemId) => _setMissing(itemId, false);

  /// Id item yang berkasnya hilang.
  List<String> get missingItemIds => List.unmodifiable(
    _items.values.where((i) => i.isMissing).map((i) => i.id),
  );

  void _setMissing(String itemId, bool missing) {
    _require(itemId);
    _items[itemId] = _items[itemId]!.withMissing(missing: missing);
  }

  void _require(String itemId) {
    if (!_items.containsKey(itemId)) {
      throw StateError('unknown item: $itemId');
    }
  }
}
