/// Kontrak Contradiction Inbox (Step 109.14).
///
/// Inbox terpadu atas temuan [ContradictionFinding] hasil pipeline 109.13
/// dengan lima kemampuan kanonik sprint_109.json:
/// 1. **severity_filter** dan **entity_filter** — dua sumbu filter bekerja
///    secara AND atas himpunan temuan yang masih terbuka;
/// 2. **jump_to_source** — sitasi verbatim berurutan per temuan;
/// 3. **resolve_or_dismiss** — penyelesaian logis tanpa mengubah naskah:
///    *dismiss* mencatat suppression pada store dismissal bersama (state
///    JSON serializable, bukan skema database, selaras D-SCHEMA-01 OPEN),
///    *resolve* menandai selesai di riwayat inbox semata;
/// 4. **history** — riwayat kronologis aksi dengan jam tersuntik agar
///    serialisasi antar-run deterministik.
///
/// Modul ini domain murni: tanpa Drift dan tanpa UI. Penyambangan ke UI
/// editor/pipeline tingkat aplikasi adalah pekerjaan langkah integrasi.
library;

import 'contradiction_analysis.dart';
import 'contradiction_rule.dart';

/// Status penyelesaian satu temuan di inbox.
enum ContradictionInboxStatus {
  /// Diabaikan: suppression aktif pada store dismissal bersama.
  dismissed,

  /// Diselesaikan: dicatat selesai; tidak menyentuh store dismissal.
  resolved,
}

/// Satu aksi penyelesaian yang terekam di riwayat inbox.
class ContradictionInboxEvent {
  const ContradictionInboxEvent({
    required this.findingId,
    required this.action,
    required this.at,
    this.actor = '',
    this.note = '',
  });

  /// ID temuan (fingerprint `ruleId::subjectId`).
  final String findingId;

  /// Nama aksi: `dismiss`, `resolve`, atau `restore`.
  final String action;
  final DateTime at;
  final String actor;
  final String note;

  Map<String, Object?> toJson() => <String, Object?>{
    'findingId': findingId,
    'action': action,
    'at': at.toIso8601String(),
    'actor': actor,
    'note': note,
  };

