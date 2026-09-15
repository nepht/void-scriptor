# run314 — Registry audit journal (forensics insiden 5->1 run313)

Tanggal: 2026-09-15 (cron, Asia/Jakarta)
HEAD masuk: bf8936b (run313 ledger) — guard PASS recommended_step 145.27, stream corrective_core_mvp.
Pemilik region: ProjectRegistryService (core/persistence) — wilayah run197 BUG-19, sudah clean di HEAD.

## Gap yang ditutup

Insiden run313: `projects.json` ter-prune 5->1 + tombstone 4 ID dalam ~2 detik saat
sesi dua-instance Debug. Investigasi Phase-1 run ini (read-only, bukti aktual):

- Satu-satunya penulis `*.removed.json` di seluruh lib/ = `ProjectRegistryService.remove()`
  (grep `removedSuffix|.removed.json` -> hanya project_registry_service.dart).
- UI delete (`_confirmDelete` di project_list_screen.dart) butuh dialog konfirmasi
  ketik-nama-persis per proyek -> 4 panggilan remove() dalam 2 detik mustahil dari UI.
- Tidak ada jalur produksi lain yang memanggil `save()` penuh dengan listing usang
  yang bisa memperkecil listing TANPA tombstone (save() juga menulis jurnal, lihat di bawah).
- Forensik tidak ada di tree: satu-satunya artefak adalah projects.json + .bak itu sendiri;
  repro startup bersih run313 tidak menghasilkan pelaku. AKTOR BELUM TERBUKTI —
  bukan di-fix tapi di-instrumen.

## Slice (Phase 1.4 systematic-debugging: instrumentasi boundary)

Semua mutasi durable registry kini append satu baris JSONL ke `<registry>.audit.log`:
`{ts, instance, op(save|upsert|remove), id?, after}` dengan `instance` = nonce
per-proses (`pid-micros`). Desain:

- Dua instance yang berbalapan terbedakan lewat nonce berbeda -> hipotesis
  "sinkronisasi listing lama via save penuh" (kandidan run313) jadi terbaca dari
  jurnal: `save` yang menyusutkan `after` tanpa `remove` pendamping =Actor A menulis
  listing usang Actor B.
- Best-effort murni: seluruh `_appendAudit` dalam try/catch `on Object` — kegagalan
  audit tidak pernah membatalkan mutasi registry (test #5 membuktikan jalur tulis gagal
  via direktori penghalang di path jurnal).
- Dibatasi 500 baris (trim tulis-ulang hanya saat lewat cap; jalur umum = append murah).
  Rewrite append-then-trim dipilih setelah RED test cap timeout 30 dtk pada desain
  rewrite-per-op (O(n^2) fsync) — lesson tercatat.
- Simpan dalam daftar file jurnal: op `save` juga direkam karena jalur load() internal
  (healing move/stash/admission) memanggil `_saveUnlocked`; run pertama pasca-deploy
  akan memperlihatkan op healing normal sebagai baseline.

## Gates

- RED: `test/core/persistence/project_registry_audit_log_test.dart` compile-fail tepat
  (`Member not found: 'auditMaxLines'` dll) -> GREEN 5/5 PASS.
- Regression: `flutter test --no-pub test/core/persistence` 129 PASS/0 FAIL exit 0;
  `test/features/projects` 29 PASS/0 FAIL exit 0.
- `dart format` owned 2 file exit 0; `dart analyze lib/core/persistence test/core/persistence`
  No issues; `flutter analyze --no-pub` FULL REPO No issues found (161,3 s);
  `git diff --check` exit 0.
- Full suite + Windows build: lihat ledger run314 (hasil aktual dicatat di entri ledger).

## File milik slice

- lib/core/persistence/project_registry_service.dart (modifikasi, additive)
- test/core/persistence/project_registry_audit_log_test.dart (baru)

## Sisa risiko / batas

- Jurnal forensik adalah EVIDENCE-only: tidak mengubah acceptance 145.27/145.42 dan
  tidak membuktikan apa-apa sampai kejadian berikutnya terjadi di build ini.
- Entri 4 tombstone lama tidak bisa diattribut retroaktif (jurnal baru aktif mulai
  build ini). Registry Choi kini 2 entri; tombstone file tidak ada di disk saat ini
  (sudah dibersihkan manual run313/Choi) — konfirmasi via audit filesystem:
  `D:/VoidScriptor_Data/projects.json.removed.json` TIDAK ada saat run ini.
- `_instanceNonce` memakai pid+mikrodetik; dua proses dengan pid sama yang start di
  mikrodetik sama secara praktis tidak mungkin.
- Trim 500 baris membaca seluruh jurnal tiap op setelah cap tercapai (rewrite penuh);
  pada beban nyata (puluhan op/hari) tidak relevan.

## Next action

1. Choi: jalankan aplikasi normal; bila prune terulang, lampirkan
   `D:\VoidScriptor_Data\projects.json.audit.log` -> pelaku + op terbaca eksplisit.
2. Run cron berikutnya: baca jurnal (bila ada) untuk mendeteksi pola save-usang,
   lalu putuskan perbaikan preventif (mis. gating save() penuh vs diff-based save)
   BERDASARKAN bukti jurnal, bukan spekulasi.
