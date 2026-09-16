# Sprint 112.2 — Scope Freeze & Non-Goals

**Sprint:** 112 — VOID SCRIPTOR v1.2 Worldbuilding Integration, Validation & Release Candidate
**Canonical step:** `112.2`
**Base:** `1.2.0-beta.1`
**Target:** `1.2.0-rc.1`

Dokumen ini membekukan scope stabilisasi release candidate. Ia adalah kontrak
batas, bukan klaim bahwa semua capability sudah berfungsi atau siap dirilis.

## Frozen scope — 29 konsep unik

Feature 30 adalah alias Feature 24 dan tidak menambah capability, authority,
acceptance set, atau feature flag baru.

| Feature | Capability |
|---:|---|
| F1 | Inline Lore Linking |
| F2 | Story Contradiction Detector |
| F3 | Travel & Logistics Simulation |
| F4 | Character Voice Interview |
| F5 | Custom Calendar & Celestial Time |
| F6 | Genealogy Tree |
| F7 | Constructed Language Dictionary |
| F8 | Focus Writing, Word Targets & Draft Snapshots |
| F9 | Global Lore Graph |
| F10 | Kanban Plot Board |
| F11 | Temporal World Map |
| F12 | Character Visual Moodboard |
| F13 | Faction Diplomacy Grid |
| F14 | Automatic Character Age & Location Tracker |
| F15 | Power-System Guardrails |
| F16 | Spoiler-Aware Sharing |
| F17 | POV Consistency Tracker |
| F18 | Pacing & Tension Heatmap |
| F19 | Clean Manuscript Export |
| F20 | Fiction Economy & Inflation Calculator |
| F21 | Rumor Propagation |
| F22 | Technology Tree & Civilization Limits |
| F23 | Herbology & Alchemy Database |
| F24 | Bestiary Journal (includes alias F30: Bestiary Creature Profile) |
| F25 | Subplot, Mission & Quest Tracker |
| F26 | Artifacts & Ancient Relics |
| F27 | Myth, Legend & Theology Archive |
| F28 | Syllable-Based Name Generator |
| F29 | Local Idiom & Proverb Bank |

## Non-goals selama RC stabilization

1. Tidak ada perluasan fitur baru di luar 29 konsep unik dan kontrak Wave 1–3.
2. Tidak ada automatic canon mutation; hasil generator, simulasi, dan analisis
   tetap proposal/draft sampai penulis menyetujuinya.
3. Tidak ada penggantian source of truth, co-ownership lintas workspace, atau
   circular dependency antar Novel, Character, dan lore project-level.
4. Tidak ada transmisi story/world content ke jaringan secara default; diagnostics
   tetap local-first, privacy-safe, dan redacted.
5. Tidak ada perubahan schema atau migration yang tidak memiliki kontrak,
   compatibility, backup, rollback, dan evidence tersendiri.
6. Tidak ada klaim native platform certification, hosted CI, signing, arbitrary
   scale performance, atau public release dari bukti lokal saja.
7. Tidak ada AI judge untuk kebenaran canon; validasi rule-based yang explainable
   tetap lapisan pertama dan AI bersifat opsional/non-authoritative.
8. Feature 30 tidak boleh diberi flag, owner, atau acceptance terpisah dari F24.

## Deferred items

Item yang belum memiliki evidence implementasi dan gate sendiri tetap `DEFERRED`,
bukan dianggap selesai: native certification, hosted CI, signing/publication,
hardware/power-loss proof, arbitrary-scale performance, dan keputusan schema
D-SCHEMA-01 yang belum dibekukan.

## Exception process

Perubahan scope hanya dapat masuk melalui keputusan produk yang tercatat dan
pembaruan kontrak kanonik sebelum implementasi. Exception wajib menyebut feature
atau non-goal yang terdampak, alasan, owner, migration/rollback impact, dan gate
baru. Worker tidak boleh memperluas scope hanya karena menemukan TODO atau
kapabilitas yang tampak menarik.

## Delivery boundaries

Feature flags tetap `OFF` secara default, local-first dan backward compatibility
wajib dipertahankan, serta setiap perubahan harus memiliki RED → GREEN →
regression → analyzer evidence. Status dokumen ini adalah **FROZEN-LOCAL**;
status public/production tetap **NO-GO**.
