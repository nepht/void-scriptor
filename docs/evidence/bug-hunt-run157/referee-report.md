# Referee Report — Void Scriptor narrative-assignment / support-relationship region (hunt-run157)

Repo: D:\VoidScriptor\void_scriptor_multiplatform — branch `master`, HEAD verified by me: `2317894d4149c3cf49a32401cf5dfe58eabe666c` (matches both agents). Working tree has only untracked/modified docs (`.hermes/`, `docs/backlog/` — the backlog file I read is untracked but present on disk); no code files dirty.

Method: read every in-scope file myself (narrative_assignment_card.dart, support_relationship_section.dart, narrative_assignment_repository.dart, narrative_assignment.dart, narrative_character_filter.dart, character_narrative_assignments.dart table), plus traced files: character_repository_impl.dart, project_persistence_providers.dart, project selection/resolver chain (inspector_panel, inspector_resolver, character_inspector, selection_controller, explorer_panel tap paths), character_mode_controller.dart, workspace_resolver.dart, scene_workspace_screen.dart, asset_type.dart, backlog JSON. Re-ran all "no callers" greps independently. Read-only; no edits, no network.

---

**BUG-01**
- **Hunter's claim:** High — `_loadFor` has no staleness/request-token guard; a stale in-flight load can land last and populate the editor with another character's/novel's assignment, which a subsequent Save persists under the wrong coordinates.
- **Skeptic's response:** UPHELD (95%) — no cancellation or sequence guard exists; card has no `Key` so State survives character switches; `didUpdateWidget` resets fields but cannot cancel the awaited future; Save writes current coordinates with stale `_roles`/`_importance`/`_pov`.
- **Your analysis:** Verified in full. `_loadFor` (card 82–109) guards only on `mounted`; `didUpdateWidget` (61–71) and `_selectNovel` (147–154) reset `_loadedForCurrentNovel` but never cancel in-flight futures. I confirmed the card is instantiated without a key at character_workspace_screen.dart:224/264, so the State (and any in-flight load) genuinely survives character switches. `_save` (111–131) composes `NarrativeAssignment(novelWorkspaceId: novel.id /* current */, characterId: widget.characterId /* current */, roles: _roles /* possibly stale */)` — a real last-writer-wins corruption shape, proven by code, on the card's primary interaction path (every character/novel switch can overlap loads). Mitigating factors I weighed: the editor (and Save) is hidden while `_loading || !_loadedForCurrentNovel` (284–288), so a human Save click can only land in the window after a stale completion re-reveals the editor; and drift query execution is FIFO in practice, so the later-issued (correct) load usually completes last and self-corrects. Corruption requires inverted completion order plus a Save click inside that window — possible, not routine. Per the static-analysis honesty rule I downgrade the claimed High: the unguarded shared mutation is code-proven, but the corrupting outcome is runtime-timing dependent with no runtime evidence.
- **VERDICT: REAL BUG**
- **Confidence:** High (defect is unambiguous; corrupting outcome is timing-dependent)
- **True severity:** Medium (downgraded from High)
- **Suggested fix:** Add a monotonically increasing request token: capture `final epoch = ++_loadEpoch;` plus `novel.id`/`widget.characterId` before the await; after `await`, return unless `epoch == _loadEpoch` (and coordinates still match). Also key the card per character (`ValueKey(characterId)`) so State doesn't straddle characters.

---

