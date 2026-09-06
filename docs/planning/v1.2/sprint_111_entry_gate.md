# Sprint 111 Entry Gate — Lore Encyclopedias, Bestiary & Cultural Generators

**Sprint:** 111 — VOID SCRIPTOR v1.2 Lore Encyclopedias, Bestiary & Cultural Generators
**Base version:** `1.2.0-alpha.2`
**Target version:** `1.2.0-beta.1`
**Decision scope:** local/offline implementation entry gate
**Decision:** `GO_WITH_DOCUMENTED_RISK`

This gate records entry evidence only. It does not claim that Sprint 111
features have been implemented. The six Wave-3 capability contracts remain
pending and must be delivered in their canonical order. Feature 30 is recorded
as an alias for feature 24; no new authority, no new flag.

## Required entry evidence

| Evidence | Result | Current proof |
|---|---|---|
| `sprint_110_acceptance` | PASS-LOCAL | Sprint 110 closure `110.50 Sprint Closure` recorded `closed` per `docs/sprints/sprint-110-world-logic-simulation-tools.md`. Alpha 2 gate `110.49` recorded `GO_WITH_DOCUMENTED_RISK` per the same ledger. |
| `stable_world_schema` | PASS-LOCAL | Sprint 110 step `110.5` shipped `lib/features/world_logic/domain/shared_world_data_schema.dart` with cross-workspace namespace and ownership. No replacement world schema is introduced here. |
| `stable_timeline_contract` | PASS-LOCAL | Sprint 110 `110.3` shipped `WorldTimeStateAuthority` and `110.13` shipped `CustomCalendar`; lore temporal scopes (111.5) consume these contracts without inventing new clocks. |
| `stable_culture_ids` | PASS-LOCAL | Sprint 110 `110.23` faction diplomacy registry plus `110.17` genealogy graph expose stable culture references that lore cultural scope (111.5) reuses. |
| `migration_readiness` | PASS-LOCAL | Sprint 110 `110.6` migration, backup, rollback, compatibility, and repair paths remain live. D-SCHEMA-01 stays OPEN; Sprint 111 does not add live Drift tables. |
| `risk_register` | RECORDED | Risks and boundaries below are explicit; unresolved risks remain owned by the relevant later step or product authority. |

## Entry boundaries

- Sprint 111 starts at `111.1` and proceeds through `111.46` in order.
- `111.2` (this run) records Wave-3 scope and the F30 alias rule; the next
  implementation step is `111.3 Shared Encyclopedia Taxonomy`.
- Feature flags for new capabilities remain `OFF` by default; foundation from
  `110.8` is reused.
- Encyclopedia data is local-first; no story/lore content is sent externally by
  default.
- Lore records never mutate canon automatically. Generator output and rumor
  reach are draft state until the writer explicitly accepts them.
- Existing character canon and novel-owned narrative state remain separate;
  cross-domain references are IDs plus provenance, not circular ownership.
- D-SCHEMA-01 remains an open product decision. This entry gate does not add
  tables, migrations, or silently ratify schema evolution.
- Alias feature 30 does **not** add a separate flag, contract, or authority.
  All alias work lives under feature 24 steps `111.14`-`111.19`.
- This document is a planning and acceptance artifact; it performs **no source
  mutation** of project data.

## Risk register

| ID | Risk | Owner / handling |
|---|---|---|
| R111-01 | Encyclopedia taxonomy could fragment into per-domain silos, defeating the search contract at `111.37`. | Resolve in `111.3`; enforce shared category/tag/alias registries and add cross-domain integration tests. |
| R111-02 | Canon/provenance could be muddled between user-authored lore, generator output, and imported third-party content. | Resolve in `111.4`; require `canon_status` + `source_reference` + `revision_history` on every record. |
| R111-03 | New lore records may require schema evolution beyond v56. | Resolve in `111.5`-`111.6` after contract review; backup and rollback are mandatory. |
| R111-04 | Generated names/idioms could be mistaken for canon. | Resolve in `111.31` and `111.35`; keep generator results in a draft bucket with explicit accept-or-discard. |
| R111-05 | Encyclopedia UI may degrade on large catalogs, dense trees/graphs, or narrow screens. | Resolve in `111.37`-`111.38` and `111.43` with keyboard, scaling, and performance evidence. |
| R111-06 | Spoiler content, proprietary media, and third-party licenses could leak through search, import, or diagnostic export. | Resolve in `111.7`-`111.8` and `111.42` with deny-by-default and redaction tests. |
| R111-07 | Alias feature 30 could be misread as a new capability, new flag, or new authority. | Resolve by reading `docs/planning/v1.2/sprint_111_scope_contract.md`; flag, contract, and acceptance set belong to F24. |
| R111-08 | Hosted CI, public distribution, native platform signing, and native assistive-technology certification are not available in the local gate. | Remains a release risk; no public/production release claim is made. |

## Gate result

Sprint 111 may begin implementation from `111.3` under these boundaries. This is
not a feature-completion claim and not a beta-1 release approval.

**Production/public status:** `NO-GO` until the later Beta 1 Acceptance Gate has
real feature, alias, taxonomy, canon/provenance, scope, media/rights,
spoiler/flags/a11y, integration, search, portability, test matrix, performance,
security, accessibility, documentation, and rollback evidence.
