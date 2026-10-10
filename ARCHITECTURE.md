# ARCHITECTURE.md — Void Scriptor

Peta arsitektur dari repo live (`D:\Project\Void Scriptor Studio`, branch `master`).
Kontrak perilaku untuk kontributor/agent ada di `AGENTS.md`.

## 1. Ringkas

Flutter multiplatform (Windows primary, Linux, Web, Android, macOS/iOS sim) berbasis:

- **State:** Riverpod (`flutter_riverpod`).
- **Navigasi:** GoRouter (`lib/app/routing/app_router.dart`, `app_routes.dart`).
- **Persistence:** Drift/SQLite **per proyek** — `project.db` di dalam folder `<uuid>.voidproject/`.
- **Keamanan lokal:** `flutter_secure_storage` (kredensial) + feature flags default OFF.
- **Build/tooling:** Dart SDK ≥3.12, `build_runner` untuk kode Drift.

```text
main.dart → app/bootstrap (bootstrap gate, diagnostics, crash log, startup recovery)
         → app/adaptive (breakpoint resolver) → shell (desktop|mobile)
         → routing (GoRouter + capability guard) → features/* (presentation)
features/* → core/* (services) → database/project (Drift DAO) → project.db
```

## 2. Peta `lib/`

| Path | Tanggung jawab |
|---|---|
| `app/` | bootstrap, adaptive shell/breakpoint, routing + `RouteCapabilityGuard`, desktop/mobile shell, top bar, status bar, project exit guard |
| `core/` | services lintas fitur: `selection`, `jobs`, `performance`, `security`, `feature_flags`, `persistence`, `project_package`, `search`, `commands`, `theme`, `auth`, `capabilities`, `plugin`, `publishing`, `render`, `roadmap`, `observability`, `network`, dsb. |
| `database/project/` | Drift database proyek: tabel, DAO, migrasi (schema live tercatat 62 pada manifest RC 112.52), asersi skema diuji di seluruh `test/` |
| `features/` | 57 feature modules — setiap modul `domain/` + `presentation/` (dan `data/` bila ada), satu vertical slice = satu domain boundary |
| `design_system/` | token warna/spacing/radius/tipografi + komponen Void — lihat `DESIGN-SYSTEM.md` |
| `workflow/` | engine workflow kanonik: definition, execution, validation, recovery, policies, audit, feature flag |
| `shared/` | widget lintas fitur (skeleton loading, error boundary, scale comparison) |
| `l10n/` | ARB lokal (`app_en`, `app_id`) + resolver |
| `release/` | `artifact_manifest.dart` untuk manifest RC (checksum/provenance) |
| `automation/` | skrip otomasi internal |
| `database/` | hanya berisi `project/` (jangan bikin global DB — dilarang kontrak README) |

## 3. Prinsip desain yang dipakai

1. **Satu backend kanonik per domain.** Selection Engine generik memetakan `AssetType` → workspace/inspector masing-masing; tanpa duplikasi database.
2. **Domain dulu, test-first.** Tiap fitur: RED → minimal impl → GREEN → regression → analyzer → build gate (aturan wajib `AGENTS.md`).
3. **Fail-closed untuk gate risiko.** Validasi identitas, capability route, redaction spoiler, migration, signing → menolak ketika syarat tidak jelas, bukan menebak.
4. **Flags default OFF.** Wave capabilities aktif hanya via opt-in eksplisit (`feature_flags`, `vs12_world_logic_shared`).
5. **Local-first.** Tidak ada jaringan yang diperlukan untuk alur inti; provider eksternal difenced di belakang guard.
6. **Adaptive shell, bukan widget tunggal.** Desktop dan mobile shell terpisah, kontrak test dua lebar.

## 4. Batas & antarmuka penting

- **ProjectSession** — pemilik siklus hidup proyek: lock, open/close, background jobs transient, metrics startup. Satu-satunya jalan memegang `project.db`.
- **RouteCapabilityGuard + ReactivationDependencyMap** — route di belakang capability yang deferred di-fallback ke Core.
- **SpoilerSafeExportService** — ekspor berbagi melewati redaction; jalur lain dilarang mem-paste metadata internal.
- **ReferenceRepository / primary invariant** — satu primary per (project, owner, type) di layer service/DAO, bukan widget.
- **BackgroundJobQueue** — kerja berat off UI thread, per-resource concurrency, retry/dependency graph.

## 5. Kualitas & gerbang

Gerbang per slice (urutan wajib): focused test → `flutter analyze --no-pub` → regresi wilayah → `git diff --check` → build gate platform → ledger + state + `roadmap_guard` → commit scoped → push (setelah gate hijau).

- Sumber status sprint: ledger `docs/sprints/*.md` (kolom status mesin) + `docs/roadmap/ROADMAP_POLICY.json` + `.hermes/ROADMAP_STATE.json`.
- Guard: `dart run tool/roadmap_guard.dart` — sha policy, konsistensi pointer, rekomendasi step.
- Benchmark suite live (Sprint 112.39): 5635 PASS / 0 fail / 1 expected skip.

## 6. Konvensi kontribusi

- Baca, tulis, uji, commit **hanya** dari path kanonik di atas (WSL/mirror = legacy).
- `git add -- <path>` eksplisit; larangan `git add -A`; inspeksi `git diff --cached --name-only` sebelum commit (worktree dipakai paralel oleh cron v4).
- Schema Drift berubah → regenerasi `build_runner`, perbarui SEMUA asersi `schemaVersion` di `test/`, pertahankan minimal satu tes migrasi open/legacy.
- Klaim selesai wajib berbasis output eksekusi nyata (lihat `AGENTS.md`, bagian anti-slop report gate).

## 7. Keterbatasan arsitektur saat ini (jujur)

- Hosted CI tidak berfungsi sejak 14 Sep 2026 (billing block, job 0-step) → gerbang resmi = suite lokal.
- macOS/iOS/Windows release artifact & distribusi publik belum masuk pipeline otomatis.
- Fitur `collaboration` & marketplace masih seam bertahap, sebagian disabled-by-flag.
