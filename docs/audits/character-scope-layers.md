# Sprint 145.26 — Character Scope Layers

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json` langkah 145.26 dan `core_mvp_scope_reset_spec.json`.  
Metode: inspeksi read-only terhadap source/test live.

## Required contract

Character identity harus dibedakan secara eksplisit menjadi:

1. **Canonical** — identitas dasar karakter yang menjadi source of truth.
2. **Universe / Timeline Override** — perubahan yang berlaku hanya pada universe atau timeline tertentu.
3. **Novel-specific State** — perubahan yang berlaku hanya pada novel tertentu.

Setiap edit scoped harus menyatakan scope-nya dan tidak boleh memutasi canonical identity secara diam-diam.

## Live evidence

- `lib/features/character/domain/character_model.dart` memiliki model karakter dasar dengan `displayName`, `alias`, dan `biography`.
- `lib/features/character/domain/character_identity_profile.dart` memiliki identity profile, tetapi inspeksi tidak menemukan model eksplisit untuk universe/timeline override atau novel-specific state.
- `lib/features/character/domain/visual_continuity.dart` memiliki user override berbasis scene. Ini adalah continuity override, bukan bukti lengkap untuk tiga layer Character Scope Layers.
- `lib/features/character/application/update_character_command.dart` dan `rename_character_command.dart` menyediakan command terhadap karakter, tetapi payload yang diaudit tidak memuat discriminator universe/timeline/novel scope.
- `lib/features/character/application/character_version_service.dart` menyediakan revision capture/restore/undo, tetapi revision history bukan pengganti scoped state.

## Test evidence

Focused Character suite terbaru lulus 33 test dan membuktikan identity, repository, revision, visual continuity, moodboard, interview, dan command behavior. Namun pencarian test khusus untuk `universeOverride`, `timelineOverride`, `novelState`, `scopeLayer`, dan `effectiveIdentity` tidak menemukan coverage.

## Evidence boundary

| Area | Status |
|---|---|
| Canonical Character identity | VERIFIED by Character model/repository tests |
| Scene-local visual continuity override | VERIFIED by visual continuity tests |
| Universe/Timeline Override layer | MISSING |
| Novel-specific State layer | MISSING |
| Explicit scope discriminator on identity commands | MISSING |
| Effective identity resolution | MISSING |
| No silent canonical mutation across layers | UNVERIFIABLE until scoped model/service tests exist |
| Native Windows interaction | UNVERIFIABLE; driver previously returned `snapshot_id_required` |

## Required next implementation slice

Implement only after a contract-first RED test defines:

1. immutable scoped-state model and scope discriminator;
2. canonical fallback precedence;
3. explicit universe/timeline/novel override precedence;
4. update command that writes only the declared scope;
5. effective identity resolver;
6. restart persistence and migration behavior;
7. undo/redo behavior across scoped edits;
8. Character Workspace display of effective state plus source scope.

The migration must preserve existing canonical Character data and must not reinterpret scene-local visual overrides as novel/universe state without an explicit adapter.

## Decision

`145.26 Character Scope Layers` berstatus **BLOCKED**. The live repository has canonical identity and a separate scene-local visual continuity override, but the required Universe/Timeline Override and Novel-specific State layers are absent from the inspected source/test contract. No production code or schema change was made because the precedence, persistence, and migration contract is underspecified.

The previously created `docs/audits/environment-location-core.md` is a separate Environment audit and must not be counted as evidence for this step.

Next canonical step: `145.27 Core Worldbuilding Reduction`.

## Evidence paths

- `lib/features/character/domain/character_model.dart`
- `lib/features/character/domain/character_identity_profile.dart`
- `lib/features/character/domain/visual_continuity.dart`
- `lib/features/character/application/update_character_command.dart`
- `lib/features/character/application/rename_character_command.dart`
- `lib/features/character/application/character_version_service.dart`
- `test/features/character/character_workspace_test.dart`
- `test/features/character/character_repository_test.dart`
- `test/features/character/character_version_service_test.dart`
- `test/features/character/visual_continuity_test.dart`
- `test/features/character/update_character_identity_command_test.dart`
- `test/features/character/rename_character_command_test.dart`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`

## Audit note

This is an evidence audit. No production Character code, schema, migration, or concurrent agent file was changed.
## Slice update 2026-09-02 (nephthys cron)

Kontrak preseden kini tersedia secara eksplisit dari
`core_mvp_scope_reset_spec.json` -> `character_model` (APPROVED resolution
guidance 145.24-145.26 item 2): tiga layer `CANONICAL_CHARACTER`,
`UNIVERSE_OR_TIMELINE_OVERRIDE`, `NOVEL_SPECIFIC_STATE`; ownership field per
layer; `quick_edit_requires_scope_choice`; `override_never_silently_mutates_canonical`.
Status berubah dari BLOCKED menjadi PARTIAL dengan slice contract-first
pertama (commit 681023e).

