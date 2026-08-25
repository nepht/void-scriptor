# Inline Lore Link Syntax & Parser (Step 109.9)

Sumber kanonik: `sprint_109.json` → feature "Inline Lore Linking", langkah 109.9
"Inline Lore Link Syntax & Parser". Objective: mendukung sintaks `[[Entity]]`
tanpa merusak teks atau ekspor.

## Sintaks

| Input | Interpretasi |
|---|---|
| `[[Ratu Angin]]` | Tautan lore ke entitas bernama `Ratu Angin` |
| `\[[teks]]` | Literal — backslash meniadakan pembuka tautan |
| `[[teks` tanpa penutup | Teks biasa (tidak pernah jadi tautan) |
| `[[]]` / `[[   ]]` | Teks biasa (isi kosong/whitespace) |
| `[[dua\nbaris]]` | Teks biasa — tautan tidak pernah melintasi baris baru |

Isi kurung di-trim hanya saat lookup (`displayName`); bentuk mentah disimpan,
sehingga round trip identik.

## Permukaan API

`lib/features/story/domain/inline_lore_links.dart`:

- `InlineLoreSegment` (sealed) → `LoreTextSegment` / `LoreLinkSegment`.
- `InlineLoreLinkParser.parse(String)` → daftar segmen berurutan.
- `InlineLoreLinkRenderer.render(List<InlineLoreSegment>)` → teks kembali.
- `InlineLoreLinkEditor.renameTarget(source, from:, to:)` → mengganti nama
  target semua tautan yang cocok (case sensitive, via display name), tanpa
  menyentuh kemunculan polos maupun escape literal; tanpa kecocokan mengembalikan
  string yang sama persis.

## Pemetaan acceptance kanonik → bukti

| Acceptance | Bukti (`test/features/story/domain/inline_lore_links_test.dart`) |
|---|---|
| `parse_valid_links` | 4 tes: link tunggal, banyak link, displayName ter-trim, pasage penuh link |
| `preserve_plain_text` | 4 tes: prosa verbatim, kurung tak tertutup, isi kosong, tidak lintas baris |
| `handle_rename` | 7 tes: ganti target, teks polos luput, escape luput, padded→kanonik, case sensitive, tanpa match = identik, hasil tetap round trip |
| `escape_syntax` | 2 tes: escape meniadakan, escape hidup berdampingan dengan link asli |
| `round_trip` | Korpus 12 kasus (termasuk emoji, backslash lepas, penutup liar) lolos `render(parse(s)) == s` |

Hasil: **18 tes All tests passed**, `dart format` bersih, analyzer bersih;
gerbang penuh repo dijalankan sebelum komit.

## Batasan langkah ini (jujur)

- **Tanpa perubahan skema**: 109.9 murni parser domain; tabel indeks tautan
  (mis. `lore_link_index`, skema v57) sengaja ditunda sampai D-SCHEMA-01
  diratifikasi Choi di gate 109.51. Acceptance 109.9 tidak mensyaratkannya.
- **Tanpa UI**: pencarian/autocomplete/preview adalah 109.10; backlinks &
  integritas link rusak/ambigu adalah 109.11.
- Exporter markdown (`StoryMarkdownExporter`) mengalirkan draft verbatim, dan
  kontrak round trip parser menjamin ekspor tak berubah untuk input apa pun.
