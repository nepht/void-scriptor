# Skeptic Report — Content Domain

Target: `D:\VoidScriptor\void_scriptor_multiplatform`
Branch/HEAD verified: `master` / `bc96094c48f3c02784ca04ec2b2759ad5c2cfd91`
Hunter report reviewed: `docs/evidence/vs-hunt-20260914-content/hunter_report.md`

I independently read each reported implementation location, its surrounding code and canonical sprint_109 header comment, and the matching POV/lore tests. Decisions use the required expected-value rule: DISPROVE only when confidence is greater than 67%.

---
**CT-BUG-01** | Original: 5 pts
- **Counter-argument:** No counter-argument supports dismissal. The large-graph branch returns before constructing `survivors`, so all four optional filters are ignored. It also chooses the center from all nodes, rather than from the requested filtered domain/project/canon set.
- **Evidence:** The sprint_109 header defines `filter_nodes` as filtration by domain, canon status, and project, and `filter_edges` as requiring both endpoints to survive. `buildView` enters `if (_nodes.length > maxRenderNodes)` at lines 138-140 and directly returns `_neighborhood(...)`; the filtering code begins only at line 142. The test only establishes fallback activation and reduced node count, so it does not establish filter preservation.
- **Confidence:** 99%
- **Risk calc:** EV = (99% x 5) - (1% x 10) = 4.85
- **Decision:** ACCEPT

---
**CT-BUG-02** | Original: 5 pts
- **Counter-argument:** No counter-argument supports dismissal. The public documentation explicitly promises add/update behavior, but `putIfAbsent` refuses to replace an existing value for the same ID. Therefore edits to any immutable node field remain stale while insertion order is preserved.
- **Evidence:** `lore_graph.dart` says `/// Menambah/memperbarui node; urutan pertama dipertahankan.` Immediately below, `void addNode(LoreNode node) => _nodes.putIfAbsent(node.id, () => node);`. `LoreNode` fields such as `label`, `projectId`, `canon`, and `firstMention` are final, so the old object cannot reflect the replacement values. The matching graph tests cover filtering/focus/fallback but do not test duplicate-ID replacement.
- **Confidence:** 99%
- **Risk calc:** EV = (99% x 5) - (1% x 10) = 4.85
- **Decision:** ACCEPT

---
**CT-BUG-03** | Original: 5 pts
- **Counter-argument:** No counter-argument supports dismissal. `hinted` is keyed only by destination `c`, while the emitted finding identity is `hint:$a>$c`. Once one source produces a hint to a destination, another source's distinct valid gap to that same destination is skipped.
- **Evidence:** In the documented triadic-gap loop, the code says `if (c == a || hinted.contains(c)) continue;`, then records `hinted.add(c)` and emits `id: 'hint:$a>$c'`. The contract documents a gap for `A->B->C` without a direct `A-C` relation; it does not say that all source-specific gaps to the same C are one finding. Existing lore tests exercise one chain (`n-zed->n-kael->n-mira`) and one closed triangle only, so they do not validate multiple source nodes.
- **Confidence:** 96%
- **Risk calc:** EV = (96% x 5) - (4% x 10) = 4.60
- **Decision:** ACCEPT

---
**CT-BUG-04** | Original: 5 pts
- **Counter-argument:** The reported invariant is not established by the canonical contract. Section override is documented as an operation over all section members whose resulting value is always `locked`; neither `defineSection` nor `overrideSection` documents or tests a requirement that every member was previously registered through `lockScene`. Thus creating a lock entry for a listed member is consistent with the stated override behavior, and `statusOf` correctly reports that resulting entry as locked.
- **Evidence:** The file header defines `section_override` as a section inheriting scene locks except where explicitly overridden. The method documentation states `Meng-override seluruh adegan anggota satu bagian sekaligus; nilai hasil override selalu berstatus locked.` The implementation assigns `ScenePovLock` for every `members` entry and removes it from `_unlockedScenes`. The tests define and lock `sc-01`/`sc-02` before overriding, but contain no assertion that uninitialized members must throw. There is no scene registry separate from `_sceneLocks` against which unknown IDs could be validated.
- **Confidence:** 82%
- **Risk calc:** EV = (82% x 5) - (18% x 10) = 2.30
- **Decision:** DISPROVE

---
**CT-BUG-05** | Original: 1 pt
- **Counter-argument:** No counter-argument supports dismissal. The documentation requires `markUnlocked` to be valid only from `locked`, but the guard checks only whether a lock entry exists. After one unlock, the entry remains and a second call silently succeeds instead of raising a state error.
- **Evidence:** `markUnlocked` contains `if (!_sceneLocks.containsKey(sceneId)) throw StateError(...)`, followed by `_unlockedScenes.add(sceneId)`. It never checks `_unlockedScenes.contains(sceneId)`. The canonical visible-status test checks the first transition and re-locking, not repeated unlock, so it does not disprove the finding.
- **Confidence:** 98%
- **Risk calc:** EV = (98% x 1) - (2% x 2) = 0.94
- **Decision:** ACCEPT

---
**CT-BUG-06** | Original: 5 pts
- **Counter-argument:** No counter-argument supports dismissal with sufficient confidence. `KnowledgeTime` exposes both scene and chapter variants, but `compareTo` collapses whichever field is present to a string and applies ordinary lexicographic comparison. Consequently `sc-10` sorts before `sc-2`, and a scene ID is compared directly against a chapter ID without a defined shared timeline ordering. The header contract requires chronological event recording and precise timeline queries; the comment's stated repository convention does not make arbitrary non-padded IDs numerically ordered.
- **Evidence:** The implementation is exactly `final a = sceneId ?? chapterId ?? ''; final b = other.sceneId ?? other.chapterId ?? ''; return a.compareTo(b);`. The tests use padded scene IDs (`sc-01`, `sc-02`, `sc-03`, `sc-05`, `sc-07`, `sc-08`, `sc-09`, `sc-20`, `sc-30`) and therefore do not exercise the failing cases. The header explicitly calls `timeline_query` a canonical capability, while no code maps chapter and scene identifiers onto a common ordinal.
- **Confidence:** 78%
- **Risk calc:** EV = (78% x 5) - (22% x 10) = 1.70
- **Decision:** ACCEPT

---

**SUMMARY:**
- Bugs disproved: 1 (total points claimed: 5)
- Bugs accepted as real: 5 (total points: 21)
- Skeptic final score: 5 points (no accepted finding was wrongly dismissed)

**ACCEPTED BUG LIST:**
- CT-BUG-01 — Medium
- CT-BUG-02 — Medium
- CT-BUG-03 — Medium
- CT-BUG-05 — Low
- CT-BUG-06 — Medium

ACCEPTED: 5 / DISPROVED: 1
