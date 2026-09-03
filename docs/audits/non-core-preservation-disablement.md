# Sprint 145.39 — Non-Core Preservation and Disablement

Tanggal audit: 2026-08-27
Sumber kanonik: `sprint_145.json`, item `145.39`.
Status: **PARTIAL**.

## Kontrak kanonik

Mempertahankan code/data non-Core di balik flag Beta/Experimental/Off, menghapus dead primary navigation, mendokumentasikan dependency reactivation, dan menjalankan regression test Core.

## Evidence terverifikasi

- `FeatureFlagRegistry` mengetahui 13 flag `vs12_*` dan seluruhnya default OFF.
- Unknown flag names ditolak dengan `ArgumentError`.
- Enable/disable, reset, dan instance isolation teruji.
- `WorkflowFeatureFlag` default OFF dan runtime override menghasilkan audit event.
- Plugin repository/host mempertahankan status enabled/disabled dan settings persistence.
- Core navigation/workspace regression suite lulus **20 tests**.

Command:

```bash
flutter test \
  test/core/feature_flags/feature_flag_registry_test.dart \
  test/workflow/workflow_feature_flag_test.dart \
  test/core/plugin/plugin_host_test.dart \
  test/core/plugin/plugin_repository_test.dart \
  test/app/shell/core_mvp_navigation_test.dart
```

## Gaps

- `FeatureFlagRegistry` belum diwiring ke primary navigation atau route visibility.
- Desktop shell masih mengekspos menu non-reduced seperti Marketplace pada kondisi wide.
- Desktop/mobile shell masih memiliki Story, Characters, dan Assets sebagai menu/surface lama; test saat ini mengunci sebagian layout tersebut.
- Tidak ada inventory/dependency document khusus yang memetakan cara mengaktifkan kembali setiap non-Core module.
- Tidak ada proof bahwa non-Core data tetap readable setelah module di-disable melalui user-facing settings.
- Persistence override untuk `FeatureFlagRegistry` bukan bagian dari registry; wiring settings belum ada.
- Native Windows interaction tetap `UNVERIFIABLE` karena `snapshot_id_required`.

## Verdict

`PARTIAL`: preservation dan safe default flags teruji pada domain/plugin boundary, tetapi disablement belum terhubung ke primary navigation dan reactivation dependencies belum terdokumentasi secara lengkap. Source/data non-Core tidak dihapus.

## Non-actions

Tidak ada penghapusan source/data, tidak ada route mass-edit, tidak ada cleanup, commit, push, atau tag.

## Next

Langkah kanonik berikutnya: 145.40 — Schema and Migration Fixtures. D-SCHEMA-01 tetap OPEN; audit harus membedakan fixture/schema evidence yang sudah ada dari migrasi baru yang belum diotorisasi.

## Provenance

Jenis evidence: source inspection, domain/plugin tests, navigation regression tests. Tidak mencakup native runtime interaction atau release readiness.

nephthys — 2026-08-27

## Update 2026-09-03 cron (nephthys, reactivation dependency map)

