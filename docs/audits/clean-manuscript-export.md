# Sprint 145.35 — Clean Manuscript Export

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json`, item `145.35`.  
Status: **PARTIAL**.

## Kontrak kanonik

`Menyediakan at least TXT/Markdown and chosen publishing-friendly format only when output fidelity, chapter order, encoding, metadata options, and no watermark pass.`

## Implementasi yang terverifikasi

Repository memiliki beberapa lapisan export:

- `CleanExportTransformer` menghapus private notes, lore-link syntax, dan internal scene links tanpa mengubah whitespace/line ending di sekelilingnya;
- fingerprint deterministic FNV-1a atas clean text;
- `ExportPreflightValidator` dengan blocking errors untuk dokumen kosong/missing assets, warning untuk spoiler/control character, clean preview, dan export manifest;
- `ExportProfile` untuk plain text, DOCX, dan web novel dengan chapter rules, scene-break rules, front matter, dan saved presets;
- `StoryMarkdownExporter` yang menyusun story → chapters → scenes dalam urutan repository dan menulis file `.md`;
- `StoryDocxExporter` yang menghasilkan file DOCX dan diuji sebagai ZIP artifact valid.

## Verification terbaru

Command:

```bash
flutter test \
  test/features/export/clean_export_test.dart \
  test/features/export/export_preflight_test.dart \
  test/features/export/export_profiles_test.dart \
  test/features/story/story_persistence_test.dart \
  test/features/story/story_workspace_resolver_test.dart \
  test/e2e/sprint_109_export_workspace_e2e_test.dart
```

Result:

```text
All tests passed! — 25 tests
```

Evidence yang lulus:

- clean output menghapus private/internal markers;
- surrounding whitespace dan CRLF tetap dipertahankan;
- output/fingerprint deterministic;
- preview memakai cleaned render;
- preflight memblokir empty document dan missing asset;
- chapter dan scene order berasal dari story hierarchy;
- Markdown file benar-benar ditulis;
- DOCX artifact memiliki ZIP signature dan ukuran non-trivial;
- profile chapter numbering, scene breaks, front matter, dan presets lulus;
- story workspace export controls dan narrow layout tidak menghasilkan exception.

## Evidence boundary

| Acceptance | Status | Evidence / gap |
|---|---|---|
| TXT/Markdown | VERIFIED (domain) | Clean text domain ada; Story Markdown real file terbukti; plain `.txt` writer `StoryTxtExporter` landed (commit a51a68a): chapter-order page-break output tanpa markup Markdown, draft verbatim, `test/features/export/story_txt_export_test.dart` 2 PASS |
| Publishing-friendly format | PARTIAL | DOCX writer ada dan ZIP valid; fidelity/render compatibility belum diverifikasi |
| Output fidelity | VERIFIED (domain) | Clean transform preserves surrounding text structure; full DOCX semantic fidelity belum |
| Chapter order | VERIFIED | Story hierarchy exporter loops ordered chapters/scenes |
| Encoding | VERIFIED (domain) | Unicode publishing matrix round-trip byte-exact TXT/Markdown/DOCX tanpa U+FFFD (story_export_encoding_matrix_test.dart 3 PASS, commit 27712d8); opsi non-UTF-8 Encoding+BOM di TXT writer (0b3d34e) dan paritas Markdown (5bcf275) dgn default tetap UTF-8 tanpa BOM (story_txt_encoding_options_test.dart 3 PASS + story_markdown_encoding_options_test.dart 3 PASS); DOCX OOXML menuntut part XML UTF-8 tanpa BOM, dibuktikan PASS-first (story_docx_encoding_evidence_test.dart 1 PASS); bukti fresh 2026-09-04: export suite 53 PASS / 0 FAIL @ HEAD 8de0c73 |
| Metadata options | VERIFIED (domain) | ExportProfile front matter + chapter rules terpropagasi ke artefak ketiga writer: TXT (story_export_metadata_propagation_test.dart 3 PASS, 27712d8), Markdown dan DOCX termasuk metadata OOXML docProps/core.xml dc:title/dc:creator (story_export_md_docx_profile_test.dart 4 PASS, b6363d2); output tanpa profile tetap identik legacy (backward compatible); bukti fresh 2026-09-04: export suite 53 PASS / 0 FAIL @ HEAD 8de0c73 |
| No watermark | VERIFIED | Private master TXT/Markdown/DOCX bersih dari watermark di semua format (story_export_no_watermark_test.dart, 27712d8); kontras publicPreview membuktikan planner aktif |
| Preflight/preview | VERIFIED | Blocking/warning checks, cleaned preview, manifest, and fingerprint tested |
| Native interaction | UNVERIFIABLE | Native Windows click-through tetap blocked oleh `snapshot_id_required` |

## Safety boundary

Export tests menggunakan temporary directories dan test database. Naskah canonical tidak ditimpa. Tidak ada credential, cloud upload, atau publishing service yang dipanggil.

## Verdict

**PARTIAL — clean Markdown/story export, deterministic cleaning, chapter ordering, preflight, profile controls, DOCX artifact primitive, plain TXT writer, explicit encoding matrix (Unicode round-trip + opsi encoding/BOM), complete metadata-option propagation, dan no-watermark proof lintas format semuanya teruji. Sisa terbuka: publishing fidelity DOCX render-compat eksternal (butuh Word/LibreOffice nyata) dan native interaction UNVERIFIABLE dari cron.**

Next canonical step: `145.36 AI Optional Boundary`.

145.42 tetap tidak disentuh karena milik eksekutor lain.

## Update 2026-09-02c (nephthys cron, 145.35 plain TXT writer)

- Gap 'plain TXT writer' CLOSED: commit a51a68a menambah
  `lib/features/story/application/story_txt_exporter.dart`
  (`StoryTxtExporter`) + `test/features/export/story_txt_export_test.dart`.
  Kontrak: output teks polos tanpa markup Markdown (`#` diverifikasi
  absent), urutan chapter -> scene dari story hierarchy, page break ASCII
  40 `=` di antara chapter, draft ditulis verbatim setelah trim sisi luar,
  `writeExport` menolak filename non-`.txt` dan path component
  (`../story.txt` ditolak), isi file = export string + trailing newline.
