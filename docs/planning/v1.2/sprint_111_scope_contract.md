# Sprint 111 — Wave 3 Scope & Alias Contract

**Base:** `1.2.0-alpha.2`  
**Target:** `1.2.0-beta.1`  
**Next contract:** `111.3 Shared Encyclopedia Taxonomy`

This contract locks the six Wave 3 capability families before implementation. It
is a scope boundary, not evidence that the families already exist. Feature 30 is
treated as an alias for feature 24 (Encyclopedia + Bestiary + Cross-Domain
Bridges); the alias does not add a new authority.

## Capability map

| Feature | Capability | Canonical steps | Acceptance boundary |
|---|---|---|---|
| F23 | Herbology & Alchemy Database | 111.9–111.13 | Substance catalog, habitat/rarity/harvest, effect/toxicity, recipes, and explainable consistency validation. |
| F24 | Bestiary Journal (aliases F30) | 111.14–111.19 | Species registry, anatomy, ecology, weakness/defense reference, encounter journal, and harvestable materials with ecological consequence. |
| F26 | Artifacts & Ancient Relics | 111.20–111.23 | Artifact registry, ownership lineage, activation/cost/curse rules, and usage & authenticity checks. |
| F27 | Myth, Legend & Theology Archive | 111.24–111.28 | Myth registry, public belief vs historical truth, theology & deities, belief distribution history, and reveal/foreshadowing links. |
| F28 | Syllable-Based Name Generator | 111.29–111.32 | Syllable pool & phonotactic rules, cultural profiles, seeded generation, and collision/cultural consistency. |
| F29 | Local Idiom & Proverb Bank | 111.33–111.36 | Idiom registry, cultural ownership & usage context, tone & connotation, and anachronism checks. |

## Shared dependencies

1. `111.1` entry gate must remain verified before implementation continues. The
   gate inherits from Sprint 110 Alpha 2: shared world data schema, canonical
   timeline, valid genealogy/cultural ids, and migration readiness.
2. `111.2` (this contract) locks scope and aliases. Feature 30 is recorded as
   part of feature 24; no separate authority, no separate flag.
3. `111.3` owns the encyclopedia taxonomy: controlled categories, free tags,
   aliases, localized names, cross-domain links, and taxonomy versioning.
4. `111.4` owns canon status, source reference, author or culture, confidence,
   assumptions, and revision history for every lore record.
5. `111.5` owns validity ranges, locations, cultures, factions, languages, and
   world branches so each entry can be temporally and regionally scoped.
6. `111.6` owns the shared data schema, migration, backup, rollback,
   compatibility, and data-repair path. D-SCHEMA-01 remains OPEN; no premature
   Drift tables are introduced.
7. `111.7` owns media rights: local media, source credit, license notes, missing
   file state, metadata sanitization, and explicit export.
8. `111.8` owns spoiler levels, reveal points, per-feature flags, keyboard
   navigation, screen reader labels, and nonvisual fallback.
9. Feature work proceeds in JSON-canonical order: F23, F24, F26, F27, F28, F29.

## Alias rule (feature 30)

- `feature_delivery[1].title = "Bestiary Journal"` already declares
  `"includes_alias": 30`. The alias does **not** create a new capability, new
  acceptance set, new flag, or new contract; it exists to surface lore-search
  results that span creatures, variants, and lifecycle under one user-facing
  bucket.
- All alias work is recorded under F24 steps `111.14`–`111.19`. If the alias
  requires new acceptance later, it must be proposed as a new canonical step,
  not silently added.

## Non-goals

- No automatic canon mutation: lore records are explicit user entries; generator
  output stays in a draft bucket until writer approval.
- No hidden real-world clock, locale, global randomness, network call, or
  implicit unit conversion in deterministic generators or validators.
- No external transmission of story/lore content by default; diagnostics must
  stay local and redacted.
- No premature Drift table or migration. D-SCHEMA-01 remains open until the
  shared schema contract is explicitly resolved.
- No production release, hosted publication, native platform certification, or
  claim that the encyclopedia is performant at arbitrary scale before its own
  verification step (`111.41`).
- No AI judge for canon truth. Rule-based, explainable validation is the first
  acceptance layer; AI suggestions remain optional and non-authoritative.
- Alias feature 30 is not a separate flag. It uses the F24 default.

## Delivery rules

- Every capability has a feature flag defaulting `OFF` (foundation from
  `110.8`).
- Local-first and backward compatibility are mandatory.
- Manual exceptions require provenance and an explicit reason.
- Invalid inputs fail closed with an explainable error; partial subsystem
  failure must not corrupt unrelated lore data.
- All new IDs are stable UUIDs or stable existing entity references.
- Each step requires RED -> minimal implementation -> focused GREEN -> analyzer
  -> full regression gate before ledger closeout.

## Contract result

The scope is locked for implementation beginning at `111.3`, after this contract
is verified. The acceptance boundary for Beta 1 remains all six capability
families plus shared contracts (taxonomy, canon/provenance, scope, media/rights,
spoiler/flags/a11y), plus integration, search, portability, automated test
matrix, performance, security, accessibility, documentation, acceptance gate,
and closure evidence.

**Public/production status:** `NO-GO`. This document authorizes local feature
implementation only and records **no automatic canon mutation**.
