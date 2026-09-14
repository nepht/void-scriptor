# run312 — vs-hunt-20260914-workspaces BUG-1 + BUG-5 (TDD)

- Repo: D:\VoidScriptor\void_scriptor_multiplatform, branch master, HEAD masuk 53ce459
- Preflight: `dart run tool/roadmap_guard.dart` exit 0 (recommended_step 145.27, canonical sha256 86af6a53, stream corrective_core_mvp ACTIVE, stability gate PASS). Nol M source milik orang lain; 9 untracked artefak lama dipreservasi; conflict markers nihil.
- Selection: antrean eksplisit run310 — BUG-1 (High) + BUG-5 (Medium) satu desain (transaksi + kompensasi), keduanya region `workspace_migration_runner.dart`. Nol caller produksi (grep: hanya test) → perubahan additive aman.

## Verdict otoritatif (on-disk)
`referee_report_workspaces_run308.md` (head_at_verdict 141e86e): 7 REAL / 0 dismissed. BUG-1 High "data integrity/recovery" — tanpa transaksi/kompensasi lintas fase; BUG-5 Medium — `_verifyCopy` gagal hanya men-set `validatedCounts` lalu runner mengembalikan report shape-sukses.

## Mekanisme yang direproduksi (bukan dikarang)
1. BUG-1 copy: `_copyInto` story-2 gagal setelah story-1 terpasang → direktori story-1 tertinggal + backup tetap ada.
2. BUG-1 database: `links.create` deterministik menabrak PK `linkId`; loop lama me-commit link pertama lalu throw di link kedua → set link separuh.
3. BUG-5: target `legacy/` sudah berisi file → jumlah terverifikasi beda; runner lama tetap return `projectionRebuilt: true`.

## Kontrak yang ditegakkan
- `WorkspaceMigrationFailure` (stage: backup|copy|verification|database, compensated, compensationErrors, cause) — kegagalan selalu terlapor, bukan IO/SQLite mentah, bukan report-sukses.
- Ledger instalasi presisi: `_copyInto` mencatat HANYA file yang benar-benar dibuat run ini (cek `existsSync` sebelum copy); direktori workspace ditandai dengan flag `fresh` → kompensasi tidak pernah menghapus konten pre-existing milik pengguna.
- Link: seluruh insert dalam SATU `links.transaction(...)`; `NovelCharacterLinkRepository.transaction<R>` = seam Drift baru (additive).
- Backup pra-migrasi tetap DIPERTAHANKAN pada setiap kegagalan (recovery path), dan kegagalan backup = fail-closed sebelum ada mutasi.
- Rollback drill TETAP diagnostik (run310 contract): kegagalan drill melapor `rollbackDrillPassed:false` tanpa membatalkan migrasi yang sudah commit — di luar cakupan BUG-1/5, tidak diubah diam-diam.
- Urutan baru: validasi → backup → inventory → copy → **verifikasi (gate, throw)** → transaksi link → invalidasi proyeksi → drill. Verifikasi pindah sebelum DB write supaya tidak ada link ter-commit untuk salinan tak terverifikasi.

## Gates aktual (run312)
- RED: fokus 3 test compile-fail tepat (`'WorkspaceMigrationFailure' isn't a type`) sebelum patch.
- GREEN: focused 3/3 PASS; ulang pasca `dart format` + run310 drill contract 2/2 dalam satu batch → **5/5 PASS**.
- Region `test/features/workspaces`: **142 PASS / 0 FAIL** exit 0 (~1m42s) — delta +3 vs run310 (139) = tepat jumlah test baru.
- Consumers (live_cutover + link persistence + create-service + narrative persistence): **11 PASS / 0 FAIL** exit 0.
- `dart format` owned 3 file → exit 0 (2 changed); `dart analyze` scoped: No issues; `dart analyze` FULL REPO: **No issues found!** exit 0.
- `git diff --check`: exit 0.
- Windows debug build: **BLOCKED** — `void_scriptor.exe` PID 14280 (app pengguna, start 14/09 19:23) memegang build\windows\x64\runner\Debug\void_scriptor.exe; tidak dibunuh (kebijakan run307/310). Native: **UNVERIFIABLE** dari cron.
- Full suite: lihat ledger (dijalankan solo, satu proses Flutter pada satu waktu).

## File milik slice ini
- lib/features/workspaces/application/workspace_migration_runner.dart
- lib/features/workspaces/application/novel_character_link_repository.dart
- test/features/workspaces/vs_hunt_20260914_migration_atomicity_run312_test.dart (baru)
- docs/evidence/vs-hunt-20260914-workspaces/post_fix_notes_run312_BUG1_BUG5.md (baru)

## Sisa risiko / catatan jujur
- Kompensasi filesystem bukan snapshot-restore: pada kegagalan post-backup, run ini MENGHAPUS artifact yang ia pasang, bukan memulihkan paket dari backup. Arah Referee mengizinkan keduanya ("restore the database (or ...)"); restore penuh dari backup yang tertangkap = kandidat slice terpisah bila acceptance memintanya.
- BUG-7 (token representasi import) masih antrean — butuh keputusan arah kontrak Choi.
- Native GUI journey migrasi: belum pernah ada (runner tidak punya caller produksi di shell), jadi bukan regresi.
