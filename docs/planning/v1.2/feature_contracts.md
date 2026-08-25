# 109.2 Output 1/4 — Feature Contracts (13 Capability v1.2)

> Sumber kanonik: `Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_109.json`
> (blok `feature_delivery`, 13 entri) + `workspace_separation_architecture.json` (ADR-WS-001,
> status ACCEPTED_USER_DIRECTION / implementasi NOT_STARTED).
> Disusun nephthys 2026-08-26. Semua nama tabel baru bertanda **ESTIMASI** — angka final
> diputuskan di langkah 109.4 (Shared Data Schema) berdasarkan audit live, bukan dokumen ini.

## Kontrak umum (mengikat semua capability)

- Kepemilikan mengikuti ADR-WS-001: NOVEL vs CHARACTER vs lore level-proyek;
  tidak ada co-ownership lintas workspace; link hanya via `novel_character_link`
  (mode REFERENCE default / SNAPSHOT / FORK).
- Feature flag default **OFF** (`delivery_rules.feature_flag_default`); nama flag di bawah
  adalah usulan, registrasi nyata di langkah 109.8.
- Local-first; tanpa service remote; export data user wajib tersedia.
- Setiap capability lolos gerbang TDD penuh (RED→GREEN→regresi) sebelum status VERIFIED.

## Daftar kontrak

| # | Capability (kanonik) | Langkah | Kepemilikan (ADR) | Persistensi | Flag usulan | Acceptance inti |
|---|---|---|---|---|---|---|
| F1 | Inline Lore Linking | 109.9–11 | NOVEL (teks manuskrip) | parser link + indeks backlink **ESTIMASI** tabel baru | `vs12_lore_links` | syntax+parser, autocomplete/preview, backlinks, integritas broken-link |
| F2 | Story Contradiction Detector | 109.12–14 | NOVEL membaca canon; hasil analisis milik proyek | reuse `canon_rules`/`canon_conflicts` yang ADA + kontrak rule baru | `vs12_contradictions` | rule contract, pipeline analisis, inbox dengan dismiss/explain |
| F4 | Character Voice Interview | 109.15–16 | CHARACTER | interview + voice profile **ESTIMASI** tabel baru | `vs12_voice_interview` | workspace interview, profil suara, konsistensi dialog |
| F7 | Constructed Language Dictionary | 109.17–19 | Lore level-proyek * (lihat catatan) | registry/dictionary **ESTIMASI** tabel baru | `vs12_conlang` | registry+kamus, grammar/phonology/script, usage consistency |
| F8 | Focus Writing, Word Targets & Draft Snapshots | 109.20–22 | NOVEL (manuscript_text, draft_snapshots) | snapshot + target **ESTIMASI** tabel baru | `vs12_focus_writing` | focus mode, target multi-level timezone-safe, diff+restore dengan backup otomatis |
| F9 | Global Lore Graph | 109.23–24 | Read-model level-proyek (agregasi, tanpa co-ownership) | view/index turunan, tanpa duplikasi kebenaran | `vs12_lore_graph` | filter domain/waktu/canon, fokus entitas, navigasi ke sumber, fallback graph besar, insight yatim/konflik |
| F10 | Kanban Plot Board | 109.25–27 | NOVEL (plot_boards) | board/card/order **ESTIMASI** tabel baru | `vs12_plot_board` | schema board, drag+keyboard reorder, multi-select, undo, sinkron eksplisit ke urutan cerita dengan preview konflik |
| F12 | Character Visual Moodboard | 109.28–29 | CHARACTER (kanonik); Novel hanya link+override | moodboard + attribute registry **ESTIMASI** | `vs12_moodboard` | media lokal, kategori, anotasi, kredit sumber, state file hilang; continuity deskripsi visual timeline-aware |
| F16 | Spoiler-Aware Sharing | 109.30–32 | NOVEL (spoiler_reveal_state, beta_reader_shares) | klasifikasi spoiler + clearance **ESTIMASI** | `vs12_spoiler_sharing` | level spoiler, reveal point, audience policy, redaction, preflight export tanpa metadata bocor, revoke |
| F17 | POV Consistency Tracker | 109.33–35 | NOVEL (scene_pov_assignments) | POV lock + knowledge events **ESTIMASI** | `vs12_pov` | POV/tense/mode per scene+section, knowledge boundary timeline-aware, laporan head-hopping dengan false-positive control |
| F18 | Pacing & Tension Heatmap | 109.36–37 | NOVEL (pacing_tension) | label tensi/pacing **ESTIMASI** | `vs12_pacing` | label manual+sinyal durasi/jumlah kata, heatmap bab/arc, hint plateau, threshold custom, tanpa penilaian mutlak |
| F19 | Clean Manuscript Export | 109.38–40 | NOVEL (publishing_profiles) | profil export + manifest **ESTIMASI** | `vs12_export` | profil DOCX/txt/web-novel, strip link internal+catatan privat, output deterministik, preflight blocking-error vs warning, tanpa mutasi sumber |
| F25 | Subplot, Mission & Quest Tracker | 109.41–43 | NOVEL (subplots_quests) | quest/dependency/stakeholder **ESTIMASI** tabel baru | `vs12_quests` | schema tujuan/dependency/outcome, board misi dengan story links, alert subplot menggantung + dismissal reason |

## Catatan kepemilikan

\* **D-OWN-02 (terbuka)**: ADR-WS-001 hanya mendefinisikan dua workspace (NOVEL, CHARACTER).
Conlang (F7) dan lore graph (F9) bukan keduanya. Default kontrak ini: lore level-proyek,
disimpan di namespace proyek, tidak dimiliki salah satu workspace — final ditetapkan di 109.3.

## Rantai integrasi antar-capability (ringkas)

F1 menyediakan referensi stabil → F9/F2 mengonsumsi; F16 memberi model spoiler → F32 & F19
memakai sanitizer yang sama; F10/F17/F18/F25 semuanya menambat pada hierarchy
Story→Arc→Chapter→Scene yang SUDAH ADA (`story_arcs/chapters/scenes`, `scene_characters`,
`timelines`) — tidak ada fitur yang boleh menduplikasi kebenaran naratif tersebut.
