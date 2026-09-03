# Sprint 145.15 — Core / Cloud / Network Roadmap Split

Tanggal audit: 2026-08-27  
Sumber kanonik: `core_mvp_scope_reset_spec.json` dan `sprint_145.json`.  
Metode: rekonsiliasi read-only terhadap roadmap layer, Core MVP, source live, dan evidence boundary.

## Dependency direction

```text
CORE
  ↑
CLOUD
  ↑
NETWORK
```

Kontrak kanonik lebih tepat dibaca sebagai:

- `CORE` bergantung pada neither Cloud maupun Network.
- `CLOUD` boleh bergantung pada Core.
- `NETWORK` boleh bergantung pada Cloud dan Core.
- Payment tidak berada di startup atau save path.
- Navigation component tidak memiliki domain data.
- Feature flags memiliki safe defaults.

## Roadmap layer matrix

| Layer | Canonical capabilities | Release eligibility | Current evidence | Current treatment |
|---|---|---|---|---|
| CORE | Local projects, Novel Workspace, Character Workspace, Writing Room, core worldbuilding, search/lore links, autosave/recovery, local backup/restore, portable import/export, clean manuscript export, custom desktop storage | Boleh masuk Core MVP hanya jika local-first journey dan data-safety gates lulus | Source/test/local persistence/build evidence tersedia untuk banyak slice; native end-to-end dan failure matrix belum penuh | Keep visible where verified; stabilize; regression-test |
| CLOUD | Optional account, cloud backup, sync, collaboration, optional AI, limited connectors | Hanya setelah Core berjalan tanpa Cloud; explicit opt-in; separate provider/network gates | Local/mock/provider contracts ada; live cloud/provider/backend belum terverifikasi | Optional/deferred; no startup dependency |
| NETWORK | Reader, publishing, community, support author, payment/payout, marketplace, developer platform, regional scale | Tidak eligible untuk Core MVP; memerlukan external/service, privacy, operational, payment, and release evidence | Banyak source/routes/contracts lokal; production network/payment/service evidence belum ada | Preserve source; hide/feature-gate/defer until evidence |

## Core MVP boundary

Kanonik mendefinisikan platform `WINDOWS_X64_LOCAL_FIRST` dengan:

- account tidak wajib;
- internet tidak wajib;
- subscription tidak wajib untuk local writing;
- workspace utama `NOVEL` dan `CHARACTER`;
- writing: chapter/scene tree, editor, word count, search, lore links, clean export;
- worldbuilding: characters, locations, factions, timeline, relationship map, lore notes;
- data safety: autosave, snapshots, crash recovery, backup, restore, portable format, custom drive;
- satu BYOK AI provider hanya optional setelah Core stabil;
- Cloud, Community, Publishing, Payment, Payout, Marketplace, Mobile Editor, dan macOS bukan syarat MVP.

## Feature treatment rules

| Evidence classification | Required treatment |
|---|---|
| Core verified | Keep visible, stabilize, and regression-test |
| Non-Core verified | Preserve behind clear Beta/Experimental/feature flag unless low-risk |
| Partial | Complete only when required by vertical slice; otherwise disable and backlog |
| UI-only/mock | Remove from primary navigation and label internal state honestly |
| Planned | Backlog; no runtime claim |
| High-risk/unverified | OFF by default |

## Current mapping of live areas

### CORE candidates

- `features/projects`, project package, manifest, project registry, session/open/close.
- Character, Story/Novel, chapter/scene, Environment/World, relations, Bible/lore, timeline.
- Explorer selection, workspace resolver, writing/workspace shell, search/lore links.
- Autosave/recovery, local database, backup/restore, workspace import/export, clean export.
- Windows debug artifact and WSL Linux development build.

Evidence: focused suites, full source tests, analyzer, Linux build, Windows snapshot build. Native route interaction and complete 145.42 failure matrix remain separate.

### CLOUD candidates

- Optional account/auth remote path.
- Cloud backup/sync/collaboration and conflict services.
- Optional AI providers and limited connectors.

Evidence: local abstractions/mock/provider routing exist; live remote behavior, credentials, server, conflict operations, and production reliability are not verified. No credential is read or stored by this audit.

### NETWORK candidates

- Reader platform and community.
- Public publishing and author support.
- Payment/payout and marketplace.
- Developer platform and regional scale.

Evidence: source/routes/local contracts may exist, but network/service/payment/operational gates are not satisfied. These remain preserved/deferred rather than deleted.

## Release and startup guards

1. Core launch, open, edit, save, search, export, backup, and restore must work without account/internet/subscription.
2. Cloud and Network initialization must not block Core startup.
3. AI provider failure must not prevent Core project opening or writing.
4. Payment must not enter startup or save path.
5. A live project has one sync authority; app cloud plus external folder sync is prohibited until conflicts are verified.
6. Publishing receives an explicit versioned snapshot, not mutable live manuscript state.
7. Community has no implicit manuscript access.
8. New capabilities default OFF unless their local contract and evidence gate are complete.
9. Non-Core code/data is preserved and reactivatable; scope reset is not destructive.
10. Native/build/release evidence is reported separately from local domain/UI evidence.

## Unresolved boundaries

- Primary user/job decision (`145.14`) still needs Choirudin/user validation; this split does not assume a persona beyond the canonical “novelist” promise.
- Data safety failure matrix (`145.42`) remains owned by another executor.
- Custom drive, full portable compatibility, clean export fidelity, and complete Core vertical journey still need their dedicated steps.
- Native Windows click-through remains blocked by `snapshot_id_required`.
- Cloud/server/payment/live-provider, packaging/signing, and production rollout remain external/deferred.

## Decision

`145.15 Core / Cloud / Network Roadmap Split` berstatus **VERIFIED sebagai audit scope lokal**. Semua capability dipetakan sesuai layer kanonik, dengan dependency direction dan release guards eksplisit. Tidak ada feature code, schema, route, account, cloud, payment, atau user data yang diubah.

Langkah berikutnya yang aman: `145.16 Core MVP Scope`, menggunakan daftar Core di atas untuk mengunci scope implementasi tanpa memperluasnya.

## Evidence paths

- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`
- `docs/audits/product-promise-lock.md`
- `docs/audits/working-feature-protection-list.md`
- `docs/audits/dependency-coupling-map.md`
- `docs/audits/data-ownership-map.md`
- `docs/audits/existing-user-data-compatibility.md`
- `docs/IMPLEMENTATION_GOAL.md`
