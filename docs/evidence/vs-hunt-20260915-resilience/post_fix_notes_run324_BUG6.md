vs-hunt-20260915-resilience BUG-6 — remediasi run324 (2026-09-15)

Temuan (Referee, REAL BUG, Medium, terverifikasi di HEAD 762ed7f):
`ProjectIntegrityReport.portable` hanya memeriksa manifestValid,
databaseValid, missingFiles==0, externalFiles==0 — tanpa `orphanFiles`.
Proyek yang satu-satunya cacatnya adalah file aset yatim menampilkan
`Portable: yes` di layar Project Diagnostics, padahal layar Repair masih
menawarkan "Move Orphans to Trash" dan mendeteksinya sebagai kondisi repair.

Fix (pola minimal sesuai suggested fix Referee):
- lib/features/project_resilience/application/project_resilience_repository.dart:
  getter `portable` kini mensyaratkan `orphanFiles == 0` + komentar alasan.
- Consumer getter satu-satunya di produksi = baris presentasi diagnostics
  (`Portable: ${snapshot.integrity.portable ? 'yes' : 'needs attention'}`),
  diverifikasi via grep `\.portable\b` di lib/ — tidak ada jalur lain yang
  berubah perilaku.

Tes baru (test/features/project_resilience/diagnostics_portable_orphan_bug6_test.dart):
1. Domain: scan paket dengan satu file yatim -> `orphanFiles==1` dan
   `portable==false`. RED pertama: `Expected: false, Actual: true` —
   mereproduksi mekanisme persis seperti diklaim.
2. Presentasi: `ProjectResilienceWorkspaceScreen(view: diagnostics)` dengan
   sesi nyata + satu yatim -> `Portable: needs attention` dan bukan
   `Portable: yes`. RED: finder 0 kandidat sebelum fix; GREEN setelah fix.

Bukti run324:
- RED: 00:0X +0 -2 (kedua tes gagal untuk alasan BUG-6) — exit 1.
- GREEN fokus: `All tests passed!` (2/2) — exit 0; diulang pasca-format: PASS.
- Region penuh `flutter test --no-pub test/features/project_resilience`:
  243 PASS / 1 skip (platform-bound) / 0 FAIL — exit 0 (243 = 241 milik
  run323 + 2 tes baru).
- `flutter analyze --no-pub lib/features/project_resilience
  test/features/project_resilience`: No issues found.
- `dart format --output=none --set-exit-if-changed` pada kedua file milik
  slice: exit 0 (gate CI format).
- `git diff --check`: exit 0.
- `flutter build windows --debug --no-pub`: PASS — √ Built
  build\windows\x64\runner\Debug\void_scriptor.exe (exit 0).

Batasan: bukti level widget-test + build; interaksi native GUI untuk baris
Portable tidak dijalankan pada run ini (UNVERIFIABLE native), konsisten
dengan batas cron. Tidak ada data pengguna yang disentuh (fixture temp).

Next action: antrean bug terkonfirmasi tersisa = BUG-7 (Medium, hitung
`Available backups` mengabaikan root eksternal tercatat) lalu BUG-4/BUG-9
(region sama, hunt baru 15 Sep — jangan ulangi scan). Push tetap milik Choi.
