## Berikutnya: Sprint 26

Sekarang kita sudah punya **data, project package, recovery, dan mutation architecture**. Sprint 26 sebaiknya fokus pada bagian yang sangat penting untuk aplikasi multi-platform ini:

**Performance + Background Jobs + Thumbnail Pipeline + Virtualized UI + Large Project Optimization.**

Targetnya adalah membuat Void Scriptor tetap lancar ketika project bukan lagi berisi puluhan asset, tetapi misalnya:

```text
50 Characters
300 Wardrobes
500 Weapons/Props
2,000 References
1,000 AI Generations
500 Scenes
10,000 Timeline Clips
20,000+ searchable records
```

Kita akan membuat **background job manager, priority queue, thumbnail worker, lazy loading, pagination, virtualized asset grid/list, timeline viewport rendering, image memory cache, DB indexes, debounced search, cancellation, task center, dan performance diagnostics** sebelum menambahkan fitur besar berikutnya. memcite

Lanjutkan 

Lanjut ke **Sprint 26 — Performance + Background Jobs + Large Project Optimization**.

Sprint ini tidak menambah banyak fitur visual baru, tetapi sangat penting. Kalau kita melewatkannya, aplikasi bisa terasa cepat saat project kecil tetapi mulai berat ketika berisi ribuan asset, reference image, AI generation, scene, audio, dan timeline clip.

Targetnya adalah membuat Void Scriptor tetap responsif pada project besar tanpa mengubah arsitektur inti.

```text
UI THREAD
│
├── Navigation
├── Selection
├── Editing
└── Rendering
        │
        ▼
BACKGROUND JOB SYSTEM
│
├── Thumbnail generation
├── Waveform generation
├── Integrity scan
├── Search indexing
├── Hash calculation
├── Cache rebuild
├── Export
├── Import
└── AI downloads
```

## Step 26.1 — Jangan jalankan pekerjaan berat di UI path

Contoh yang sebaiknya tidak dilakukan langsung saat widget dibangun:

```dart
final bytes = await file.readAsBytes();

final hash = sha256.convert(bytes);

final thumbnail = await createThumbnail(bytes);
```

Pekerjaan seperti hashing, thumbnail generation, scanning ribuan file, dan export harus masuk job system.

UI hanya menerima:

```text
queued
running
completed
failed
```

---

## Step 26.2 — Background Job model

Buat:

`core/jobs/background_job.dart`

```dart
enum BackgroundJobStatus {
  queued,
  running,
  completed,
  failed,
  cancelled,
}

enum BackgroundJobPriority {
  low,
  normal,
  high,
  critical,
}

enum BackgroundJobType {
  thumbnail,
  waveform,
  searchIndex,
  fileHash,
  integrityScan,
  cacheRebuild,
  import,
  export,
  backup,
  generationDownload,
  custom,
}

class BackgroundJob {
  const BackgroundJob({
    required this.id,
    required this.projectId,
    required this.type,
    required this.label,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.progress = 0,
    this.error,
  });

  final String id;
  final String projectId;

  final BackgroundJobType type;
  final String label;

  final BackgroundJobStatus status;
  final BackgroundJobPriority priority;

  final double progress;

  final DateTime createdAt;

  final String? error;
}
```

---

## Step 26.3 — Job interface

```dart
abstract interface class BackgroundTask {
  String get id;

  BackgroundJobType get type;

  Future<void> execute(
    JobContext context,
  );

  Future<void> cancel();
}
```

`JobContext`:

```dart
class JobContext {
  const JobContext({
    required this.reportProgress,
    required this.isCancelled,
  });

  final void Function(double progress)
      reportProgress;

  final bool Function()
      isCancelled;
}
```

---

## Step 26.4 — Job Queue

Buat:

```dart
class BackgroundJobQueue {
  BackgroundJobQueue({
    this.maxConcurrentJobs = 2,
  });

  final int maxConcurrentJobs;

  final List<BackgroundTask> _pending = [];
  final Set<String> _running = {};

  void enqueue(
    BackgroundTask task,
  ) {
    _pending.add(task);
  }
}
```

