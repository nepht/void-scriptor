# Sprint 145.25 — Character Workspace Core

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json` langkah 145.25 dan `core_mvp_scope_reset_spec.json`.  
Metode: inspeksi source/test live read-only dan focused Flutter test.

## Required contract

Character Workspace Core harus mencakup canonical identity, aliases, voice/visual notes, relations, linking, history, quick reference, dan responsive workspace behavior. Character identity harus tetap menjadi source of truth; scene/mode overrides bersifat scoped dan tidak mengubah canonical profile tanpa command eksplisit.

## Live implementation evidence

### Identity and repository

- `lib/features/character/domain/character_model.dart` — canonical character model dengan display name, alias, biography, serta immutable update path.
- `lib/features/character/domain/character_identity_profile.dart` — identity profile contract.
- `lib/features/character/data/character_repository_impl.dart` — project-scoped repository, search, persistence, dan corrupt-database handling.
- `lib/features/character/presentation/character_workspace.dart` / `character_workspace_screen.dart` — Character Workspace UI.
- `lib/features/character/presentation/widgets/character_identity_card.dart` — identity summary surface.
- `lib/features/character/application/update_character_command.dart` — undoable identity update command.
- `lib/features/character/application/character_version_service.dart` — capture/compare/restore/undo revision behavior.

### Continuity, visual notes, and history

- `lib/features/character/domain/visual_continuity.dart` — canonical visual attributes, timeline awareness, deterministic mismatch explanation, and scoped user override.
- `lib/features/character/domain/character_moodboard.dart` — local-media references, categories, annotations, source credit, and missing-file state.
- `lib/features/character/domain/character_interview.dart` — question sets, first-person answers, chronological session history, manual edit, and source provenance.
- `lib/features/character/domain/character_reference.dart` — typed character reference contract.

### Selection and workspace wiring

- `lib/features/character/presentation/character_controller.dart` — compatibility selection provider/action path used by Explorer and Inspector.
- `lib/features/character/presentation/character_workspace_controller.dart` — workspace identity actions.
- Character Workspace tests use the shared selection controller rather than an isolated shell-only selection state.

## Latest focused evidence

Command:

```text
wsl.exe -d Ubuntu -- bash -lc 'cd /home/nepht/Projects/void_scriptor_multiplatform && export PATH="$HOME/toolchain/flutter/bin:$PATH" && flutter test test/features/character/character_workspace_test.dart test/features/character/character_repository_test.dart test/features/character/character_version_service_test.dart test/features/character/character_interview_test.dart test/features/character/visual_continuity_test.dart test/features/character/character_moodboard_test.dart test/features/character/update_character_identity_command_test.dart test/features/character/rename_character_command_test.dart'
```

Result:

```text
All tests passed! — 33 tests
```

Covered behaviors:

- Character Workspace renders desktop identity sections;
- narrow empty state and populated long-name layout do not overflow;
- selection starts without an accidental character;
- repository search is case-insensitive and project-scoped;
- corrupt character project database is rejected;
- character revision capture/compare/restore/undo works;
- visual canon is registered per character;
- scene descriptions compare against canon with deterministic warnings;
- timeline-aware visual changes and scoped user overrides work;
- moodboard local media, categories, annotations, source credits, and missing-file recovery work;
- interview question/session history, first-person answers, manual edits, and provenance work;
- identity and rename commands execute, undo, and redo.

## Evidence boundary

| Area | Status |
|---|---|
| Canonical identity model/repository | VERIFIED by focused tests |
| Alias/search/project scope | VERIFIED by focused tests |
| Responsive Character Workspace | VERIFIED by focused tests |
| Version history and restore/undo | VERIFIED by focused tests |
| Visual continuity and scoped override | VERIFIED by focused tests |
| Moodboard/local reference handling | VERIFIED by focused tests |
| Interview history/provenance | VERIFIED by focused tests |
| Generic selection/resolver integration | VERIFIED by live-session journey (2026-09-01 cron g): `selectionProvider` mutation (production Explorer path, bukan override constructor) -> `WorkspaceResolver` -> `CharacterWorkspaceScreen` dengan data repository live (nama karakter dari DB, panel Character Identity) `test/features/workspace/workspace_resolver_character_journey_test.dart` 1 PASS; overview state saat selection null juga di-assert |
| Character relations/linking | VERIFIED by live-session journey (2026-09-01 cron): create via mutation bus (`RelationCommand.create` -> `RelationRepositoryImpl`), `RelationDisplayService.forAsset` resolves label `uses` + target name `Void Dagger`, `RelationSection` renders inside `CharacterInspector` with live `projectSessionProvider`, repository delete resolves empty again — `test/features/relations/character_relations_journey_test.dart` 1 PASS (commit 1ce0f81) |
| Quick reference across Story/Scene/AI context | VERIFIED at domain+AI+UI layers (2026-09-01 cron f): `CharacterQuickRef` domain (`lib/features/character/domain/character_quick_ref.dart`), `StoryRepositoryImpl.quickReferenceForScene` (canonical profile rows + identity notes + scene role; empty facts tidak bocor — kontrak baris eksak), `AiCharacterContext.quickRef` propagated by `AiContextResolver.resolveScene` (per-scene list, firstOrNull per character), Story Workspace panel `CHARACTER QUICK REF` loads on scene selection via repository (no dialog, no manual input). RED terverifikasi (quickReferenceForScene/quickRef/panel No element) -> GREEN: `test/features/story/character_quick_reference_test.dart` 1 PASS + `test/features/story/story_workspace_quick_ref_ui_test.dart` 1 PASS. Native Windows interaction tetap UNVERIFIABLE dari cron |
| Native Windows interaction | PARTIAL (2026-09-01 cron g): native window render proven via alive probe (`MainWindowHandle` valid + `Responding=True` + CopyFromScreen pixel stats non-kosong); foreground input/click interaction tetap UNVERIFIABLE dari cron (no computer_use driver) |
| Full Core vertical journey | PENDING; depends on remaining 145.30–145.35 and 145.41–145.44 contracts |

## No-break conditions

1. Canonical Character identity must not be silently overwritten by scene or mode-local overrides.
2. Character search and repository reads must remain project-scoped.
3. Revision restore/undo must preserve a readable prior state and must not claim success after persistence failure.
4. Visual continuity warnings must be deterministic and explainable.
5. Missing local moodboard media must render a recoverable state, not crash the workspace.
6. Narrow layouts must remain free of RenderFlex overflow diagnostics.
7. Character references must resolve to real source/target records before relation UI is called complete.
8. Native feature interaction remains separate from widget-test evidence.

## Relations journey evidence (2026-09-01 cron)

Command: `flutter test test/features/relations/character_relations_journey_test.dart` -> 1 PASS.

Journey on a real `ProjectSession` (real temp package + SQLite + mutation bus):

1. Create Character (`CharacterRepositoryImpl.createCharacter`) and a weapon Asset row.
2. Create relation via `session.mutationRuntime.bus.execute(RelationCommand.create(...))` — the same command path the inspector UI uses.
3. `RelationDisplayService.forAsset(characterId)` -> `[uses: Void Dagger]` (source-target name resolution proven against real DB rows).
4. `RelationSection` renders inside `CharacterInspector` through `InspectorResolver` + live `projectSessionProvider` override (widget presence + no exception).
5. Delete via `RelationRepositoryImpl.delete` (same repo the UI delete button drives through `RelationCommand.delete`) -> `forAsset` returns empty.

Boundary note: the dialog-driven add/delete click flow in a running native window remains UNVERIFIABLE from cron (no computer_use driver); a Windows-native alive probe (exe up, window handle valid, rendering non-empty content) is recorded separately in the sprint ledger. Interactive click proof is deferred to an attended session.

## Decision

`145.25 Character Workspace Core` berstatus **PARTIAL**. The Character Workspace and supporting identity/continuity primitives have strong live evidence: 33 focused tests pass. Relations/linking closed (commit 1ce0f81), quick-reference propagation into Story/Scene/AI context closed at domain+AI+UI layers (commit slice ini); full shared resolver journey dan native Windows interaction remain open.

Next: `145.26 Environment / Location Core`.

## Evidence paths

- `lib/features/character/domain/character_model.dart`
- `lib/features/character/domain/character_identity_profile.dart`
- `lib/features/character/domain/character_reference.dart`
- `lib/features/character/domain/visual_continuity.dart`
- `lib/features/character/domain/character_moodboard.dart`
- `lib/features/character/domain/character_interview.dart`
- `lib/features/character/data/character_repository_impl.dart`
- `lib/features/character/application/update_character_command.dart`
- `lib/features/character/application/character_version_service.dart`
- `lib/features/character/presentation/character_workspace.dart`
- `lib/features/character/presentation/character_workspace_screen.dart`
- `lib/features/character/presentation/character_controller.dart`
- `lib/features/character/presentation/character_workspace_controller.dart`
- `test/features/character/character_workspace_test.dart`
- `test/features/character/character_repository_test.dart`
- `test/features/character/character_version_service_test.dart`
- `test/features/character/character_interview_test.dart`
- `test/features/character/visual_continuity_test.dart`
- `test/features/character/character_moodboard_test.dart`
- `test/features/character/update_character_identity_command_test.dart`
- `test/features/character/rename_character_command_test.dart`
- `docs/audits/core-mvp-vertical-slice-contract.md`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`

