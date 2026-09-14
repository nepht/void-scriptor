/// Kontrak Lore Graph Integrity Insights (Step 109.24).
///
/// Analisis integritas graf lore sebagai domain murni (tanpa DB/UI),
/// mengikat graf 109.23. Lima kemampuan kanonik sprint_109.json:
/// 1. **orphan_report** — node tanpa satu pun relasi dilaporkan yatim;
/// 2. **conflict_path** — relasi identik ganda pada pasangan sama
///    dilaporkan konflik (relasi berbeda bukan konflik);
/// 3. **missing_relation_hint** — celah triadik rantai A->B->C tanpa
///    relasi langsung C diberi petunjuk;
/// 4. **explain_result** — penjelasan deterministik menyebut subjek dan
///    jenis temuan;
/// 5. **dismiss_hint** — temuan dapat diabaikan beserta alasan dan
///    statusnya bertahan lintas analisis berikutnya.
library;

import 'lore_graph.dart';

/// Jenis temuan integritas.
enum LoreInsightKind {
  /// Node yatim tanpa relasi.
  orphanNode,

  /// Relasi ganda identik pada pasangan sama.
  conflictingRelation,

  /// Petunjuk celah relasi triadik.
  missingRelation,
}

/// Satu temuan integritas dengan penjelasan deterministik.
class LoreInsight {
  const LoreInsight({
    required this.id,
    required this.kind,
    required this.subjectId,
    required this.explanation,
  });

  /// Identitas temuan stabil lintas analisis (mis. orphan:n-pulau).
  final String id;
  final LoreInsightKind kind;

  /// Node subjek utama temuan.
  final String subjectId;

  /// Penjelasan siap tampil yang deterministik.
  final String explanation;
}

/// Catatan pengabaian sebuah temuan.
class LoreDismissal {
  const LoreDismissal({
    required this.insightId,
    required this.reason,
    required this.at,
  });

  final String insightId;
  final String reason;
  final DateTime at;
}

/// Hasil satu kali analisis: seluruh temuan plus status pengabaian.
class LoreIntegrityReport {
  const LoreIntegrityReport({
    required this.insights,
    required this.dismissals,
    required this.dismissedIds,
  });

  /// Temuan saat ini urut deterministik.
  final List<LoreInsight> insights;

  /// Seluruh pengabaian yang pernah dicatat analyzer ini.
  final List<LoreDismissal> dismissals;
  final Set<String> dismissedIds;

  /// Temuan yang belum diabaikan.
  List<LoreInsight> get activeInsights =>
      List.unmodifiable(insights.where((i) => !dismissedIds.contains(i.id)));
}

/// Analisis integritas graf lore; instans memegang status pengabaian.
class LoreIntegrityAnalyzer {
  LoreIntegrityAnalyzer({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, LoreDismissal> _dismissed = <String, LoreDismissal>{};
  Set<String> _lastFindingIds = <String>{};

  /// Analisis sekali jalan pada tingkat statis tanpa status pengabaian.
  static LoreIntegrityReport analyzeStatic(LoreGraph graph) =>
      LoreIntegrityAnalyzer().analyze(graph);

  /// Menganalisis graf: laporan penuh temuan aktif + pengabaian.
  LoreIntegrityReport analyze(LoreGraph graph) {
    final nodes = graph.nodes;
    final edges = graph.edges;
    final findings = <LoreInsight>[];

    final degree = <String, int>{};
    for (final edge in edges) {
      degree[edge.sourceId] = (degree[edge.sourceId] ?? 0) + 1;
      degree[edge.targetId] = (degree[edge.targetId] ?? 0) + 1;
    }

    // Orphans: urutan penyusunan node.
    for (final node in nodes) {
      if ((degree[node.id] ?? 0) == 0) {
        findings.add(
          LoreInsight(
            id: 'orphan:${node.id}',
            kind: LoreInsightKind.orphanNode,
            subjectId: node.id,
            explanation:
                'Node ${node.id} yatim: tidak memiliki satu pun '
                'relasi pada graf lore.',
          ),
        );
      }
    }

    // Conflicts: pasangan+relasi identik; kemunculan pertama menang.
    final seenFirst = <String, String>{};
    for (final edge in edges) {
      final key = '${edge.sourceId}>${edge.targetId}:${edge.relation}';
      if (seenFirst.containsKey(key)) {
        findings.add(
          LoreInsight(
            id: 'conflict:$key',
            kind: LoreInsightKind.conflictingRelation,
            subjectId: edge.sourceId,
            explanation:
                'Relasi ${edge.relation} dari ${edge.sourceId} ke '
                '${edge.targetId} tercatat ganda: pertama pada '
                '${seenFirst[key]}, kedua pada ${edge.id}.',
          ),
        );
      } else {
        seenFirst[key] = edge.id;
      }
    }

    // Missing-relation hints: triadik A->B->C tanpa A-C langsung.
    final forward = <String, Set<String>>{};
    final backward = <String, Set<String>>{};
    for (final edge in edges) {
      forward.putIfAbsent(edge.sourceId, () => <String>{}).add(edge.targetId);
      backward.putIfAbsent(edge.targetId, () => <String>{}).add(edge.sourceId);
    }
    final hinted = <String>{};
    for (final edge in edges) {
      final a = edge.sourceId;
      final b = edge.targetId;
      for (final c in forward[b] ?? const <String>{}) {
        // vs-hunt-20260914-content CT-BUG-03: dedup memakai identitas
        // temuan (sumber,tujuan) — bukan tujuan saja — supaya celah dari
        // sumber lain ke tujuan yang sama tidak ikut teredam.
        final hintKey = '$a>$c';
        if (c == a || hinted.contains(hintKey)) continue;
        if (forward[a]?.contains(c) ?? false) continue;
        if (backward[c]?.contains(a) ?? false) continue;
        hinted.add(hintKey);
        findings.add(
          LoreInsight(
            id: 'hint:$a>$c',
            kind: LoreInsightKind.missingRelation,
            subjectId: a,
            explanation:
                'Petunjuk relasi: $a dan $c sama-sama terhubung ke $b '
                'namun belum memiliki relasi langsung.',
          ),
        );
      }
    }

    _lastFindingIds = findings.map((i) => i.id).toSet();
    final active = findings
        .where((i) => !_dismissed.containsKey(i.id))
        .toList();
    return LoreIntegrityReport(
      insights: List.unmodifiable(active),
      dismissals: List.unmodifiable(_dismissed.values),
      dismissedIds: Set.unmodifiable(_dismissed.keys.toSet()),
    );
  }

  /// Mengabaikan temuan dari analisis terakhir; wajib beralasan;
  /// [StateError] bila id tak dikenal atau bukan hasil analisis terakhir.
  void dismiss(String insightId, {required String reason}) {
    if (!_lastFindingIds.contains(insightId)) {
      throw StateError('unknown insight for dismissal: $insightId');
    }
    _dismissed[insightId] = LoreDismissal(
      insightId: insightId,
      reason: reason,
      at: _clock(),
    );
  }
}
