/// Pipeline analisis kontradiksi cerita (Step 109.13).
///
/// Mengeksekusi [ContradictionRule] dari langkah 109.12 secara
/// deterministik dengan lima jaminan kanonik:
/// 1. **incremental_scan** — lingkup subjek dapat dibatasi tanpa memindai
///    seluruh proyek;
/// 2. **source_citations** — setiap temuan membawa rujukan sumber atribut;
/// 3. **deterministic_rules** — input sama menghasilkan laporan identik,
///    termasuk ID temuan yang stabil sebagai fingerprint;
/// 4. **dismissal_state** — keputusan abaikan tersimpan sebagai state
///    logika serializable (JSON), bukan skema database;
/// 5. **rescan** — pemindaian ulang mengevaluasi data terbaru sambil tetap
///    menghormati dismissal yang masih berlaku.
///
/// Modul ini domain murni: tanpa Drift dan tanpa UI. Persistensi dismissal
/// ke penyimpanan proyek menyusul di Contradiction Inbox (109.14).
library;

import 'contradiction_rule.dart';

/// Lingkup pemindaian satu run pipeline.
class ContradictionScanScope {
  const ContradictionScanScope({this.subjectIds = const <String>{}});

  /// Subjek yang dinilai. Set kosong berarti pindai penuh.
  final Set<String> subjectIds;

  bool get isFullScan => subjectIds.isEmpty;
}

/// Cuplikan nilai atribut satu subjek beserta provenance-nya.
class SubjectSnapshot {
  const SubjectSnapshot({
    required this.subjectKind,
    required this.subjectId,
    required this.attributes,
    this.sources = const <String, List<ContradictionSourceRef>>{},
  });

  /// Jenis subjek, selaras [ContradictionRule.subjectKind].
  final String subjectKind;

  /// ID stabil subjek (karakter, scene, item, dsb).
  final String subjectId;

  /// Nilai atribut dalam bentuk teks siak.
  final Map<String, String> attributes;

  /// Rujukan sumber per kunci atribut; urutannya dipertahankan apa adanya.
  final Map<String, List<ContradictionSourceRef>> sources;
}

/// Hasil satu run analisis.
class ContradictionAnalysisResult {
  const ContradictionAnalysisResult({
    required this.findings,
    required this.evaluatedRules,
    required this.skippedRules,
    required this.evaluatedSubjects,
    required this.isIncremental,
  });

  final List<ContradictionFinding> findings;
  final int evaluatedRules;

  /// Aturan yang dilewati karena nonaktif atau schema-nya rusak.
  final int skippedRules;
  final int evaluatedSubjects;

  /// True bila run ini memakai lingkup terbatas, bukan pindai penuh.
  final bool isIncremental;
}

/// Satu keputusan "abaikan temuan ini" yang tahan sesi.
class ContradictionDismissalRecord {
  const ContradictionDismissalRecord({
    required this.id,
    required this.ruleId,
    required this.subjectId,
    required this.reason,
    required this.actor,
    required this.dismissedAt,
  });

  /// ID record; identik dengan fingerprint temuan `ruleId::subjectId`.
  final String id;
  final String ruleId;
  final String subjectId;
  final String reason;
  final String actor;
  final DateTime dismissedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'ruleId': ruleId,
    'subjectId': subjectId,
    'reason': reason,
    'actor': actor,
    'dismissedAt': dismissedAt.toIso8601String(),
  };

  static ContradictionDismissalRecord fromJson(Map<String, Object?> json) =>
      ContradictionDismissalRecord(
        id: json['id']! as String,
        ruleId: json['ruleId']! as String,
        subjectId: json['subjectId']! as String,
        reason: json['reason'] as String? ?? '',
        actor: json['actor'] as String? ?? '',
        dismissedAt: DateTime.parse(json['dismissedAt']! as String),
      );
}

/// Penyimpanan keputusan dismissal. State logika serializable — bukan
/// tabel Drift — agar dapat dipersist tanpa migrasi skema.
class ContradictionDismissalStore {
  final Map<String, ContradictionDismissalRecord> _records =
      <String, ContradictionDismissalRecord>{};

  static String keyOf({required String ruleId, required String subjectId}) =>
      '$ruleId::$subjectId';

  Iterable<ContradictionDismissalRecord> get records =>
      _records.values.toList();

  bool get isEmpty => _records.isEmpty;

  void add(ContradictionDismissalRecord record) => _records[record.id] = record;

  ContradictionDismissalRecord? remove(String id) => _records.remove(id);

  bool isDismissed({required String ruleId, required String subjectId}) =>
      _records.containsKey(keyOf(ruleId: ruleId, subjectId: subjectId));

  Map<String, Object?> toJson() => <String, Object?>{
    'version': 1,
    'records': <Object?>[
      for (final record
          in _records.values.toList()..sort((a, b) => a.id.compareTo(b.id)))
        record.toJson(),
    ],
  };

  static ContradictionDismissalStore fromJson(Map<String, Object?> json) {
    final store = ContradictionDismissalStore();
    final records = (json['records'] as List<Object?>? ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>();
    for (final raw in records) {
      store.add(
        ContradictionDismissalRecord.fromJson(
          raw.map((k, v) => MapEntry(k.toString(), v)),
        ),
      );
    }
    return store;
  }
}

/// Orkestrator deterministic untuk menjalankan aturan kontradiksi.
class ContradictionAnalysisPipeline {
  ContradictionAnalysisPipeline({
    ContradictionDismissalStore? dismissals,
    DateTime Function()? clock,
  }) : _dismissals = dismissals ?? ContradictionDismissalStore(),
       _clock = clock ?? DateTime.now;

  final ContradictionDismissalStore _dismissals;
  final DateTime Function() _clock;

  ContradictionDismissalStore get dismissals => _dismissals;