**BUG-02**
- **Hunter's claim:** Medium — `deleteForCharacter` (documented "Used by character deletion cleanup") has zero production callers; deleting a character permanently orphans narrative assignments and support rows (as source and as supported target).
- **Skeptic's response:** UPHELD (93%) — no FKs on either table so nothing cascades; full deletion chain verified to never touch the narrative tables; orphan `supportedId` renders as a raw UUID.
- **Your analysis:** Independently verified. My grep: `deleteForCharacter` = definition (repo:131) + one test call only. `characterRepositoryImpl.deleteCharacter` (102–123, read directly) transactionally removes references, scope rows, modes, asset data, identity profiles, characters, assets — never the narrative tables; no other lib code references `characterNarrativeAssignments`/`characterSupportRelationships` outside the repository (grep). Both tables (character_narrative_assignments.dart, read in full) are plain TextColumns with composite PKs — no foreign keys, so orphans are neither blocked nor cascaded. Orphan display path confirmed (section 172–173 raw-UUID fallback). Result: permanent junk rows that surface as raw UUIDs in other characters' sections and ride along in export/import.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Call `deleteForCharacter(characterId)` inside `deleteCharacter`'s existing `database.transaction` (it then also inherits BUG-15's fix), or add `REFERENCES ... ON DELETE CASCADE` FKs to both tables in a migration.

---

**BUG-03**
- **Hunter's claim:** Medium — `_editSupport` performs non-transactional remove-then-save; a `saveSupport` failure after a successful `removeSupport` permanently loses the row.
- **Skeptic's response:** UPHELD-WITH-CAVEAT (88%) — mechanism real, but the remove branch is defensive-only because the edit dialog locks both coordinate pickers; corrected severity Low.
- **Your analysis:** Mechanism verified (section 211–236: two independent awaits, no `database.transaction`). Reachability: I verified the pickers are locked in edit mode (`onChanged: widget.initial == null ? ... : null`, 392–394/413–415), so `result` always carries the original coordinates and the remove branch (217–226) cannot fire from the UI today. In the normal path a `saveSupport` failure leaves the old row intact (no remove ran; upsert is keyed on the same composite PK). Data loss needs coordinates changed (impossible via UI now) AND remove succeeding AND save failing. Real non-atomicity, near-zero current exposure — Low is correct.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Wrap the remove-then-save pair in `database.transaction(() async { ... })` so the edit is atomic if the defensive branch ever becomes reachable.

---

**BUG-04**
- **Hunter's claim:** Medium — the three mutation handlers capture the session-bound repository before awaiting dialogs, so a project switch mid-dialog writes into the previous project's database (cross-project contamination).
- **Skeptic's response:** UPHELD-WITH-CAVEAT (80%) — stale capture is real, but the repository is immutable (write lands in project A with A's ids, i.e. where the data semantically belongs), `_openProject` closes the old DB so the realistic outcome is a loud closed-DB error, and the modal barrier blocks switching while the dialog is open; corrected severity Low.
- **Your analysis:** Stale capture verified (194–209, 211–236, 238–281: `_repository()` result held across `showDialog` and the save/delete, never re-validated). I verified `_openProject` (project_persistence_providers.dart:114–135) closes the previous session (`await _session?.close()`) before opening the new one, so a save racing the switch hits a closed drift database → thrown → caught → "Failed to save support relationship" SnackBar. The "contamination" framing is wrong: A's repository can only write A's ids under A's projectId. Residual real defects: raw-error UX instead of graceful cancellation, and (if the write wins the race against the close) a row lands in A while the follow-up `_load()` shows B — confusing but not corruption.
- **VERDICT: REAL BUG**
- **Confidence:** High (pattern) — impact bounded as described
- **True severity:** Low (downgraded from Medium)
- **Suggested fix:** Capture `session.manifest.id` before the dialog; after each await, re-read `projectSessionProvider` and silently abort (or toast "project changed") when the id changed.

---

**BUG-05**
- **Hunter's claim:** Medium — novel-option providers derive from asset snapshots never invalidated on story creation, so a newly created novel is missing from both "Story (novel)" dropdowns until an unrelated action rebuilds the graph.
- **Skeptic's response:** UPHELD (90%) — no invalidation found on any creation path; notes the Hunter's scene_workspace_screen.dart:139–159 citation is actually beat mutations (verdict unaffected).
- **Your analysis:** Verified independently. Greps: no `invalidate(projectAssetsProvider|narrativeNovelOptionsProvider|supportNovelOptionsProvider)` anywhere in lib; explorer_panel story creation invalidates only `storyExplorerProvider` (1049); workspace_resolver `onCreateNovel` (107–138, read directly) invalidates nothing. All `projectAssetsProvider` invalidation sites are unrelated flows (asset_browser:357, character_mode_controller:125, references card 43/87). Both providers are plain non-autoDispose `FutureProvider`s watching either `projectAssetsProvider.future` (card 25) or a raw `getAllAssets()` (section 24). I confirmed the skeptic's citation correction: scene_workspace_screen.dart:139–159 is beat add/delete/reorder. A novel created mid-session is absent from both dropdowns until an unrelated invalidation or project switch, with no error shown. Functional feature failure with a workaround; Medium stands.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Invalidate `projectAssetsProvider` (both providers derive from it directly or transitively) in every story-creation path — explorer_panel's story case and `onCreateNovel` in workspace_resolver.

