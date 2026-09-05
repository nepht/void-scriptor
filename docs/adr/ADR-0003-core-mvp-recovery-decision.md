# ADR-0003 - Core MVP Recovery Decision (Sprint 145.49)

- Status: Proposed (draft awaiting architect decision)
- Date: 2026-09-05
- Step: Sprint 145.49 Core MVP Recovery Decision
- Driver: Choirudin (product authority), drafted by nephthys cron
- Scope note: this document PROPOSES a recovery direction with options and
  consequences. It is not a decision until the architect ratifies it. It does
  not move the roadmap pointer, close Sprint 145.49, or authorize stream
  transition. Evidence cited is re-verified against the live tree at drafting
  time (HEAD 961eeb1) unless explicitly quoted from the sprint ledger.

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
