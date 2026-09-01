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
