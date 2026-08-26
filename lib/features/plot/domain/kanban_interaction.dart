/// Kontrak Kanban Plot Interaction (Step 109.26).
///
/// Interaksi papan kanban sebagai domain murni (tanpa UI/DB) di atas
/// PlotBoard 109.25. Lima kemampuan kanonik sprint_109.json:
/// 1. **drag_reorder** — drop kartu ke indeks memindahkan tepat satu
///    posisi dengan validasi;
/// 2. **keyboard_reorder** — geser maju/mundur setara drag tetangga;
///    ujung papan tidak bergerak dan tak error;
/// 3. **multi_select** — blok terpilih bergerak utuh menjaga urutan
///    relatif; indeks drop = celah pada daftar tanpa blok terpilih;
/// 4. **undo** — setiap mutasi dapat dibalik sekali secara LIFO;
/// 5. **screen_reader_announcement** — setiap aksi menghasilkan
///    pengumuman deterministik.
library;

import 'plot_board.dart';

/// Pengumuman satu aksi untuk pembaca layar.
class KanbanAnnouncement {
  const KanbanAnnouncement({required this.message});

  final String message;
}

/// Transaksi satu mutasi papan, cukup untuk dibalik.
class _KanbanMutation {
  _KanbanMutation({required this.orderBefore, required this.announce});

  final List<String> orderBefore;
  final String announce;
}

/// Sesi interaksi kanban; memegang seleksi, riwayat undo, dan
/// pengumuman. Murni domain.
class KanbanInteractionSession {
  KanbanInteractionSession({required this.board});

  /// Papan yang dimodifikasi sesi ini.
  final PlotBoard board;

  final List<String> _selected = <String>[];
  final List<_KanbanMutation> _history = <_KanbanMutation>[];
  final List<KanbanAnnouncement> _announcements = <KanbanAnnouncement>[];

  /// Kartu terpilih urut papan.
  List<String> get selectedIds => List.unmodifiable(_selected);

  /// Riwayat pengumuman kronologis.
  List<KanbanAnnouncement> get announcements =>
      List.unmodifiable(_announcements);

  bool get _hasSelection => _selected.isNotEmpty;

  void _record(String announce) {
    _history.add(
      _KanbanMutation(
        orderBefore: board.cards.map((c) => c.id).toList(),
        announce: announce,
      ),
    );
    _announcements.add(KanbanAnnouncement(message: announce));
  }

  void _requireCard(String cardId) {
    final ids = board.cards.map((c) => c.id).toSet();
    if (!ids.contains(cardId)) {
      throw StateError('unknown card: $cardId');
    }
  }

  void _applyOrder(List<String> newOrder) {
    for (final id in newOrder) {
      board.moveCard(id, toIndex: newOrder.indexOf(id));
    }
  }

  /// Drop satu kartu ke [dropIndex]; validasi ketat.
  void drag({required String cardId, required int dropIndex}) {
    _requireCard(cardId);
    if (dropIndex < 0 || dropIndex >= board.cardCount) {
      throw RangeError.index(dropIndex, board.cards, 'dropIndex');
    }
    _record('kartu $cardId dipindahkan lewat drag ke posisi ${dropIndex + 1}');
    board.moveCard(cardId, toIndex: dropIndex);
  }

  /// Geser kartu satu langkah (keyboard); ujung papan no-op.
  void nudge({required String cardId, required bool forward}) {
    _requireCard(cardId);
    final ids = board.cards.map((c) => c.id).toList();
    final from = ids.indexOf(cardId);
    final to = forward ? from + 1 : from - 1;
    if (to < 0 || to >= ids.length) {
      return;
    }
    _record(
      'kartu $cardId digeser ${forward ? "maju" : "mundur"} '
      'lewat keyboard ke posisi ${to + 1}',
    );
    board.moveCard(cardId, toIndex: to);
  }

  /// Menandai kartu sebagai bagian seleksi multi.
  void select(String cardId) {
    _requireCard(cardId);
    if (!_selected.contains(cardId)) {
      _selected.add(cardId);
      _announcements.add(KanbanAnnouncement(message: 'kartu $cardId dipilih'));
    }
  }

  /// Mengosongkan seleksi.
  void clearSelection() => _selected.clear();

  /// Memindahkan seluruh blok terpilih utuh ke celah [dropIndex]
  /// pada daftar TANPA kartu terpilih (ter-clamp ke rentang valid).
  void moveSelectedTo({required int dropIndex}) {
    if (!_hasSelection) {
      throw StateError('no selection to move');
    }
    final allIds = board.cards.map((c) => c.id).toList();
    final block = _selected.where(allIds.contains).toList();
    final rest = allIds.where((id) => !block.contains(id)).toList();
    var index = dropIndex.clamp(0, rest.length);
    final moved = <String>[...rest];
    moved.insertAll(index, block);
    _record(
      '${block.length} kartu terpilih dipindahkan bersama ke posisi '
      '${index + 1}',
    );
    _applyOrder(moved);
  }

  /// Membalik mutasi terakhir secara LIFO; [StateError] bila kosong.
  void undo() {
    if (_history.isEmpty) {
      throw StateError('nothing to undo');
    }
    final last = _history.removeLast();
    _applyOrder(last.orderBefore);
    _announcements.add(
      KanbanAnnouncement(message: 'aksi diurungkan: ${last.announce}'),
    );
  }
}
