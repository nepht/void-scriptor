/// Kontrak Writer-Focused Lore Graph (Step 109.23).
///
/// Graf hubungan entitas lore sebagai domain murni (tanpa DB/UI).
/// Lima kemampuan kanonik sprint_109.json:
/// 1. **filter_nodes** — filtrasi node menurut domain, status canon,
///    dan project secara independen;
/// 2. **filter_edges** — edge hanya bertahan bila kedua ujungnya lolos
///    filtrasi node dan relasinya cocok;
/// 3. **focus_entity** — fokus entitas memuat tetangga langsung saja;
/// 4. **source_navigation** — node membawa firstMention dan edge membawa
///    atMention sebagai rujukan sumber bab;
/// 5. **large_graph_fallback** — graf di atas ambang render otomatis
///    jatuh ke tampilan lingkungan satu pusat dan menandai fallback.
library;

/// Domain lore sebuah node.
enum LoreDomain {
  /// Tokoh.
  character,

  /// Lokasi/territori.
  location,

  /// Bahasa buatan.
  language,

  /// Benda penting.
  item,

  /// Peristiwa.
  event,
}

/// Node entitas lore.
class LoreNode {
  const LoreNode({
    required this.id,
    required this.label,
    required this.domain,
    required this.projectId,
    required this.canon,
    required this.firstMention,
  });

  final String id;
  final String label;
  final LoreDomain domain;

  /// Project pemilik entitas.
  final String projectId;

  /// Status kanonis entitas.
  final bool canon;

  /// Rujukan sumber kemunculan pertama (mis. id bab).
  final String firstMention;
}

/// Edge relasi terarah antara dua node.
class LoreEdge {
  const LoreEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.relation,
    required this.atMention,
  });

  final String id;
  final String sourceId;
  final String targetId;

  /// Nama relasi bebas (sekutu, penutur, dsb).
  final String relation;

  /// Rujukan sumber saat relasi terjadi (mis. id bab).
  final String atMention;
}

/// Hasil tampilan graf yang siap dirender UI.
class LoreGraphView {
  const LoreGraphView({
    required this.nodes,
    required this.edges,
    required this.focusNodeId,
    required this.fallbackActive,
  });

  /// Node urut deterministik (urutan penyusunan/pemusatan).
  final List<LoreNode> nodes;

  /// Edge yang kedua ujungnya berada dalam tampilan.
  final List<LoreEdge> edges;

  /// Node pusat untuk tampilan fokus/fallback; null pada tampilan penuh.
  final String? focusNodeId;

  /// True bila tampilan adalah hasil fallback graf besar.
  final bool fallbackActive;
}

/// Graf lore satu project; murni domain.
class LoreGraph {
  /// Ambang jumlah node sebelum render penuh ditolak dan fallback aktif.
  static const int maxRenderNodes = 32;

  final Map<String, LoreNode> _nodes = <String, LoreNode>{};
  final List<LoreEdge> _edges = <LoreEdge>[];

  /// Jumlah seluruh node pada graf.
  int get nodeCount => _nodes.length;

  /// Menambah/memperbarui node; urutan pertama dipertahankan.
  void addNode(LoreNode node) => _nodes.putIfAbsent(node.id, () => node);

  /// Menambah edge; kedua ujung wajib sudah ada ([StateError]).
  void addEdge(LoreEdge edge) {
    if (!_nodes.containsKey(edge.sourceId) ||
        !_nodes.containsKey(edge.targetId)) {
      throw StateError('edge ${edge.id} references unknown node');
    }
    _edges.add(edge);
  }

  /// Salinan node urut penyusunan (akses baca untuk analisis).
  List<LoreNode> get nodes => List.unmodifiable(_nodes.values);

  /// Salinan edge urut penyusunan (akses baca untuk analisis).
  List<LoreEdge> get edges => List.unmodifiable(_edges);

  /// Menyusun tampilan dengan filtrasi opsional; deterministik.
  LoreGraphView buildView({
    LoreDomain? domainFilter,
    bool canonOnly = false,
    String? projectFilter,
    String? relationFilter,
  }) {
    if (_nodes.length > maxRenderNodes) {
      final ids = _nodes.keys.toList();
      return _neighborhood(ids[ids.length ~/ 2], fallbackActive: true);
    }
    final survivors = <String, LoreNode>{
      for (final node in _nodes.values)
        if ((domainFilter == null || node.domain == domainFilter) &&
            (!canonOnly || node.canon) &&
            (projectFilter == null || node.projectId == projectFilter))
          node.id: node,
    };
    final edges = <LoreEdge>[
      for (final edge in _edges)
        if (survivors.containsKey(edge.sourceId) &&
            survivors.containsKey(edge.targetId) &&
            (relationFilter == null || edge.relation == relationFilter))
          edge,
    ];
    return LoreGraphView(
      nodes: List.unmodifiable(survivors.values),
      edges: List.unmodifiable(edges),
      focusNodeId: null,
      fallbackActive: false,
    );
  }

  /// Menyusun tampilan fokus pada satu entitas: pusat plus tetangga
  /// langsung saja; [StateError] bila entitas tak dikenal.
  LoreGraphView buildFocus({required String entityId}) {
    if (!_nodes.containsKey(entityId)) {
      throw StateError('unknown focus entity: $entityId');
    }
    return _neighborhood(entityId, fallbackActive: false);
  }

  LoreGraphView _neighborhood(String centerId, {required bool fallbackActive}) {
    final center = _nodes[centerId]!;
    final nodes = <LoreNode>[center];
    final seen = <String>{centerId};
    final edges = <LoreEdge>[];
    for (final edge in _edges) {
      var other = '';
      if (edge.sourceId == centerId) {
        other = edge.targetId;
      } else if (edge.targetId == centerId) {
        other = edge.sourceId;
      } else {
        continue;
      }
      edges.add(edge);
      final neighbor = _nodes[other];
      if (neighbor != null && seen.add(other)) {
        nodes.add(neighbor);
      }
    }
    return LoreGraphView(
      nodes: List.unmodifiable(nodes),
      edges: List.unmodifiable(edges),
      focusNodeId: centerId,
      fallbackActive: fallbackActive,
    );
  }
}