- RED terverifikasi: kompilasi gagal `StoryTxtExporter isn't defined`
  sebelum implementasi.
- Bukti: focused 2 PASS; export suite 30 PASS; flutter analyze No issues;
  git diff --check PASS; full suite 3326 PASS + 1 FAIL (app_bootstrap_test,
  concurrent 145.20, untouched; delta +2 eksak); windows debug build PASS
  27.5s.
- 145.35 tetap PARTIAL: publishing fidelity, encoding matrix, metadata
  propagation, dan cross-format no-watermark proof masih terbuka.

## Update 2026-09-02 run2 (nephthys cron, encoding + metadata + no-watermark)

- Encoding matrix CLOSED: `test/features/export/story_export_encoding_matrix_test.dart`
  3 PASS. Fixture Unicode publishing (CJK, emoji U+1F4D6/U+1F327, Arabic,
  musical symbol U+1D11E, tanda kutip, em-dash) round-trip byte-exact:
  TXT tanpa BOM, Markdown heading `#`/`##`/`###`, DOCX ZIP+XML dengan
  `ZipDecoder verify:true`. Nol U+FFFD; escape XML hanya menyentuh lima
  karakter XML, Unicode tetap literal.
- Metadata propagation CLOSED: `StoryTxtExporter.exportStory/writeExport`
  kini menerima `ExportProfile?`. Front matter (title+author) menjadi
  halaman muka di puncak dokumen menggantikan header judul story saat
  profil menyediakannya (selaras `renderFrontMatter()`); chapter rules
  `titlePrefix` + `numberingStart` dirender ke body page-break
  (`Chapter 1` menggantikan judul bab asli saat prefix dipakai).
  `test/features/export/story_export_metadata_propagation_test.dart`
  3 PASS; RED terverifikasi (`No named parameter with the name 'profile'`).
  Test tanpa profil membeku output lama (backward compatible).
- Cross-format no-watermark proof CLOSED:
  `test/features/export/story_export_no_watermark_test.dart` 4 PASS.
  TXT/MD/DOCX yang direncanakan sebagai `privateMaster` tetap bersih
  bahkan pada `WatermarkMode.always`: `applyWatermark` false, overlay
  null, `manifest.watermarkApplied` false, teks watermark absen dari
  bytes artefak. Kontras `publicPreview` + `previewOnly` menghasilkan
  `applyWatermark` true dengan overlay eksplisit - membuktikan planner
  aktif (test tidak vacuous) dan artefak master tidak pernah ditimpa.
- Bukti gerbang: export suite 40 PASS; `flutter analyze` No issues
  (12.0s); full suite 3336 PASS + 1 FAIL (app_bootstrap_test concurrent
  145.20, untouched; delta +10 eksak dari 3+3+4 test baru);
  `flutter build windows --debug` PASS (20.3s); `git diff --check` PASS;
  commit 27712d8 (feat) lalu docs commit ini.