## Audit note

This is a scope/evidence audit. No production Character code, schema, migration, or concurrent agent file was changed.
- 145.24: `docs/audits/novel-workspace-core.md`
- 145.25: `docs/audits/character-workspace-core.md`

Current blockers remain: `145.19` dependency boundary, `145.20–145.25` partial vertical slices, and native Windows interaction blocked by `snapshot_id_required`. No commit, push, tag, cleanup, or destructive storage action was performed. The next concrete step is to audit `145.26 Environment / Location Core`.

## Update 2026-09-01 (cron f: quick-reference propagation)

- Gap "Quick reference across Story/Scene/AI context" ditutup pada tiga
  lapisan dengan TDD (RED terverifikasi sebelum implementasi):
  1. **Domain**: `lib/features/character/domain/character_quick_ref.dart`
     — `CharacterQuickRef` (characterId, name, alias, compactDescription,
     role, summary getter). Murni domain, tanpa DB/UI.
  2. **Repository**: `StoryRepositoryImpl.quickReferenceForScene(sceneId)`
     — untuk tiap anggota scene (SceneCharacters), baca profil canon
     `Characters` (biography, personality, gender, age, heightCm, hair,
     eyes, skin), notes `CharacterIdentityProfiles`, lalu rangkai baris
     non-kosong menjadi `compactDescription`; role dari keanggotaan
     scene. Karakter yang barisnya hilang di `Characters` dilewati.
  3. **AI context**: `AiCharacterContext.quickRef` (field opsional baru)
     diisi `AiContextResolver.resolveScene` dari daftar quick reference
     per scene (firstOrNull per karakter) sehingga prompt composer punya
     akses kartu ringkas tanpa membaca Drift langsung.
  4. **UI**: panel `CHARACTER QUICK REF` di `StoryWorkspaceScreen`
     ditempatkan SETELAH panel SCENE SNAPSHOTS (geometri tap test
     existing tidak bergeser), memuat kartu via
     `_loadQuickRefsFor(sceneId)` pada pemilihan scene (CHAPTERS dan
     hasil NOVEL SEARCH), hint eksplisit saat belum ada scene, tanpa
     dialog/input manual.
