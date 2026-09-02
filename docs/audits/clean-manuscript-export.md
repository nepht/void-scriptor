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
| Encoding | PARTIAL | Dart string/file path lulus fixture; explicit encoding matrix/Unicode publishing fixture belum |
| Metadata options | PARTIAL | Front matter/profile metadata ada; export option-to-artifact assertions terbatas |
| No watermark | PARTIAL | TXT kini punya negative assertion eksplisit (tanpa `#`, tanpa penanda lain); cross-format (DOCX/Markdown) negative proof masih terbuka |
| Preflight/preview | VERIFIED | Blocking/warning checks, cleaned preview, manifest, and fingerprint tested |
| Native interaction | UNVERIFIABLE | Native Windows click-through tetap blocked oleh `snapshot_id_required` |

## Safety boundary

Export tests menggunakan temporary directories dan test database. Naskah canonical tidak ditimpa. Tidak ada credential, cloud upload, atau publishing service yang dipanggil.

## Verdict

**PARTIAL — clean Markdown/story export, deterministic cleaning, chapter ordering, preflight, profile controls, dan DOCX artifact primitive teruji; plain TXT writer, full publishing fidelity, explicit encoding matrix, complete metadata-option propagation, dan no-watermark proof lintas format masih terbuka.**

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
