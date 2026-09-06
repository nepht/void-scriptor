# ADR-0003 - Core MVP Recovery Decision (Sprint 145.49)

- Status: Accepted — Option B, safety-first sequencing (2026-09-05)
- Date: 2026-09-05
- Step: Sprint 145.49 Core MVP Recovery Decision
- Driver: Choirudin (product authority), drafted by nephthys cron
- Scope note: Choirudin authorized Codex to select and apply the current
  direction on 2026-09-05. Option B is accepted with the execution order below.
  This decision does not move the roadmap pointer, certify unfinished tests,
  close Sprint 145, or authorize expansion/release. Evidence below is a
  historical drafting snapshot (HEAD 961eeb1), not a current test run.

## Adopted decision and executor order — 2026-09-05

Stabilize existing Core. Preserve the approved product structure and deferred
implementations; do not add modules or broadly rewrite architecture.
This section supersedes the original recommendation order and decision gate.

1. Continue the outstanding 145.42 safety matrix on disposable projects:
   explicit disk-full and permission-loss failures, interrupted move/import/
   restore, then SQLite WAL process-crash recovery. Assert old data preservation,
   visible failure, and safe retry/recovery. Never fill the user's actual drive,
   change broad permissions, remove a real drive, or kill unrelated processes.
   Fault injection and process termination are simulations, not physical
   power-loss/device-certification evidence.
2. Complete exact-snapshot restore and reconcile existing edits in bounded,
   test-first slices. Preserve unrelated edits; dirty files alone are not proof
   of an active competing writer. Verify ownership before overlapping changes.
3. Complete deferred demo-route gating with explicit capability mapping and
   tests. Do not infer a missing canonical mapping or enable deferred features;
   document a bounded mapping decision if required. A blocked mapping must not
   prevent independent safety work in step 1.
4. Run focused tests, analyzer, relevant regression, a full suite on an
   identified consistent revision, and the Windows build. Arrange user-assisted
   native create/write/switch/close/reopen/export/backup/restore tests and separate
   device/removable-drive validation. Do not claim these from compilation alone.
5. Only after these gates: prepare pilot tasks and collect real-user evidence.
   Recruitment, publishing, release, payments, and sprint closure are not
   authorized automatically by this decision.

Hermes should read this decision and the current ledger/state at its next run.
Each run should choose an unfinished safe slice, record actual evidence, and
leave hardware/user-dependent checks explicitly pending. Do not keep reporting
"awaiting ADR-0002/0003 choice" as a blocker. If no safe slice remains, report
the exact input/device needed rather than fabricate progress.

Acceptance boundaries: 145.27 stays PARTIAL; 145.42 stays IN_PROGRESS until
its matrix is evidenced. The 145.49 direction is decided, but any other canonical
acceptance requirements remain open. 145.43-145.47 and 145.50 are not closed.

Historical evidence caution: the original run62 paragraph below contains
contradictory full-suite counts. It is not usable as a green gate; consult the
dated sprint ledger and original run output. This decision creates no new
runtime test evidence and does not resolve that historical discrepancy.

## Evidence Base (source/runtime audit + vertical slice + user evidence)

Source/runtime audit (live tree, HEAD 961eeb1, analyzer No issues 7.4s):

- Core stack verified: per-project package with schema v59, NativeDatabase,
  autosave journal + durable draft journal, backup/restore with per-area
  rollback (BackupRollbackException, 145.34 slice 0dfe64c), export, and
  Windows local-first startup. Full suite at run62: 3673 PASS / 0 FAIL /
  1 SKIP, exit 0 (~12 min); run62 one FAIL was a concurrent-owned file
  (session_lock_safety_review region) that passes on focused retry.
- User-priority remediation 145.27 has surfaced all six priority objectives:
  Characters, Locations, Factions, Timeline, Relationship Map, Lore Notes
  (commits 8a4d538, 602bbc8, 33aef69, 81755fa, c1f469a, 961eeb1).
- Known open gaps (ledger, re-verified):
  1. 145.27 status PARTIAL: native interaction UNVERIFIABLE from cron (no
     computer-use); user validation pending; route gating for 11 demo routes
     (app_routes.dart lines 44-55: render, animation, audio,
     virtual-production, enterprise-studio, knowledge, agents,
     studio-command-center, creative-os, xr-studio, metaverse) still missing -
     deep-link only, no menu entry, no capability rule.
  2. Uncommitted sibling regions remain in the worktree (488 dirty entries):
     project_recovery_services, project_session_manager, cloud_sync,
     void_top_bar, settings, selection memory follow-ups. These carry real
     behavior not yet covered by a green full-suite at one commit.
  3. Restore-success still merges assets; exact-snapshot restore is a
     separate acceptance. OS-native rollback fault injection UNVERIFIABLE.
  4. Pilot-facing steps 145.43-145.47 require real users and native device
     runs; cron cannot execute them (pilot recruitment, task-based
     validation, device certification).

## Options Considered

### Option A - Implement new Core features
- Meaning: treat Core MVP as incomplete and add missing product surfaces
  beyond the user-priority remediation.
- Consequences: contradicts evidence (the six priority objectives already
  have real surfaces); grows unverified surface while sibling regions are
  still uncommitted; violates the no-scope-expansion gate.
- Fit: LOW.

### Option B - Stabilize existing Core
- Meaning: close the remaining 145.27 acceptance gaps without new features:
  route-gate the 11 demo routes behind the Core capability, land the
  uncommitted sibling regions with evidence, exact-snapshot restore, and
  collect the one-time native Windows proof (user-assisted).
- Consequences: no new product risk; directly reduces data-loss and
  deep-link exposure; requires either sibling-region coordination (already
  authorized 2026-09-04) or user action for native proof.
- Fit: HIGH.

### Option C - Corrective refactor
- Meaning: rework architecture before further product work (e.g. replace
  shell/navigation layering).
- Consequences: no current audit finding requires it; ADR-0001 boundary and
  ADR-0002 stack decisions hold; refactor now would invalidate the stability
  gate and burn the remediation window.
- Fit: LOW.

### Option D - Re-scope
- Meaning: change the Core MVP contract (user decision 145.14) mid-stream.
- Consequences: invalidates the 145.24 evidence closure and the user-priority
  procedure; contradicts the approved post-145 transition policy.
- Fit: LOW.

## Recommendation

ADOPT OPTION B - Stabilize existing Core, in this order:
1. Route-gate the 11 demo destinations (one slice, test-first, no deletion of
   deferred implementations).
2. Land or reconcile the uncommitted sibling regions region-by-region with
   focused evidence, then one full-suite green at a single commit.
3. Exact-snapshot restore acceptance for restore-success.
4. One-time user-assisted native Windows journey (create -> write -> switch
   -> close/reopen -> export -> backup/restore) to convert 145.27 native
   evidence from UNVERIFIABLE to VERIFIED; cron cannot perform this.
5. Only then: pilot steps 145.43-145.47 with the architect recruiting users.

Immediate next concrete work if ratified: item 1 (route-gating slice), which
is inside the already-authorized sibling-region scope (top_bar/route gating)
and does not require new user input.

## Decision Gate

- This ADR becomes DECIDED only when the architect selects an option (or an
  amended one) in the sprint ledger or ROADMAP_STATE. Until then 145.49
  remains open and the pointer stays at 145.27-adjacent corrective work.
- Consequences of NOT deciding: executor runs keep working authorized gaps
  (route gating, sibling-region landing) which are compatible with Option B;
  no work is wasted by the current ordering.
