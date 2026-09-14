vs-hunt-20260914-workspaces BUG-6 - remediasi run310 (2026-09-14)

Mekanisme (Referee otoritatif, HEAD 141e86e): hasil backups.create dibuang;
_runRollbackDrillenumerate semua direktori backups dan ambil yang sort
leksikografis terakhir. ID backup UUID v4 -> urutan bukan identitas; drill bisa
restore snapshot yang bukan pre-state migrasi ini.

Fix (arah Referee, workspace_migration_runner.dart):
- Phase 2 menyimpan `final Directory preMigrationBackup = await backups.create(...)`.
- Phase 8 memanggil _runRollbackDrill(preMigrationBackup); enumerate/sort dibuang.
- Guard identitas: backup hilang -> drill FAIL; backup.json ada tapi projectId
  tidak cocok -> drill FAIL.

TDD:
- RED: test/features/workspaces/vs_hunt_20260914_backup_identity_run310_test.dart
  2 test; kedua gagal tepat mekanisme (drill pilih ffff-preexisting salah;
  backup hilang lolos diam-diam restore snapshot lain).
- GREEN: 2/2 PASS (8.9s).
- Regression region test/features/workspaces: 139 PASS / 0 FAIL exit 0
  (137 lama + 2 baru; run pertama region tabrak sqlite3.dll lock tester yatim
  16:35 - menunggu tester exit, tanpa kill, lalu bersih).
- live_cutover_test PASS (no-op gate).
- dart analyze scoped: No issues. flutter analyze --no-pub full repo: No issues (14.3s).
- dart format 2 file owned; git diff --check exit 0.
- Windows debug build: BLOCKED - app pengguna PID 13856 aktif dari
  build/windows/x64/runner/Debug/void_scriptor.exe (start 16:32); build akan
  menimpa .exe yang berjalan. Native UNVERIFIABLE run ini.
- Full suite: lihat ledger run310 untuk angka aktual.

Post-fix SHA-256 (HEAD f0724a5 + working tree):
03908ba37cac58d41cb9ad699887d07b493989e08e3ca6599a038173bdc5585f lib/features/workspaces/application/workspace_migration_runner.dart
48656d37e4dd1585eeb9a5eac6695b4b5d0b7c08cdc18130cbe46419fac55b14 test/features/workspaces/vs_hunt_20260914_backup_identity_run310_test.dart

Sisa antrean region: BUG-1 (High, transaksi + kompensasi lintas fase),
BUG-5 (Medium, validatedCounts==false harus gagal - arah tergantung BUG-1),
BUG-7 (Low/Medium keputusan arah token representasi import).
