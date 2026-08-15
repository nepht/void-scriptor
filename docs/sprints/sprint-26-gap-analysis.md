# Sprint 26 — Gap Analysis (Canonical Blueprint 26.1–26.99)

Sumber kebenaran: `docs/sprints/sprint-26-canonical-blueprint.md`
(diekspor dari ChatGPT share `6a7f6a0d-7c8c-83ec-b287-61e952c62b26`).

Status per step dinilai terhadap live repo pada 2026-08-15, HEAD `034ef38`.

## Legenda

- ✅ DONE — implementasi + test hijau
- 🟡 PARTIAL — implementasi ada tapi belum terintegrasi/teruji end-to-end
- ❌ MISSING — belum ada implementasi

## A. Background Job System (26.1–26.13)

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 26.1 | Jangan jalankan pekerjaan berat di UI path | 🟡 | Dokumentasi; belum ada guard/enforcement |
| 26.2 | Background Job model | ✅ | `background_job.dart` (enum + model lengkap) |
| 26.3 | Job interface | ✅ | `BackgroundTask` + `JobContext` |
| 26.4 | Job Queue | ✅ | `BackgroundJobQueue` |
| 26.5 | Priority Scheduler | ✅ | `priorityWeight` critical=4…low=1 |
| 26.6 | Concurrency per category | ✅ | `JobResource` + resource limits |
| 26.7 | Worker isolate | ✅ | `BackgroundWorker.runCpu` via `Isolate.run` |
| 26.8 | File IO tidak semuanya butuh isolate | ✅ | Dokumentasi + pemisahan async IO |
| 26.9 | Job persistence | ✅ | `BackgroundJobs` table + DAO |
| 26.10 | Transient vs persistent job | ✅ | `JobPersistence` enum |
| 26.11 | Task Center | 🟡 | `TaskCenterScreen` minimal; belum top-bar badge |
| 26.12 | Job cancellation | ✅ | `queue.cancel` |
| 26.13 | Cancellation bukan kill paksa | ✅ | cooperative via `JobContext.isCancelled` |

## B. Thumbnail Pipeline (26.14–26.21)

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 26.14 | Thumbnail Pipeline flow | ❌ | Hanya model; belum generate/cache/notify |
| 26.15 | Thumbnail request | ✅ | `ThumbnailRequest` (size enum) |
| 26.16 | Multiple sizes | ✅ | `ThumbnailSize` 64/128/256/512 |
| 26.17 | Thumbnail cache key | ✅ | `ThumbnailCacheKey` hash+size+version |
| 26.18 | Jangan invalidate berdasarkan filename | ✅ | hash-based key |
| 26.19 | Lazy Thumbnail (placeholder→fade) | ❌ | Belum ada widget lazy |
| 26.20 | Viewport priority | ✅ | `ThumbnailViewport.priorityFor` |
| 26.21 | Grid virtualization | ❌ | Belum pakai `GridView.builder` di Asset Browser |

## C. Pagination & Search (26.22–26.33)

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 26.22 | Pagination | ✅ | `PageRequest`/`PageResult` |
| 26.23 | Cursor pagination | ✅ | `AssetPageCursor` |
| 26.24 | Asset Browser page size | ❌ | Belum `assetPageSize=80` + repo paginated |
| 26.25 | Infinite scroll loading | ❌ | Belum ada UI |
| 26.26 | Search debounce | ✅ | `DebouncedSearchController` 250ms |
| 26.27 | Search cancellation | ✅ | generation counter |
| 26.28 | SQLite indexes | ❌ | Belum ada `CREATE INDEX` |
| 26.29 | Composite indexes | ❌ | Belum ada |
| 26.30 | Search FTS | ❌ | Hanya in-memory index |
| 26.31 | FTS document abstraction | ✅ | `SearchDocument` |
| 26.32 | Incremental index update | ❌ | Belum ada event-driven update |
| 26.33 | Search index queue | ❌ | Belum ada |

## D. Timeline & Image Memory (26.34–26.47)

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 26.34 | Timeline virtualization | ❌ | Belum query visible clip |
| 26.35 | Visible timeline interval | ✅ | `TimelineViewport` |
| 26.36 | Timeline clip query | ❌ | Belum `getVisibleClips` repo |
| 26.37 | Overscan | ✅ | `overscanSeconds` |
| 26.38 | Timeline track virtualization | ❌ | Belum |
| 26.39 | Timeline repaint boundaries | ❌ | Belum |
| 26.40 | Preview image memory | 🟡 | Konsep ada, belum decode guard |
| 26.41 | Full image hanya saat perlu | ✅ | size presets |
| 26.42 | Image prefetch | ❌ | Belum |
| 26.43 | Memory cache budget | ✅ | `MemoryCachePolicy` |
| 26.44 | LRU cache | ✅ | `ThumbnailMemoryCache` |
| 26.45 | Audio waveform performance | 🟡 | cache ada (Sprint 23), belum viewport |
| 26.46 | Multi-resolution waveform | ✅ | `WaveformResolution` |
| 26.47 | Large audio lazy load | ❌ | Belum |

