# Sprint 145.13 — Product Promise Lock

Tanggal audit: 2026-08-27  
Sumber kanonik: `core_mvp_scope_reset_spec.json` pada export Sprint 145.  
Sumber live terkait: `docs/IMPLEMENTATION_GOAL.md`, `docs/planning/v1.2/permission_privacy_model.md`, dan `docs/planning/v1.2/on_goals_and_open_decisions.md`.

## Locked promise

> **Membantu novelis merencanakan, menulis, menjaga konsistensi, dan mengamankan novel mereka dalam satu aplikasi local-first.**

Kalimat ini diambil verbatim dari field `product_promise` pada `core_mvp_scope_reset_spec.json`; tidak dinormalisasi atau diperluas oleh audit ini.

## Promise dimensions

| Dimensi | Makna operasional | Evidence boundary |
|---|---|---|
| Merencanakan | Struktur novel/story, chapter, scene, beat, timeline, dan lore dapat dipakai untuk menyiapkan karya | Source/test coverage lokal ada; user journey penuh belum tersertifikasi native |
| Menulis | Workspace novel/manuscript dan jalur chapter/scene menjadi aktivitas utama | Workspace/import/export coverage lokal ada; validasi usability pengguna belum dilakukan |
| Menjaga konsistensi | Character, relationship, environment, timeline, lore/Bible, references, dan context saling terhubung | Repository/domain/local persistence evidence ada; full cross-feature author workflow masih partial |
| Mengamankan | Local persistence, autosave/recovery, backup/restore, portability, dan failure handling melindungi data | Local boundaries ada; failure matrix 145.42 masih in progress |
| Satu aplikasi | Core journey tidak memerlukan perpindahan tool untuk project data utama | Shell/router/workspace evidence ada; release/native end-to-end belum lengkap |
| Local-first | Core dapat berjalan tanpa account, internet, payment, cloud, atau provider AI | Guest/Offline/source architecture evidence ada; native Guest→Dashboard belum terbukti karena driver blocker |

## Core scope inclusion

Termasuk dalam promise dan kandidat Core MVP:

- project/package dan local storage;
- Novel/Story, chapter, scene, manuscript workspace;
- Character dan typed workspace selection;
- core worldbuilding: locations/environments, relationships, lore/Bible, timeline;
- search/lore reference dan link safety;
- autosave, recovery, backup, restore;
- import/export dan clean manuscript export;
- Windows x64 local-first target.

## Explicit exclusions from this lock

Hal-hal berikut tidak boleh masuk Core hanya karena tersedia sebagai source atau route:

- cloud sync/server multiplayer;
- payment, payout, marketplace, dan community;
- account/network sebagai syarat startup Core;
- live third-party AI/provider execution;
- native hardware/GPU/XR capture;
- installer, signing, hosted CI, dan staged production rollout;
- mobile full editor, macOS release, dan platform expansion sebelum evidence gate.

Non-Core source/data dipertahankan dan dapat diberi flag/deferred boundary; promise lock ini bukan izin menghapusnya.

## Acceptance guardrails

1. Core feature harus punya jalur local-first yang bermakna tanpa kredensial dan internet.
2. Data utama tetap berada pada project package/database milik pengguna, bukan service cloud tersembunyi.
3. Setiap aksi yang memengaruhi karya harus memiliki persistence/recovery story atau dinyatakan partial.
4. Character/Story/World navigation harus mempertahankan typed selection dan resolver, bukan hanya membuka route generik.
5. AI/provider boleh memperluas workflow, tetapi tidak boleh menjadi dependency startup atau satu-satunya jalur menulis.
6. Klaim “aman” harus dipisahkan antara local atomic write, backup/restore, dan failure-matrix/device evidence.
7. Promise tidak mengubah D-SCHEMA-01; schema/migration baru tetap memerlukan kontrak eksplisit.

## Evidence and limitations

- Promise exact string diverifikasi dari export `core_mvp_scope_reset_spec.json`.
- Local-first/no-cloud direction diverifikasi silang dengan `permission_privacy_model.md` dan `on_goals_and_open_decisions.md`.
- Source/test gates terbaru: full test `2014` pass, analyzer `No issues found!`, Linux debug build pass.
- Windows debug snapshot build pass dan executable hadir; native feature flow tetap `UNVERIFIABLE` karena `snapshot_id_required`.
- User validation belum dilakukan; `145.45–145.47` tetap menjadi langkah pilot/validation terpisah.

## Decision

`145.13 Product Promise Lock` berstatus **VERIFIED**. Promise dikunci dari sumber kanonik tanpa menambah ambisi baru. `145.14 Primary User and Job` tidak dieksekusi spekulatif: pemilihan primary user/job membutuhkan validasi atau keputusan Choirudin. Tidak ada code, schema, database, atau user data yang diubah.

## Next blocker

`145.14` membutuhkan keputusan eksplisit tentang profil primary user, pekerjaan utama, konteks penggunaan, pain, constraint, dan success measure. Sampai data itu tersedia, statusnya **BLOCKED — product decision/user validation required**, bukan alasan untuk membuat asumsi baru.

## Evidence paths

- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`
- `docs/IMPLEMENTATION_GOAL.md`
- `docs/planning/v1.2/permission_privacy_model.md`
- `docs/planning/v1.2/on_goals_and_open_decisions.md`
- `docs/audits/working-feature-protection-list.md`
- `docs/audits/data-ownership-map.md`
- `docs/audits/existing-user-data-compatibility.md`