Tetapi jangan pakai FIFO murni.

Kita punya priority.

---

## Step 26.5 — Priority Scheduler

Urutan:

```text
CRITICAL
↓
HIGH
↓
NORMAL
↓
LOW
```

Contoh:

```text
User membuka image
Thumbnail missing
→ HIGH

Background cache rebuild
→ LOW

Portable export yang diminta user
→ HIGH

Search index maintenance
→ NORMAL
```

Buat:

```dart
int priorityWeight(
  BackgroundJobPriority priority,
) {
  return switch (priority) {
    BackgroundJobPriority.critical => 4,
    BackgroundJobPriority.high => 3,
    BackgroundJobPriority.normal => 2,
    BackgroundJobPriority.low => 1,
  };
}
```

---

## Step 26.6 — Concurrency per category

Jangan membiarkan:

```text
4 video hash jobs
+
4 thumbnail jobs
+
3 export jobs
```

jalan bersamaan di laptop.

Buat resource classes:

```dart
enum JobResource {
  cpu,
  disk,
  network,
  gpu,
}
```

Task dapat meminta:

```text
thumbnail
CPU + Disk

AI download
Network + Disk

Export
CPU + Disk

Search Query
Database
```

Scheduler nanti membatasi resource-heavy concurrency.

---

## Step 26.7 — Worker isolate

Flutter/Dart UI isolate jangan menangani CPU-heavy task.

Task seperti:

```text
SHA-256
image thumbnail processing
large JSON parsing
waveform analysis
```

gunakan isolate.

Untuk operasi sederhana bisa:

```dart
final result = await Isolate.run(
  () {
    // CPU-heavy work
  },
);
```

Jangan memindahkan database connection sembarangan antar isolate tanpa desain yang sesuai.

---

## Step 26.8 — File IO tidak semuanya butuh isolate

Bedakan:

```text
CPU-heavy
→ isolate

Async file IO
→ async API

Database query
→ repository/database layer
```

Jangan membuat isolate untuk setiap `File.exists()`.

Overhead-nya sendiri bisa mahal.

---

## Step 26.9 — Job persistence

Job penting yang bisa bertahan lama perlu persistence.

Buat:

```dart
class BackgroundJobs extends Table {
  TextColumn get id => text()();

  TextColumn get projectId => text()();

  TextColumn get type => text()();

  TextColumn get label => text()();

  TextColumn get status => text()();

  TextColumn get priority => text()();

  RealColumn get progress =>
      real().withDefault(
        const Constant(0),
      )();

  TextColumn get payload =>
      text().nullable()();

  TextColumn get error =>
      text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime()();

  DateTimeColumn get startedAt =>
      dateTime().nullable()();

  DateTimeColumn get completedAt =>
      dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
```

Tidak semua job perlu disimpan permanen.

---

## Step 26.10 — Transient vs persistent job

Buat:

```dart
enum JobPersistence {
  transient,
  persistent,
}
```

Contoh:

```text
Generate one thumbnail
transient

Project export
persistent

AI download
persistent

Full validation
persistent
```

---

# Step 26.11 — Task Center

Sekarang kita bisa membuat satu UI global.

Top bar:

```text
Tasks 3
```

Klik:

```text
TASK CENTER

RUNNING

Export Void Universe
██████████████░░ 81%

Generate thumbnails
████████░░░░░░░ 52%

QUEUED

Rebuild Search Index

COMPLETED

Backup Project
```

Task Center menyatukan background work dari berbagai subsystem.

---

## Step 26.12 — Job cancellation

Task yang cancellable:

```text
thumbnail
search indexing
export
integrity scan
```

Jika user cancel:

```text
RUNNING
↓
cancel requested
↓
cleanup
↓
CANCELLED
```

Task harus sering memeriksa:

```dart
if (context.isCancelled()) {
  return;
}
```

---

## Step 26.13 — Cancellation bukan kill paksa

Jangan mengandalkan hard-kill arbitrary code.

Gunakan cooperative cancellation.

Untuk task yang sedang melakukan atomic database transaction:

```text
finish or rollback
```

baru berhenti.

---

