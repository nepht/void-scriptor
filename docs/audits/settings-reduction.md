# Sprint 145.38 — Settings Reduction

Tanggal audit: 2026-08-27
Sumber kanonik: `sprint_145.json`, item `145.38`.
Status: **PARTIAL**.

## Kontrak kanonik

Menampilkan Core settings first; cloud, AI, community, publishing, payment, dan developer controls hanya berada di section feature-gated ketika implementasinya tersedia.

## Evidence terverifikasi

- `ThemeSettingsScreen` menyediakan Dark/Light/System dan persistence melalui provider/store.
- `SecuritySettingsScreen` menyediakan enable encryption dan change passphrase.
- `LanguageSwitcher` menyediakan enam pilihan bahasa serta compact/full presentation.
- `PluginSettingsStore` dan plugin repository memiliki persistence dan restart test.
- `AppRoutes.security` terdaftar dan membuka `SecuritySettingsScreen`.
- Focused settings/security/plugin suite: **23 tests passed**.

Command:

```bash
flutter test \
  test/features/settings/language_switcher_test.dart \
  test/features/platform/presentation/theme_settings_screen_test.dart \
  test/features/platform/theme_settings_persistence_test.dart \
  test/core/security/security_ui_test.dart \
  test/core/plugin/plugin_sdk_test.dart \
  test/core/plugin/plugin_repository_test.dart
```

## Gaps

- Belum ada `SettingsScreen`/settings shell terpadu yang menempatkan Core settings sebagai urutan pertama.
- Belum ada `AppRoutes.settings` atau route composition untuk settings Core.
- Theme, security, language, storage, backup/export belum disatukan dalam satu user-facing Core settings surface.
- Belum ada feature-gated section yang secara eksplisit menyembunyikan cloud, AI, community, publishing, payment, dan developer controls.
- Plugin settings persistence bukan feature gate untuk navigasi primary atau settings UI.
- Tidak ada evidence native Windows interaction untuk settings; driver masih `snapshot_id_required`.

## Verdict

`PARTIAL`: komponen settings individual dan persistence teruji, tetapi Settings Reduction sebagai composition dan feature-gated boundary belum tersedia. Implementasi UI terpadu ditunda sampai kontrak section/gating dan ownership file jelas; tidak dibuat secara spekulatif.

## Non-actions

Tidak ada secret yang dibaca, tidak ada data project yang dipindahkan, tidak ada cleanup, commit, push, atau tag.

## Next

Langkah kanonik berikutnya adalah 145.39 — Non-Core Preservation and Disablement.

## Provenance

Jenis evidence: source inspection, widget/unit tests, persistence tests. Tidak mencakup native runtime interaction, release build, atau production readiness.

nephthys — 2026-08-27