- RED: `quickReferenceForScene isn't defined`, `quickRef isn't defined
  for AiCharacterContext`, UI `Bad state: No element` pada
  `find.text('CHARACTER QUICK REF')`.
- GREEN: `test/features/story/character_quick_reference_test.dart`
  1 PASS (journey: character canon + identity notes + addCharacter ->
  quickReferenceForScene baris eksak -> AiContextResolver.resolveScene
  membawa quickRef); `test/features/story/story_workspace_quick_ref_ui_test.dart`
  1 PASS (journey UI fake-repository: hint -> pilih scene -> kartu
  Qowner + role participant + baris Hair/Eyes tampil).
- Regression fix additive: fake repository di
  `novel_workspace_search_snapshot_ui_test.dart` di-override
  `quickReferenceForScene` (return const []) karena tap path scene baru
  memuat quick reference; asersi 145.24 tidak diubah.
- Bukti: story+relations+ai_context+inspector 153 PASS; `flutter
  analyze` No issues found; `dart format` scoped 8 file (4 changed,
  format-only); `git diff --check` PASS; full suite + windows debug
  build direkam di update ledger berikutnya.
- Sisa gap 145.25: full shared resolver journey (clean-device route
  journey) dan native Windows interaction (UNVERIFIABLE dari cron).

