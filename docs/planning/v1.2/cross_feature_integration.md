# 109.44 — Cross-Feature Integration

**Acceptance kanonik:** `stable_ids`, `explicit_novel_character_links`,
`no_cross_workspace_co_ownership`, `no_circular_ownership`,
`unlink_does_not_delete_character`, `graceful_partial_failure`,
`distinct_navigation`.

## Implementasi yang diadopsi

Subtree `lib/features/workspaces/` menyediakan contract dan vertical slice
Novel–Character terpisah:

- `NovelCharacterLink` memakai `linkId`, Novel workspace ID, Character workspace
  ID, Character ID, mode, role, visibility, provenance timestamps, dan owner
  eksplisit `novel`;
- `NovelCharacterLinkService` membuat/list/unlink link tanpa menghapus sumber
  Character;
- `WorkspacePermissionPolicy` mensyaratkan link eksplisit serta grant baca/tulis
  untuk akses lintas workspace;
- `WorkspaceFileNamespace` menjaga namespace file Novel dan Character terpisah
  serta menolak traversal/absolute path;
- export/import memakai manifest provenance dan collision choices;
- partial import gagal sebelum meninggalkan workspace parsial;
- deletion Character meminta keputusan unlink eksplisit, menginvalidasi projection
  Novel, lalu menghapus sumber Character;
- `WorkspaceProjectionCard` dan actions menyediakan distinct projection/navigation
  tanpa co-ownership.

Tidak ada circular ownership: Novel memiliki link; Character tetap menjadi
sumber yang direferensikan. Unlink hanya menghapus relasi.

## Bukti

- Scoped format: `dart format --set-exit-if-changed` — 35 files, 0 changed.
- Scoped analyzer: `dart analyze lib/features/workspaces test/features/workspaces`
  — No issues found.
- Workspace suite: `flutter test test/features/workspaces` — **55 tests passed**.
- Cakupan test meliputi domain link/JSON, persistence reopen, permission policy,
  namespace, deletion safety, projection UI, export/import, collision handling,
  migration, rollback, dan partial failure.

Runtime Drift dapat mencetak warning tentang beberapa instance `ProjectDatabase`
selama test persistence. Warning tidak menyebabkan failure; tidak disuppress
karena bukan bagian dari kontrak 109.44 dan perlu audit lifecycle terpisah.

## Scope boundary

Perubahan ini tidak mengubah routing global atau file workspace lain. Integrasi
ke layar utama tetap melalui contract workspace/projection yang sudah dites.
