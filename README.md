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

Dependency foundation dibatasi pada Riverpod, GoRouter, UUID, SharedPreferences, dan PathProvider. Database, cloud, authentication backend, pembayaran, dan AI ditambahkan saat modulnya mulai dibangun.

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

## Repository

Private canonical remote: <https://github.com/nepht/void-scriptor>

Legacy repositories bersifat read-only/archive dan bukan sumber implementasi baru.