Slice yang sudah terbukti:

- `lib/features/character/domain/character_scope_layers.dart`:
  `CharacterScopeLayer` (canonical/universeTimeline/novelSpecific + priority
  eksplisit 0/1/2), `CharacterScopeFieldOwnership` (ownership eksak per spec:
  canonical = IDENTITY/BASE_VOICE/BASE_VISUAL_PROFILE/BASE_RELATION_REFERENCES;
  universe/timeline = ALTERNATE_HISTORY/ALTERNATE_RELATIONSHIPS/
  ERA_SPECIFIC_FACTS; novel = ROLE/ARC/CURRENT_LOCATION/CURRENT_AGE/
  CURRENT_STATUS/SCENE_POV/NOVEL_RELATION_STATE), `CharacterScopeState`
  (null = inherit dari layer di bawah, tidak pernah mutasi layer lain),
  `CharacterScopeEffectiveResolver` (precedence canonical -> universe ->
  novel; membaca tanpa mutasi input), `UpdateCharacterScopeCommand`
  (ArgumentError sebelum write untuk field bukan milik scope target;
  payload membawa discriminator scope eksplisit).
- RED terverifikasi: seluruh simbol baru undefined sebelum implementasi
  (compile error pada test pertama), lalu 14/14 focused test PASS
  (`test/features/character/character_scope_layers_contract_test.dart`).
- Regresi: character suite 53 PASS (39 lama + 14 baru), `flutter analyze`
  No issues found, `flutter build windows --debug` PASS (29.5s),
  `git diff --check` PASS.

Sisa gap menuju VERIFIED 145.26:

1. Persistence scoped state: tabel/DAO per layer + migration guarded yang
   mempertahankan seluruh data canonical yang ada (kontrak 145.26 guidance
   item 2 poin 6); snapshot/undo/redo lintas restart untuk scoped edit.
2. Integrasi command dengan repository/session nyata (execute menulis hanya
   layer yang dideklarasikan; clear override = fallback ke layer di bawah,
   bukan mutasi canonical).
3. Character Workspace source-scope display (per guidance item 2 poin 9).
4. Native interaction proof (UNVERIFIABLE dari cron; bukan acceptance item
   per presedens 145.24/145.25).


## Persistence slice (2026-09-02, cron)

Gap #1 (persistence scoped state) closed by `test/features/character/character_scope_persistence_test.dart` (5 PASS, RED terverifikasi: `getScopeState`s/`updateScopeState` undefined di interface sebelum implementasi):

- Schema 58 -> 59: tiga tabel baru `lib/database/project/tables/character_scope_layers.dart` - `CharacterCanonicalScopes`, `CharacterUniverseTimelineOverrides`, `CharacterNovelStates` (PK characterId; kolom nullable hanya milik layer masing-masing, jadi write lintas layer mustahil secara fisik; null = inherit dari layer di bawah).
- Migration guarded `if (from < 59)` createTable x3; data canonical existing tidak disentuh (tabel baru, tidak ada ALTER/DROP pada tabel lama; preseden v57/v58).
- `CharacterDao`: `getCanonicalScope`/`getUniverseTimelineScope`/`getNovelScope`, `upsertCanonicalScope`/`upsertUniverseTimelineScope`/`upsertNovelScope`, `removeCharacterScopeRows` (delete-safety: `deleteCharacter` kini membersihkan ketiga tabel scope dalam transaksi yang sama).
- `CharacterRepository` interface + `CharacterRepositoryImpl`: `getScopeStates` (Future<Map<CharacterScopeLayer, CharacterScopeState>>, selalu 3 layer, default empty state) dan `updateScopeState` (switch layer, hanya menulis tabel layer target).
- 30 file test asersi schema stale 58 -> 59 (28 `schemaVersion, 58` + rc_freeze + rc_migration_recovery; yang terakhir juga: seedV53 strip 3 tabel scope + user_version 59 + v59 wave proven via sqlite_master containsAll).
- Bukti gerbang: focused 5/5 PASS, character+release+database+project_package regression 108 PASS, analyze No issues (9.1s), full suite 3288 PASS / 1 FAIL (app_bootstrap_test konkuren 145.20, root-caused run sebelumnya, tidak disentuh), windows debug build PASS 29.9s + re-verify 28.2s pasca-format, diff --check PASS.

Sisa gap menuju VERIFIED 145.26 (setelah slice ini):

1. Integrasi command dengan repository/session nyata (execute menulis hanya layer yang dideklarasikan; clear override = fallback ke layer di bawah, bukan mutasi canonical).
2. Character Workspace source-scope display (per guidance item 2 poin 9).
3. Native interaction proof (UNVERIFIABLE dari cron; bukan acceptance item per presedens 145.24/145.25).