---

**BUG-06**
- **Hunter's claim:** Medium — `_assignmentFromRow` throws on unknown role/importance/POV tokens, so one corrupt row fails `listAssignments()` wholesale, and the explorer swallows the error into `?? const []`, silently collapsing the character list to zero when a filter is active.
- **Skeptic's response:** UPHELD (85%) — fail-loud is documented intent, but portable import preserves rows as-is (version-skew vector) and the consumer's silent swallow is the core defect.
- **Your analysis:** Verified: `fromWire` throws (domain 25–32/46–53/66–73); `listAssignments` (repo 62–67) has no per-row tolerance; consumer (explorer_panel 1301–1316, read directly) uses `.valueOrNull` then `assignments ?? const []` with no error UI — with a role filter active, `own.any(...)` over an empty list is false for every character. The plausible trigger is cross-version portability: `portable_project_service` rewrites only `project_id`, so vocabulary skew between builds plants unknown tokens. Today no write path produces unknown tokens, so the trigger requires version-skewed imports or manual DB edits — real for a file-based desktop app whose projects are shared/imported, but not reachable from in-app operation alone.
- **VERDICT: REAL BUG**
- **Confidence:** Medium
- **True severity:** Medium (conditional on the import/portability vector; the silent `valueOrNull` swallow is the fixable core)
- **Suggested fix:** Two layers: (1) decode per-row tolerantly in `listAssignments` (skip unknown tokens with a logged warning, or default to `unspecified`), and (2) surface the provider's error state in the explorer instead of collapsing to `const []`.

---

**BUG-07**
- **Hunter's claim:** Low — `_load()` stores `_supports = const []` when the session is null, rendering "No support relationships yet" (fake empty) despite the section's own comment forbidding it.
- **Skeptic's response:** UPHELD-WITH-CAVEAT (78%) — conflation real but narrow: `_openProject` releases foreign selections before `AsyncLoading`, and the build guard self-corrects.
- **Your analysis:** Conflation verified (60–71 vs 158–164, comment 91–92). Reachability is narrower than even the skeptic allowed: I verified `currentProjectIdProvider` (project_persistence_providers.dart:59–61) returns null while the session is loading, and InspectorResolver (24–28) renders `EmptyInspector` whenever the selection's projectId doesn't match the (null) active project — so the section is unmounted during every project-switch loading state. The null-session `_load()` branch is essentially dead unless the mount contract changes. Code-true, near-unreachable.
- **VERDICT: REAL BUG**
- **Confidence:** Medium
- **True severity:** Low
- **Suggested fix:** In the null-session branch keep `_supports = null` (the Loading state) instead of `const []`, preserving the not-ready/empty distinction.

---

