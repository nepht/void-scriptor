# 109.11 Backlinks & Broken-Link Integrity

Langkah: `109.11` — Sprint 109 "v1.2 Writer, Story & Lore Productivity".
Objective kanonik: menampilkan referensi balik dan mendeteksi target hilang
atau ambigu.

## Arsitektur (tanpa perubahan skema DB)

| Lapisan | File | Isi |
|---|---|---|
| Domain murni | `lib/features/story/domain/lore_backlinks.dart` | `LoreLinkHealth` (resolved/broken/ambiguous), `LoreLinkFinding` (sourceId, sourceTitle, target, health, occurrences, candidates), `LoreLinkIntegrityReport` (`brokenLinks`, `ambiguousLinks`, `isClean`), `LoreLinkClassifier` (normalize trim+lowercase+collapse-spasi; classify per sumber dengan grouping occurrences + display name asli), `ProjectLoreLinkEditor.retarget` |
| Application | `lib/features/bible/application/lore_backlink_service.dart` | `LoreBacklinkService`: `collectSources` (pindai SceneBeats milik scene proyek), `backlinks`, `scanIntegrity`, `retargetOccurrences` |

Sumber teks = tabel `SceneBeats` eksisting (draft `beatType='draft'`
id `<sceneId>_draft` + beat biasa). Tidak ada tabel/migrasi baru —
D-SCHEMA-01 tetap OPEN untuk gate 109.51.

## Acceptance ↔ bukti

| Acceptance | Implementasi | Bukti tes |
|---|---|---|
| `backlink_query` | `backlinks()` — pencocokan case-sensitive pada display name (selaras `renameTarget`), escape `\[[X]]` dan teks polos tak pernah dihitung, label judul scene | 4 tes grup `backlink_query` |
| `broken_link_report` | `scanIntegrity()` → `report.brokenLinks`; katalog live via `CreateLoreEntityService.loadCatalog` bila tidak diinjeksi | 3 tes grup `broken_link_report` |
| `ambiguous_link_report` | Normalisasi cocok ≥2 entitas katalog → `ambiguousLinks` berisi semua kandidat; kemunculan identik dalam satu sumber digabung dengan `occurrences` | 2 tes grup `ambiguous_link_report` |
| `repair_action` | `retargetOccurrences()` — tulis ulang hanya konten yang benar-benar berubah; teks polos & escape selamat; tracer scan→retarget→rescan menutup broken end-to-end | 5 tes grup `repair_action` |

Total **14 tes** di `test/features/story/lore_backlinks_test.dart`.

## Keputusan desain

- **Backlink case-sensitive** selaras semantik editor 109.9
  (`renameTarget`); laporan integritas tetap memakai normalisasi untuk
  mengelompokkan `[[Kubus]]`/`[[kubus]]` sebagai satu target ambigu.
- `finding.target` menyimpan display name asli ter-trim (bukan bentuk
  ternormalisasi) agar laporan siap tampil ke penulis.
- Kandidat katalog diisi untuk SEMUA temuan (bukan hanya ambigu) sehingga
  UI bisa menawarkan resolusi satu-klik dari temuan mana pun.
- Repair bekerja pada seluruh beat proyek dan hanya menulis baris yang
  berubah (identical check), tanpa menyentuh teks polos/escape.

## Out of scope (langkah lain)

UI panel backlink, integrasi editor scene, dan indeks tautan persisten
(v57) menunggu ratifikasi D-SCHEMA-01 di gate 109.51.
