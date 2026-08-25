# 109.4 — Shared Data Schema (Kontrak Skema Novel × Character × Lore)

> Kanonik 109.4 menuntut: distinct_workspace_ids, distinct_persistence_namespaces,
> stable_character_refs, novel_owned_overrides, character_owned_canon, provenance,
> soft_delete, versioning. Disusun nephthys 2026-08-26 dari audit live
> (`project_database.dart` v56, pola migrasi guarded, `WorkspaceFileNamespace`,
> konvensi tabel Drift). Status desain: mengikat untuk implementasi Wave 1;
> nomor tabel final dibekukan per langkah fitur saat RED test ditulis.

## S1 — Model penyimpanan (kejujuran arsitektur)

Satu `project.db` SQLite per proyek (Drift, v56 hari ini) + namespace file fisik.
"Namespace persistensi terpisah" dimaknai dua lapis:

1. **Fisik (file/media)**: `<package>/workspaces/novels/{id}/…` dan
   `workspaces/characters/{id}/…` — SUDAH ADA di `workspace_file_namespace.dart`
   dan dipakai untuk media/dokumen (moodboard, export, snapshot besar).
2. **Logis (DB)**: satu file DB, kepemilikan ditegakkan lewat aturan kolom wajib +
   batas DAO + permission policy — BUKAN file DB terpisah per workspace. Ini konsisten
   dengan kata "conceptual_storage_namespace" di ADR-WS-001. Dilarang membuat DB kedua.

## S2 — Aturan kolom lintas-tabel (mengikat semua tabel baru)

| Aturan | Isi |
|---|---|
| A-ID | PK `id` TEXT UUIDv4; identitas TIDAK PERNAH diderivasi dari nama |
| A-PROJ | Tabel level-proyek membawa `projectId`; tabel workspace membawa `novelWorkspaceId` ATAU `characterWorkspaceId` — tidak keduanya |
| A-TIME | `createdAt`/`updatedAt` UTC (DateTime.toUtc), disentuh setiap mutasi |
| A-SOFT | Soft delete: `deletedAt` TEXT NULL; query baca default menyaring; purge hanya via maintenance eksplisit; hapus karakter tetap wajib review service yang ada |
| A-VER | `revision` INTEGER monoton naik per mutasi baris (+1); snapshot/riwayat = baris terpisah, bukan overwrite |
| A-PROV | Setiap rekaman salinan/proyeksi wajib provenance: `sourceId`, `sourceRevision`, `capturedAt`, `origin` (`canonical`\|`override`\|`import`) |
| A-CANON | Tabel canon CHARACTER DILARANG membawa kolom novel-scoped; sebaliknya tabel NOVEL dilarang menyalin field canon karakter — hanya `characterId` sebagai referensi |
| A-LINK | Satu-satunya jalur relasi novel↔character adalah tabel `novel_character_links` yang ADA (linkMode reference/snapshot/fork) |

## S3 — Inventaris tabel Wave 1 (kepemilikan + status)

Legenda: **ADA** = sudah hidup di repo (dipakai, tidak dibuat ulang); BARU = akan
dibuat oleh langkah fiturnya masing-masing, satu increment skema per fitur.

| Family | Tabel | Owner | Status | Catatan kunci |
|---|---|---|---|---|
| F1 links | `lore_link_index` (targetType,targetId,sourceSceneId,anchorText,resolved,brokenReason) | NOVEL | BARU (109.9–11) | indeks turunan dari teks — rebuildable, bukan sumber kebenaran |
| F2 contradictions | `canon_rules`, `canon_conflicts` + `contradiction_dismissals` | proyek | ADA + BARU dismissals (109.12–14) | dismissal = user decision ber-history |
| F4 voice | `VoiceProfiles`, `VoiceReferences`, `DialogueLines` | CHARACTER / NOVEL | **ADA** (dialogue.dart) | profil suara kanon sudah ada — F16 tinggal pakai; interview baru |
| F7 conlang | `conlangs`, `conlang_entries`, `conlang_grammar_rules`, `conlang_versions` | proyek (D-OWN-02) | BARU (109.17–19) | versi grammar = baris riwayat |
| F8 writing | `word_targets` (scope: session/scene/chapter/project), `writing_sessions`, `draft_snapshots` | NOVEL | BARU (109.20–22) | snapshot isi di file namespace novel; metadata di DB; restore selamaat buat backup |
| F9 graph | read-model saja: view/index atas link + worldbuilding_entities + relations | proyek | tanpa tabel sumber baru | cache graf rebuildable (invariant ADR) |
| F10 board | `plot_boards`, `plot_cards`, `plot_card_order` | NOVEL | BARU (109.25–27) | order = posisi eksplisit (fractional/rank), sinkron eksplisit ke scenes |
| F12 moodboard | `character_moodboard_items` + file media di namespace character | CHARACTER | BARU (109.28–29); override novel via provenance | path relatif package, hash konten, state missing-file |
| F16 spoiler | `spoiler_classifications`, `reader_clearances`, `share_packages` | NOVEL | BARU (109.30–32) | safe_default level tertinggi; revoke = status, bukan hapus |
| F17 POV | `scene_pov_assignments`, `pov_knowledge_events` | NOVEL | BARU (109.33–35) | knowledge event menunjuk timeline + sumber |
| F18 pacing | `pacing_labels` (sceneId, tension, label, sinyal durasi/kata) | NOVEL | BARU (109.36–37) | heatmap = agregasi baca-only |
| F19 export | `export_profiles`, `export_runs` (+manifest) | NOVEL | BARU (109.38–40) | output deterministik → golden-file test |
| F25 quests | `quests`, `quest_dependencies`, `quest_stakeholders`, `quest_outcomes` | NOVEL | BARU (109.41–43) | dependency DAG; alert = query unresolved |

## S4 — Referensi stabil & override (inti kontrak)

- `characterId` = UUID immutable dari Character Workspace; rename/judul ulang TIDAK
  mengubah id; semua fitur NOVEL menyimpan id, nama hanya tampilan yang diresolve saat baca.
- Override novel (misal alias panggilan khusus novel) disimpan di tabel NOVEL dengan
  provenance penuh (A-PROV); resolusi baca: override novel > canon character — tanpa
  penulisan balik ke canon.
- SNAPSHOT/FORK pada link memutus propagasi otomatis sesuai definisi ADR; FORK menulis
  entitas character baru dengan `origin='fork'` + `sourceId` link lama.

## S5 — Evolusi skema & rollback (jawaban operasional D-SCHEMA-01)

1. Increment ADDITIVE ONLY: satu langkah fitur = satu nomor skema berurutan mulai **57**,
   blok `if (from < N)` guarded mengikuti pola live; dilarang mengubah/menghapus kolom lama.
2. Regenerasi build_runner + update assertion skema di seluruh `test/` wajib dalam commit
   yang sama (pola terbukti dari sprint sebelumnya).
3. Sebelum upgrade pertama yang menaikkan versi: backup paket otomatis + drill restore
   (rincian di 109.5); proyek lama harus tetap terbuka di build baru.
4. Ratifikasi final arah skema (56→N vs beku v56) tetap milik Choirudin di gate 109.51;
   sampai itu posisi kerja = evolusi aditif kanonik.

## S6 — Peta requirement kanonik → bagian

distinct_workspace_ids→S2/A-ID+A-LINK · distinct_persistence_namespaces→S1 ·
stable_character_refs→S4 · novel_owned_overrides→S3+S4 · character_owned_canon→S2/A-CANON ·
provenance→S2/A-PROV · soft_delete→S2/A-SOFT · versioning→S2/A-VER+S5.
