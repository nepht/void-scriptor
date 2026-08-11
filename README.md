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

Breakpoints awal:

- `< 600 px`: compact/mobile — app bar + bottom navigation.
- `600–1199 px`: medium/tablet — navigation rail.
- `≥ 1200 px`: expanded/desktop — top bar + explorer + workspace + inspector + status bar.

Capability platform dimodelkan terpisah dari layout sehingga shared core tidak bergantung pada `dart:io` dan tetap dapat dikompilasi untuk Web.

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