# Step 26.14 — Thumbnail Pipeline

Sekarang banyak asset membutuhkan thumbnail.

Daripada menyimpan thumbnail manual untuk setiap layar, buat satu service.

Flow:

```text
Source Image
↓
Thumbnail Request
↓
Cache Lookup
↓
Exists?
├── yes → return
└── no
     ↓
Queue thumbnail job
     ↓
Generate
     ↓
Cache
     ↓
Notify UI
```

---

## Step 26.15 — Thumbnail request

```dart
class ThumbnailRequest {
  const ThumbnailRequest({
    required this.sourcePath,
    required this.cacheKey,
    required this.width,
    required this.height,
  });

  final String sourcePath;
  final String cacheKey;

  final int width;
  final int height;
}
```

---

## Step 26.16 — Multiple sizes

Jangan membuat satu thumbnail 2000×2000 untuk semua UI.

Preset:

```dart
enum ThumbnailSize {
  tiny,
  small,
  medium,
  large,
}
```

Contoh:

```text
Tiny
64 px

Small
128 px

Medium
256 px

Large
512 px
```

Asset Browser memakai `small/medium`.

Reference Compare memakai source image atau large preview.

---

## Step 26.17 — Thumbnail cache key

Gunakan:

```text
source content hash
+
requested size
+
thumbnail algorithm version
```

Contoh:

```text
abc123_256_v1.webp
```

Kalau source berubah:

```text
hash berubah
```

cache lama tidak digunakan.

---

# Step 26.18 — Jangan invalidate cache berdasarkan filename

Karena:

```text
master.png
```

bisa berubah content.

Hash jauh lebih aman.

---

# Step 26.19 — Lazy Thumbnail

Asset grid menampilkan:

```text
placeholder
↓
thumbnail arrives
↓
fade in
```

Jangan membuat layar freeze menunggu semua 500 thumbnails selesai.

---

# Step 26.20 — Viewport priority

Asset yang terlihat di viewport:

```text
HIGH
```

asset di bawah viewport:

```text
NORMAL
```

asset beberapa halaman jauh:

```text
LOW
```

Ini menghasilkan perceived performance yang jauh lebih baik.

---

# Step 26.21 — Grid virtualization

Jangan render:

```text
10,000 AssetCard
```

sekaligus.

Gunakan lazy builder:

```dart
GridView.builder(
  gridDelegate: ...,
  itemCount: items.length,
  itemBuilder: ...,
)
```

Widget hanya dibuat untuk area yang diperlukan.

---

# Step 26.22 — Pagination

Tetapi `GridView.builder` saja tidak cukup jika query memuat 100.000 rows.

Repository harus paginated.

Buat:

```dart
class PageRequest {
  const PageRequest({
    required this.limit,
    required this.offset,
  });

  final int limit;
  final int offset;
}
```

Response:

```dart
class PageResult<T> {
  const PageResult({
    required this.items,
    required this.hasMore,
  });

  final List<T> items;
  final bool hasMore;
}
```

---

# Step 26.23 — Cursor pagination lebih baik

Offset untuk dataset besar bisa makin mahal.

Kita bisa menuju keyset/cursor:

```text
lastUpdatedAt
lastId
```

Buat abstraction yang tidak memaksa UI tahu mekanisme.

```dart
class AssetPageCursor {
  const AssetPageCursor({
    this.value,
  });

  final String? value;
}
```

---

# Step 26.24 — Asset Browser page size

Awal:

```text
50–100 items
```

Misalnya:

```dart
const assetPageSize = 80;
```

Saat scroll mendekati akhir:

```text
load next page
```

---

# Step 26.25 — Infinite scroll loading

UI:

```text
Assets

[80 items]

↓

Loading more...

↓

next 80
```

Jangan request 10 pages sekaligus.

---

# Step 26.26 — Search debounce

User mengetik:

```text
q
qo
qow
qown
qowner
```

Jangan query database lima kali terlalu cepat.

Gunakan debounce sekitar:

```text
200–300 ms
```

untuk interactive search.

---

# Step 26.27 — Search cancellation

Jika query:

```text
qow
```