  /// Menjalankan [rules] atas [subjects] dalam [scope], menyaring temuan
  /// yang sedang di-dismiss, dan mengembalikan laporan deterministik.
  ContradictionAnalysisResult scan({
    required Iterable<ContradictionRule> rules,
    required Iterable<SubjectSnapshot> subjects,
    ContradictionScanScope scope = const ContradictionScanScope(),
  }) {
    final byId = <String, SubjectSnapshot>{
      for (final subject in subjects) subject.subjectId: subject,
    };
    final scopedSubjects = scope.isFullScan
        ? byId.values.toList(growable: false)
        : [
            for (final id in scope.subjectIds)
              if (byId.containsKey(id)) byId[id]!,
          ];

    final findings = <ContradictionFinding>[];
    var evaluatedRules = 0;
    var skippedRules = 0;
    var evaluatedSubjects = 0;

    // Urutan deterministik: aturan sesuai urutan input, subjek sesuai
    // urutan input pada pindai penuh, urutan set lingkup saat inkremental.
    for (final rule in rules) {
      if (!rule.enabled || rule.validateSchema().isNotEmpty) {
        skippedRules++;
        continue;
      }
      evaluatedRules++;
      for (final subject in scopedSubjects) {
        if (subject.subjectKind != rule.subjectKind) continue;
        evaluatedSubjects++;
        if (_dismissals.isDismissed(
          ruleId: rule.id,
          subjectId: subject.subjectId,
        )) {
          continue;
        }
        final finding = evaluate(rule: rule, subject: subject);
        if (finding != null) findings.add(finding);
      }
    }

    return ContradictionAnalysisResult(
      findings: findings,
      evaluatedRules: evaluatedRules,
      skippedRules: skippedRules,
      evaluatedSubjects: evaluatedSubjects,
      isIncremental: !scope.isFullScan,
    );
  }

  /// Menilai satu pasangan aturan–subjek. Null berarti tidak melanggar.
  ///
  /// Perbandingan numerik dipakai bila kedua sisi dapat di-parse sebagai
  /// angka (rentang usia dsb); sisanya leksikografis. Keyakinan deteksi
  /// mengikuti provenance: atribut bersumber skor high, nilai telanjang
  /// skor low.
  ContradictionFinding? evaluate({
    required ContradictionRule rule,
    required SubjectSnapshot subject,
  }) {
    final actual = subject.attributes[rule.attributeKey];
    if (actual == null) return null;

    final violated = switch (rule.comparator) {
      ContradictionComparator.equals => actual != rule.expectedValues.first,
      ContradictionComparator.notEquals => actual == rule.expectedValues.first,
      ContradictionComparator.before => !_compare(
        actual,
        rule.expectedValues.first,
        max: false,
      ),
      ContradictionComparator.after => !_compare(
        actual,
        rule.expectedValues.first,
        max: true,
      ),
      ContradictionComparator.withinRange => !_withinRange(
        actual,
        min: rule.expectedValues[0],
        max: rule.expectedValues[1],
      ),
    };
    if (!violated) return null;

    final citations =
        subject.sources[rule.attributeKey] ?? const <ContradictionSourceRef>[];
    return ContradictionFinding(
      id: fingerprint(ruleId: rule.id, subjectId: subject.subjectId),
      ruleId: rule.id,
      subjectId: subject.subjectId,
      dimension: rule.dimension,
      severity: ContradictionSeverity.violation,
      confidence: citations.isEmpty
          ? DetectionConfidence.low
          : DetectionConfidence.high,
      explanation: ContradictionExplanation(
        summary:
            '${rule.title}: "$actual" bertentangan dengan nilai diharapkan.',
        expectedValue: rule.expectedValues.join(' – '),
        actualValue: actual,
        sources: citations,
        suggestion: rule.description,
      ),
    );
  }

  /// Fingerprint stabil temuan: dua pemindaian atas data yang sama
  /// menghasilkan ID identik sehingga dismissal dan riwayat tetap sah.
  static String fingerprint({
    required String ruleId,
    required String subjectId,
  }) => '$ruleId::$subjectId';

  /// Mencatat keputusan abaikan untuk pasangan aturan–subjek sebuah
  /// temuan, lalu mengembalikan recordnya.
  ContradictionDismissalRecord dismiss({
    required ContradictionFinding finding,
    required String reason,
    String actor = '',
  }) {
    final record = ContradictionDismissalRecord(
      id: fingerprint(ruleId: finding.ruleId, subjectId: finding.subjectId),
      ruleId: finding.ruleId,
      subjectId: finding.subjectId,
      reason: reason,
      actor: actor,
      dismissedAt: _clock(),
    );
    _dismissals.add(record);
    return record;
  }

  /// Membatalkan dismissal berdasar ID record. False bila tak ditemukan.
  bool restore(String recordId) => _dismissals.remove(recordId) != null;

  /// Perbandingan angka-bila-bisa: numerik lebih diutamakan daripada
  /// leksikografis agar '9' benar dilaporkan di bawah rentang [15, 40].
  static bool _compare(String a, String b, {required bool max}) {
    final na = num.tryParse(a);
    final nb = num.tryParse(b);
    if (na != null && nb != null) {
      return max ? na >= nb : na <= nb;
    }
    return max ? a.compareTo(b) >= 0 : a.compareTo(b) <= 0;
  }

  static bool _withinRange(
    String value, {
    required String min,
    required String max,
  }) {
    final nv = num.tryParse(value);
    final nMin = num.tryParse(min);
    final nMax = num.tryParse(max);
    if (nv != null && nMin != null && nMax != null) {
      return nv >= nMin && nv <= nMax;
    }
    return value.compareTo(min) >= 0 && value.compareTo(max) <= 0;
  }
}