## Update 2026-09-01 (cron g: full shared resolver journey + native render proof)

- Gap "full shared resolver journey" ditutup dengan journey test pada live
session (real package + SQLite, bukan fake repository):
`test/features/workspace/workspace_resolver_character_journey_test.dart`.
- Journey: package dibuat via `ProjectPackageService`, session dibuka via
`ProjectSessionManager`, karakter dibuat via `CharacterRepositoryImpl`,
resolver dirender dengan `projectSessionProvider` override ke session live;
overview state (`Novel Workspace`) di-assert saat selection null; lalu
`selectionProvider.notifier.select(...)` dimutasi persis seperti jalur
Explorer (bukan override selection controller) -> `WorkspaceResolver`
me-render `CharacterWorkspaceScreen` dengan nama karakter dari database
live + panel `Character Identity`. `tester.takeException()` null.
- Test ini PASS pada percobaan pertama: perilaku production sudah benar;
yang ditambahkan adalah bukti journey eksplisit (preseden: relations
journey commit 1ce0f81). Tidak ada kode produksi yang diubah.
- Native render proof: alive probe menemukan window dengan
`MainWindowHandle` valid, `Responding=True`, pixel stats 2093 unique
colors / 112578 edge transitions (1280x720) = render non-kosong.
Interaction native (klik/typing) tetap UNVERIFIABLE dari cron.
- Bukti: focused workspace+character+relations+selection 48 PASS;
full suite 3239 PASS; `flutter analyze` No issues; windows debug build
PASS (45.7s); `git diff --check` PASS.
- Sisa gap 145.25: native Windows interaction (UNVERIFIABLE dari cron,
butuh sesi interaktif/computer_use).

## Update 2026-09-01 (cron k: BASE_VOICE + private notes wiring)

- Dua gap objective 145.25 ditutup dengan TDD (RED terverifikasi):
  1. **BASE_VOICE** (`canonical_owns` core_mvp_scope_reset_spec):
     kolom `Characters.voice` (schema 57->58, guarded `if (from < 58)`
     `m.addColumn(characters, characters.voice)`), field
     `CharacterModel.voice` + copyWith, mapper `characterToData/
     characterFromData` di `UpdateCharacterCommand`, tulis-baca di
     `CharacterRepositoryImpl.updateCharacter/_fromRow`, dan baris
     `Voice: <...>` di `StoryRepositoryImpl.quickReferenceForScene`
     (hanya saat non-kosong).
  2. **Private notes wiring**: `CharacterRepositoryImpl.getIdentity`
     kini membaca `CharacterIdentityProfiles.notes` dan `updateIdentity`
     menulisnya — sebelumnya kolom ada tapi SILENT-DROP di kedua
     boundary (bug data-loss halus).
- RED: `voice isn't defined` (5 compile error pada `CharacterModel`),
  notes roundtrip gagal. GREEN: 5/5 test di
  `test/features/character/character_voice_notes_test.dart` (notes
  roundtrip dua arah, voice update+readback, voice lintas restart DB,
  quick ref memuat baris Voice).
- 29 asersi schema stale diperbarui 57->58 (23 `schemaVersion, 57`,
  6 `currentSchemaVersion, 57`); rc_freeze wording v58; matrix
  rc_migration seedV53 kini juga `ALTER TABLE characters DROP COLUMN
  voice` agar rewind setia ke pre-58, dan wave v58 dibuktikan via
  `PRAGMA table_info(characters)` contains 'voice'.
- Sisa gap 145.25: voice/notes BELUM tampil di UI Character Workspace
  (identity card menampilkan Hair/Eyes/Skin, bukan voice; tidak ada
  editor untuk keduanya) — dicatat sebagai slice berikutnya; native
  interaction tetap UNVERIFIABLE dari cron.
