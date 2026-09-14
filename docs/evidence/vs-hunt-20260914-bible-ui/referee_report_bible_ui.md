# Adversarial Bug Hunt — Referee Report (Bible UI)

**Scope:** `lib/features/bible/domain` and `lib/features/bible/presentation` (14 non-generated Dart files)  
**Referee basis:** Hunter report, Skeptic report, and independent inspection of the code at HEAD `67aeec6a27210f3297ad78957c47cf1d278f8a86`.

## Independent verdicts

### BUI-BUG-01

- **Hunter's claim:** Section tabs/dropdown update `_selectedSection`, but the selected value is never used to select, filter, scroll to, or navigate content; all sections remain rendered.
- **Skeptic's response:** ACCEPT / CONFIRMED. The control state only changes the selected indicator; the content tree is unconditional.
- **Your analysis:** The claim is verified at HEAD. `_selectedSection` is initialized at line 37 and changed by the narrow dropdown at lines 57–68 and desktop chips at lines 69–74. The build then always renders `_OverviewGrid`, `_FactionsSection`, `_RelationMapSection`, and the canon/conflict/timeline cards at lines 75–102. No conditional render, scroll target, route action, or callback connects the selected section to content. The controls therefore provide selection feedback but do not perform the apparent section-navigation function.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Define an explicit section-to-content mapping and render or scroll to only the selected section; preserve the responsive control as the same navigation model on narrow and wide layouts. If the intended UX is one long dashboard, remove the inert controls or change their semantics to labeled anchor/scroll controls.

### BUI-BUG-02

- **Hunter's claim:** Overview metrics permanently show `Void Universe` and zero counts rather than project data.
- **Skeptic's response:** ACCEPT / CONFIRMED. The feature has project-scoped Bible data, but `_OverviewGrid` neither watches the session nor queries repositories, and no documented placeholder contract makes these values honest.
- **Your analysis:** The claim is verified at HEAD. `_OverviewGrid.build` creates a `const` card list at lines 203–226 with hard-coded `Void Universe`, `0` canon entries, `0 entities`, and `0` historical events. Unlike `_TimelineCard` (lines 327–389), it has no session watch, repository query, loading/error state, or indication that the values are placeholders. The dashboard consequently presents fixed values as current project metrics, and populated project data cannot affect them. Given the authorized UI/UX policy requiring placeholder data to be honestly labelled, this is a user-visible data-integrity defect rather than merely incomplete future functionality.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Load the active project's manifest and relevant repositories, compute each metric from project-scoped data, and represent loading/error/empty states explicitly. If a metric is not implemented yet, label it as unavailable/placeholder instead of displaying fabricated current values.

### BUI-BUG-03

- **Hunter's claim:** Factions and relationship-map data do not reload on a direct active-project A-to-B switch, allowing project A's results to remain visible in project B.
- **Skeptic's response:** ACCEPT / CONFIRMED. Both Bible route entries build an unkeyed `const ProjectBibleWorkspaceScreen`, and both child listeners reload only on null-to-non-null session transitions.
- **Your analysis:** The claim is verified at HEAD and is reachable in the live route composition. `ProjectBibleWorkspaceScreen` is built as `const ProjectBibleWorkspaceScreen()` at `app_router.dart` lines 130–132 and 446–449, without a project-dependent key. `_FactionsSectionState` loads the session's database and manifest ID at lines 409–417; its listener at lines 441–448 only handles `null -> non-null`. `_RelationMapSectionState` has the same load pattern at lines 663–672 and the same listener condition at lines 678–685. Thus a persistent ConsumerState receiving a non-null A -> non-null B update neither clears nor reloads its cached list. The already displayed A list can remain under B. There is also no identity check before assigning an asynchronously returned result, so a late A response could overwrite B after a reload is added.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Track the loaded project ID in each state, listen for every session identity change, clear state while reloading, and validate the captured project ID/session identity before applying an async result. Alternatively key the relevant subtree by active project ID, while retaining an async stale-result guard.

### BUI-BUG-04

- **Hunter's claim:** `WorldImageCard` reloads only when `entityId` changes, so an unchanged entity ID can retain project A's image when injected session/database callbacks switch to project B.
- **Skeptic's response:** ACCEPT / CONFIRMED. Parent rebuilds replace the callbacks, but retained child state does not reload because `didUpdateWidget` compares only `entityId`.
- **Your analysis:** The claim is verified at HEAD. `WorldImageCard` stores the loaded path in `_path` (line 46), calls `_reload()` in `initState` (lines 49–53), and calls it in `didUpdateWidget` only when `oldWidget.entityId != widget.entityId` (lines 55–59). `_reload()` reads through the current injected callback at lines 61–73. Both `FactionImageCard` and `TimelineEraImageCard` watch the current project session and close over its database/package when constructing those callbacks (their lines 26–37). On a direct A-to-B switch, the parent can rebuild with new callbacks while the entity ID remains equal; the child state is retained by the unkeyed composition and `_path` remains A's path because no reload is initiated. Watching session presence at `world_image_card.dart:103` only controls the import button and does not fix image refresh.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Make project identity an explicit input to `WorldImageCard` and reload/reset when it changes, or key the card by project ID plus entity ID. Also guard asynchronous loads against stale project/callback results; retain the existing missing-file cleanup behavior.

## Verified bug report

**CONFIRMED REAL tally:** 4 of 4 reported findings. **Dismissed:** 0.

| # | Severity | File | Line(s) | Verdict | Description | Fix direction |
|---|---|---|---:|---|---|---|
| BUI-BUG-01 | Medium | `lib/features/bible/presentation/project_bible_workspace_screen.dart` | 37, 57–102 | REAL BUG | Section controls update only the selected indicator; they do not select, filter, scroll to, or navigate content. | Map controls to section rendering/anchors, or remove/relabel the controls if the intended UX is a single dashboard. |
| BUI-BUG-02 | Medium | `lib/features/bible/presentation/project_bible_workspace_screen.dart` | 203–226 | REAL BUG | Overview cards present hard-coded universe and zero metrics as current project data; populated data cannot affect them. | Query active-project manifest/repositories and expose loading/error/empty states; honestly label unimplemented values. |
| BUI-BUG-03 | Medium | `lib/features/bible/presentation/project_bible_workspace_screen.dart`; `lib/app/routing/app_router.dart` | 409–417, 441–448, 663–672, 678–685; 130–132, 446–449 | REAL BUG | Persistent Bible state ignores non-null A-to-B session changes, leaving factions and relation-map data from A visible in B. | Reload on project-ID changes, clear during reload, and reject stale async results; optionally key by project ID. |
| BUI-BUG-04 | Medium | `lib/features/bible/presentation/widgets/world_image_card.dart`; callers in `faction_image_card.dart` and `timeline_era_image_card.dart` | 46, 49–73, 101–103; caller lines 26–37 | REAL BUG | Retained image path is not reloaded when session-bound callbacks change but `entityId` is unchanged, so A's image can persist in B. | Pass/key by project ID and reload on identity changes; guard stale async image loads. |

**Stats:** Total reported by Hunter: 4 | Dismissed: 0 | Confirmed real: 4 | Critical: 0 | Medium: 4 | Low: 0

**Low-confidence items:** None. All four verdicts are high-confidence static findings verified against the stated HEAD. Severity is calibrated Medium because each is a user-visible correctness/functionality defect but no destructive or security impact was established.
