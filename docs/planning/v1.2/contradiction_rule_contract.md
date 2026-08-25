# 109.12 Contradiction Rule Contract

Langkah: `109.12` — Sprint 109, fitur "Story Contradiction Detector".
Objective kanonik: menyatukan rule continuity untuk waktu, usia, lokasi,
status hidup, kepemilikan, dan fakta canon.

## Arsitektur

Domain murni di `lib/features/story/domain/contradiction_rule.dart` —
tanpa DB, tanpa UI. Lapisan penyatuan di atas sistem eksisting:
`CanonRule`/`CanonConflict` (bible) dan `SceneContinuityValidator`
(story). Pipeline eksekusi aturan adalah langkah 109.13.

## Output kanonik ↔ bukti

| Output | Implementasi | Bukti tes |
|---|---|---|
| `rule_schema` | `ContradictionDimension` (time/age/location/lifeStatus/ownership/canonFact), `ContradictionComparator` (equals/notEquals/before/after/withinRange), `ContradictionRule.validateSchema()` — masalah bernama deterministik: title → projectId → attributeKey → jumlah operand komparator (1, kecuali withinRange = 2) | 5 tes grup `rule_schema` |
| `severity_model` | `ContradictionSeverity` info/warning/violation; hanya `violation.blocksPublication == true` | 2 tes grup `severity_model` |
| `confidence_model` | `DetectionConfidence` low/medium/high, sumbu terpisah dari severity — data parsial boleh melahirkan pelanggaran keras berkeyakinan rendah | 2 tes grup `confidence_model` |
| `explanation_contract` | `ContradictionExplanation.render()` deterministik (render ulang = teks identik) memuat dimensi, ringkasan, expected vs actual, daftar `ContradictionSourceRef` berurutan, saran opsional; `ContradictionFinding` membawa payload lengkap rule+subject+dimension+severity+confidence+explanation | 3 tes grup `explanation_contract` |

Total **12 tes** di `test/features/story/contradiction_rule_contract_test.dart`.

## Keputusan desain

- **Dua sumbu terpisah** severity × confidence: kekerasan konsekuensi dan
  keyakinan deteksi tidak saling menimpa; UI nanti bisa menyaring
  "pelanggaran keras berkeyakinan rendah" secara eksplisit.
- Operand komparator divalidasi sebagai bagian schema, bukan saat analisis,
  supaya aturan rusak tertangkap sebelum pipeline jalan.
- Nama `Contradiction*` dipilih agar tidak menabrak `CanonConflict`
  (multiverse/bible) maupun `SyncConflict` (collaboration).
- Tidak ada persistensi pada langkah ini — dismissal state & rescan
  milik 109.13 (`dismissal_state`, `rescan`).
