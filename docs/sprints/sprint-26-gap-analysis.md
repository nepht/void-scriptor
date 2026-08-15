# Sprint 26 — Gap Analysis & DoD Status

Status diperbarui: **2026-08-15** · Branch `master` · SHA `8fe165a`

Blueprint kanonik: `docs/sprints/sprint-26-canonical-blueprint.md` (99 step, diekspor dari ChatGPT share).

## Ringkasan eksekusi

| Kategori | Jumlah | Status |
|---|---|---|
| Step kanonik | 99 | — |
| DONE (terverifikasi test + analyze + push) | 99 | ✅ |

> Semua 99 step kini memiliki bukti konkret: implementasi terverifikasi, atau assertion test eksplisit untuk properti arsitektur yang sebelumnya hanya "de facto dipatuhi". Release readiness tetap **diblokir** oleh hosted CI (`failure` + `steps: []`) dan target macOS/iOS — keduanya eksternal, bukan failure sumber. Tidak boleh diklaim release-ready.

## Penutupan gap batch terakhir (PARTIAL + NOT DONE)

| Step | Isi | Bukti |
|---|---|---|
| 26.40/41/43/44 | Thumbnail memory cache LRU | `thumbnail_memory_cache_test.dart` (7 test: LRU, eviction, replace, key equality) |
| 26.45/46/47 | Waveform multi-resolusi + mipmap | `waveform_peak_resolver.dart` + test (downsample coarse/medium/fine) |
| 26.48/50/51 | Reference/Story/Bible lazy loading | `repository_page_loader.dart` + test (first page, loadMore, trim) |
| 26.52-58 | DB lifecycle, immutable state, batch write | `test/architecture/immutable_state_test.dart` |
| 26.63/64/65 | Startup fast path phases | `startup_metrics.dart` + test (manifest→db→workspace→firstFrame) |
| 26.80 | job_dependencies DB schema | `job_dependencies.dart` + migration v38 + DAO + test |
| 26.82-85 | Benchmark dataset seed generator | `benchmark_dataset_seeder.dart` + test (deterministic, dev-only) |
| 26.88/89 | Dispose/subscription lifecycle | `mutation_event_listener_test.dart` |
| 26.94/95 | UI skeleton + error isolation | `content_loading_skeleton.dart` + `section_error_boundary.dart` + widget test |

## Schema migration

- **Schema v37 → v38**: table `job_dependencies` (jobId + dependsOnId, composite PK).
- 27 file test yang meng-hardcode `schemaVersion == 37` dimigrasi ke `38`.

## DoD (26.99) — pemeriksaan kotak

```
✓ heavy jobs tidak memblok UI            (worker isolate + queue)
✓ background queue punya priority        (priorityWeight + scheduler)
✓ jobs bisa cancel                       (cooperative cancellation)
✓ duplicate jobs dideduplicate           (taskKey coalescing)
✓ thumbnail generation lazy              (viewport priority + pipeline)
✓ thumbnail berdasarkan viewport priority (ThumbnailViewport)
✓ asset browser paginated                (page size 80)
✓ search debounced                       (SearchIndexQueue coalescing)
✓ search lama tidak menimpa query baru   (cancellation + queue)
✓ DB indexes tersedia                    (v38 + query plan test)
✓ FTS search tersedia                    (SQLite FTS5)
✓ timeline query berdasarkan viewport    (getVisibleClips)
✓ image grid tidak decode source penuh   (thumbnail presets + LRU cache)
✓ waveform memakai cache + mipmap        (WaveformPeakResolver)
✓ project startup fast path              (manifest→db→workspace→firstFrame)
✓ session dispose bersih                 (lifecycle + close stress test)
✓ task center bekerja                    (Task Center screen + queue)
✓ large project benchmark responsif      (20k FTS <2s, seeded dataset)
```

## Gates terakhir

```text
dart format --set-exit-if-changed  PASS (641 files)
flutter analyze                   PASS (0 issues)
flutter test                      417 PASS (naik dari 361)
flutter build web --release       PASS (103.9s)
git diff --check                  PASS (clean tree)
```

## Kesimpulan jujur

Sprint 26 kini **100% tertutup**: semua 9 PARTIAL + 8 NOT DONE memiliki bukti test/implementasi. Full regression 417 test PASS, web build PASS, schema v38 konsisten local/remote. Release readiness tetap terblokir eksternal (CI macOS/iOS + hosted CI) — bukan failure sumber.
