# Sprint 114 — VOID SCRIPTOR v1.2 Post-Release Stability & Adoption

- **Status:** ACTIVE (2026-09-24, keputusan Choirudin untuk melanjutkan roadmap)
- **Kanonik:** `sprint_114.json` — 44 langkah, sequence PASS
- **Start condition:** keputusan Sprint 113 tercatat; jalur yang aktif adalah `DELAYED` dengan corrective scope lokal
- **Batas klaim:** Sprint ini tidak mengklaim v1.2.0 sudah dipublikasikan; bukti eksternal tetap `DEFERRED-EXTERNAL`

| Step | Title | Status | Evidence |
|---|---|---|---|
| 114.1 | Post-Release Entry Gate | VERIFIED-LOCAL | `docs/planning/v1.2/sprint_114_post_release_entry_gate.json` + `lib/features/world_logic/domain/post_release_entry_gate.dart` + `test/release/sprint_114_post_release_entry_gate_test.dart`; jalur `DELAYED`, release `DEFERRED_RELEASE`, artifact lokal `1.2.0-rc.1`, rollout `NOT_STARTED`, known issues dan residual risks tercatat; tidak mengklaim GA/publication/telemetry. Test fokus 3/3 PASS, analyzer penuh `No issues found`, format dan diff-check PASS; blocker compile sibling `workspace_panel.dart` direkonsiliasi tanpa mengadopsi WIP lain, lalu Windows debug build PASS 34,5 detik. |
| 114.2 | Observation Charter | VERIFIED-LOCAL | `docs/planning/v1.2/sprint_114_observation_charter.json` + `lib/features/world_logic/domain/observation_charter.dart` + `test/release/sprint_114_observation_charter_test.dart`; charter `DELAYED`/`LOCAL_CORRECTIVE` mendefinisikan window, questions, privacy-safe local signals, owners, escalation, stop conditions, exit criteria, dan `DEFERRED-EXTERNAL` gates tanpa klaim production telemetry. Test fokus 3/3 PASS, analyzer scoped `No issues found`, format, diff-check, dan Windows debug build PASS 27,6 detik. |
