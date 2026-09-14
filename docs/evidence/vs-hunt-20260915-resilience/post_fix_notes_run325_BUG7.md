vs-hunt-20260915-resilience BUG-7 — remediasi run325 (2026-09-15)

Temuan (Referee on-disk, REAL BUG, Medium, confidence High):
`Available backups` di layar Project Backups dihitung dari
`_backupDirectories()` — scan direktori internal paket saja. Sementara
`createBackup` dengan custom root terpilih mencatat baris ProjectBackups
ber-path absolut DI LUAR paket (isExternalBackup). Backup eksternal yang
valid ada di daftar restore tetapi tidak dihitung di baris jumlah —
kesalahan observability/UI nyata, lokasi eksternalnya sendiri memang
disengaja.

Keputusan arah (tanpa menunggu Choi): arahan Referee eksplisit —
"Keep the database row as the source of truth for backups created outside
the package" — jadi fix mengikuti opsi pertama: count dari baris record
yang tersimpan dan storage-nya saat ini ada. Tidak ada kontrak sprint
yang berubah; hanya semantics baris presentasi.

Fix (commit db4f282):
- lib/features/project_resilience/application/project_resilience_controller.dart:
  `backupItems` = jumlah baris `backupsFor(projectId)` whose
  `_resolveBackupDirectory(relativePath).exists()`. Helper
  `_backupDirectories()` dihapus (satu-satunya konsumen hilang; analyzer
  unused_element = gate fail).

Tes baru (test/features/project_resilience/backup_count_external_root_bug7_test.dart):
1. Controller: createBackup di custom root -> direktori internal kosong
   (prasyarat mekanisme bug) -> `scan().backupItems == 1`.
   RED: Expected <1> Actual <0> — mereproduksi klaim persis.
2. Controller: baris eksternal tercatat + custom root dihapus ->
   `backups` tetap 1 (audit) tetapi `backupItems == 0` (tidak dihitung
   tersedia bila storage hilang) — fail-closed pada kebenaran display.
3. Widget: layar backups dengan satu backup eksternal ->
   `Available backups: 1` ter-render; `takeException()` null.

Bukti run325 (HEAD db4f282 di atas 0708599; guard PASS awal run,
recommended_step 145.30):
- RED: fokus gagal 2/3 dengan pesanBUG-7 (count 0 vs 1; finder 0) — exit 1.
- GREEN fokus: `All tests passed!` (3/3) — exit 0.
- Region penuh `flutter test --no-pub test/features/project_resilience`:
  246 PASS / 1 skip (platform-bound) / 0 FAIL — exit 0 (246 = 243 milik
  run324 + 3 tes baru).
- `flutter analyze --no-pub`: No issues found! (14.7s).
- `dart format --output=none --set-exit-if-changed` pada kedua file milik
  slice: exit 0 pasca reformat.
- `git diff --check`: exit 0.
- `flutter build windows --debug --no-pub`: PASS — √ Built
  build\windows\x64\runner\Debug\void_scriptor.exe.
- Regression tetangga tak berubah: backup_configurable_location_test dan
  backup_restore_screen_wiring_test lulus dalam run region penuh.

Batasan: bukti level widget-test + build; interaksi native GUI pada baris
"Available backups" UNVERIFIABLE dari cron sesi ini (tidak diklaim).
Push tidak diizinkan (keputusan Choi; ahead bertambah sejak run324).

Sisa antrean run320 aman-cron: BUG-4 (Medium, competing-create re-read
sessionId di recovery marker), BUG-9 (Low, JSON compare struktural).