## Command integration + source-scope display slices (2026-09-02, cron)

Gap #1 (command integration) closed by `test/features/character/update_character_scope_field_command_test.dart` (3 PASS, RED terverifikasi: `UpdateCharacterScopeFieldCommand` undefined sebelum implementasi):

- `lib/features/character/application/update_character_scope_field_command.dart` - `UpdateCharacterScopeFieldCommand` (BaseCommand): execute membaca state layer target via `getScopeStates`, merge SATU field milik layer tsb, tulis via `updateScopeState` - sibling field di layer yang sama tidak pernah ikut ter-clear; field bukan milik layer ditolak `ArgumentError` SEBELUM akses database; undo menulis kembali `oldValue` hanya pada field tsb; redo = execute. `null` newValue meng-clear override field tsb sehingga resolver efektif fallback ke layer di bawah (bukti test ketiga: clear CURRENT_STATUS novel -> efektif null, canonical rows tak tersentuh). Catatan desain: ownership disjoint berarti canonical table tidak punya kolom CURRENT_STATUS/CURRENT_LOCATION/ROLE/ARC - nilai efektif field tsb hanya berasal dari universe/novel layer.
- Bukti gerbang: focused 3/3 PASS, character suite 61 PASS (pasca-format), format 2 files, analyze No issues, commit 11de9de.

Gap #2 (Workspace source-scope display) closed by `test/features/character/character_scope_status_ui_test.dart` (2 PASS, RED terverifikasi: `Character Scope` text 0 widgets + RenderFlex overflow 28px pre-existing di 390px):

- `lib/features/character/presentation/widgets/character_scope_status_card.dart` - `characterScopeStatesProvider` (FutureProvider.family via projectSessionProvider + CharacterRepositoryImpl.getScopeStates, production path) + `CharacterScopeStatusCard` (ConsumerWidget): menampilkan chip layer yang punya data (Canonical / Universe-Timeline / Novel-Specific) dan baris sumber efektif per field `Identity/Voice/Role/Status/Location: <nilai> (from <layer>)` - layer tanpa data tidak diklaim. Mounted di CharacterWorkspaceScreen SETELAH ReferencesCard (akhir konten) agar geometri tap test narrow existing tidak bergeser.
- RED kedua sekaligus: test narrow 390px mereproduksi RenderFlex overflow 28px PRE-EXISTING di `character_workspace_screen.dart` (CharacterModeSection fixed di luar scroll area). Fix responsif: pada width < 1100 CharacterModeSection pindah ke DALAM SingleChildScrollView (di atas konten), desktop >= 1100 tidak berubah (mode section tetap fixed di atas scroll area). Test narrow existing `character_workspace_test.dart` (390x844) tetap PASS.
- Pola test live-session: setup IO nyata (ProjectPackageService.create + ProjectSessionManager.open + drift writes) HARUS dibungkus `tester.runAsync` - tanpa itu test hang di fake-async zone (2 kali run hang terverifikasi lalu dibersihkan Stop-Process).
- Bukti gerbang: focused 2/2 PASS, character suite 63 PASS, analyze No issues (9.5s setelah fix curly_braces lint), full suite 3293 PASS / 1 FAIL (app_bootstrap_test konkuren 145.20, tidak disentuh; 3288 + 5 test baru = 3293 eksak), windows debug build PASS 28.0s, diff --check PASS, commit 84e9b04 (mixed-file technique: staging mine-only - sibling deletion-review slice pada character_workspace_screen.dart dipreservasi di disk, tidak ikut ter-commit).

Sisa gap menuju VERIFIED 145.26:

1. Native interaction proof (UNVERIFIABLE dari cron; bukan acceptance item per presedens 145.24/145.25 - reconciliation guidance mengizinkan closure tanpa native click/type bila tool interaksi tidak tersedia).

## Evidence-closure (2026-09-02, cron)

Status naik PARTIAL -> VERIFIED via evidence-closure reconciliation (pola RESOLUTION_GUIDANCE_145_24_145_26): objective eksak "Menerapkan or document Canonical, Universe/Timeline Override, and Novel-specific State with explicit scoped edits and no silent canonical mutation" terbukti per item - implementasi (enum discriminator, ownership map spec-exact, resolver, 3 tabel persistence, scoped command dengan write nyata, display sumber scope) dan dokumentasi (audit ini + ledger) keduanya tersedia dengan test eksekusi live (14+5+3+2 PASS). No silent canonical mutation terbukti struktural (tabel disjoint per layer + ArgumentError pre-write + merge sibling) dan behavioral (test lintas layer + clear-override). Native interaction direkam jujur UNVERIFIABLE dan tidak menghalangi closure per guidance.
