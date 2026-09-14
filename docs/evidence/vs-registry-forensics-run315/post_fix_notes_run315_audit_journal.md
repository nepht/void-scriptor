# run315 — Forensik insiden registry 5->1: audit journal terverifikasi penuh + gate build Windows tertutup

Tanggal: 2026-09-14/15 (cron, Asia/Jakarta)
HEAD mulai: bf8936b (ledger run313). HEAD akhir sesi: 3272944 (audit journal) + dirty sibling 145.42.
Guard awal: PASS exit 0 (recommended_step 145.27, canonical sha 86af6a53, stream corrective_core_mvp).

## Kontribusi sesi ini (kronik jujur)

1. Investigasi Phase-1 (read-only) atas "aktor misterius" run313:
   - Satu-satunya penulis `*.removed.json` di seluruh lib/ = `ProjectRegistryService.remove()`
     (grep `removedSuffix|.removed.json` -> hanya project_registry_service.dart).
   - UI delete (`_confirmDelete`, project_list_screen.dart) wajib dialog ketik-nama-persis
     per proyek -> 4 remove() dalam ~2 detik mustahil dari UI.
   - Tidak ada jalur produksi yang memanggil save() listing usang secara tak terdeteksi.
   - Forensik retroaktif TIDAK ADA di tree (satu-satunya artefak = projects.json + .bak);
     repro startup bersih run313 tidak menunjuk pelaku. AKTOR BELUM TERBUKTI.
2. Slice diagnostik (TDD, Phase 1.4 systematic-debugging): audit journal JSONL
   `<registry>.audit.log` — op `save|upsert|remove` + `id` + `after` + `ts` +
   `instance` (nonce per-proses pid+mikrodetik), cap 500 baris, best-effort murni
   (kegagalan audit tak pernah membatalkan mutasi). RED compile-fail tepat ->
   GREEN 5/5 -> perbaikan performa setelah timeout 30 dtk pada desain
   rewrite-per-op (append murah + trim hanya saat lewat cap).
3. Karya slice (runner + test) diserap sesi interaktif sibling ke commit HEAD
   3272944 "feat(145.42-forensics): audit-journal append-only" saat suite cron
   berjalan — terverifikasi byte-identik terhadap hasil kerja sesi ini
   (`git diff HEAD` atas kedua file = kosong; nol delta milik run315).

## Gates yang dijalankan run315 (bukti aktual di HEAD 3272944)

- focused `test/core/persistence/project_registry_audit_log_test.dart`: 5/5 PASS.
- regression `test/core/persistence`: 129 PASS / 0 FAIL exit 0.
- regression `test/features/projects`: 29 PASS / 0 FAIL exit 0.
- `dart format` owned 2 file: exit 0. `dart analyze` scoped: No issues.
- `flutter analyze --no-pub` FULL REPO: No issues found (161,3 s).
- `git diff --check`: exit 0.
- FULL SUITE `flutter test --no-pub`: **4461 PASS / 0 FAIL / 1 platform-skip**,
  exit 0 (~26 m; rekonsiliasi eksak 4456 baseline run312 + 5 test slice journal).
  Catatan: WIP sibling (test fixture disk_full/permission_loss 145.42,
  mtime 21:36 = tengah suite) ada di tree saat run; angkanya cocok TANPA test
  sibling itu (file termuat sebelum perubahan tiba) — hasil valid untuk HEAD.
- `flutter build windows --debug --no-pub`: **PASS 54,9 s — gate yang BLOCKED
  empat run berturut-turut (run309? tidak; run310/311/312 + awal 313) kini
  VERIFIED** karena nol void_scriptor.exe/flutter_tester saat eksekusi.

## Interpretasi jurnal (panduan baca untuk kejadian berikutnya)

- Baris `save` dengan `after` menyusut TANPA `remove` pendamping, instance nonce
  berbeda dari op terakhir = instance lain menulis listing usang (hipotesis
  dua-instance run313).
- Empat `remove` dengan nonce sama dalam satu rentang detik = satu proses
  memanggil remove() 4x (jalur non-UI) — langsung terattribusi.
- Entri lama (4 tombstone 19:07 run313) TIDAK bisa diattribut retroaktif;
  jurnal aktif mulai build pasca-3272944.

## Sisa risiko / batas

- EVIDENCE-only: tidak mengubah acceptance 145.27/145.42; tidak membuktikan
  apa-apa sampai kejadian berikutnya terjadi di build ini.
- Trim pasca-cap melakukan rewrite penuh (tidak relevan pada beban nyata).
- Build debug di atas kini memuat WIP sibling lib/core/persistence/
  project_move_service.dart (uncommitted) — bukti build untuk HEAD+delta itu,
  bukan HEAD murni; HEAD 3272944 sendiri compile-green via analyzer penuh.

## Next action

1. Choi jalankan aplikasi normal; bila prune terulang, lampirkan
   `D:\VoidScriptor_Data\projects.json.audit.log` -> pelaku + op terbaca eksplisit.
2. Run cron berikutnya: inspect jurnal (bila ada) sebelum memutuskan perbaikan
   preventif (mis. gating save() penuh vs diff-based) — berdasarkan bukti, bukan spekulasi.
3. Region WIP sibling (move cross-volume fixture 145.42) menunggu pemiliknya commit;
   jangan diutak-atik.