- 145.35 tetap PARTIAL: publishing fidelity DOCX render-compat,
  encoding matrix non-UTF-8 (latin-1 shift target) di luar kontrak
  writer UTF-8, metadata propagation untuk Markdown/DOCX writer
  (parameter `profile` baru terpasang di TXT writer), dan native
  interaction proof tetap terbuka.

## Update 2026-09-03 (nephthys cron, TXT export UI vertical wiring)

- Gap 145.35 "TXT writer tidak reachable dari UI" ditutup: commit 761323a
  menambahkan tombol `Export TXT` di `_exportActions()` Story Workspace
  (antara Export Markdown dan Export DOCX), handler `_exportTxt()` memanggil
  `StoryTxtExporter.writeExport` dengan guard binding sama seperti MD/DOCX
  (disabled saat repository/exportDirectory null), feedback snackbar
  `TXT diekspor: <path>`.
- RED terverifikasi: `Found 0 widgets with text "Export TXT"` (2 FAIL) sebelum
  implementasi.
- Test: `test/features/export/story_txt_export_ui_test.dart` 2 PASS:
  (1) journey tap Export TXT -> file story.txt nyata berisi judul story +
  draft scene + snackbar konfirmasi; (2) guard: tombol hadir tapi onPressed
  null tanpa binding repository. Root cause terdokumentasi: handler menulis
  via dart:io async yang beku di fake-async zone widget test; tap dijalankan
  di real-async zone via `tester.runAsync` sehingga IO selesai.
- Bukti gerbang: focused export+story 57 PASS; full suite 3435 PASS / 0 FAIL
  (delta +2 eksak dari 3433); flutter analyze No issues (10.4s);
  flutter build windows --debug PASS; git diff --check PASS;
  roadmap guard PASS pre+post (pointer tetap 145.27).
- 145.35 tetap PARTIAL: publishing fidelity DOCX render-compat eksternal,
  native interaction proof (butuh sesi interaktif).

## Update 2026-09-03 cron enc (nephthys, 145.35 TXT encoding options)

- Sisa gap 145.35 "encoding non-UTF-8" ditutup pada level TXT writer:
  `StoryTxtExporter.writeExport` kini menerima `Encoding encoding = utf8`
  dan `bool bom = false`; penulisan via `writeAsBytes` dengan prefix BOM
  EF BB BF saat `bom=true`. Default TETAP UTF-8 tanpa BOM sehingga
  kontrak encoding matrix Unicode (commit 27712d8) tidak berubah.
- RED terverifikasi: "No named parameter with the name 'encoding'" dan
  "'bom'" (kompilasi gagal hanya pada dua simbol itu; fixture memakai
  createScene storyId+chapterId+sceneNumber eksak sesuai API live).
- Bukti: test/features/export/story_txt_encoding_options_test.dart 3 PASS
  (latin1+BOM byte-exact: prefix EF BB BF + body dekodabel latin1 dan
  BUKAN urutan utf8-2-byte; utf8+BOM round-trip; default tetap tanpa
  BOM); export suite 49 PASS; focused TXT 7 PASS; analyzer scoped
  No issues; windows debug build PASS 33.1s exit 0.
- Konsumen publishing lawas yang butuh BOM/encoding single-byte kini
  terlayani tanpa mengubah perilaku default UI Export TXT.
- Sisa 145.35: publishing fidelity DOCX render-compat eksternal,
  metadata encoding-aware utk MD/DOCX (opsi kini hanya di TXT writer),
  native interaction UNVERIFIABLE (cron).
## Update 2026-09-03 cron mdenc (nephthys, 145.35 Markdown encoding + DOCX evidence)

