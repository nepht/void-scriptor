# Adversarial Bug Hunt Report — Content Domain

Scope was read completely: POV, spoiler, and lore domain files, their feature tests, the scope hash manifest, and the content capability catalog. Findings below are limited to behaviors evidenced in the read source.

---
**CT-BUG-01** | Severity: Medium | Points: 5
- **File:** `lib/features/lore/domain/lore_graph.dart`
- **Line(s):** 138-140
- **Category:** logic
- **Claim:** Large-graph fallback ignores every requested node/edge filter and can return nodes outside the requested domain, canon, project, or relation.
- **Evidence:** `if (_nodes.length > maxRenderNodes) {\n      final ids = _nodes.keys.toList();\n      return _neighborhood(ids[ids.length ~/ 2], fallbackActive: true);\n    }`
---

---
**CT-BUG-02** | Severity: Medium | Points: 5
- **File:** `lib/features/lore/domain/lore_graph.dart`
- **Line(s):** 113-114
- **Category:** data-integrity
- **Claim:** `addNode` promises add/update behavior but silently retains the original node when the same ID is added again, leaving edited labels, canon state, project, or source references stale.
- **Evidence:** `/// Menambah/memperbarui node; urutan pertama dipertahankan.\n  void addNode(LoreNode node) => _nodes.putIfAbsent(node.id, () => node);`
---

---
**CT-BUG-03** | Severity: Medium | Points: 5
- **File:** `lib/features/lore/domain/lore_integrity.dart`
- **Line(s):** 152-159
- **Category:** logic
- **Claim:** Missing-relation hints are deduplicated by destination node globally, so valid gaps from different source nodes to the same destination are incorrectly suppressed.
- **Evidence:** `final hinted = <String>{};\n    for (final edge in edges) {\n      final a = edge.sourceId;\n      final b = edge.targetId;\n      for (final c in forward[b] ?? const <String>{}) {\n        if (c == a || hinted.contains(c)) continue;`
---

---
**CT-BUG-04** | Severity: Medium | Points: 5
- **File:** `lib/features/pov/domain/pov_lock.dart`
- **Line(s):** 102-121
- **Category:** data-integrity
- **Claim:** `overrideSection` creates locks for section members that were never locked as scenes, bypassing the scene-POV lock invariant and turning unknown scene IDs into apparently valid locked scenes.
- **Evidence:** `/// Meng-override seluruh adegan anggota satu bagian sekaligus;\n  /// nilai hasil override selalu berstatus locked.\n  void overrideSection({` followed by `for (final sceneId in members) {\n      _sceneLocks[sceneId] = ScenePovLock(`
---

---
**CT-BUG-05** | Severity: Low | Points: 1
- **File:** `lib/features/pov/domain/pov_lock.dart`
- **Line(s):** 84-90
- **Category:** error-handling
- **Claim:** `markUnlocked` accepts repeated unlock operations although its documented precondition requires the scene to be in the locked state, so an already-unlocked scene does not raise the promised state error.
- **Evidence:** `/// Membuka kunci satu adegan; hanya sah dari status locked\n  /// ([StateError] bila belum ada kunci).\n  void markUnlocked(String sceneId) {\n    if (!_sceneLocks.containsKey(sceneId)) {\n      throw StateError('scene has no lock to unlock: $sceneId');\n    }\n    _unlockedScenes.add(sceneId);\n  }`
---

---
**CT-BUG-06** | Severity: Medium | Points: 5
- **File:** `lib/features/pov/domain/knowledge_boundary.dart`
- **Line(s):** 24-29
- **Category:** edge-case
- **Claim:** Timeline comparisons are raw lexicographic comparisons of whichever ID field is present, so the documented scene/chapter timeline is incorrect for non-zero-padded IDs and is not meaningfully ordered across scene and chapter time types.
- **Evidence:** `/// Urutan pembanding dalam satu proyek: id adegan dipakai langsung\n  /// karena konvensi repo memakai 'sc-<angka>' monoton.\n  int compareTo(KnowledgeTime other) {\n    final a = sceneId ?? chapterId ?? '';\n    final b = other.sceneId ?? other.chapterId ?? '';\n    return a.compareTo(b);\n  }`
---

## Notes

The existing tests cover the happy path with zero-padded `sc-01`-style identifiers and do not exercise the filter/fallback interaction, node replacement, multiple independent triadic gaps, uninitialized section members, repeated unlock, or non-padded/mixed timeline identifiers.

TOTAL FINDINGS: 6
TOTAL SCORE: 26