**BUG-08**
- **Hunter's claim:** Low — after a load failure the card shows the error plus a permanent "Loading assignment..." line (error branch leaves `_loadedForCurrentNovel` false), with no retry; `didUpdateWidget` never clears `_error`.
- **Skeptic's response:** UPHELD (92%) — verified; sub-claim about stale `_error` largely mitigated since the next `_loadFor` clears it (line 87).
- **Your analysis:** Verified exactly: catch (102–107) sets `_error`/`_loading=false` without touching `_loadedForCurrentNovel`; build (280–288) renders both the error text and the `!_loadedForCurrentNovel` loading line forever; no Retry control (unlike the section's ActionChip). The `didUpdateWidget` sub-claim is indeed mitigated — any subsequent successful `_loadFor` nulls `_error` before rendering. Reachable via infra errors and via BUG-06-family `ArgumentError`s on corrupt rows.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** In the catch, set `_loadedForCurrentNovel = true` (or a dedicated `_failed` flag) so the editor is replaced by an error state, and add a Retry chip mirroring the support section.

---

**BUG-09**
- **Hunter's claim:** Low — `_loadFor` returns silently when the repository is missing, leaving `_loadedForCurrentNovel` false and the card stuck on "Loading assignment..." with no error or retry.
- **Skeptic's response:** UPHELD-WITH-CAVEAT (75%) — real path but nearly unreachable: with no session the options provider yields `const []` and the "No novels yet" branch means `_selectNovel` never runs.
- **Your analysis:** Verified: early return at 83–84 precedes any state change, after `_selectNovel` already cleared `_loadedForCurrentNovel`. I confirmed the skeptic's mitigation: `narrativeNovelOptionsProvider` (card 21–30) returns `const []` with no session and build renders the "No novels yet" card (192–213), so the dropdown/postFrame path never executes. The stuck state needs the session to vanish between a successful provider build and a novel pick — a narrow timing window.
- **VERDICT: REAL BUG**
- **Confidence:** Medium
- **True severity:** Low
- **Suggested fix:** On `repo == null`, set an explicit `_error` (e.g. 'No project session') instead of returning silently.

---

**BUG-10**
- **Hunter's claim:** Low — `SupportRelationship.copyWith` can never null `purpose`/`separationReason` ("keep current value" sentinel collides with the legitimate null).
- **Skeptic's response:** UPHELD-WITH-CAVEAT (85%) — fact-true; no production callers (only narrative_assignment_test.dart:176); dialog constructs fresh instances.
- **Your analysis:** Verified (domain 303–318). My grep confirms zero production `copyWith` call sites for SupportRelationship; the dialog builds fresh objects (498–518). Latent API flaw, zero current user impact.
- **VERDICT: REAL BUG**
- **Confidence:** High (fact)
- **True severity:** Low
- **Suggested fix:** Sentinel-parameter copyWith (`Object? purpose = _unchanged`) or explicit `clearPurpose`/`clearSeparationReason` flags before the API gains callers.

---

**BUG-11**
- **Hunter's claim:** Low — `NarrativeAssignment.fromJson` hard-casts role entries and routes through strict `fromWire`, so one malformed/unknown token aborts the whole decode; no production caller justifies the strictness.
- **Skeptic's response:** UPHELD-WITH-CAVEAT (88%) — verified; fully dead in lib/, latent.
- **Your analysis:** Verified (domain 139–153: `role as String`, `json['novel_workspace_id'] as String`, strict `fromWire`). My grep: callers only in narrative_assignment_test.dart (96/108/119). Latent robustness defect contingent on future adoption.
- **VERDICT: REAL BUG**
- **Confidence:** High (fact)
- **True severity:** Low
- **Suggested fix:** Before adoption, use `is String` checks with per-entry tolerance (skip/filter unknown tokens) rather than hard casts, or document the fail-loud contract deliberately.

---

**BUG-12**
- **Hunter's claim:** Low — `matchesCharacter` linearly scans all assignments per character, making the explorer filter O(characters × assignments) per rebuild.
- **Skeptic's response:** UPHELD-WITH-CAVEAT (85%) — complexity code-true but negligible at realistic scale.
- **Your analysis:** The complexity claim is accurate (filter 38–40, called per character from explorer_panel 1310–1316). But both inputs are project-scoped: at plausible scale (hundreds of characters, low-thousands of assignments) the scan is ~10⁵–10⁶ cheap comparisons per rebuild — sub-millisecond in release. The behavior is correct; there is no incorrect output, no unbounded input, and no observable degradation at any realistic project size. A constant-factor optimization opportunity is not a defect.
- **VERDICT: NOT A BUG**
- **Confidence:** Medium
- **True severity:** — (optimization note only)

---

**BUG-13**
- **Hunter's claim:** Low — `listSupportsFor` lacks the deterministic ordering its sibling `listSupports` has, so reverse-direction views would have unstable row order.
- **Skeptic's response:** UPHELD-WITH-CAVEAT (88%) — code-true; zero production callers, so no visible instability today.
- **Your analysis:** Verified (listSupports orders at 79–82; listSupportsFor 87–98 has no `orderBy`). My grep confirms `listSupportsFor` has no callers anywhere (definition only). Latent API inconsistency — no behavior exists to be wrong today, but the method is public repository API and will surface unordered rows the day it is wired.
- **VERDICT: REAL BUG** (latent)
- **Confidence:** High (fact)
- **True severity:** Low
- **Suggested fix:** Add the same `orderBy` clause as `listSupports` (or delete the method if reverse-direction views are out of scope).

---

**BUG-14**
- **Hunter's claim:** Low — the Add-Support dialog opens with zero novels or zero other characters, presenting empty dropdowns with a silently disabled Save and no explanation.
- **Skeptic's response:** UPHELD (92%) — no guards; sibling card handles the analogous case with an explicit message, confirming oversight.
- **Your analysis:** Verified: `_showEditDialog` (283–314) has no empty-list guard; `_SupportEditDialog` disables Save when `_supportedId == null || _novelId == null` (492) with no hint. The card's "No novels yet" branch (192–213) shows the codebase's own convention. Pure UX gap.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** In `_showEditDialog`, return early with an explanatory SnackBar (or a disabled Add button with a tooltip) when novels or eligible characters are empty.

---

**BUG-15**
- **Hunter's claim:** Low — `deleteForCharacter`'s two deletes run outside any transaction; a failure between them half-cleans the character.
- **Skeptic's response:** UPHELD-WITH-CAVEAT (90%) — code-true and violates the codebase convention (`deleteCharacter` uses `database.transaction`), but the method is currently dead.
- **Your analysis:** Verified (131–145: two sequential `.go()` calls, no transaction) against the convention (character_repository_impl.dart:103–117). Latent until BUG-02 wires it up — fixing BUG-02 should fix this simultaneously.
- **VERDICT: REAL BUG** (latent)
- **Confidence:** High (fact)
- **True severity:** Low
- **Suggested fix:** Wrap both deletes in `database.transaction(() async { ... })`.

---

**BUG-16**
- **Hunter's claim:** Low — a `_load()` started for the previous project can complete after the session-switch guard resets state, briefly rendering the previous project's relationships and character-name map, then triggering a duplicate reload.
- **Skeptic's response:** DISPROVEN (88%) — the build guard executes in the same build pass before the render read, so the stale data is synchronously nulled before anything renders; the "duplicate reload" is the guard's by-design behavior.
- **Your analysis:** I verified the ordering myself in support_relationship_section.dart: the guard (111–123) runs at the top of `build` and assigns `_supports = null` synchronously whenever `sessionId != _loadedSessionId`; `final supports = _supports;` (line 124) executes only afterwards, in the same build. Flutter executes `setState` as a scheduleBuild — there is no build pass between the stale completion's setState and the next build, and in that next build the guard nulls the stale rows before line 124 reads them. The claimed foreign-data frame therefore cannot render. (Edge: a `setState` landing mid-build would throw "setState during build" — a different, unclaimed failure mode.) The residual A→B→A same-project staleness the skeptic noted is real but a materially weaker, unclaimed defect. I additionally note an adjacent REAL gap neither agent reported — see Referee Observation below.
- **VERDICT: NOT A BUG** (as stated)
- **Confidence:** High

---

**BUG-17**
- **Hunter's claim:** Low — the domain documents the supported target as "one character or group", but the picker offers only character assets, so group targets cannot be created through the UI.
- **Skeptic's response:** UPHELD-WITH-CAVEAT (80%) — fact-true; may be an accepted phase-one scope cut since the backlog UI checklist never explicitly requires a group picker.
- **Your analysis:** Verified: filter `asset.type == 'character'` only (292–296); domain docs "character or group" (193, 258); backlog JSON scope says "supported character/group". `AssetType` (read in full) has `faction` but no character-group type — the vocabulary to express "group" does not exist, so this is a spec/vocabulary gap rather than a dropped requirement. The schema comment on `supportedId` ("supported character/group") also cannot be satisfied by the UI today.
- **VERDICT: REAL BUG** (spec-vs-UI gap)
- **Confidence:** Medium
- **True severity:** Low
- **Suggested fix:** Either narrow the domain/backlog vocabulary to "character" until groups ship, or add a group asset concept and include it in the picker.

---

**BUG-18**
- **Hunter's claim:** Low — support rows/dropdowns display raw wire tokens ("travel_companion · permanent · active") while the narrative card maps every enum through label helpers.
- **Skeptic's response:** UPHELD (93%) — verified, including dialog dropdowns at 426/441/457; no label helpers exist anywhere for the support enums.
- **Your analysis:** Verified (subtitle 179–183; card helpers 366–384). My grep confirms no `supportTypeLabel`-style mapping exists. Cosmetic/consistency defect, user-visible on every support row.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Add `supportTypeLabel`/`supportDurationLabel`/`supportStatusLabel` switch helpers mirroring the card's and use them in the row subtitle and dialog dropdowns.

---

**BUG-19**
- **Hunter's claim:** Low — `roleTokensToRoles` is exported dead code duplicating `_assignmentFromRow`'s decode logic, existing "only for the test suite".
- **Skeptic's response:** UPHELD (92%) — stronger than claimed: no callers anywhere, not even tests.
- **Your analysis:** Verified (repo 221–222). My grep across lib/test/tool: definition only — the Hunter's "test suite" rationale is wrong (tests don't reference it either), the skeptic's correction stands. Fully dead, exported, duplicate decode path.
- **VERDICT: REAL BUG** (dead code)
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Delete it, or make `_assignmentFromRow` use it so there is one decode path.