## E. Lazy Loading Fitur Lain (26.48–26.51)

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 26.48 | Reference Library pagination | ❌ | Belum |
| 26.49 | Relation graph loading | ❌ | Belum |
| 26.50 | Story tree lazy loading | ❌ | Belum |
| 26.51 | Bible lazy loading | ❌ | Belum |

## F. Lifecycle & Provider (26.52–26.57)

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 26.52 | Database connection lifecycle | ✅ | session owns db |
| 26.53 | Repository provider scope | 🟡 | ada `ProjectSessionController`, belum family/scope |
| 26.54 | Avoid giant global provider | 🟡 | dokumentasi |
| 26.55 | Selective watching | ❌ | Belum |
| 26.56 | Immutable state discipline | ✅ | model immutable |
| 26.57 | Large list keys | ❌ | Belum `ValueKey` konsisten |

## G. Batch & Maintenance (26.58–26.62)

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 26.58 | Batch database writes | ✅ | benchmark pakai batch |
| 26.59 | Import chunking | ❌ | Belum |
| 26.60 | Prepared statements/batch | ✅ | Drift batch |
| 26.61 | Database maintenance | ❌ | Belum |
| 26.62 | Maintenance warning | ❌ | Belum |

## H. Startup & Diagnostics (26.63–26.72)

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 26.63 | Project startup fast path | 🟡 | manifest+DB metrik ada; belum skip heavy scan |
| 26.64 | Startup phases | 🟡 | metrik fase manifest/database |
| 26.65 | Startup metrics | ✅ | `PerformanceMetrics` |
| 26.66 | Performance diagnostics | ❌ | Belum page |
| 26.67 | Slow query log | ❌ | Belum |
| 26.68 | UI frame monitoring | ❌ | Belum |
| 26.69 | Performance mode | ❌ | Belum |
| 26.70 | Battery awareness mobile | ❌ | Belum |
| 26.71 | Pause background jobs | ❌ | Belum |
| 26.72 | Network job policy | ❌ | Belum |

## I. Dedup/Retry/Dependency (26.73–26.79)

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 26.73 | Duplicate task suppression | ✅ | taskKey dedup |
| 26.74 | Work coalescing | ❌ | Belum |
| 26.75 | Thumbnail failure | ❌ | Belum error state |
| 26.76 | Job retry | ✅ | `JobRetryPolicy` |
| 26.77 | Task dependency | ✅ | `JobDependency` + graph |
| 26.78 | User task vs derived task | ❌ | Belum |
| 26.79 | Task hierarchy | ❌ | Belum |

## J. DB Schema & Index (26.80–26.81)

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 26.80 | Background Jobs DB schema | ✅ | schema 36 |
| 26.81 | Database indexes migration | ❌ | Belum `CREATE INDEX` migration |

## K. Benchmarks (26.82–26.87)

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 26.82 | Benchmark dataset | ✅ | `LargeProjectBenchmarkProfile` |
| 26.83 | No dev seed in prod | ✅ | `isDevelopmentOnly` |
| 26.84 | Asset Browser benchmark | 🟡 | runner seed referensi+timeline |
| 26.85 | Timeline benchmark | 🟡 | runner timing timeline range |
| 26.86 | Search benchmark | ❌ | Belum |
| 26.87 | Memory benchmark | ❌ | Belum |

## L. Dispose/Lifecycle/Notification (26.88–26.97)

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 26.88 | Dispose controllers | ❌ | Belum audit |
| 26.89 | Subscription lifecycle | ✅ | `BackgroundJobController.dispose` |
| 26.90 | Project close stress test | 🟡 | session lifecycle test |
| 26.91 | Task session ownership | ✅ | `ProjectSession.jobs` + transient cancel |
| 26.92 | Thumbnail jobs after close | 🟡 | transient cancel via session |
| 26.93 | Import/export tasks | ❌ | Belum prompt |
| 26.94 | UI skeletons | ❌ | Belum |
| 26.95 | Error isolation | ❌ | Belum |
| 26.96 | Task Center notification | ❌ | Belum |
| 26.97 | Dashboard background status | ❌ | Belum |

## M. Test Suite & DoD (26.98–26.99)

| Step | Judul | Status | Bukti |
|---|---|---|---|
| 26.98 | Performance test suite | 🟡 | 10+ test files ada; belum lengkap |
| 26.99 | Definition of Done | ❌ | Checklist belum seluruhnya hijau |

## Ringkasan

- ✅ DONE: 32 step
- 🟡 PARTIAL: 12 step
- ❌ MISSING: 55 step

## Catatan penting

- Spec kanonik menyebut schema `18→19` untuk background_jobs, tetapi live repo
  sudah di schema `36` (karena Sprint 26.9 dieksekusi lebih awal). Ini bukan
  konflik — nomor schema live lebih tinggi dan sudah mencakup background_jobs.
- Acceptance untuk index (26.81) bukan sekadar "index exists" tapi
  "query improves / remains reasonable", perlu benchmark sebelum/sesudah.