belum selesai, lalu user mengetik:

```text
qowner
```

hasil `qow` jangan menimpa hasil terbaru.

Gunakan request generation/token:

```dart
int requestGeneration = 0;
```

Setiap search:

```dart
final generation =
    ++requestGeneration;
```

Saat selesai:

```dart
if (generation != requestGeneration) {
  return;
}
```

---

# Step 26.28 — SQLite indexes

Sekarang database kita besar.

Tambahkan indexes untuk field yang sering dicari:

```text
assets.projectId
assets.type
assets.name
assets.updatedAt
asset_tags.assetId
asset_tags.tagId
relations.sourceAssetId
relations.targetAssetId
scene_characters.sceneId
timeline_clips.trackId
timeline_clips.startSeconds
```

Jangan membuat index setiap field secara buta.

Index juga punya biaya write/storage.

---

# Step 26.29 — Composite indexes

Query:

```text
project + type + updatedAt
```

bisa mendapat composite index.

Contoh konseptual:

```sql
CREATE INDEX idx_assets_project_type_updated
ON assets(project_id, type, updated_at);
```

Test dengan query nyata.

---

# Step 26.30 — Search FTS

Sprint 19 awalnya menggunakan query biasa.

Sekarang sudah waktunya menyiapkan **SQLite FTS** untuk text search besar.

Index:

```text
asset name
description
alias
tags
story title
scene title
bible terminology
```

Jangan taruh raw image metadata di FTS.

---

# Step 26.31 — FTS document abstraction

Buat:

```dart
class SearchDocument {
  const SearchDocument({
    required this.entityId,
    required this.entityType,
    required this.title,
    required this.body,
  });

  final String entityId;
  final String entityType;

  final String title;
  final String body;
}
```

Search Index Service menerima domain event dan update index.

---

# Step 26.32 — Incremental index update

Jangan:

```text
edit one character
↓
rebuild entire search index
```

Gunakan:

```text
CharacterChangedEvent
↓
update document Qowner only
```

Full rebuild hanya untuk repair/cache maintenance.

---

# Step 26.33 — Search index queue

Update indexing bisa:

```text
NORMAL priority
```

Tetapi user search langsung harus tetap menggunakan index versi terakhir yang tersedia.

---

# Step 26.34 — Timeline virtualization

Ini bagian kritis.

Timeline 10 detik kecil mudah.

Tapi project bisa punya:

```text
500 clips
```

atau lebih.

Jangan render semua clip di luar viewport.

Timeline tahu:

```text
visibleStart
visibleEnd
```

Query/render hanya clip yang intersect:

```text
clip.end >= visibleStart
AND
clip.start <= visibleEnd
```

---

# Step 26.35 — Visible timeline interval

```dart
class TimelineViewport {
  const TimelineViewport({
    required this.startSeconds,
    required this.endSeconds,
    required this.pixelsPerSecond,
  });

  final double startSeconds;
  final double endSeconds;

  final double pixelsPerSecond;
}
```

---

# Step 26.36 — Timeline clip query

Repository:

```dart
Future<List<TimelineClipModel>>
    getVisibleClips({
  required String timelineId,
  required double start,
  required double end,
});
```

Jangan load entire timeline setiap pan/zoom.

---

# Step 26.37 — Overscan

Kalau viewport:

```text
10–20 sec
```

render sedikit extra:

```text
8–22 sec
```

supaya scroll/pan halus.

Ini disebut overscan.

---

# Step 26.38 — Timeline track virtualization

Jika ada 100 tracks, viewport vertikal juga perlu virtualization.

Render tracks yang terlihat + beberapa overscan.

---

# Step 26.39 — Timeline repaint boundaries

Clip yang bergerak jangan membuat seluruh app repaint.

Gunakan:

```text
RepaintBoundary
```

secara strategis pada area timeline.

Jangan membungkus setiap tiny widget tanpa profiling.

---

# Step 26.40 — Preview image memory

Salah satu penyebab aplikasi kreatif berat adalah image memory.

Contoh:

```text
6000×4000 RGBA
```

bisa membutuhkan memory sangat besar ketika decoded.

