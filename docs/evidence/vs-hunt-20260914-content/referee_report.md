# Referee Report — Content Domain

Target: `D:\VoidScriptor\void_scriptor_multiplatform`  
HEAD: `bc96094c48f3c02784ca04ec2b2759ad5c2cfd91`  
Scope: sprint_109 content-domain modules, their canonical header contracts, POV/lore/spoiler tests, and repository callers.

## Stats

| Measure | Count |
|---|---:|
| Findings reported by Hunter | 6 |
| Skeptic accepted | 5 |
| Skeptic disputed/disproved | 1 |
| Referee: REAL BUG | 5 |
| Referee: NOT A BUG / dismissed | 1 |
| Critical | 0 |
| High | 0 |
| Medium | 3 |
| Low | 2 |

The affected classes are domain-only in the current product wiring. Search of `lib/` found no application callers for `LoreGraph`, `PovLedger`, `KnowledgeLedger`, or `LoreIntegrityAnalyzer`; the content capability catalog lists the related Bible and Pacing/POV areas as partial/domain-only rather than a fully wired workflow. Severity therefore reflects the contract and domain impact without treating these as currently proven production outages.

---

## CT-BUG-01

- **Hunter's claim:** On graphs larger than `maxRenderNodes`, `buildView` ignores node and edge filters and may return nodes outside the requested domain, canon, project, or relation.
- **Skeptic's response:** ACCEPT. The fallback returns before the filtering code and chooses its center from all node IDs.
- **Your analysis:** I verified the `LoreGraph` header contract: `filter_nodes` requires independent domain, canon-status, and project filtering; `filter_edges` requires both endpoints to survive and requires a matching relation when requested. In `buildView`, lines 138–140 immediately enter the large-graph branch and call `_neighborhood` using the middle ID of `_nodes.keys()`. The `survivors` map and relation-filtered edge construction begin only at lines 142–155. `_neighborhood` itself has no filter parameters and appends every incident edge and neighbor. Thus a call such as `buildView(domainFilter: ..., projectFilter: ..., relationFilter: ...)` on a large graph can return nonmatching nodes and edges. The lore graph test only checks fallback activation and smaller output, not filter preservation in fallback. This is a direct contract violation, independently verified.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Apply node filters first, then apply relation/end-point edge filters, and select the fallback center from the surviving nodes. Define deterministic behavior when no nodes survive (for example an empty fallback view with no center) rather than indexing an unfiltered list.

---

## CT-BUG-02

- **Hunter's claim:** `addNode` promises add/update semantics but retains the original immutable node for duplicate IDs.
- **Skeptic's response:** ACCEPT. `putIfAbsent` preserves the old object and only preserves insertion order as a side effect.
- **Your analysis:** The file header establishes the graph model, and the method comment at lines 113–114 explicitly says “add/update node; first order preserved.” The implementation is `_nodes.putIfAbsent(node.id, () => node)`. Since `LoreNode` fields (`label`, `domain`, `projectId`, `canon`, and `firstMention`) are final, a second node with the same ID cannot update the stored values. Existing edges refer to the ID and would remain compatible with replacement, so the intended operation can preserve map order while assigning `_nodes[node.id] = node`. The existing graph tests do not exercise duplicate IDs or replacement fields. This is a real data-integrity defect.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Replace the value unconditionally while retaining insertion order. In Dart's insertion-ordered map, `_nodes[node.id] = node` preserves the existing key position. Add a test that replaces label, canon, project, and source fields and verifies the original position remains unchanged.

---

## CT-BUG-03

- **Hunter's claim:** Missing-relation hints are deduplicated globally by destination node, suppressing distinct gaps from other source nodes to the same destination.
- **Skeptic's response:** ACCEPT. The emitted identity is source-specific (`hint:$a>$c`), but the suppression set contains only `c`.
- **Your analysis:** I verified the canonical `missing_relation_hint` header contract: each triadic `A->B->C` gap without a direct `A-C` relation receives a hint. The loop uses `hinted = <String>{}` and skips when `hinted.contains(c)` at line 157. It then adds only `c` at line 160 but emits an ID containing both source and destination at line 163. Therefore after one valid `A->...->C` hint, a distinct `D->...->C` hint is skipped even though its source-specific relation is independently absent. The existing lore test has one open chain and one closed triangle, so it does not pin the multi-source case. This is a real logic defect.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Deduplicate by the actual finding identity, at minimum the `(sourceId, destinationId)` pair (for example `hinted` as `Set<String>` containing `'$a>$c'`). Preserve the existing direct-edge and reverse-edge suppression rules, and add a test with two independent sources reaching the same destination.

---

## CT-BUG-04

