# 109.40 — Export Preflight & Format Validation

**Kontrak kanonik:** `preflight_report`, `blocking_errors`, `warnings`,
`sample_preview`, `export_manifest`.

## Implementasi

`lib/features/export/domain/export_preflight.dart` mengikat profil ekspor
109.38 dengan render bersih 109.39. Nama tipe memakai prefiks
`ExportPreflight*` karena `PreflightReport` sudah digunakan modul spoiler.

- `ExportPreflightRequest` membawa dokumen, profil, referensi aset, spoiler
  belum selesai, dan batas preview.
- Lima `ExportPreflightCheckKind`: structure, assets, spoilers,
  specialCharacters, render — selalu hadir dalam report.
- Error blokir: dokumen kosong, aset hilang, atau render bersih kosong.
- Warning nonblokir: spoiler belum selesai dan control character selain
  tab/LF/CR.
- Preview berasal dari hasil `CleanExportTransformer`, bukan sumber mentah;
  dipotong tepat pada batas karakter dengan ellipsis termasuk dalam limit.
- `ExportManifest` deterministik: document ID, `ExportFormat`, fingerprint
  render bersih, dan path aset tersedia yang dedupe+urut alfabet.

## Bukti TDD

| Acceptance | Bukti fokus |
|---|---|
| `preflight_report` | Report selalu memiliki lima kategori pemeriksaan dan status ready. |
| `blocking_errors` | Naskah kosong+aset hilang menghasilkan kode bernama; private-only source menghasilkan `empty_render`. |
| `warnings` | Spoiler belum selesai dan control character memperingatkan tanpa memblokir. |
| `sample_preview` | Preview memakai teks setelah link/catatan privat dibersihkan; truncation menghormati limit; teks pendek verbatim. |
| `export_manifest` | Dua validasi input sama menghasilkan manifest value-equal dan JSON identik; format/hash/aset terverifikasi. |

## Iterasi jujur

Ekspektasi preview pada draf tes salah menghitung satu karakter: string
`mene…` panjang 17 padahal limit 18. Dikoreksi di sisi tes menjadi `menem…`;
implementasi `limit - 1 + ellipsis` tidak berubah.

## Out of scope

Writer/export UI, pembentukan DOCX nyata, pemeriksaan file aset secara I/O,
dan pengiriman adalah langkah integrasi/release terpisah.