Thumbnail grid jangan decode full resolution.

Gunakan thumbnail cache.

---

# Step 26.41 — Full image hanya saat perlu

Asset Browser:

```text
256px preview
```

Reference Comparison:

```text
larger preview
```

Export/detail view:

```text
original
```

Jangan gunakan original untuk semuanya.

---

# Step 26.42 — Image prefetch

Ketika user membuka asset 10:

```text
prefetch asset 11/12 thumbnails
```

boleh dilakukan low priority.

Jangan prefetch ratusan.

---

# Step 26.43 — Memory cache budget

Buat configurable memory policy.

```dart
class MemoryCachePolicy {
  const MemoryCachePolicy({
    this.maxPreviewItems = 100,
  });

  final int maxPreviewItems;
}
```

Nanti bisa berdasarkan estimated bytes, lebih baik daripada jumlah item.

---

# Step 26.44 — LRU cache

Thumbnail/previews yang baru dipakai bertahan.

Yang lama:

```text
evict
```

Gunakan Least Recently Used concept.

Disk cache tetap tersedia.

---

# Step 26.45 — Audio waveform performance

Waveform sudah di-cache Sprint 23.

Timeline hanya meminta peaks yang relevan.

Jangan menyimpan jutaan sample mentah di widget.

---

# Step 26.46 — Multi-resolution waveform

Untuk file panjang:

```text
full waveform
medium
coarse
```

Saat timeline zoom out:

```text
coarse
```

Saat zoom in:

```text
fine
```

Mirip mipmaps untuk audio waveform.

---

# Step 26.47 — Large audio lazy load

Audio Library:

```text
title
duration
waveform preview
```

jangan decode file penuh sampai user menekan Play/Edit.

---

# Step 26.48 — Reference Library pagination

Reference Library juga harus paginated.

Filter:

```text
Qowner / Face
```

hanya query matching references.

Jangan memuat semua project references lalu filter di Dart.

---

# Step 26.49 — Relation graph loading

Asset bisa punya ribuan relation.

Inspector hanya load:

```text
first N immediate relations
```

misalnya:

```text
20
```

dengan:

```text
View All
```

Relation Graph bisa load neighborhoods on-demand.

---

# Step 26.50 — Story tree lazy loading

Story Explorer:

```text
Story
```

load arcs.

Expand Arc:

```text
load chapters
```

Expand Chapter:

```text
load scenes
```

Jangan load semua beats/timeline saat tree dibuka.

---

# Step 26.51 — Bible lazy loading

Project Bible sidebar hanya load category counts.

Content loaded setelah user memilih section.

---

# Step 26.52 — Database connection lifecycle

Satu project session:

```text
one ProjectDatabase instance
```

Jangan membuka DB connection baru pada setiap widget.

ProjectSession owns:

```text
database
repositories
services
```

Saat project close:

```text
dispose
```

---

# Step 26.53 — Repository provider scope

Riverpod providers yang bergantung project harus memiliki lifecycle project/session.

Jangan meninggalkan provider project lama aktif setelah user membuka project lain.

Gunakan `family`/scope dengan project ID atau session object secara konsisten.

---

# Step 26.54 — Avoid giant global provider

Jangan buat:

```text
ProjectEverythingProvider
```

yang load:

```text
all assets
all scenes
all references
all timeline
all story
all AI
```

Setiap workspace meminta domain yang diperlukan saja.

---

# Step 26.55 — Selective watching

Widget kecil jangan:

```dart
ref.watch(
  entireHugeStateProvider,
);
```

kalau hanya membutuhkan:

```text
favorite
```

Gunakan selectors / provider granularity supaya perubahan kecil tidak rebuild seluruh workspace.

---

# Step 26.56 — Immutable state discipline

State update:

```text
new instance
```

bukan mutate object besar secara diam-diam.

Ini membuat rebuild lebih mudah diprediksi.

---

# Step 26.57 — Large list keys

Asset cards:

```dart
ValueKey(asset.id)
```

Timeline clip:

```dart
ValueKey(clip.id)
```

agar Flutter bisa mempertahankan element identity saat reorder/update.

---