---

## Referee Observation (unreported by either agent — flagged for follow-up, not scored)

**Cross-character staleness in `SupportRelationshipSection` (support_relationship_section.dart + character_inspector.dart).** The section's State is instantiated with `SupportRelationshipSection(assetId: characterId)` (character_inspector.dart:22) — **no key, no `didUpdateWidget`**, and its build guard (111–123) compares **session id only**, never `assetId`. I verified the mount chain has no keys anywhere (InspectorPanel → InspectorResolver → CharacterInspector → ListView children), and selection updates are plain `state = selection` notifications (selection_controller.dart:45) with no clear between picks — so switching characters A→B within one project updates the subtree in place and **reuses the section's State**. `_supports` and `_characterNames` then still hold A's rows, rendered under B's inspector indefinitely (no reload trigger fires; `initState` ran once). Consequences: (1) B's screen displays A's support relationships; (2) deleting a row from B's screen calls `removeSupport` with the **stale A-row coordinates**, silently deleting A's data; (3) editing prefills the dialog with A's row but `_SupportEditDialog._save` stamps `sourceCharacterId: widget.assetId` (= B), so save moves A's relationship to B. This is the same last-writer/state-straddle family as BUG-01 but with a *guaranteed* (non-timing-dependent) trigger: every character switch. Static analysis only — verify at runtime. Fix direction: `SupportRelationshipSection(key: ValueKey(assetId))` at character_inspector.dart:22 (and same for `RelationSection` if it ever gains local state), or add `didUpdateWidget` with an assetId-change reload.

