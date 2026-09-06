# Sprint 145.37 — Navigation Reduction

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json`, item `145.37`.  
Status: **PARTIAL**.

## Kontrak kanonik

`Menyederhanakan primary navigation to Dashboard, Novels, Characters, World, Search, Backup/Export, Settings while hiding unready modules without deleting source.`

## Evidence live

Desktop shell `lib/app/shell/desktop/void_top_bar.dart` saat ini mengekspos:

- Workspace;
- Story;
- Characters;
- Projects;
- AI Tools;
- Assets;
- Bible;
- wide-only Marketplace dan Donate.

Mobile shell `lib/app/shell/mobile/void_mobile_shell.dart` mengekspos:

- Home;
- Projects;
- AI;
- Assets;
- More.

Menu More masih menampilkan Story, Characters, References, Project Bible, dan Diagnostics. Route inventory juga masih memiliki banyak route feature-level termasuk AI, collaboration, project resilience, references, dan security.

## Verification terbaru

Command:

```bash
flutter test \
  test/app/shell/core_mvp_navigation_test.dart \
  test/app/shell/void_mobile_shell_test.dart \
  test/app/shell/void_top_bar_command_test.dart \
  test/app/project_resilience_routes_test.dart \
  test/app/shell/void_app_shell_dashboard_test.dart \
  test/app/adaptive/void_adaptive_scaffold_test.dart
```

Result:

```text
All tests passed! — 11 tests
```

Tests membuktikan shell dapat dirender pada desktop/mobile/tablet, menu Story/Characters tersedia, mobile destinations navigate, More menu membuka feature entries, dan top-bar search disembunyikan pada width terbatas.

## Gap terhadap target Core

| Acceptance | Status | Reason |
|---|---|---|
| Target primary destinations | PARTIAL | Target Dashboard/Novels/Characters/World/Search/Backup-Export/Settings belum menjadi daftar canonical shell |
| Hide unready modules | PARTIAL | AI/Assets/Bible/References/Diagnostics/Marketplace masih exposed di beberapa surface |
| Preserve source | VERIFIED | Tidak ada source feature yang dihapus dalam audit |
| Route semantics | PARTIAL | Existing callbacks/routes belum dipetakan satu-per-satu ke target Novels/World/Search/Backup-Export |
| Desktop/mobile parity | PARTIAL | Kedua shell berbeda dan mobile memakai Projects/AI/Assets sebagai primary destinations |
| Regression shell | VERIFIED-LOCAL | 11 navigation/adaptive tests lulus |
| Native interaction | UNVERIFIABLE | Windows native click-through tetap blocked oleh `snapshot_id_required` |

## Verdict

**PARTIAL — shell responsif dan routing existing teruji, tetapi primary navigation belum direduksi ke target Core dan unready modules belum seluruhnya feature-gated/tersembunyi.**

Next canonical step: `145.38 Settings Reduction`.

145.42 tetap tidak disentuh karena milik eksekutor lain.