# Step 26.58 — Batch database writes

Import 1000 assets.

Salah:

```text
transaction
asset 1
commit

transaction
asset 2
commit
...
```

Gunakan:

```text
ONE reasonable transaction
batch insert
```

atau chunk transaction jika sangat besar.

---

# Step 26.59 — Import chunking

Untuk 100.000 files, satu giant transaction juga buruk.

Gunakan chunk misalnya:

```text
250–1000 records
```

tergantung data.

Job progress:

```text
12%
38%
71%
```

---

# Step 26.60 — Prepared statements/batch

Gunakan fasilitas batch Drift/SQLite untuk repetitive insert.

Kurangi round trips.

---

# Step 26.61 — Database maintenance

Tambahkan:

```text
Project
→ Database Maintenance
```

Operations:

```text
Analyze
Optimize
Integrity Check
Vacuum
```

`VACUUM` jangan dijalankan otomatis terlalu sering karena bisa berat.

---

# Step 26.62 — Maintenance warning

Untuk large DB:

```text
VACUUM may take several minutes.
```

Run sebagai background job setelah DB berada dalam state aman.

---

# Step 26.63 — Project startup fast path

Jangan saat Open Project menjalankan:

```text
hash 30,000 files
rebuild all caches
validate everything
```

Fast open:

```text
manifest
schema
DB
quick integrity
session
workspace
```

Lalu optional jobs:

```text
background health scan
```

---

# Step 26.64 — Startup phases

UI:

```text
Opening Void Universe...

Reading manifest
Opening database
Restoring workspace
```

Begitu cukup:

```text
Studio opens
```

Background:

```text
Checking references...
```

Task Center menangani sisanya.

---

# Step 26.65 — Startup metrics

Catat internally:

```text
manifest load
DB open
workspace restore
first frame
```

supaya kita tahu bottleneck.

Jangan menebak.

---

# Step 26.66 — Performance diagnostics

Tambahkan development/performance page:

```text
PERFORMANCE

Project Assets
21,482

Database
182 MB

Search Index
Healthy

Thumbnail Cache
1.8 GB

Running Jobs
2

Recent Query
12 ms

Last Project Open
820 ms
```

---

# Step 26.67 — Slow query log

Repository/database wrapper dapat log query yang melampaui threshold.

Contoh:

```text
>100 ms
```

development builds.

Jangan log sensitive content berlebihan.

---

# Step 26.68 — UI frame monitoring

Development mode bisa menunjukkan:

```text
UI frame build
raster
dropped frames
```

Tetapi jangan membuat custom profiler berlebihan jika tooling Flutter sudah cukup.

Kita hanya butuh lightweight indicators di diagnostics.

---

# Step 26.69 — Performance mode

Settings:

```text
Performance

Thumbnail Quality
Low / Balanced / High

Background Workers
1 / 2 / 4

AI Downloads
1 / 2 / 4

Preload
Minimal / Balanced / Aggressive
```

Default `Balanced`.

Jangan meminta user mengerti thread count untuk menjalankan aplikasi normal.

---

# Step 26.70 — Battery awareness mobile

Android/mobile:

```text
background expensive jobs
```

lebih konservatif.

Misalnya:

```text
workers desktop = 2–4
workers mobile = 1–2
```

Battery/thermal lebih penting.

---

# Step 26.71 — Pause background jobs

Task Center:

```text
Pause Background Work
```

Tidak mem-pause critical user task/export kecuali diminta.

Low priority jobs berhenti scheduling.

---

# Step 26.72 — Network job policy

AI download/cloud work dapat punya:

```text
Wi-Fi only
```

option di mobile bila nantinya diperlukan.

Jangan hardcode sekarang.

---

# Step 26.73 — Duplicate task suppression

Jika thumbnail `ABC-256` sudah:

```text
queued
```

request kedua jangan membuat job baru.

Gunakan task key:

```text
thumbnail:ABC:256
```

deduplicate.

---

# Step 26.74 — Work coalescing

Search index receives:

```text
Qowner changed
Qowner changed
Qowner changed
```

dalam 200ms.

Bisa coalesce menjadi:

```text
Update Qowner search document
```

sekali.

---

# Step 26.75 — Thumbnail failure

Jika source corrupt:

```text
Thumbnail Failed
```

jangan retry tanpa batas.

Cache error state sementara.

UI:

```text
broken image placeholder
```

Validation Center bisa mencatat source file issue.

---

# Step 26.76 — Job retry

Background jobs:

```dart
class JobRetryPolicy {
  const JobRetryPolicy({
    this.maxAttempts = 2,
  });

  final int maxAttempts;
}
```

Thumbnail failure karena corrupted file tidak akan sembuh dengan 10 retries.

---

# Step 26.77 — Task dependency

Beberapa jobs:

```text
Import
↓
Hash
↓
Thumbnail
↓
Search Index
```

Jangan buat semuanya tightly coupled satu giant function.

Job graph/dependencies bisa sederhana:

```dart
class JobDependency {
  const JobDependency({
    required this.jobId,
    required this.dependsOnId,
  });

  final String jobId;
  final String dependsOnId;
}
```

---

# Step 26.78 — User task vs derived task

Import is user-facing:

```text
Import 50 References
```

Derived:

```text
Generate 50 thumbnails
```

Task Center bisa collapse derived children di bawah parent.

---

# Step 26.79 — Task hierarchy

```text
Import References                      62%

  ✓ Copy files
  ✓ Add database records
  ◌ Calculate hashes
  ◌ Generate thumbnails
  ○ Update search index
```

Lebih mudah dipahami user.

---

# Step 26.80 — Background Jobs DB schema

Naikkan schema:

```text
18 → 19
```

Tambahkan:

```text
background_jobs
```

Jika perlu:

```text
job_dependencies
```

Cache entries sudah ada dari Sprint 24.

Search FTS mungkin menggunakan virtual tables/database-specific migration.

---

# Step 26.81 — Database indexes migration

Tambahkan index penting melalui migration.

Sebelum dan sesudah, benchmark beberapa query.

Acceptance bukan sekadar:

```text
index exists
```

tetapi:

```text
query improves / remains reasonable
```

---

# Step 26.82 — Performance benchmark dataset

Buat test project generator untuk development.

Contoh:

```text
50 Characters
200 Wardrobes
300 Weapons
500 Props
100 Environments
2,000 References
1,000 Generations
500 Scenes
10,000 Clips
```

Jangan isi manual.

Buat seed generator khusus test/dev.

---

# Step 26.83 — Jangan ship dev seed generator di production UI

Pisahkan:

```text
dev_tools/
```

atau compile/debug guarded.

---

# Step 26.84 — Asset Browser benchmark

Target praktis awal:

```text
open asset browser
< ~1s reasonable desktop test hardware

scroll
no major stutter

search
interactive response
```

Jangan mengunci angka absolut tanpa hardware baseline.

Yang penting baseline + regression test.

---

# Step 26.85 — Timeline benchmark

Dataset:

```text
10,000 clips
```

Tetapi viewport hanya mungkin 100–300 visible.

Pastikan render complexity bergantung pada visible items, bukan total clips.

---

# Step 26.86 — Search benchmark

FTS:

```text
20,000+ docs
```

Search:

```text
qowner
```

harus terasa instant/interaktif.

Pagination tetap berlaku pada result besar.

---

# Step 26.87 — Memory benchmark

Scroll 2,000 image references.

Memory seharusnya tidak terus meningkat tanpa batas.

Kalau:

```text
500 MB
→ 1 GB
→ 2 GB
```

setelah scroll terus, berarti preview/cache lifecycle bermasalah.

---

# Step 26.88 — Dispose controllers

Pastikan:

```text
TextEditingController
ScrollController
AnimationController
FocusNode
```

di-dispose.

Pada workspace yang dibuka berulang kali ini bisa menjadi leak kecil tapi kumulatif.

---

# Step 26.89 — Subscription lifecycle

Streams/listeners:

```text
database
job progress
event bus
```

harus dilepas ketika provider/widget/session mati.

Riverpod dapat membantu, tetapi jangan menyimpan listener manual global tanpa cleanup.