---

# VERIFIED BUG REPORT

Stats:
- Total reported by Hunter: 19
- Dismissed as false positives: 2 (BUG-12, BUG-16)
- Confirmed as real bugs: 17
- Critical: 0 | Medium: 4 | Low: 13

Confirmed bugs (ordered by severity):

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|----------|------|---------|-------------|---------------|
| BUG-01 | Medium | lib/features/character/presentation/widgets/narrative_assignment_card.dart | 82–109, 111–131 | `_loadFor` has no request token; stale completion can leave another character's/novel's roles in `_roles`, which `_save` persists under current coordinates | Epoch/coordinate check after the await; key the card per character |
| BUG-02 | Medium | lib/features/workspaces/application/narrative_assignment_repository.dart (+ character_repository_impl.dart:102–123) | 126–145 | `deleteForCharacter` never called in production; character deletion orphans narrative assignment and support rows forever (no FKs) | Invoke it inside `deleteCharacter`'s transaction, or add FK cascades |
| BUG-05 | Medium | narrative_assignment_card.dart 21–30; support_relationship_section.dart 19–29 | — | Novel dropdowns stale after story creation (no provider invalidation on any creation path) | Invalidate `projectAssetsProvider` on story creation (explorer_panel + workspace_resolver) |
| BUG-06 | Medium | narrative_assignment_repository.dart; explorer_panel.dart:1301–1316 | 182–202 | One unknown enum token fails `listAssignments()` wholesale; explorer swallows the error into an empty list — filter silently collapses | Per-row tolerant decode + surface provider errors instead of `?? const []` |
| BUG-03 | Low | support_relationship_section.dart | 211–236 | Non-atomic remove-then-save in `_editSupport` (defensive branch; row lost if save fails after remove) | Wrap in `database.transaction` |
| BUG-04 | Low | support_relationship_section.dart | 194–281 | Repository captured before dialog awaits; project switch mid-flight yields loud closed-DB error or write into previous project (no corruption) | Re-validate session id after each await; abort on change |
| BUG-07 | Low | support_relationship_section.dart | 60–71 vs 158–164 | Null-session `_load()` stores `const []` → fake "No support relationships yet" (near-unreachable; inspector unmounts during loading) | Keep `_supports = null` (loading) when session is null |
| BUG-08 | Low | narrative_assignment_card.dart | 102–107, 280–288 | Load failure renders error + eternal "Loading assignment..." with no retry | Set a terminal failed state in catch + Retry chip |
| BUG-09 | Low | narrative_assignment_card.dart | 82–84 | Missing-repo early return leaves eternal loading (narrow timing window) | Set an explicit error instead of silent return |
| BUG-10 | Low | narrative_assignment.dart | 303–318 | `SupportRelationship.copyWith` cannot clear purpose/separationReason (latent; no production callers) | Sentinel-parameter copyWith |
| BUG-11 | Low | narrative_assignment.dart | 139–153 | Strict `fromJson` casts/`fromWire` abort whole decode; dead in lib/ (latent) | `is String` checks + per-entry tolerance before adoption |
| BUG-13 | Low | narrative_assignment_repository.dart | 87–98 | `listSupportsFor` lacks deterministic ordering (dead path, latent) | Add `orderBy` matching `listSupports` |
| BUG-14 | Low | support_relationship_section.dart | 283–314, 492 | Add-Support dialog opens with empty dropdowns and silently disabled Save, no explanation | Guard empty novels/characters with an explanatory message |
| BUG-15 | Low | narrative_assignment_repository.dart | 131–145 | Two deletes outside a transaction (dead code; fix together with BUG-02) | Wrap in `database.transaction` |
| BUG-17 | Low | support_relationship_section.dart | 292–296 | Group targets unselectable though domain/backlog say "character/group" (vocabulary gap) | Narrow the docs or add group asset support |
| BUG-18 | Low | support_relationship_section.dart | 179–183, 426/441/457 | Raw wire tokens shown to users; inconsistent with card's label helpers | Add support label helpers |
| BUG-19 | Low | narrative_assignment_repository.dart | 221–222 | `roleTokensToRoles` fully dead (no callers anywhere, incl. tests), duplicate decode | Delete it or unify decode through it |

Low-confidence items (flagged for manual review):
- BUG-06 (Medium confidence): trigger requires version-skewed portable imports or manual DB edits; not reachable from in-app operation alone.
- BUG-07 (Medium confidence): near-unreachable — the inspector unmounts whenever the session is loading/null (verified via currentProjectIdProvider + InspectorResolver), so the branch is essentially dead as mounted today.
- BUG-09 (Medium confidence): requires the session to vanish in a narrow window between provider build and novel pick.
- BUG-12 (NOT A BUG at Medium confidence): complexity fact-true but no observable defect at plausible scale — judgment call, recorded for transparency.
- BUG-17 (Medium confidence): possibly an accepted phase-one scope cut rather than a defect.
- Referee Observation above (cross-character section staleness): statically derived from widget-reuse reasoning; needs runtime verification before ticketing.

Scorekeeping note: 17 confirmed (4 Medium + 13 Low = 47 claimed points → confirmed 40 after BUG-01 High→Medium and BUG-03/BUG-04 Medium→Low downgrades, −2 for the two false positives).
