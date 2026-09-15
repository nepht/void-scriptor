# HANDOFF -> CRON v4: vs-hunt-20260912-autosave fix queue
Keputusan Choi 2026-09-12 malam: eksekusi ANTREAN FIX hunt autosave menjadi milik cron v4.
Sesi interaktif ini tidak akan mengambil slice hunt ini; sesi paralel "run254" sudah berhenti menulis ke region ini.

## Status evidence (PENTING — baca sebelum eksekusi)
- Rantai 3-tahap selesai DUA kali paralel (sesi ini + run254). File committed 7f5e541 = CHIMERA:
  ledger menyebut "18 REAL / 2 dismissed", tapi referee_report_autosave.md on-disk berisi 15 REAL /
  6 NOT A BUG dengan penomoran BUG-1..21 versi SESI INI (bukan renumber run254), dan hunter_report
  on-disk salah jumlah (deklarasi 48; rekap poin nyata 58).
- Otoritas nephthys untuk antrean fix = TABEL REFEREE on-disk (baris ~255-270) yang sudah di-spot-check
  terhadap source di HEAD 86a96da, plus 2 koreksi verifikasi-independen:
  1) DraftSnapshotStore memang TIDAK pernah di-instantiate di lib/ (hanya definisi + test) -> semua
     temuan yang objeknya store itu = NOT-PRODUCTION (skeptic sesi ini benar).
  2) DurableDraftJournal.close() tidak punya caller produksi; _inFlightStages hanya tracked utk close();
     acknowledge() memakai file.delete() telanjang tanpa content guard (:214) -> jalur blind-delete
     replay (BUG-6 sesi ini) NYATA dan reachable via story_workspace_screen (draftJournal di-wire di
     workspace_resolver.dart:235).

## Antrean fix prioritas (TDD, satu slice per run, gates penuh + roadmap_guard)
A. CRITICAL data-loss:
   A1 stage(): unique per-call temp suffix sebelum rename (durable_draft_journal.dart:76-98).
   A2 coordinator: sequence/generation guard utk _pendingSceneId/_pendingContent + assign SEBELUM
      await stage() (durable_autosave_coordinator.dart:59-86); caller fire-and-forget
      story_workspace_screen.dart:322.
   A3 restore/acknowledge: content/generation guard pada delete (journal:192-215) + flush/cancel
      pending autosave sebelum restoreSceneDraftSnapshot (story_repository_impl.dart:351-380).
B. MEDIUM: dispose() flush-on-inflight + larang Timer pasca-dispose (:98-157); saveSceneDraft upsert/
   transaksi (:72-95); retention limits persisten bukan map per-instance (:69-70); mislabel error
   ack-vs-persist (:109-143); jurnal korup tak pernah pensi (quarantine) (:200-215).
C. LOW: indeks (sceneId,createdAt); _kindFromDb unknown -> throw/log; tie-breaker prune; sweep .tmp
   clock UTC; fsync documented-limitation; close() dipanggil dari lifecycle resolver atau hapus kontraknya.

## Aturan main
- Scope: 6 file di autosave_scope.json + callsites-nya; JANGAN sentuh region character (diff format-only
  sibling masih ada di worktree) sampai penulisnya commit.
- Cross-check reachability per temuan terhadap HEAD hidup sebelum menulis RED (pelajaran run251+).
- Setelah tiap slice: focused tests -> region regression -> flutter analyze -> format -> diff-check ->
  roadmap_guard -> commit scoped -> push dual-remote (izin standing). Ledger entri menyebut hunt-ID
  vs-hunt-20260912-autosave + BUG-n MERUJUK PENOMORAN REFEREE ON-DISK (sebutkan renumber run254 bila bentrok).