---

# Step 26.90 — Project close stress test

Open project A.

Browse 100 assets.

Close.

Open project B.

Expected:

```text
project A database closed
providers disposed
old thumbnail requests cancelled where appropriate
old listeners removed
```

Tidak ada data A muncul di B.

---

# Step 26.91 — Task session ownership

Setiap task punya:

```text
projectId
```

Saat project ditutup:

Transient task:

```text
cancel
```

Persistent export/job:

```text
prompt user
```

atau task manager ownership sesuai jenis.

---

# Step 26.92 — Thumbnail jobs after close

Jika thumbnail derived cache untuk project sudah tidak open:

```text
LOW jobs can cancel
```

Tidak ada alasan terus menghabiskan CPU kecuali user memang meminta cache rebuild.

---

# Step 26.93 — Import/export tasks

User close project saat export:

```text
Export is still running.

[Keep Project Open]
[Cancel Export & Close]
```

Jangan menutup database/resources di bawah task yang masih membutuhkannya.

---

# Step 26.94 — UI skeletons

Daripada spinner besar untuk seluruh screen:

```text
Asset Browser
```

tampilkan:

```text
toolbar ready
filters ready
grid skeleton
```

Lalu data muncul.

Perceived performance lebih baik.

---

# Step 26.95 — Error isolation

Jika thumbnail service gagal:

```text
Asset Browser tetap jalan
```

Jika waveform generation gagal:

```text
Audio metadata tetap tampil
```

Derived service failure jangan menjatuhkan project.

---

# Step 26.96 — Task Center notification

Jika user pindah workspace dan export selesai:

```text
Portable project export completed.
```

Notification kecil.

Jangan modal kecuali perlu keputusan user.

---

# Step 26.97 — Dashboard background status

Dashboard bisa menampilkan:

```text
BACKGROUND TASKS

2 running
5 queued

Thumbnail cache 72%
Search index ready
```

Tetapi jangan membuat Dashboard penuh telemetry.

Task Center adalah detail utamanya.

---

# Step 26.98 — Performance test suite

Tambahkan:

```text
asset_pagination_test.dart
search_index_test.dart
timeline_viewport_query_test.dart
job_scheduler_test.dart
job_dedup_test.dart
thumbnail_cache_test.dart
project_session_dispose_test.dart
```

---

# Step 26.99 — Definition of Done

Sprint 26 selesai jika:

```text
✓ heavy jobs tidak memblok UI
✓ background queue punya priority
✓ jobs bisa cancel
✓ duplicate jobs dideduplicate
✓ thumbnail generation lazy
✓ thumbnail berdasarkan viewport priority
✓ asset browser paginated
✓ search debounced
✓ search lama tidak menimpa query baru
✓ DB indexes tersedia untuk hot queries
✓ FTS search tersedia
✓ timeline query berdasarkan viewport
✓ image grid tidak decode source penuh
✓ waveform memakai cache
✓ project startup menggunakan fast path
✓ session dispose bersih
✓ task center bekerja
✓ large project benchmark tetap responsif
```

---

## Status proyek

```text
01 Foundation                           ✅
02 Design System                        ✅
03 Adaptive Shell                       ✅
04 Authentication                      ✅
05 Dashboard                           ✅
06 Project System                      ✅
07 Persistence                         ✅
08 Asset + Character Core              ✅
09 Character Workspace                 ✅
10 Selection + Inspector               ✅
11 Wardrobe                            ✅
12 Weapon                              ✅
13 Character Mode + Loadout            ✅
14 Environment                         ✅
15 Story + Scene                       ✅
16 Timeline + Cinematic Editor         ✅
17 AI Context + Prompt Composer        ✅
18 AI Providers + Generation Queue     ✅
19 Asset Browser + Global Search       ✅
20 Reference + Consistency System      ✅
21 Project Bible + Canon System        ✅
22 Creature + Vehicle + Prop System    ✅
23 VFX + Audio + Production System     ✅
24 Project Package + Backup/Recovery   ✅
25 Undo/Redo + History + Versioning    ✅
26 Performance + Background Jobs       ◀ CURRENT
