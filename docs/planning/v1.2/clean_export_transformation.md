# 109.39 — Clean Export Transformation

**Kontrak kanonik:** menghapus metadata/link internal sambil mempertahankan
teks dan struktur naskah. Acceptance: `strip_internal_links`,
`strip_private_notes`, `preserve_formatting`, `deterministic_output`,
`no_source_mutation`.

## Implementasi

`lib/features/export/domain/clean_export.dart` menyediakan
`CleanExportTransformer.transform(String)` dan hasil immutable
`CleanExportResult`.

- Markdown link internal `[label](scene:id)` menjadi `label`.
- Lore link `[[Entity]]` menjadi `Entity`.
- Bare pointer `scene:id` dihapus.
- Catatan `[[PRIVATE:...]]`, termasuk multiline, dihapus penuh.
- External Markdown link tidak disentuh.
- Semua karakter di luar token yang dikenali—indentasi, blank lines, CRLF,
  tabs, trailing spaces, heading—dipertahankan byte-for-byte.
- Hasil mencatat jumlah token yang dibuang dan fingerprint FNV-1a 64-bit
  stabil lintas proses.
- Sumber disimpan verbatim pada result; transformer tidak memiliki state dan
  tidak memutasi input.

## Bukti TDD

| Acceptance | Bukti fokus |
|---|---|
| `strip_internal_links` | Scene Markdown link mempertahankan label; lore link mempertahankan nama; bare scene pointer dihapus; external URL tetap utuh. |
| `strip_private_notes` | Catatan inline dan multiline dihapus penuh; teks sekitar tetap ada. |
| `preserve_formatting` | Fixture CRLF membuktikan heading, indentasi, tab, tiga blank lines, dan trailing spaces tetap identik di luar marker. |
| `deterministic_output` | Dua transformasi input sama menghasilkan value-equal result dan fingerprint sama; teks berbeda menghasilkan fingerprint berbeda. |
| `no_source_mutation` | `sourceText` tetap verbatim; input tanpa marker dilaporkan `wasChanged=false` tanpa perubahan buatan. |

## Keputusan desain

Draft awal yang diadopsi hanya memiliki API berantai `MemoryNaskah` dan
`preserveFormatting()` mengompresi deret blank line menjadi maksimal dua.
Itu bertentangan dengan acceptance preserve-formatting. Implementasi final
menggunakan satu transformasi murni dan tidak menormalisasi whitespace sama
sekali.

## Out of scope

Preflight struktur/aset/spoiler/karakter khusus/preview/manifest adalah
langkah 109.40.