- Gap 145.39 'reactivation dependencies belum terdokumentasi lengkap' ditutup sebagai kontrak Dart + test arsitektur yang enforceable:
- `lib/core/capabilities/reactivation_dependency_map.dart`: ReactivationEntry (capabilityId/label/layer/owningFlag/featureModules/entryEvidence/defaultState) + ReactivationDependencyMap.entries untuk 10 capability deferred kanonik dari core_mvp_scope_reset_spec.json (deferred_until_evidence): COMMUNITY_CHAT, READER_PLATFORM, PUBLIC_PUBLISHING, AUTHOR_PAYMENT_AND_PAYOUT, CONNECTOR_MARKETPLACE, DEVELOPER_PLATFORM, MULTI_REGION, MOBILE_FULL_EDITOR, MACOS_RELEASE, DOZENS_OF_AI_AND_CLOUD_PROVIDERS.
- Grounding jujur: owningFlag hanya diisi bila flag registry vs12_* memang semantik (COMMUNITY_CHAT->vs12_spoiler_sharing), sisanya null; MULTI_REGION/MOBILE_FULL_EDITOR/MACOS_RELEASE jujur tanpa modul tree; layer + entry evidence dikutip dari registry 145.17.
- Test arsitektur `test/core/capabilities/reactivation_dependency_map_test.dart` 6 test: 10/10 id kanonik hadir, id unik + label/layer/evidence non-kosong, flag hanya namespace vs12_*, modul yang dideklarasikan ada di tree (anti modul imajiner), tidak ada capability mengklaim modul Core, default off/deferred, entry tanpa modul hanya platform follow-up.
- RED terverifikasi: Method not found 'ReactivationDependencyMap' (kompilasi gagal sebelum implementasi).
- Bukti: focused 6 PASS; regresi reactivation+feature_flags+architecture 17 PASS; analyze lib/core/capabilities+test/core/capabilities No issues; windows debug build PASS 28.0s; diff --check PASS. Full suite berjalan saat penulisan bukti ini; hasil final dicatat pada update ledger berikutnya.
- Boundary tetap: primary-nav removal + uniform route gating milik shell concurrent 145.20 (JANGAN disentuh dari cron); persistence override flag milik settings wiring; disabled-module data proof belum ada; native interaction UNVERIFIABLE dari cron.
- Status 145.39 tetap PARTIAL: reactivation dependency map CLOSED; sisa gap = primary-nav removal + uniform route gating (shell concurrent 145.20), persistence override flag (settings wiring), disabled-module data proof, native interaction UNVERIFIABLE dari cron.

## Update 2026-09-03 cron (nephthys, persistence override flag + disabled-module data proof)

- Dua gap cron-actionable dari daftar Gaps ditutup dengan TDD:
- Persistence override flag: `lib/core/feature_flags/feature_flag_override_store.dart` FeatureFlagOverrideStore menyimpan proyeksi durable flag vs12_* yang diaktifkan (`feature_flag_overrides.json`, `{"schema": 1, "overrides": {...}}`), tulis atomik tmp+rename tanpa residue, unknown flag di file dibuang saat load dan ditolak ArgumentError saat save, file hilang/korup = default bersih tanpa crash. `FeatureFlagRegistry.restoreOverrides({store})` memuat override saat konstruksi dan menulis balik pada setiap enable/disable via callback `_onChange`; registry tetap single runtime primitive dan constructor default dipertahankan (instance isolation test tetap hijau).
- Disabled-module data proof: `test/features/spoiler/spoiler_module_data_proof_test.dart` membuktikan menonaktifkan capability non-Core tidak menghapus/mengubah/membocorkan data: (1) gate OFF body tidak dieksekusi sama sekali; (2) data sumber tetap utuh dan readable setelah disable; (3) serialisasi pratinjau reader bebas teks spoiler dan bebas metadata internal; (4) restart proses (gate+registry baru) menetap akses disabled karena default OFF. Modul ber-data spoiler (keluarga reaktivasi COMMUNITY_CHAT, flag vs12_spoiler_sharing) dipakai sebagai korban bukti.
- RED terverifikasi: Method not found FeatureFlagOverrideStore + Member not found FeatureFlagRegistry.restoreOverrides (kompilasi gagal sebelum implementasi).
- Bukti gerbang: focused 12 PASS; regresi feature_flags+capabilities+workflow+plugin 57 PASS; full suite 3453 PASS / 0 FAIL (delta +12 eksak dari 3441); flutter analyze No issues; flutter build windows --debug PASS; git diff --check PASS. Commit 20f1562 (4 file, 391 insertions).
- Status 145.39 tetap PARTIAL: sisa gap = primary-nav removal + uniform route gating (shell concurrent 145.20, jangan disentuh dari cron), native interaction UNVERIFIABLE dari cron.
