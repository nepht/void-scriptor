# Sprint 145.17 — Explicit Deferred Scope

Tanggal audit: 2026-08-27  
Sumber kanonik: `core_mvp_scope_reset_spec.json`, `sprint_145.json`, dan spesifikasi capability terkait pada export Sprint 145.  
Metode: rekonsiliasi scope read-only; tidak ada source, data, route, atau feature yang dihapus.

## Aturan deferred

Capability non-Core tetap dipertahankan sebagai backlog atau controlled feature flag. Status `source exists` tidak sama dengan `verified`, dan logo/route/mock tidak sama dengan integrasi siap rilis.

Sebuah deferred capability hanya boleh diaktifkan setelah:

1. kontrak domain dan data ownership jelas;
2. dependency tidak masuk ke Core startup/open/save path;
3. failure, privacy, security, and rollback behavior diuji;
4. relevant provider/service/hardware evidence tersedia;
5. UI state jujur saat capability unavailable;
6. focused tests, analyzer, full regression, dan platform gate lulus;
7. release approval terpisah diberikan.

## Deferred capability registry

| Capability | Layer | Reason deferred | Entry evidence required | Default |
|---|---|---|---|---|
| Optional account/auth | CLOUD | Core must work without identity; account authority and privacy contract separate | Account lifecycle, logout, token handling, privacy, offline fallback, restart tests | OFF for Core startup |
| Cloud backup | CLOUD | Needs remote service, encryption, retry, quota, deletion, and recovery evidence | Sandbox service, authenticated opt-in, restore drill, outage/retry tests | OFF |
| Sync | CLOUD | Conflict semantics and one-authority rule unresolved | Two-device conflict matrix, deterministic merge/rollback, interrupted transfer tests | OFF |
| Collaboration | CLOUD/NETWORK | Sharing permissions and private manuscript boundaries | Access-control matrix, revocation, audit, concurrent edit policy | OFF |
| Optional AI | CLOUD/LOCAL OPTIONAL | Provider/network failure must not block writing; secrets must stay outside project data | One BYOK provider, consent/cancel/redaction/timeout/rate-limit tests, provider sandbox | OFF |
| Limited connectors | CLOUD/NETWORK | External API and privacy contracts absent | Per-connector capability, permission, retry, quota, and data-minimization tests | OFF |
| Reader platform | NETWORK | Requires hosted content, account/privacy, moderation, and operations | Published artifact contract, access control, abuse handling, uptime/rollback evidence | OFF |
| Publishing pipeline | NETWORK | Export/publish must use immutable versioned snapshot, not mutable live manuscript | Versioned snapshot, preview, rollback, metadata, rights, and end-to-end service tests | OFF |
| Community | NETWORK | Public identity, moderation, reporting, and privacy required | Moderation policy/tooling, abuse escalation, privacy tests, operational owner | OFF |
| Support-author systems | NETWORK | Operational workflow and personal-data handling not established | Ticket/data-retention/access policy and service evidence | OFF |
| Payment/payout | NETWORK | Financial, legal, provider, and reconciliation risk; never startup/save dependency | Sandbox payment, webhook idempotency, refund/chargeback, ledger, payout and compliance evidence | OFF |
| Marketplace | NETWORK | Installed connectors/extensions require trust and permission boundaries | Signed package, permission review, provenance, uninstall/rollback, privacy-safe analytics | OFF |
| Developer platform | NETWORK | SDK/versioning/support surface is not Core | Stable public contract, compatibility policy, security review, sample integration | OFF |
| Regional scale | NETWORK | Deployment, support, policy, and data-residency work absent | Region matrix, localization, observability, incident/recovery drills | OFF |
| Mobile full editor | PLATFORM FOLLOW-UP | Native storage/editor UX and platform QA not verified | Android/iOS persistence, permissions, interruption/restart, responsive integration | DEFERRED |
| macOS release | PLATFORM FOLLOW-UP | Signing/notarization and native QA not verified | Developer ID, notarization, packaging, native storage and QA evidence | DEFERRED |
| Dozens of AI/cloud providers | CLOUD FOLLOW-UP | Provider-specific reliability and cost/credential contracts multiply risk | One-by-one provider contract and sandbox evidence | DEFERRED |
| Audio/video production | FOLLOW-UP | Missing complete Core MVP contract and evidence matrix | Explicit product contract, persistence, import/export, runtime, and platform evidence | DEFERRED |

## Preserve, hide, or disable

- Preserve implementation and data when it is already present.
- Hide from primary navigation when it is not part of the Core promise.
- Disable with a visible explanation when the user can reach the surface but its dependency is unavailable.
- Keep feature flags safe-off by default.
- Never expose payment logos, cloud labels, or marketplace cards as proof of active integration.
- Never delete project data merely because its feature is deferred.

## Core isolation contract

The following must remain true while deferred capabilities exist:

- Core launches without account, internet, subscription, Cloud, Network, Payment, or AI provider.
- Local project open, edit, save, search, export, backup, and restore do not await remote services.
- AI and cloud errors surface as optional capability errors, not Core data errors.
- Payment/payout code is not on startup, save, migration, or project-open paths.
- Community and marketplace have no implicit access to manuscript, character, private notes, cloud paths, or credentials.
- Portable export excludes credentials, session tokens, API keys, cloud credentials, payment data, device identifiers, temporary files, and regenerable cache.
- A capability is not reclassified as Core from a route, model, mock, or passing unit test alone.

## Evidence boundary

Current repository evidence supports this document as a scope/dependency decision. It does not prove live Cloud, Network, Payment, Marketplace, mobile, macOS, or production operations.

Known separate blockers:

- Native Windows click-through remains `UNVERIFIABLE` because the driver returns `snapshot_id_required`.
- Data-safety failure matrix remains owned by another executor under 145.42.
- Primary-user validation remains blocked under 145.14.
- Existing-data compatibility matrix remains partial under 145.12.

## Decision

`145.17 Explicit Deferred Scope` berstatus **VERIFIED sebagai registry scope**. Non-Core capability, alasan penundaan, entry evidence, dan safe defaults tercatat tanpa penghapusan atau aktivasi fitur. Runtime completion remains evidence-gated.

Langkah berikutnya: `145.18 Core MVP Vertical Slice Definition`.

## Evidence paths

- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`
- `docs/audits/core-mvp-scope-lock.md`
- `docs/audits/core-cloud-network-roadmap-split.md`
- `docs/audits/existing-user-data-compatibility.md`
- `docs/audits/working-feature-protection-list.md`
- `docs/sprints/sprint-145-product-scope-reset-mvp-recovery.md`
