# Post-fix notes — vs-hunt-20260915-resilience BUG-4 (run326, 2026-09-15)

- Verdict Referee on-disk (otoritas numbering): REAL BUG, Medium, Confidence
  High. `project_recovery_services.dart:22-34, 50-73` — delete-marker-lalu-
  create-eksklusif punya kompetisi antar-pembuka tanpa retry/rekonsiliasi.
- Mekanisme terverifikasi di HEAD sebelum fix (9a7fe44): recovery pemilik mati
  menghapus marker, lalu `create(exclusive: true)` KEDUA dieksekusi tanpa
  proteksi; kompetitor yang merebut jendela => FileSystemException mentah
  lolos, tanpa klasifikasi 'owner baru sah' vs 'stale'.
- Fix (7b1da8a): loop terikat — setiap create gagal me-re-read marker lewat
  `_recoverDeadOwnerMarker()`: holder hidup sah => StateError fail-closed dan
  marker kompetitor DIPERTAHANKAN; holder mati => diarsipkan + retry. Budget
  `_maxRecoveryAttempts = 3`; cek give-up dilakukan SEBELUM menyentuh marker
  pihak lain (melempar setelah recovery sukses akan melepas lock sambil
  melapor gagal — ditemukan oleh tes #3 saat implementasi awal).
- Seam injeksi: `@visibleForTesting afterDeadOwnerMarkerRecoveredForTest`
  (publik, sesuai aturan validitas anotasi) dipanggil hanya setelah recovery
  marker mati, sebelum create berikutnya — menembak jendela yang di produksi
  hanya terbuka lewat scheduling OS. Pola sama run323 BUG-8.
- Konsumen: `ProjectSessionManager.open` hanya mengharapkan kegagalan bersih;
  tes lama (`session_lock_*`, `project_open_error`) sudah mengunci
  throwsStateError — tidak ada kontrak yang dilonggarkan; jalur lama tanpa
  kompetisi tak berubah perilakunya (create pertama sukses => break).
- Bukti run326: RED = compile fail tepat seam absen; GREEN fokus 3/3; region
  `test/features/project_resilience` + `test/app/shell/project_open_error_test.dart`
  = 250 PASS / 1 platform-skip / 0 FAIL (~2m47d; 250 = 246 region run325 + 3
  baru + 1 project_open_error); `flutter analyze --no-pub` No
  issues; gate format CI `--set-exit-if-changed` exit 0 (2 file slice);
  `git diff --check` exit 0; `flutter build windows --debug --no-pub` PASS.
- Batas jujur: race OS sesungguhnya tidak dieksekusi native (injeksi seam +
  fixture temporer); dua proses nyata saling mengunci = VERIFIABLE parsial
  lewat harness hard-kill lama (session_lock_process_worker_test) yang tetap
  lulus di region. Tidak ada data pengguna disentuh; TIDAK di-push.
- Sisa antrean hunt: BUG-9 (Low, JSON compare struktural di
  `ProjectVersionControlService.compare`).