- Sisa gap 145.35 "metadata encoding-aware utk MD/DOCX (opsi kini hanya di
  TXT writer)" ditutup dua arah:
  1. Paritas MD writer: `StoryMarkdownExporter.writeExport` kini menerima
     `Encoding encoding = utf8` dan `bool bom = false` (paritas
     StoryTxtExporter commit 0b3d34e); penulisan via `writeAsBytes` dengan
     prefix BOM EF BB BF saat `bom=true`. Default TETAP UTF-8 tanpa BOM
     sehingga kontrak encoding matrix Unicode (27712d8) tidak berubah.
     RED terverifikasi: "No named parameter with the name 'encoding'" dan
     "'bom'" (kompilasi gagal hanya pada dua simbol itu).
     test/features/export/story_markdown_encoding_options_test.dart 3 PASS:
     latin1+BOM byte-exact (prefix EF BB BF + body latin1, bukan urutan
     utf8-2-byte), utf8+BOM round-trip, default tetap tanpa BOM.
  2. Bukti encoding-aware DOCX: format OOXML mempersyaratkan part XML
     dienkode UTF-8 TANPA BOM (Word menolak file bila prolog XML tidak
     persis di awal part), sehingga opsi encoding tidak berlaku pada
     writer ini. test/features/export/story_docx_encoding_evidence_test.dart
     1 PASS PASS-first (tanpa perubahan produksi): keempat part XML
     (word/document.xml, docProps/core.xml, [Content_Types].xml,
     word/styles.xml) diawali prolog `<?xml version="1.0" encoding="UTF-8"`
     tanpa prefix BOM, dan Unicode publishing fixture tetap byte-exact di
     document.xml.
- Bukti gerbang: export suite 53 PASS (50 lama + 3 MD baru + 1 DOCX baru,
  delta +4 eksak vs 49); flutter analyze scoped (lib/features/story/
  application + test/features/export) No issues; dart format 2 test files;
  git diff --check PASS; flutter build windows --debug PASS 24.0s
  (build/windows/x64/runner/Debug/void_scriptor.exe); commit 5bcf275.
- Sisa 145.35: publishing fidelity DOCX render-compat eksternal (perlu
  Word/LibreOffice nyata), native interaction UNVERIFIABLE (cron).

## Update 2026-09-03 (nephthys cron: evidence-closure row No watermark)

- Row "No watermark" di tabel Gap ternyata STALE: kontrak no-watermark
  cross-format sudah terbukti sejak commit 27712d8 lewat
  `test/features/export/story_export_no_watermark_test.dart` (4 test):
  TXT/Markdown/DOCX sebagai private master tetap bersih dari watermark
  meski WatermarkPolicy mode `always`, manifest `watermarkApplied false`,
  dan kontras publicPreview pada policy `previewOnly` menerima watermark
  (membuktikan planner tidak vacuous).
- Bukti fresh run ini (HEAD b4b35d5): file test tersebut
  + export_protection_test.dart = 12 PASS ("All tests passed!");
  export suite penuh (test/features/export/) = 53 PASS.
- Row diperbaiki PARTIAL -> VERIFIED. Sisa 145.35 tetap: publishing
  fidelity DOCX render-compat eksternal (butuh Word/LibreOffice nyata),
  native interaction UNVERIFIABLE (cron).

## Update 2026-09-04 (nephthys cron: evidence-closure rows Encoding + Metadata options)

- Dua row tabel Gap ternyata STALE terhadap bukti yang sudah landed:
  1. Encoding: matrix Unicode publishing (27712d8) + opsi non-UTF-8
     Encoding/BOM di TXT (0b3d34e) dan paritas Markdown (5bcf275) +
     bukti OOXML DOCX tanpa BOM (PASS-first) sudah terbukti, tetapi row
     masih memuat narasi pra-27712d8.
  2. Metadata options: propagation ExportProfile ke artefak bukan lagi
     asersi terbatas; commit b6363d2 (2026-09-02) menambah
     test/features/export/story_export_md_docx_profile_test.dart 4 PASS
     (front matter + chapter prefix pada Markdown DAN DOCX termasuk
     docProps/core.xml dc:title/dc:creator; output tanpa profile tetap
     identik legacy).
- Rekonsiliasi doc-only: row Encoding PARTIAL -> VERIFIED (domain),
  row Metadata options PARTIAL -> VERIFIED (domain), Verdict aligned
  dengan bukti landed. Blok riwayat tanggal dipertahankan apa adanya.
- Bukti fresh run ini (HEAD 8de0c73, Windows host): flutter test
  test/features/export = 53 PASS / 0 FAIL exit 0, mencakup encoding
  matrix 3 + TXT encoding options 3 + MD encoding options 3 + DOCX
  encoding evidence 1 + md/docx profile 4 + metadata propagation 3 +
  no-watermark 4 + TXT UI 2. Tanpa perubahan kode produksi/test.
## Update 2026-09-04 cron run24 (nephthys, cited-test provenance adopted)

The story test files this audit cites as provenance were still untracked at audit time; they are
now adopted into the repository byte-identical (commit of run24, pattern of run12/run23). Cited-test
provenance no longer resolves to untracked files. No status rows rewritten; Verdict unchanged.
