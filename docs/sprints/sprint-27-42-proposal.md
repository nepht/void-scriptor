# Sprint 27–42 — Proposal Blueprint (DRAFT untuk review Choirudin)

Status: **PROPOSAL / DRAFT** — bukan spesifikasi kanonik. Disusun oleh nephthys (arsitek)
berdasarkan: (1) PRD v1.0 milestones & fitur, (2) audit Sprint 1–26, (3) daftar
"deliberately deferred" di README, (4) struktur repo aktual. **Menunggu persetujuan
Choirudin sebelum implementasi apa pun.**

## Dasar analisis

PRD v1.0 menetapkan 5 milestone dan 7 fitur utama. Status per audit 1–26:

| Milestone PRD | Status |
|---|---|
| M1 Foundation | ✅ Sprint 1–8 (auth, project registry, DB, asset core, selection) |
| M2 UI | ✅ Sprint 9–15 (adaptive shell, explorer, workspace, inspector, responsive) |
| M3 Core Engine | ✅ Sprint 16–26 (timeline, bible/canon, production assets, VFX/audio, package, command, performance) |
| M4 Studio Features | ⬜ **Belum** |
| M5 AI & Plugins | 🟡 Partial (AI generation ada, **Plugin belum ada**) |

Fitur PRD yang belum ada sama sekali:
- **Plugin** (PRD fitur #6) — sistem plugin, manifest, registry, sandbox, lifecycle.
- **Settings** (PRD fitur #7) — dedicated settings surface (belum; hanya tersebar).

Item "deliberately deferred" di README yang kini menjadi target Sprint 27+:
1. Binary file picker / import pipeline + reference-image preview/editor.
2. History/version timeline UI + favorite metadata.
3. Component/material/measurement editors (Wardrobe & Weapon).
4. Export PNG/PDF + release packaging/signing.
5. Cloud authentication + real email/password reset delivery.
6. Donation/payment integration.
7. macOS/Linux/mobile release packaging.

---

## Blueprint Sprint 27–42 (16 sprint)

### Fase A — M4 Studio Features (Sprint 27–32)

**S27 — Studio Dashboard & Project Overview**
- Dashboard agregasi lintas-domain (asset counts, canon health, recent activity, AI queue status).
- Project overview screen: metadata, stats, storage, session, quick actions.
- Wiring ke `dashboard_status.dart`, `PerformanceDiagnosticsSnapshot`, `CanonHealthService`.

**S28 — Reference Image Preview & Editor**
- Binary file picker (image) + reference-image preview (zoom/pan/fit).
- Basic annotation/editor (crop, rotate) — non-destructive.
- Thumbnail pipeline integration (LRU cache + viewport priority).

**S29 — History / Version Timeline UI**
- Version timeline untuk asset (character/weapon/wardrobe) & reference.
- Restore/revert dari history, diff label.
- Reuse `command_history`, `project_version_control_service`, `character_version_service`.

**S30 — Component / Material / Measurement Editors**
- Wardrobe: component/material editor (CRUD + reorder).
- Weapon: component/material/measurement editor.
- Reuse tabel existing (`wardrobe_components`, `weapon_components`, `weapon_measurements`).

**S31 — Export PNG/PDF & Packaging Foundation**
- Export asset sheet → PNG; story/scene → PDF (report).
- Project package export (zip) — reuse `portable_project_service`.
- Release packaging foundation (versioned builds).

**S32 — Favorite Metadata & Universal Actions**
- Favorite flag di semua asset type + filter/sort.
- Universal action bar (duplicate, archive, delete-with-trash) lintas domain.

### Fase B — M5 AI & Plugins (Sprint 33–40)

**S33 — Plugin System Foundation**
- Plugin manifest spec, registry, discovery (folder + packaged).
- Lifecycle (load/unload), capabilities declaration.

**S34 — Plugin Sandbox & Permissions**
- Isolate/process isolation, permission model (filesystem/network/DB scope).
- Capability enforcement + audit log.

**S35 — Plugin API Surface & Events**
- Public plugin API (asset hooks, command hooks, UI slots).
- Event bus extension (project mutation events) → plugin subscribers.

**S36 — AI Provider Management UI**
- Provider CRUD, key storage (secure), connection test.
- Reuse `ai_provider_settings.dart`, `ai_provider.dart`, provider HTTP clients.

**S37 — AI Prompt Library & Presets**
- Prompt preset CRUD, sharing, import/export.
- Reuse `prompt_preset.dart`, `prompt_composer.dart`, `prompt_compiler.dart`.

**S38 — AI Generation Gallery Enhancements**
- Batch generation, compare/select, re-roll, feedback loop.
- Reuse `generation_queue.dart`, `ai_generation_gallery_screen.dart`.

**S39 — Settings Surface (PRD fitur #7)**
- Dedicated settings: editor, AI, appearance, performance, storage, plugins.
- Persist + apply (theme, defaults, performance mode).

**S40 — Cloud Authentication (deferred item #5)**
- Real email/password auth (Supabase/Firebase backend adapter) + reset delivery.
- Hybrid local/cloud account model (guest offline tetap jalan).

### Fase C — Release & Platform (Sprint 41–42)

**S41 — macOS/Linux/Mobile Packaging**
- macOS bundle, Linux AppImage/deb, mobile (Android APK/AAB) build config.
- CI pipeline yang benar (hosted) + notarization/signing scaffold.

**S42 — Release Readiness & Hardening**
- Full acceptance suite lintas domain, performance budget enforcement, migration soak test.
- Release notes, versioning, upgrade path, beta flag.

---

## Catatan metodologi (mengikat untuk semua Sprint 27–42)

1. Setiap sprint = **vertical slice lengkap** (domain → application → data → presentation → test).
2. TDD RED→GREEN→refactor; gate `flutter analyze` + `flutter test` + `build` + `git diff --check`.
3. Blueprint kanonik per-sprint (step-by-step 50–99 step) akan ditulis **setelah** garis besar ini disepakati, dan **sebelum** implementasi sprint tersebut.
4. Tidak ada klaim selesai tanpa bukti live command output.
5. Plugin/settings/cloud bersifat **opt-in**; guest/offline local mode tetap berfungsi (tidak regresi).

## Pertanyaan kunci untuk Choirudin (sebelum finalisasi)

1. **Fase A vs B**: urutkan M4 (Studio Features) dulu lalu M5 (AI & Plugins) — setuju?
2. **Plugin scope**: target plugin = Dart isolate in-process (aman + portabel) atau full process sandbox (lebih berat)? Saya rekomendasikan isolate dulu.
3. **Cloud auth backend**: Supabase, Firebase, atau backend custom? (M5 butuh keputusan ini.)
4. **Mobile target**: Android dulu (S41) atau iOS dulu? (Blocker macOS saat ini.)
5. **Prioritas deferred**: dari 7 item deferred, mana yang WAJIB di 27–42 vs boleh ditunda lagi (mis. donation/payment)?
