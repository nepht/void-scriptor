# Sprint 145.16 — Core MVP Scope Lock

Tanggal audit: 2026-08-27  
Sumber kanonik: `core_mvp_scope_reset_spec.json`, field `core_mvp`, `vertical_slice`, `architecture_constraints`, dan `ux_reduction`.

## Locked baseline

Platform target: **Windows x64 local-first**.

Core MVP tidak mensyaratkan:

- account;
- internet;
- subscription untuk local writing;
- Cloud, Community, Publishing, Payment, Payout, Marketplace;
- Mobile full editor atau macOS release;
- dozens of AI/cloud providers.

## Included scope

### Project and writing

- Local project/package lifecycle.
- Novel/Story workspace.
- Chapter/scene tree.
- Writing editor/manuscript.
- Word count.
- Search.
- Lore links.
- Clean manuscript export.

### Character and worldbuilding

- Character workspace and canonical identity.
- Locations/environments.
- Factions.
- Timeline.
- Relationship map.
- Lore notes/Bible.
- Explicit character layers: canonical, universe/timeline override, and novel-specific state.

### Data safety and portability

- Autosave.
- Snapshots.
- Crash recovery.
- Local backup and restore.
- Portable `.vscriptor` project format.
- Custom desktop storage after drive/permission/free-space/removal tests.

### Optional after Core stability

- One explicit BYOK AI provider.
- AI must remain opt-in, consented, cancellable, redacted, and non-blocking for startup/save/open.

## Release-blocking vertical journey

```text
CREATE_PROJECT
  → CREATE_CHAPTER
  → WRITE
  → AUTOSAVE
  → CLOSE
  → REOPEN
  → SEARCH_OR_LORE_LINK
  → EXPORT
  → BACKUP
  → RESTORE
```

Success requires a writer to complete this on a clean Windows device without login or internet and without data loss.

Failure conditions:

- unrecovered data loss;
- project cannot reopen;
- export misses text;
- backup cannot restore;
- login or internet is required;
- missing drive creates an empty replacement project.

## Navigation scope

Primary navigation is limited to:

- Dashboard;
- Novels;
- Characters;
- World;
- Search;
- Backup/Export;
- Settings.

Advanced features use progressive disclosure. Existing non-Core source/data is preserved; this lock does not authorize deletion. Unready capabilities should be hidden, disabled, or feature-gated with an honest state.

## Implementation guardrails

1. Core domain data is not owned by navigation components.
2. Core launch/open/save/search/export/backup/restore must not depend on Cloud, Network, Payment, or AI provider availability.
3. One live project has one sync authority; app cloud plus external folder sync is prohibited until conflict behavior is verified.
4. Publishing, if later enabled, receives an explicit versioned snapshot rather than mutable live manuscript state.
5. Character overrides require explicit scope choice and never silently mutate canonical identity.
6. Schema and migration work remains additive and evidence-gated; D-SCHEMA-01 remains OPEN.
7. Core feature completion requires source, test, persistence, UI/integration, and relevant platform evidence; a route or model alone is insufficient.
8. Non-Core capabilities remain in backlog or behind safe OFF defaults and are not reclassified as Core merely because source code exists.

## Current evidence classification

| Area | Current state |
|---|---|
| Project/asset/character/story/workspace source and local tests | VERIFIED local/source-test |
| Responsive TopBar/Explorer overflow correction | VERIFIED source-test; full suite passed 2014 tests at prior gate |
| Linux debug build | VERIFIED |
| Windows debug snapshot build | VERIFIED: pub get, 3007 generated outputs, Windows debug build, executable present |
| Native Core journey | UNVERIFIABLE: driver returns `snapshot_id_required` during interaction |
| Failure matrix | PARTIAL/BLOCKED under 145.42 ownership |
| User validation | NOT YET COMPLETED; 145.45–145.47 |
| Production/release/cloud/payment/provider/hardware | DEFERRED or UNVERIFIABLE |

## Decision

`145.16 Core MVP Scope` berstatus **VERIFIED sebagai scope lock dokumenter**. Daftar Core, non-Core, vertical journey, navigation boundary, dan guardrails diambil dari sumber kanonik tanpa penambahan capability baru. Implementasi status tetap harus mengikuti evidence per fitur; scope lock tidak menutup gap native, failure matrix, compatibility, atau user validation.

Langkah berikutnya: `145.17 Explicit Deferred Scope`, untuk memetakan non-Core capability ke backlog evidence-gated tanpa menghapus source/data.

## Evidence paths

- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`
- `docs/audits/product-promise-lock.md`
- `docs/audits/core-cloud-network-roadmap-split.md`
- `docs/audits/working-feature-protection-list.md`
- `docs/sprints/sprint-145-product-scope-reset-mvp-recovery.md`
- `docs/IMPLEMENTATION_GOAL.md`
