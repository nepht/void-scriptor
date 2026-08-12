# Void Scriptor

Void Scriptor adalah creative studio multiplatform untuk membangun karakter, dunia, dan cerita dari satu shared core Flutter.

## Target platform

| Platform | Experience |
|---|---|
| Windows | Full Studio |
| macOS | Full Studio |
| Linux | Full Studio |
| Android | Adaptive Studio |
| iOS/iPadOS | Adaptive Studio (fondasi tersedia) |
| Web | Adaptive Studio dengan capability terbatas |

## Fondasi Sprint 01

Alur aplikasi saat ini:

```text
main
→ AppBootstrap (ProviderScope)
→ VoidScriptorApp
→ GoRouter
→ AdaptiveAppShell
```

Breakpoints resmi:

- `< 600 px`: phone — navigation bawah, workspace satu panel, inspector sebagai bottom sheet.
- `600–1023 px`: tablet — navigation rail, workspace, inspector overlay.
- `1024–1439 px`: compact desktop — sidebar + workspace, inspector collapsible.
- `≥ 1440 px`: desktop — sidebar + workspace + inspector permanen.

Capability platform dimodelkan terpisah dari layout sehingga shared core tidak bergantung pada `dart:io` dan tetap dapat dikompilasi untuk Web.

Dependency foundation menggunakan Riverpod, GoRouter, UUID, SharedPreferences, PathProvider, Drift, dan SQLite native. Isi project disimpan pada database SQLite mandiri per project; cloud sync, authentication backend, pembayaran, dan AI tetap menjadi modul lanjutan.

## Foundation routes

```text
SPLASH → ONBOARDING / AUTHENTICATION → DASHBOARD
                                      ├── PROJECTS → WORKSPACE
                                      ├── AI STUDIO
                                      └── DONATION
```

Sprint 01 mendaftarkan dan menguji seluruh route foundation. Keputusan first launch, guest/offline mode, session recovery, dan authentication redirect diimplementasikan bersama session engine pada sprint Authentication.

## Workspace canonical

Pengembangan dilakukan dari filesystem ext4 WSL:

```text
~/Projects/void_scriptor_multiplatform
```

Drive Windows/D: hanya untuk backup dan artefak, bukan working copy aktif.

## Quality gate

```bash
export PATH="$HOME/toolchain/flutter/bin:$PATH"
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build linux --debug
flutter build web --release
flutter build apk --debug
```

Build Windows dijalankan melalui GitHub Actions `windows-latest` atau toolchain Flutter Windows.

## Project persistence

Setiap project adalah paket mandiri berbasis UUID:

```text
Projects/<project-uuid>/
├── project.json
├── project.db
└── assets/
    └── characters/<character-uuid>/
        ├── references/
        ├── generated/
        ├── thumbnails/
        └── exports/
```

`projects.json` hanya menyimpan registry application-level untuk daftar project dan recent projects. Isi creative universe tidak disimpan di database global.

Project database saat ini memakai Drift schema version 2 dengan tabel Asset Core dan Character:

```text
assets
asset_tags
characters
character_identity_profiles
character_references
asset_relations
```

Pembuatan Character bersifat transactional: Asset, Character, dan Identity Profile dibuat bersama. Character repository juga mendukung identity lock, reference metadata, tags, asset relations, persistence setelah database reopen, serta pembersihan folder UUID ketika Character dihapus.

## Sprint status

```text
01 Multiplatform Foundation    ✅
02 Design System               ✅
03 Adaptive App Shell          ✅
04 Authentication              ✅
05 Dashboard                   ✅
06 Project System              ✅
07 Persistence Engine          ✅
08 Asset + Character Core      ✅
09 Character Workspace UI      planned
```

## Repository

Private canonical remote: <https://github.com/nepht/void-scriptor>

Legacy repositories bersifat read-only/archive dan bukan sumber implementasi baru.
