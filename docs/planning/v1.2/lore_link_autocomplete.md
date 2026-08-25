# Lore Link Autocomplete & Preview (Step 109.10)

Sumber kanonik: `sprint_109.json` langkah 109.10 — pencarian, autocomplete,
pembuatan entitas, dan preview kontekstual dari editor.

## Arsitektur

| Lapisan | File | Peran |
|---|---|---|
| Domain | `lib/features/story/domain/lore_link_suggester.dart` | `LoreEntityRef` (id/name/kind/detail), `LoreLinkSuggester` (skor exact 300 > prefix 200 > substring 100, dedupe nama ternormalisasi, `exactMatchOf` untuk duplicate warning), `LoreLinkSyntax.activeQueryAt` (deteksi `[[query` aktif pada caret; escape `\[[`, penutup sudah ada, atau baris baru → null) |
| Application | `lib/features/bible/application/create_lore_entity_service.dart` | `loadCatalog` (gabungan Species + Technologies + PowerSystems + BibleEntries per proyek), `findExistingName` (case-insensitive, spasi dipipihkan), `create` (BibleEntry tipe `lore`; blank → `ArgumentError`, duplikat → `StateError`) |
| Presentation | `lib/features/story/presentation/story_workspace_screen.dart` | Overlay menu via `CompositedTransformFollower` di bawah TextField draft; dibuka dari `onChanged` saat `activeQueryAt` menghasilkan query |

## Binding jujur (null = fitur absen, tidak ada stub)

`StoryWorkspaceScreen` menerima dua parameter opsional baru:

- `loadLoreCatalog`: memuat katalog entitas lore proyek.
- `onCreateLoreEntity`: membuat entitas baru by-name; tanpa ini aksi "Buat
  entitas" tidak pernah dirender.

Integrasi produksi: `workspace_resolver.dart` mengikat keduanya ke
`CreateLoreEntityService` pada sesi proyek aktif (null-safe saat sesi belum
ada). Tanpa binding, editor berperilaku persis seperti sebelumnya.

## Pemetaan acceptance kanonik → bukti

(`test/features/story/lore_link_autocomplete_test.dart`, 16 tes)

| Acceptance | Bukti |
|---|---|
| `keyboard_navigation` | ArrowDown memindah highlight (preview ikut), Enter menerima → teks menjadi `[[Kapal Api]]` dengan caret di akhir, menu tertutup; Escape menutup tanpa menyisipkan apa pun |
| `duplicate_warning` | Query persis sama dengan entitas (`[[Api`) menampilkan pesan "<nama> sudah ada di lore — pilih untuk menautkan." dan TIDAK menawarkan pembuatan |
| `create_entity` | Nama baru menampilkan aksi "Buat entitas …"; tap memanggil creator dengan nama ter-trim dan menyisipkan `[[Naga Salju]]`; service-level: tersimpan sebagai Bible entry, blank ditolak, duplikat ditolak |
| `hover_or_focus_preview` | Focus: detail item pertama tampil tanpa pointer sama sekali; hover MouseRegion pada tile lain memindahkan preview ke entitas itu |

Detail perilaku completion: rentang yang diganti adalah **pembuka + query**
(`[[$query` → `[[Nama]]`), caret dipindah ke akhir link; autosave draft tetap
berjalan lewat jalur `_count` yang sama.

## Batasan langkah ini (juhur)

- Indeks tautan lintas-naskah (backlink query cepat) adalah ranah 109.11 dan
  skema v57 tetap menunggu ratifikasi D-SCHEMA-01 di gate 109.51.
- Preview kontekstual berbasis konten entitas (detail/deskripsi) — bukan panel
  editor penuh; itu bukan acceptance kanonik langkah ini.
