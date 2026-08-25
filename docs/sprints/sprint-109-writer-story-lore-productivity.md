# Sprint 109 — VOID SCRIPTOR v1.2 Writer, Story & Lore Productivity

- **Status:** BERJALAN (dibuka 2026-08-25 ±22:00 WIB, pasca penutupan S108) · **Base aktual:** `1.1.0` stable · **Target kanonik:** `1.2.0-alpha.1`
- **Kanonik:** `sprint_109.json` (SPRINT_MASTER, 52 langkah, VALIDATED; `depends_on: [108]`)
- **Deviasi kanonik terdokumentasi:** `base_version` kanonik menyebut `1.1.1`; nyata tetap `1.1.0`
  (konsekuensi opsi A Sprint 107 — pola deviasi sama dengan S108, direkam atas rantai keputusan arsitek).
- **Delivery rules kanonik diadopsi penuh:** tanpa fabricated completion; feature flag default OFF;
  backward-compat + migration-rollback + local-first + user-data-export + review a11y & security wajib.
- **Entry gate 109.1:** seluruh bukti tersedia dari paket gate 108.31 (komit `ad55f76`).

| langkah | judul | status | bukti/catatan |
|---|---|---|---|
| 109.1 | Sprint Entry Gate | VERIFIED | Paket lengkap: direction approval (GO 108.31), scope disetujui (`scope-non-goals-draft.md`), success metrics, feasibility x5, risk register R-01..R-09 — semua di `docs/discovery/v1.2/` |
| 109.2 | Wave 1 Scope Contract | VERIFIED | 4 output di `docs/planning/v1.2/`: feature_contracts.md (13 capability + kepemilikan ADR-WS-001), non_goals_and_open_decisions.md (NG-1..7 + D-SCHEMA-01 OPEN), acceptance_matrix.md (170 kriteria/35 langkah, terverifikasi programatik dari kanonik), dependency_map.md (L0-L3). Sumber: sprint_109.json feature_delivery + workspace_separation_architecture.json |
| 109.3 | Shared Architecture & Ownership | VERIFIED | Review 7 area di docs/planning/v1.2/architecture_ownership_review.md: 5 area VERIFIED (link contract, permission, deletion-review, namespace, service boundaries) + keputusan baru WS-EVENTS v1 (D-109.3-A) dan FISO-01 (D-109.3-B); koreksi jujur metadata kanonik NOT_STARTED — modul lib/features/workspaces/ 1418 LOC + tabel novel_character_links + 19 file tes SUDAH ADA; bukti eksekusi: flutter test test/features/workspaces = +55 All tests passed exit 0 (2026-08-26) |
| 109.4 | Shared Data Schema | VERIFIED | Kontrak di docs/planning/v1.2/shared_data_schema.md: 8 aturan lintas-tabel (A-ID..A-LINK: UUID, soft delete, revision, provenance, larangan co-ownership kolom), inventaris 13 family tabel dengan status ADA vs BARU per langkah fitur, evolusi skema ADDITIVE ONLY mulai v57 + rollback drill; temuan live: VoiceProfiles sudah ADA, namespace file workspaces/novels|characters sesuai ADR |
| 109.5 | Migration, Backup & Rollback Plan | VERIFIED | Rencana di docs/planning/v1.2/migration_backup_rollback_plan.md: 9 langkah migrasi ADR terbukti SUDAH terimplementasi sebagai WorkspaceMigrationRunner (report field = langkah ADR 1:1, validasi penuh sebelum mutasi); protokol skema Drift v56-57+ (backup pra-upgrade wajib, additive only, rollback = restore paket bukan downgrade); lapisan backup in-app/portable/host dipetakan; drill eksekusi pertama menempel pada migrasi v57 pertama |
| 109.6 | Permission & Privacy Model | VERIFIED | Model di docs/planning/v1.2/permission_privacy_model.md: baseline single-user local-first (owner mencakup dua boundary), beta reader via clearance paket bukan akun, penegakan di application layer, media in-package tanpa scan luar, telemetri opt-in OFF metadata-only, enkripsi SecuritySettings dipertahankan apa adanya; semua aturan lintas-workspace live+teruji |
| 109.7 | Accessibility & Localization Baseline | VERIFIED | Baseline terukur di docs/planning/v1.2/a11y_localization_baseline.md: Semantics=0, tooltip/semanticsLabel=42, l10n 4 kunci paritas en-id penuh, tes scaling 1 file; standar mengikat A11Y-01..05 + L10N-01..04 untuk semua fitur Wave 1; tanpa remediasi retroaktif (NG-6); jadi pembanding delta di 109.48 |
| 109.8 | Feature Flags & Observability | VERIFIED | KODE TERUJI: FeatureFlagRegistry 13 flag vs12_* default OFF dipaksa (nama tak dikenal ditolak) di lib/core/feature_flags/ + LocalUsageJournal anti-leak BY CONSTRUCTION (whitelist ganda event-type & field-key, opt-in default OFF, audit trail opted_in) di lib/core/observability/ + dokumen docs/planning/v1.2/feature_flags_observability.md; TDD RED-GREEN nyata: fokus +13 All tests passed, format bersih; GERBANG PENUH: flutter analyze No issues (14.4s) + flutter test FULL SUITE +1748 All tests passed exit 0 (2026-08-26) |
| 109.9 | Inline Lore Link Syntax & Parser | VERIFIED | KODE TERUJI TDD: lib/features/story/domain/inline_lore_links.dart (parser sealed-segment + renderer round-trip + editor renameTarget) memenuhi 5 acceptance kanonik; RED terkonfirmasi (load fail) sebelum implementasi; fokus 18 tes All tests passed; dokumen docs/planning/v1.2/inline_lore_links.md; GERBANG PENUH: analyze No issues (13.1s) + flutter test FULL SUITE +1766 All tests passed exit 0 (2026-08-26); tanpa perubahan skema (D-SCHEMA-01 tetap OPEN utk gate 109.51) |
| 109.10 | Lore Link Autocomplete & Preview | PENDING | Menyediakan pencarian, autocomplete, pembuatan entitas, dan preview kontekstual dari editor. |
| 109.11 | Backlinks & Broken-Link Integrity | PENDING | Menampilkan referensi balik dan mendeteksi target hilang atau ambigu. |
| 109.12 | Contradiction Rule Contract | PENDING | Menyatukan rule continuity untuk waktu, usia, lokasi, status hidup, kepemilikan, dan fakta canon. |
| 109.13 | Contradiction Analysis Pipeline | PENDING | Menjalankan rule secara incremental dan menjaga referensi sumber. |
| 109.14 | Contradiction Inbox | PENDING | Menyediakan inbox terpadu dengan filter, alasan, bukti, dan tindakan penyelesaian. |
| 109.15 | Character Interview Workspace | PENDING | Menyediakan sesi wawancara orang pertama di Character Workspace sebagai sumber profil karakter kanonis. |
| 109.16 | Voice Profile & Dialogue Consistency | PENDING | Menghasilkan profil diksi, nada, tabu, pola bicara, dan peringatan konsistensi yang dapat diedit. |
| 109.17 | Conlang Registry & Dictionary | PENDING | Menyimpan bahasa, kata, arti, kelas kata, varian, dan contoh penggunaan. |
| 109.18 | Conlang Grammar, Phonology & Script | PENDING | Mendokumentasikan rule tata bahasa, bunyi, romanisasi, dan sistem tulisan. |
| 109.19 | Conlang Usage Consistency | PENDING | Mendeteksi ejaan atau arti yang tidak konsisten dengan kamus tanpa mengubah naskah otomatis. |
| 109.20 | Focus Writing Mode | PENDING | Menyediakan ruang menulis minim distraksi dengan kontrol yang tetap dapat diakses. |
| 109.21 | Word Targets & Session Progress | PENDING | Mendukung target kata per sesi, adegan, bab, dan project. |
| 109.22 | Draft Snapshot Compare & Restore | PENDING | Membandingkan snapshot dan memulihkan versi secara aman tanpa menghapus versi kini. |
| 109.23 | Writer-Focused Lore Graph | PENDING | Menampilkan hubungan entitas dengan filter domain, waktu, canon, dan project. |
| 109.24 | Lore Graph Integrity Insights | PENDING | Mendeteksi node yatim, relasi konflik, dan jalur yang tidak lengkap. |
| 109.25 | Plot Board Data Model | PENDING | Menyatukan kartu plot dengan bab, adegan, arc, POV, status, dan label pacing. |
| 109.26 | Kanban Plot Interaction | PENDING | Mendukung pemindahan kartu melalui drag-and-drop dan keyboard. |
| 109.27 | Plot Order Synchronization | PENDING | Menyinkronkan perubahan board dengan urutan cerita dan mencegah konflik diam-diam. |
| 109.28 | Character Moodboard Workspace | PENDING | Menyimpan referensi visual kanonis di Character Workspace; Novel Workspace hanya menyimpan link dan override k |
| 109.29 | Visual Description Continuity | PENDING | Membandingkan deskripsi karakter dengan atribut visual canon dan riwayat adegan. |
| 109.30 | Spoiler Classification Model | PENDING | Menandai data berdasarkan level spoiler, titik reveal, dan audience. |
| 109.31 | Reader Clearance & Redaction | PENDING | Menyensor atau menyembunyikan konten sesuai clearance pembaca beta. |
| 109.32 | Spoiler-Safe Share Export | PENDING | Membuat paket berbagi yang telah diperiksa terhadap kebocoran spoiler. |
| 109.33 | Scene POV Lock | PENDING | Menetapkan POV, tense, dan mode narasi pada adegan atau bagian. |
| 109.34 | POV Knowledge Boundary | PENDING | Mencatat fakta yang diketahui karakter pada waktu tertentu. |
| 109.35 | Head-Hopping Analysis & Report | PENDING | Mendeteksi perpindahan akses batin atau informasi di luar POV dengan penjelasan. |
| 109.36 | Tension & Pacing Labels | PENDING | Mendukung label tensi manual dan sinyal pacing per adegan. |
| 109.37 | Pacing Heatmap & Imbalance Warnings | PENDING | Menampilkan pola tensi per bab dan arc tanpa menilai kualitas secara absolut. |
| 109.38 | Manuscript Export Profiles | PENDING | Mendefinisikan profil DOCX, plain text, dan web novel. |
| 109.39 | Clean Export Transformation | PENDING | Menghapus metadata dan link internal sambil mempertahankan teks serta struktur naskah. |
| 109.40 | Export Preflight & Format Validation | PENDING | Memeriksa struktur, aset, spoiler, karakter khusus, dan hasil render sebelum pengiriman. |
| 109.41 | Subplot & Quest Data Model | PENDING | Mencatat tujuan, pemberi tugas, pihak terkait, dependency, konsekuensi gagal, dan status. |
| 109.42 | Mission Board & Story Links | PENDING | Menyediakan board misi yang terhubung dengan adegan, karakter, lokasi, dan arc. |
| 109.43 | Unresolved Subplot & Consequence Alerts | PENDING | Mengingatkan subplot menggantung atau konsekuensi yang belum diterapkan. |
| 109.44 | Cross-Feature Integration | PENDING | Menghubungkan fitur melalui contract stabil sambil menjaga Novel dan Character sebagai workspace terpisah. |
| 109.45 | Automated Test Matrix | PENDING | Menambahkan unit, integration, migration, contract, UI, dan end-to-end tests untuk seluruh scope. |
| 109.46 | Performance & Scale Validation | PENDING | Menguji project besar, graph padat, dokumen panjang, banyak media, dan ekspor besar. |
| 109.47 | Security & Privacy Verification | PENDING | Menguji sharing, redaction, media lokal, export, permission, dan metadata leakage. |
| 109.48 | Accessibility & Localization Verification | PENDING | Memverifikasi seluruh workflow utama dengan keyboard, assistive technology, scaling, contrast, dan locale berb |
| 109.49 | User Documentation & In-Product Guidance | PENDING | Menjelaskan cara pakai, batas analisis, privasi, backup, restore, sharing, dan export. |
| 109.50 | Alpha Packaging & Upgrade Rehearsal | PENDING | Membuat build alpha terkontrol dan melatih upgrade serta rollback menggunakan salinan data. |
| 109.51 | Alpha Acceptance Gate | PENDING | Menilai apakah Wave 1 layak menjadi v1.2.0-alpha.1. |
| 109.52 | Sprint Closure | PENDING | Menutup Sprint 109 hanya setelah keputusan rilis atau penundaan tercatat. |
