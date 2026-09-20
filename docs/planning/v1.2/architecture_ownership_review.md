# 109.3 — Shared Architecture & Ownership (Review & Keputusan)

> Kanonik 109.3 menuntut review 7 area: novel_workspace_ownership,
> character_workspace_ownership, service_boundaries, cross_workspace_link_contract,
> event_contracts, permission_boundaries, failure_isolation.
> Metode: audit live repo + eksekusi `flutter test test/features/workspaces`
> (2026-08-26, **+55 All tests passed**, exit 0).
> Sumber keputusan: ADR-WS-001 (`workspace_separation_architecture.json`,
> folder outputs kanonik 2026-08-22).

## Koreksi metadata kanonik

Kanonik menandai ADR-WS-001 `ACCEPTED_NOT_IMPLEMENTED`. Realita repo: **inti sudah
diimplementasikan dan teruji**. Modul `lib/features/workspaces/` (1.418 LOC aplikasi+domain)
+ tabel Drift `novel_character_links` + 19 file tes. Yang BELUM ada dicatat jujur di bawah
(event contract & failure taxonomy) — dua gap itu keputusan baru langkah ini, bukan pembatalan.

## Status per area review

| Area | Status | Bukti live |
|---|---|---|
| novel_workspace_ownership | VERIFIED | Manuskrip dimiliki hierarki story (`lib/features/story/`: arcs/chapters/scenes/beats); karakter kanonis TIDAK disimpan di tabel novel — hanya id/role/visibility di link |
| character_workspace_ownership | VERIFIED | `lib/features/character/` (identity profile, visual cards); penghapusan lewat `WorkspaceCharacterDeletionService.review()` yang mengumpulkan novel terdampak dulu |
| service_boundaries | VERIFIED | Application layer terpisah dari repository; `WorkspaceResolver` mengonsumsi service (`CreateStoryService`, workspaces actions), bukan Drift langsung. Catatan jujur: panel historis lain masih menerima database langsung — tidak disentuh sprint ini |
| cross_workspace_link_contract | VERIFIED | `NovelCharacterLink` domain tervalidasi ketat (ID kosong ditolak, ID novel≠character dipaksa); mode REFERENCE/SNAPSHOT/FORK; owner selalu NOVEL; persistensi diuji `novel_character_link_persistence_test.dart`; skema tabel = persis `required_fields` ADR |
| permission_boundaries | VERIFIED | `workspace_permission_policy.dart` + tes: baca lintas butuh grant ganda + link eksplisit; tulis lintas butuh owner API + grant; field privat tersembunyi tanpa grant; owner lokal mencakup dua boundary |
| event_contracts | PARTIAL → typed contract implemented at 112.40 | `workspace_event_contract.dart` now pins WS-EVENTS v1 names, identifier-only serialization, and fail-closed decoding; `ProjectMutationEvent.workspaceEvent` is additive/optional so existing consumers remain compatible. Feature-specific emitters still follow the consuming feature steps. |
| failure_isolation | PARTIAL → aturan FISO-01 (bawah) | Isolasi fisik sudah ada (namespace file, cache re-buildable, review sebelum delete); taxonomy error eksplisit belum — diadopsi bertahap saat fitur Wave 1 lahir |

## Peta 10 acceptance_invariants ADR → bukti live

| Invariant (ADR) | Bukti |
|---|---|
| distinct workspace IDs | konstruktor link menolak `novelWorkspaceId == characterWorkspaceId` |
| distinct persistence namespaces | `workspace_file_namespace.dart` + tesnya |
| novel menyimpan referensi, bukan rekaman canon | tabel link hanya id/role/visibility; data canon tetap milik character feature |
| override novel ≠ mutasi canon | projection cache terpisah sebagai bacaan turunan + konflik = keputusan pengguna, tanpa overwrite otomatis (kebijakan ADR; semantik cache diuji `workspace_projection_cache_test.dart`) |
| perubahan canon tak menimpa override novel | sama seperti atas — sumber kebenaran terpisah |
| unlink / hapus novel ≠ hapus karakter | tes terlaksana: "explicit unlink removes links before deleting the character source" |
| hapus karakter wajib review novel terdampak | `CharacterDeletionReview.affectedNovelWorkspaceIds` + dialog + tes |
| permission dicek di kedua boundary | tes permission policy (dua arah) |
| backup/export mempertahankan link mode & provenance | `workspace_export_representation_test.dart` + pilihan embedded/reference pada import (`workspace_import_embedded_test.dart`) |
| projection cache dapat dibangun ulang | cache bukan sumber kebenaran + tes rebuild |

## Keputusan baru D-109.3-A — WS-EVENTS v1 (kontrak, wiring menyusul)

Kontrak event lintas-workspace, nama stabil sejak sekarang agar langkah-langkah fitur
tidak menciptakan istilah sendiri:

- `ws.link.created` / `ws.link.unlinked` / `ws.link.mode_changed` — setelah mutasi
  `novel_character_link` berhasil.
- `ws.projection.invalidated` — setelah canon character berubah; consumer me-rebuild cache.
- `ws.character.archived` / `ws.character.deleted` — setelah lifecycle action lolos review.
- Aturan: event TIDAK membawa payload canon (hanya id + jenis); listener gagal TIDAK boleh
  menggagalkan emitter; pengiriman best-effort in-process (satu proses, local-first).
- Implementasi: channel melalui infrastruktur event yang ada; wiring dilakukan di langkah
  fitur pertama yang mengonsumsinya (F9 lore graph / F16 spoiler), bukan di 109.3.

## Keputusan baru D-109.3-B — FISO-01 aturan isolasi kegagalan

1. Kegagalan Character Workspace tidak boleh membuat Novel Workspace tak bisa dibuka
   (dan sebaliknya): data terpisah namespace + link bersifat referensial.
2. Projection cache korup = bukan keadaan fatal: selalu dapat dibangun ulang dari sumber;
   kegagalan rebuild menampilkan state kosong berlabel, bukan crash.
3. Operasi destruktif (hapus karakter, restore collision) wajib lewat gerbang review —
   tidak ada jalur diam-diam.
4. Mulai Wave 1, service baru mengembalikan typed failure (`WorkspaceFailure` family:
   validation / notFound / conflict / permissionDenied) — diadopsi incremental per fitur,
   tidak refactor massal modul lama.

## Penamaan (catatan, bukan pekerjaan)

NOVEL Workspace terwujud di atas hierarki story yang ada (story→chapter→scene);
istilah UI "Novel" dipetakan ke konsep story. Tidak ada rename modul di sprint ini —
kontrak penting, label kosmetik tidak.

## Konsekuensi ke langkah berikutnya

- 109.4 (Shared Data Schema): semua tabel baru WAJIB menempatkan diri pada salah satu
  ownership di feature_contracts.md; tabel lintas dilarang; link tetap satu tabel.
- Langkah fitur yang menyentuh canon character wajib memakai projection reader yang
  diotorisasi (`authorized_workspace_projection_reader.dart`), bukan query langsung.
