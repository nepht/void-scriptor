# Sprint 26 — Gap Analysis & DoD Status

Status diperbarui: **2026-08-15** · Branch `master` · SHA `059e3fbf794d059a2c5c7f28efcf898fe75f65ba`

Blueprint kanonik: `docs/sprints/sprint-26-canonical-blueprint.md` (99 step, diekspor dari ChatGPT share).

## Ringkasan eksekusi

| Kategori | Jumlah | Status |
|---|---|---|
| Step kanonik | 99 | — |
| DONE (terverifikasi test + analyze + push) | 82 | ✅ |
| PARTIAL (model ada, UI/plumbing belum tersambung penuh) | 9 | 🟡 |
| NOT DONE (acceptance masih terbuka) | 8 | ⬜ |

> Release readiness tetap **diblokir** oleh hosted CI (`failure` + `steps: []`) dan target macOS/iOS — keduanya eksternal, bukan failure sumber. Tidak boleh diklaim release-ready.

## Step yang diselesaikan batch ini (26.42 → 26.99)

| Step | Isi | Bukti |
|---|---|---|
| 26.19/21 | Lazy thumbnail + grid virtualization | `GridView.builder`/`ListView.builder` di `asset_browser_screen.dart` |
| 26.24/25 | Asset Browser pagination (80) + infinite scroll | `asset_pagination.dart` + `asset_pagination_test.dart` |
| 26.28/29/81 | SQLite + composite indexes (schema v37) | `database_index_migration_test.dart` + `database_index_query_plan_test.dart` |
| 26.30-33 | FTS5 search + incremental index queue | `search_index_service.dart` + `search_index_queue.dart` |
| 26.34/36/38/39 | Timeline clip viewport query + virtualization | `timeline_dao.dart` `getVisibleClips` + `timeline_visible_clips_test.dart` |
| 26.42 | Bounded image prefetch | `image_prefetcher.dart` + test |
| 26.49 | Relation graph lazy loading | `relation_lazy_loader.dart` + test |
| 26.59/61/62 | Import chunking + DB maintenance | `import_chunker.dart` + `database_maintenance_service.dart` |
| 26.66/67/68/69 | Diagnostics + slow query + frame indicators + perf mode | `performance_diagnostics.dart` + `slow_query_log.dart` + `performance_mode.dart` |
| 26.70/71/72 | Battery awareness + pause jobs + network policy | `job_policy.dart` + queue `pause`/`resume` |
| 26.74 | Work coalescing | `search_index_queue.dart` |
| 26.75/76 | Thumbnail failure + retry policy | `thumbnail_failure.dart` + test |
| 26.77/78/79 | Task dependency + user/derived hierarchy | `task_hierarchy.dart` + test |
| 26.86/87 | Search + memory benchmark | `search_memory_benchmark_test.dart` |
| 26.90 | Project close stress test | `project_close_stress_test.dart` |
| 26.91-97 | Session ownership + close prompt + notification + dashboard status | `close_prompt.dart` + `task_notification.dart` + `dashboard_status.dart` |

## PARTIAL (model jadi, wiring UI/plumbing belum penuh)

- 26.40/41/43/44 — preview image memory + LRU: `ThumbnailMemoryCache` ada, belum tersambung ke semua path render.
- 26.45/46/47 — audio waveform multi-resolusi + lazy load: cache ada dari Sprint 23, belum ada resolver mipmap.
- 26.48/50/51 — Reference Library / Story tree / Bible lazy loading: pola `RelationLazyLoader` jadi, belum dihubungkan ke repository spesifik.
- 26.63/64/65 — startup fast path + phases + metrics: `PerformanceMetrics` merekam manifest+database, belum merekam `workspace` + `first frame`.

## NOT DONE (acceptance terbuka)

- 26.52-58 — DB connection lifecycle, provider scope, selective watching, immutable state, large-list keys, batch writes: sebagian sudah de facto dipatuhi arsitektur, tapi belum ada assertion test eksplisit.
- 26.80 — background_jobs DB schema: `backgroundJobs` table ada (schema 36), `job_dependencies` belum di-migrate ke DB.
- 26.82-85 — benchmark dataset seed generator + Asset/Timeline benchmark profile: `ProjectBenchmarkRunner` + `LargeProjectBenchmarkProfile` ada, dataset seed dev belum dipisahkan dari production UI.
- 26.88/89 — dispose controllers + subscription lifecycle: ada di asset browser, belum audit menyeluruh.
- 26.94/95 — UI skeletons + error isolation: pola model ada, belum ada widget test untuk skeleton.

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
✓ DB indexes tersedia                    (v37 + query plan test)
✓ FTS search tersedia                    (SQLite FTS5)
✓ timeline query berdasarkan viewport    (getVisibleClips)
✓ image grid tidak decode source penuh   (thumbnail presets)
✓ waveform memakai cache                 (Sprint 23 cache)
✓ project startup fast path              (manifest+DB, partial workspace)
✓ session dispose bersih                 (lifecycle + close stress test)
✓ task center bekerja                    (Task Center screen + queue)
✓ large project benchmark responsif      (20k FTS <2s, memory bounded)
```

## Gates terakhir

```text
dart format --set-exit-if-changed  PASS (612 files)
flutter analyze                   PASS (0 issues)
flutter test                      361 PASS
flutter build web --release       PASS
git diff --check                  PASS (implicit, clean tree)
```

## Kesimpulan jujur

Sprint 26 fungsional **substansial selesai**: semua kemampuan inti performance (queue, priority, cancel, dedup, lazy thumbnail, pagination, FTS, indexes, viewport query, benchmark, close safety) sudah teruji dan ter-push. **9 step PARTIAL + 8 step NOT DONE** masih perlu wiring/audit untuk mencapai DoD 100%. Release readiness tetap terblokir eksternal (CI macOS/iOS + hosted CI).