- **Hunter's claim:** `overrideSection` creates locks for unregistered/never-locked section members, violating a scene-POV lock invariant and making unknown IDs appear locked.
- **Skeptic's response:** DISPROVE. The canonical contract says a section override applies to all members and always yields locked values; it does not require prior `lockScene` registration or define a separate scene registry.
- **Your analysis:** I read the complete `pov_lock.dart` header and surrounding API. The stated capabilities are scene locks, section override, tense, explicit narration mode, and visible status. `defineSection` stores a list of scene IDs, while `overrideSection` documents that all member scenes are overridden and the result is always `locked`. The implementation assigns a `ScenePovLock` for every listed member and removes its unlocked marker. `statusOf` defines an unknown scene as `unset` only when it has no lock entry; after the documented override operation, a listed member is no longer unknown to the ledger and is correctly reported `locked`. There is no separate scene registry or contract precondition requiring each member to have been previously locked. The test uses pre-locked members, but that is coverage choice, not proof of the alleged invariant. The reported requirement is not established by the canonical contract, so this behavior is consistent with the API.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

## CT-BUG-05

- **Hunter's claim:** `markUnlocked` permits repeated unlocks although its documentation says it is valid only from the locked state.
- **Skeptic's response:** ACCEPT. The guard checks only map membership; it never checks whether the scene is already in `_unlockedScenes`.
- **Your analysis:** The method comment says unlocking is valid only from `locked` and promises `StateError` when there is no lock. `lockScene` leaves the lock entry in `_sceneLocks` after an unlock and records the state separately in `_unlockedScenes`. `markUnlocked` checks only `_sceneLocks.containsKey(sceneId)` and then performs an idempotent set add. Consequently the second call on the same scene succeeds and leaves status `unlocked`, rather than rejecting an invalid state transition. The visible-status test covers the first unlock and unlock-then-relock, but not repeated unlock. This is a real state-machine/error-handling defect.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Reject when `_unlockedScenes.contains(sceneId)` is already true, with a state-specific `StateError`; retain the existing unknown-scene check. Add tests for repeated unlock and for unlock after a successful relock.

---

## CT-BUG-06

- **Hunter's claim:** `KnowledgeTime.compareTo` uses raw string comparison, producing wrong ordering for non-zero-padded scene IDs and undefined ordering across scene/chapter IDs.
- **Skeptic's response:** ACCEPT. The implementation compares whichever ID field is present lexicographically; tests use only padded scene IDs.
- **Your analysis:** The header contract requires chronological knowledge events and exact timeline queries. `compareTo` reduces a scene or chapter time to a string and calls `String.compareTo`. For scene IDs, `sc-10` compares before `sc-2`, so a fact at `sc-10` can be treated as earlier than a query at `sc-2`. The constructors also permit chapter times, but no mapping establishes a common ordinal between chapter and scene identifiers; mixed comparisons therefore have no meaningful chronology. The knowledge-boundary tests use zero-padded scene IDs (`sc-01`, `sc-02`, etc.), which masks the numeric-order failure and do not test mixed time types. The comment cites a repository convention of `sc-<angka>` IDs, but that convention does not make arbitrary numeric strings lexicographically ordered, nor does it define chapter/scene ordering. This is a real robustness defect in a canonical timeline API. Because the current repository has no callers beyond the domain module and the failing inputs are outside the demonstrated padded-ID convention, I downgrade the Hunter's rating.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Represent timeline positions with an explicit comparable ordinal (or inject a project timeline resolver) and compare numeric scene/chapter positions rather than raw IDs. If mixed scene/chapter comparisons are intentionally unsupported, reject them explicitly instead of returning a misleading lexical result. Add non-padded and mixed-type tests.

---

## Final Report

**VERIFIED BUG REPORT**

- Total reported by Hunter: 6
- Dismissed as false positives: 1
- Confirmed as real bugs: 5
- Critical: 0 | High: 0 | Medium: 3 | Low: 2

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|---|---|---:|---|---|
| CT-BUG-01 | Medium | `lib/features/lore/domain/lore_graph.dart` | 138–155 | Large-graph fallback bypasses all requested filters. | Filter survivors and edges before choosing the fallback center. |
| CT-BUG-02 | Medium | `lib/features/lore/domain/lore_graph.dart` | 113–114 | Duplicate node IDs do not update immutable node data. | Assign replacement values directly while preserving map order. |
| CT-BUG-03 | Medium | `lib/features/lore/domain/lore_integrity.dart` | 152–164 | Hint suppression is keyed only by destination, losing source-specific gaps. | Deduplicate by source/destination finding identity. |
| CT-BUG-05 | Low | `lib/features/pov/domain/pov_lock.dart` | 84–90 | Repeated unlock is accepted instead of rejected as an invalid state transition. | Check `_unlockedScenes` before adding and throw `StateError`. |
| CT-BUG-06 | Low | `lib/features/pov/domain/knowledge_boundary.dart` | 24–29 | Lexical IDs do not provide reliable numeric or mixed timeline ordering. | Use explicit numeric/project timeline ordinals or reject unsupported comparisons. |

Low-confidence items: none. CT-BUG-04 was disputed but independently dismissed with high confidence; it is not a low-confidence item.

REAL BUGS: 5 / DISMISSED: 1