  static ContradictionInboxEvent fromJson(Map<String, Object?> json) =>
      ContradictionInboxEvent(
        findingId: json['findingId']! as String,
        action: json['action']! as String,
        at: DateTime.parse(json['at']! as String),
        actor: json['actor'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
}

/// Inbox terpadu temuan kontradiksi.
///
/// [ContradictionDismissalStore] dapat disuntikkan agar dibagi dengan
/// [ContradictionAnalysisPipeline]: dismissal lewat inbox langsung menekan
/// pemindaian berikutnya, dan sebaliknya suppression pipeline tampak di
/// inbox sebagai status [ContradictionInboxStatus.dismissed].
class ContradictionInbox {
  ContradictionInbox({
    ContradictionDismissalStore? dismissals,
    DateTime Function()? clock,
  }) : _dismissals = dismissals ?? ContradictionDismissalStore(),
       _clock = clock ?? DateTime.now;

  final ContradictionDismissalStore _dismissals;
  final DateTime Function() _clock;
  final Map<String, ContradictionFinding> _findings =
      <String, ContradictionFinding>{};
  final Map<String, ContradictionInboxStatus> _statuses =
      <String, ContradictionInboxStatus>{};
  final List<ContradictionInboxEvent> _history = <ContradictionInboxEvent>[];

  /// Store dismissal bersama (dibagikan dengan pipeline bila disuntikkan).
  ContradictionDismissalStore get dismissals => _dismissals;

  /// Menyelaraskan isi inbox dengan temuan hasil scan terbaru.
  ///
  /// Temuan lama tetap dikenal (status penyelesaiannya dipertahankan agar
  /// rescan tidak membuka kembali pasangan yang sudah diputuskan); temuan
  /// baru masuk sebagai terbuka.
  void sync(Iterable<ContradictionFinding> findings) {
    for (final finding in findings) {
      _findings[finding.id] = finding;
    }
  }

  /// Temuan yang masih terbuka, dalam urutan sinkronisasi.
  ///
  /// [severities] kosong/null berarti semua tingkat; [subjectIds]
  /// kosong/null berarti semua subjek. Kedua filter digabung AND.
  List<ContradictionFinding> open({
    Set<ContradictionSeverity>? severities,
    Set<String>? subjectIds,
  }) => <ContradictionFinding>[
    for (final finding in _findings.values)
      if (!_statuses.containsKey(finding.id) &&
          (severities == null || severities.contains(finding.severity)) &&
          (subjectIds == null || subjectIds.contains(finding.subjectId)))
        finding,
  ];

  /// Sitasi sumber verbatim berurutan untuk lompatan dari sebuah temuan.
  /// Kosong untuk ID tak dikenal.
  List<ContradictionSourceRef> jumpTargets(String findingId) =>
      List<ContradictionSourceRef>.unmodifiable(
        _findings[findingId]?.explanation.sources ??
            const <ContradictionSourceRef>[],
      );

  bool _isOpen(String findingId) =>
      _findings.containsKey(findingId) && !_statuses.containsKey(findingId);

  /// Mengabaikan temuan: mencatat suppression pada store bersama sehingga
  /// scan berikutnya tidak melaporkan pasangan aturan–subjek ini lagi.
  ///
  /// Alasan wajib terisi; memanggil pada temuan non-terbuka mengembalikan
  /// null tanpa efek ganda.
  ContradictionDismissalRecord? dismiss(
    String findingId, {
    required String reason,
    String actor = '',
  }) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'must not be blank');
    }
    if (!_isOpen(findingId)) return null;
    final finding = _findings[findingId]!;
    final record = ContradictionDismissalRecord(
      id: finding.id,
      ruleId: finding.ruleId,
      subjectId: finding.subjectId,
      reason: trimmed,
      actor: actor,
      dismissedAt: _clock(),
    );
    _dismissals.add(record);
    _statuses[findingId] = ContradictionInboxStatus.dismissed;
    _history.add(
      ContradictionInboxEvent(
        findingId: findingId,
        action: 'dismiss',
        at: record.dismissedAt,
        actor: actor,
        note: trimmed,
      ),
    );
    return record;
  }

  /// Menandai temuan selesai ditangani. Catatan wajib terisi; tidak
  /// menyentuh store dismissal. Null bila temuan non-terbuka.
  ContradictionInboxEvent? resolve(String findingId, {required String note}) {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(note, 'note', 'must not be blank');
    }
    if (!_isOpen(findingId)) return null;
    final event = ContradictionInboxEvent(
      findingId: findingId,
      action: 'resolve',
      at: _clock(),
      note: trimmed,
    );
    _statuses[findingId] = ContradictionInboxStatus.resolved;
    _history.add(event);
    return event;
  }

  /// Membuka kembali temuan yang di-dismiss dengan menghapus suppression
  /// pada store bersama. False bila bukan status dismissed / tak ada
  /// suppression yang cocok.
  bool restore(String findingId) {
    if (_statuses[findingId] != ContradictionInboxStatus.dismissed) {
      return false;
    }
    if (_dismissals.remove(findingId) == null) return false;
    _statuses.remove(findingId);
    _history.add(
      ContradictionInboxEvent(
        findingId: findingId,
        action: 'restore',
        at: _clock(),
      ),
    );
    return true;
  }

  /// Status penyelesaian temuan; null berarti masih terbuka/tak dikenal.
  ContradictionInboxStatus? statusOf(String findingId) => _statuses[findingId];

  /// Riwayat aksi kronologis (urutan pencatatan).
  List<ContradictionInboxEvent> get history => List.unmodifiable(_history);

  Map<String, Object?> toJson() => <String, Object?>{
    'version': 1,
    'statuses': <String, Object?>{
      for (final entry in _statuses.entries) entry.key: entry.value.name,
    },
    'events': <Object?>[for (final event in _history) event.toJson()],
  };

  static ContradictionInbox fromJson(
    Map<String, Object?> json, {
    ContradictionDismissalStore? dismissals,
    DateTime Function()? clock,
  }) {
    final inbox = ContradictionInbox(dismissals: dismissals, clock: clock);
    final statuses = json['statuses'];
    if (statuses is Map<Object?, Object?>) {
      statuses.forEach((key, value) {
        final status = switch (value) {
          'dismissed' => ContradictionInboxStatus.dismissed,
          'resolved' => ContradictionInboxStatus.resolved,
          _ => null,
        };
        if (status != null) inbox._statuses[key.toString()] = status;
      });
    }
    final events = json['events'];
    if (events is List<Object?>) {
      for (final raw in events.whereType<Map<Object?, Object?>>()) {
        inbox._history.add(
          ContradictionInboxEvent.fromJson(
            raw.map((k, v) => MapEntry(k.toString(), v)),
          ),
        );
      }
    }
    return inbox;
  }
}
