# 109.2 Output 4/4 — Dependency Map (Sprint 109)

> Disusun nephthys 2026-08-26 dari audit live repo + kanonik `sprint_109.json` +
> ADR-WS-001. Urutan EKSEKUSI tetap mengikuti urutan langkah kanonik 109.1→109.52;
> peta ini mendokumentasikan dependensi LOGIS agar tiap langkah tahu apa yang harus
> sudah ada sebelum ia mulai.

## L0 — Fondasi SUDAH ADA (dipakai, tidak dibangun ulang)

| Aset live | Dipakai oleh |
|---|---|
| `story_arcs`, `story_chapters`, `story_scenes`, `scene_characters`, `scene_beats` | F10, F17, F18, F25 (penambat naratif) |
| `timelines`, `timeline_tracks`, `timeline_clips` | F29 timeline_awareness*, F34 timeline_query |
| `canon_rules`, `canon_conflicts`, `consistency` (tabel ADA, isi diprobe saat implementasi) | F2 |
| `worldbuilding_entities`, `bible_entries`, asset relations/tags/collections | F1 target link, F9 node/edge graph |
| `characters`, `character_identity_profiles`, `character_references` | F4, F12, F29* |
| `dialogue` (tabel ADA) | F16 konsistensi dialog |
| Project package + registry (`projects.json`, `.voidproject`, backup/restore resilience) | semua persistensi baru + 109.5 |
| Feature flag infrastruktur & observability lokal | didaftarkan di 109.8 |
| Lokalisasi `app_id.arb` (ID) | 109.7 baseline |

\* 109.29 "Visual Description Continuity" (langkah kedua F12).

## L1 — Fondasi BARU wajib lebih dulu (109.3–109.8)

1. **Workspace separation** (109.3, ADR-WS-001): boundary NOVEL vs CHARACTER vs proyek —
   prasyarat kepemilikan semua fitur di feature_contracts.
2. **Shared Data Schema** (109.4): kontrak `novel_character_link` + desain tabel baru —
   prasyarat SEMUA capability yang menambah tabel (**ESTIMASI** di feature_contracts).
3. **Migration/Backup/Rollback** (109.5): prasyarat eksekusi migrasi pertama; D-SCHEMA-01
   (evolusi additive v56→>56) diratifkan di sini/di 109.51.
4. **Permission & Privacy Model** (109.6): prasyarat F16 (clearance/redaction) dan
   review keamanan 109.47.
5. **A11y & Localization Baseline** (109.7): prasyarat kriteria screen reader/keyboard
   (F8, F10) dan verifikasi 109.48.
6. **Feature Flags & Observability** (109.8): setiap fitur baru WAJIB terdaftar flag OFF
   sebelum UI pertamanya ship.

## L2 — Dependensi antar-capability

```
F1 lore links ──► F9 graph (edge dari link) ──┐
   │                                          ├─► 109.44 integrasi lintas-fitur
   ├──► F2 deteksi kontradiksi (sitasi)       │
   └──► F19/F32 strip link saat export ───────┤
F16 model spoiler ──► F32 share export         │
   ▲──────────► F19 memakai sanitizer sama ────┤
F17 POV assignments ──► F10 card_schema (POV)  │
F10 board ◄──sync eksplisit──► story hierarchy │
F25 quest links ──► scene/character/arc        │
F8 snapshot ──► F19 export teks kini           │
F12 moodboard (CHARACTER) ◄─link/override─ NOVEL│
```

Aturan: tidak ada siklus OWNERSHIP (data boleh dibaca lintas via kontrak, tidak boleh
dimiliki dua workspace); sanitizer export adalah satu komponen bersama F16+F19, bukan dua.

## L3 — Gerbang akhir

109.45 test matrix → 109.46 performa → 109.47 security/privacy → 109.48 a11y/locale →
109.49 dokumentasi → 109.50 packaging alpha → 109.51 alpha gate (ratifikasi skema &
deviasi) → 109.52 closure. Semua gerbang menuntut bukti eksekusi nyata, bukan daftar hadir file.
