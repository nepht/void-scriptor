# Referee report — vs-hunt-20260913-bible
HEAD verdict-time: 7ec14e5c5987f1f88191bf20eaf2e67f25946f7b (unchanged since hunt start)
Rantai penuh delegate lulus: Hunter -> Skeptic -> Referee (delegasi terpisah, scan-only).

| # | Severity | File | Line(s) | Verdict | Description | Fix direction |
|---|----------|------|---------|---------|-------------|---------------|
| BUG-1 | Medium | lib/features/bible/application/lore_backlink_service.dart | 36 | REAL (conf High) | collectSources unbounded select sceneBeats; retargetOccurrences sudah benar pakai isIn(sceneIds) | filter beats by sceneId.isIn(sceneIds) |
| BUG-2 | Medium | lib/features/bible/application/canon_validator.dart | 41 | REAL (conf High) | pesan violation uniqueness me-render `value "null"` karena expectedValue unset | _message: branch pesan khusus uniqueness / jangan interpolasi null |
| BUG-3 | Low | lib/features/bible/application/canon_health_service.dart | 27-28 | REAL (conf High) | info menambah weight tapi CanonHealthSummary tanpa field info | tambah final int info + increment |
| BUG-4 | Low | lib/features/bible/application/faction_image_importer.dart | 71-73 | REAL (conf High) | copy sukses lalu save gagal = file yatim di faction_images | try/catch hapus target saat save gagal (bandingkan konvensi timeline_era_image_importer) |

CONFIRMED REAL: 4 / Critical 0 / Medium 2 / Low 2. Low-confidence items: none.
Catatan parent (bukan verdict): BUG-1 tetap menghasilkan output benar (guard titles.containsKey menyaring pasca-parse) => murni scoping/perf; slice fix run ini = BUG-2 (user-visible message, RED deterministik). BUG-1/3/4 masuk antrean ledger.
