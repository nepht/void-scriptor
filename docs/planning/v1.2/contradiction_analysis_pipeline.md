# 109.13 — Contradiction Analysis Pipeline

**Status:** COMPLETE (kode + tes hijau lokal; komit menyusul gerbang penuh)
**Kontrak kanonik:** objective "Menjalankan rule secara incremental dan
menjaga referensi sumber"; acceptance `incremental_scan`,
`source_citations`, `deterministic_rules`, `dismissal_state`, `rescan`.

## Arsitektur

Domain murni di atas kontrak 109.12 — tanpa Drift, tanpa UI, **tanpa
perubahan skema** (D-SCHEMA-01 tetap OPEN). Modul:
`lib/features/story/domain/contradiction_analysis.dart`.

- `ContradictionScanScope` — set ID subjek; kosong = pindai penuh.
- `SubjectSnapshot` — nilai atribut siap-dinilai + provenance per kunci
  (`Map<String, List<ContradictionSourceRef>>`). Konversi dari tabel live
  (karakter, scene, bible) bukan bagian langkah ini.
- `ContradictionAnalysisPipeline.scan()` — orkestrator deterministic;
  urutan temuan mengikuti urutan aturan lalu urutan subjek input.
- `evaluate()` — komparator 109.12; perbandingan numerik menang atas
  leksikografis bila kedua sisi ter-parse sebagai angka.
- `ContradictionDismissalStore` — state logika serializable (JSON v1),
  bukan tabel Drift; dapat dipersist tanpa migrasi skema.

## Acceptance ↔ bukti (test/features/story/contradiction_analysis_pipeline_test.dart)

| Acceptance | Bukti |
|---|---|
| `incremental_scan` | scope `{c-marek}` → hanya pasangan dalam lingkup dinilai (`evaluatedSubjects=3`, 1 temuan); scope kosong = full scan; aturan nonaktif/rusak masuk `skippedRules`; scope tak dikenal → hasil bersih. |
| `source_citations` | Temuan membawa sitasi atribut verbatim dan berurutan; nilai berprovenance → `confidence: high`, nilai telanjang → `low` + sources kosong; render embeds baris `• Label (id)`. |
| `deterministic_rules` | Dua scan identik → findings identik termasuk render; ID = fingerprint stabil `ruleId::subjectId`; `'9'` benar dilaporkan di bawah rentang `[15,40]` (numerik > leksikografis). |
| `dismissal_state` | `dismiss(finding, reason, actor)` mencatat timestamp via clock injeksi dan menekan pasangan rule×subject pada scan berikutnya; `restore(id)` mengembalikan; store round-trip JSON utuh (reason, actor, dismissedAt ISO-8601). |
| `rescan` | Data berubah (Nova diperbaiki, Kai menua) → pelanggaran lama hilang, baru muncul, dismissal Marek tetap berlaku pada data tak berubah. |

## Keputusan desain

1. **Fingerprint `ruleId::subjectId` sebagai identity temuan** — dua
   pemindaian atas data sama menghasilkan ID identik sehingga dismissal
   dan riwayat inbox tetap sah lintas run.
2. **Dua sumbu tetap terpisah**: severity selalu `violation` untuk
   pelanggaran aturan aktif; confidence murni fungsi provenance.
3. **Numerik-menang** untuk before/after/withinRange agar usia '9' vs
   rentang [15,40] tidak lolos karena leksikografis.
4. **Dismissal = JSON store, bukan skema** — persistensi file proyek
   diserahkan ke Contradiction Inbox (109.14) tanpa migrasi.
5. **Subjek tanpa atribut yang dinilai luput** (bukan pelanggaran) —
   ketiadaan data bukan kontradiksi.

## Out of scope (diserahkan ke langkah berikutnya)

- Persistensi dismissal ke penyimpanan proyek + wiring UI → 109.14.
- Sumber snapshot dari tabel live (`Characters`, `SceneBeats`, Bible) →
  lapisan aplikasi 109.14.
