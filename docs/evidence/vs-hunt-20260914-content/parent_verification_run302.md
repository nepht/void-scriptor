# Parent Verification — vs-hunt-20260914-content (cron run301, 2026-09-14)

Repo: D:\VoidScriptor\void_scriptor_multiplatform · branch master · HEAD masuk `bc96094c48f3c02784ca04ec2b2759ad5c2cfd91`.
Scope: 8 file domain POV/spoiler/lore (1.508 baris; hash per-file di scope_hashes.txt). Rantai: Hunter (6 temuan) → Skeptic (5 accept / 1 disprove) → Referee on-disk OTORITATIF (referee_report.md): **5 REAL BUG / 1 dismissed** — CT-BUG-01/02/03 Medium, CT-BUG-05/06 Low, CT-BUG-04 NOT A BUG.

## Catatan operasional rantai
- Spawn pertama Hunter (pin config `gemini/gemini-3.5-flash-lite`) mati 429 quota setelah membaca penuh 8 file scope; tanpa laporan. Sesuai preseden run-2026-09-14, tidak ada verdict yang diarang; dispatch ulang dengan model berbeda.
- `delegation.model` dipindah ke `cx/gpt-5.6-luna` via `hermes config set` (tool-call probe PASS sebelum pindah; pin lama tinggal di catatan ini untuk rollback: `hermes config unset delegation.model` lalu set `gemini/gemini-3.5-flash-lite` saat kuota pulih).

## Verifikasi induk independen sebelum patch (semua quote line-exact di HEAD)
- CT-BUG-01: `buildView` lama memanggil fallback `_neighborhood` SEBELUM blok filter; `_neighborhood` tak punya parameter filter → filter domain/canon/project/relation diabaikan pada graf >32 node. Terkonfirmasi by reading lore_graph.dart:138-141.
- CT-BUG-02: doc `addNode` menjanjikan menambah/memperbarui; `putIfAbsent` membuang pembaruan id sama diam-diam. Terkonfirmasi (lore_graph.dart:113-114).
- CT-BUG-03: `hinted` menyimpan tujuan `c` saja padahal id temuan `hint:$a>$c` per-pasangan → celah sumber kedua ke tujuan sama teredam. Terkonfirmasi (lore_integrity.dart:152-160).
- CT-BUG-05: guard `markUnlocked` hanya cek `_sceneLocks.containsKey`, bukan status unlocked → unlock ganda lolos meski doc menuntut "hanya sah dari status locked". Terkonfirmasi (pov_lock.dart:84-90).
- CT-BUG-06: `KnowledgeTime.compareTo` leksikografis mentah; konvensi repo 'sc-<angka>' tidak menjamin urutan tanpa nol-padding ('sc-10' < 'sc-2') dan tipe scene vs chapter tak punya ordinal bersama. Terkonfirmasi (knowledge_boundary.dart:24-30). Caller check: grep lib/ → NOL pemanggil produksi (domain-only), konsisten dengan penilaian severity Referee.
- CT-BUG-04 (dismissed Referee, parent setuju): header kontrak tidak mensyaratkan lockScene sebelum overrideSection; tidak ada registry adegan terpisah — bukan bug.

## Eksekusi perbaikan (TDD, slice ini)
- RED: 4 file test baru; 10 FAIL tepat mekanisme (lihat transkrip run: Expected LoreDomain.item Actual location; containsAll hint:d>c hilang; unlock-ulang tidak melempar; sc-2 vs sc-10 → 1; dsb). Test penjaga kontrak lama (id sama == 0, tanpa-filter fallback, dedup sumber sama) hijau sejak awal.
- GREEN: filter sebelum fallback + `_neighborhood` boleh dibatasi node/edge terfilter; `addNode` assign langsung (posisi map Dart tetap); dedup hint key `'$a>$c'`; `markUnlocked` tolak unlock ganda dengan StateError; `compareTo` ordinal numerik prefix+angka, tipe campuran → UnsupportedError.
- Gates: focused 19/19 PASS; region lore+pov+spoiler+world_logic 1241 PASS / 0 FAIL exit 0; `flutter analyze --no-pub` full repo "No issues found!"; `dart format --set-exit-if-changed` owned 8 file → 0 changed (setelah autofix rewrap + prefer_const di test hint); `git diff --check` exit 0; `flutter build windows --debug --no-pub` PASS 21,8s; full suite berjalan (run301).
- Native: UNVERIFIABLE (cron; domain murni tanpa caller produksi — interaksi GUI tidak berubah).

## Sisa risiko / follow-up
- Konsumen masa depan `KnowledgeTime.compareTo` tipe campuran kini menerima UnsupportedError (bukan angka palsu) — tercatat di doc-comment; belum ada pemanggil produksi, jadi tidak ada jalur runtime yang berubah hari ini.
- Fallback besar kini memilih pusat dari node yang LOLOS filter; jika survivors ≤ maxRenderNodes, jalur tampilan penuh dipakai (perilaku lama untuk graf kecil tidak berubah).
