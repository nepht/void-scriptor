# Sprint 110 — Wave 2 Scope Contract

**Base:** `1.2.0-alpha.1`  
**Target:** `1.2.0-alpha.2`  
**Next contract:** `110.3 World Time & State Authority`

This contract locks the ten Wave 2 capabilities before implementation. It is a
scope boundary, not evidence that the capabilities already exist.

## Capability map

| Feature | Capability | Canonical steps | Acceptance boundary |
|---|---|---|---|
| F3 | Travel & Logistics Simulation | 110.9–110.12 | Route graph, terrain/season cost, travel modes, supplies, and explainable consistency warnings. |
| F5 | Custom Calendar & Celestial Time | 110.13–110.16 | Custom calendar conversion, celestial cycles, seasons, and weather hooks with provenance. |
| F6 | Genealogy Tree | 110.17–110.19 | Typed relationships, interactive family/dynasty view, validity and inheritance validation. |
| F11 | Temporal World Map | 110.20–110.22 | Location/control state by validity range, historical layers, and time-aware route validation. |
| F13 | Faction Diplomacy Grid | 110.23–110.25 | Directed public/secret/perceived relations plus treaty, conflict, trade, and history links. |
| F14 | Automatic Character Age & Location Tracker | 110.26–110.28 | Age-at-time, location history, uncertainty, and explainable continuity alerts. |
| F15 | Power-System Guardrails | 110.29–110.32 | Ability rules, costs, limits, usage ledger, violations, escalation signals, and dismissal reasons. |
| F20 | Fiction Economy & Inflation Calculator | 110.33–110.35 | Currency/unit/reference basket, price and wealth history, inflation, and comparison warnings. |
| F21 | Rumor Propagation | 110.36–110.38 | Channel profiles, seeded spread, distortion/reliability, and scene knowledge preview. |
| F22 | Technology Tree & Civilization Limits | 110.39–110.41 | Technology prerequisites/resources, civilization tree, era alignment, and validation warnings. |

## Shared dependencies

1. `110.1` entry gate must remain verified before implementation continues.
2. `110.3` owns canonical clock, calendar adapter, state snapshots, branches, and
   provenance; feature modules must consume it rather than inventing clocks.
3. `110.4` owns explicit simulation inputs, stable seed, units, precision,
   replayability, and explainability.
4. `110.5` owns cross-workspace references and namespace boundaries. Character
   canon stays character-owned; novel scene state stays novel-owned.
5. `110.6` owns migration, backup, rollback, compatibility, and repair paths.
6. `110.7` owns origin, confidence, assumptions, manual override, reason, and
   history for every derived result.
7. `110.8` owns per-feature flags, local diagnostics, privacy-safe metrics,
   kill-switch behavior, and error export.
8. Feature work proceeds in the JSON-canonical order: F3, F5, F6, F11, F13, F14,
   F15, F20, F21, F22.

## Non-goals

- No automatic canon mutation: simulations produce derived results or proposals;
  writer approval is required before canon changes.
- No hidden real-world clock, locale, global randomness, network call, or implicit
  unit conversion in deterministic calculations.
- No circular ownership or duplicated Character/Novel source of truth.
- No external transmission of story/world content by default; diagnostics must be
  local and redacted.
- No premature Drift table or migration. D-SCHEMA-01 remains open until the
  shared schema contract is explicitly resolved.
- No production release, hosted publication, native platform certification, or
  claim that a graph/map/tree is performant at arbitrary scale before its own
  verification step.
- No AI judge for canon truth. Rule-based, explainable validation is the first
  acceptance layer; AI suggestions remain optional and non-authoritative.

## Delivery rules

- Every capability has a feature flag defaulting `OFF`.
- Local-first and backward compatibility are mandatory.
- Manual overrides require provenance and an explicit reason.
- Invalid inputs fail closed with an explainable error; partial subsystem failure
  must not corrupt unrelated world data.
- All new IDs are stable UUIDs or stable existing entity references.
- Each step requires RED → minimal implementation → focused GREEN → analyzer →
  full regression gate before ledger closeout.

## Contract result

The scope is locked for implementation beginning at `110.3`, after this contract
is verified. The acceptance boundary for Alpha 2 remains all ten capabilities
plus cross-simulation, determinism, quality, migration, security, accessibility,
and rollback evidence.

**Public/production status:** `NO-GO`. This document authorizes local feature
implementation only and records **no automatic canon mutation**.
