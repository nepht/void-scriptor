# run311 — vs-native-20260914-run309 BUG-303-01 (Medium) CLOSED via TDD

## Bug (ditemukan sesi native run309, user-visible)
Repro native: ketik scene -> tutup aplikasi saat draf pending ada -> relaunch
-> klik "Pulihkan Draft" -> editor membisu input: ketikan pasca-restore tidak
muncul dan label beku 'Belum tersimpan'. Data DB aman (restore tersimpan).

## Akar penyebab (diverifikasi di kode HEAD 80a6467)
`_StoryWorkspaceScreenState._restorePendingDraft` (story_workspace_screen.dart):
1. `_draft.value = TextEditingValue(text: entry.content)` dipasang TANPA
   selection — baseOffset -1 (invalid). Tidak ada normalisasi caret; editor
   yang tidak memegang fokus tidak pernah memperoleh selection valid.
2. Tap 'Pulihkan Draft' memindahkan fokus ke TextButton; layar tidak punya
   FocusNode editor eksplisit sehingga fokus tidak pernah kembali ke
   TextField. Di Windows native, IME hanya mengirim ke fokus aktif ->
   ketikan tidak pernah mencapai kontrol.
3. Bonus defect kelas sama (kontrak vs-hunt-20260912-autosave BUG-5 yang
   ditegakkan untuk snapshot restore tapi TIDAK untuk journal restore):
   konten autosave yang masih menunggu debounce persist SETELAH restore dan
   menimpa hasil restore secara diam-diam di repository.

## RED (test/features/story/recovery_restore_editor_selection_run311_test.dart)
2 test, fake journal + fake repository deterministik (pola file tetangga
novel_recovery_prompt_ui_test.dart):
1. Caret: `Expected: true / Actual: false` pada `controller.selection.isValid`
   (pesan 'restore wajib menormalkan caret; selection -1 = editor bisu') +
   assert fokus editor.
2. Koordinasi: `Expected: 'Isi jurnal lama.' / Actual: 'Ketik baru pengguna'`
   — stale debounce menimpa hasil restore, tepat mekanisme silent-clobber.
Keduanya FAIL tepat mekanisme sebelum patch; pitfall dicatat: tap 'Pulihkan
Draft' pasca enterText butuh `ensureVisible` (tombol ter-scroll keluar).

## GREEN (patch minimal, lib/features/story/presentation/story_workspace_screen.dart)
- Field `_editorFocus = FocusNode(debugLabel: 'scene-draft-editor')` di-wire
  ke TextField editor (`focusNode:`) dan di-dispose setelah `_draft.dispose()`.
- `_restorePendingDraft`: save + ack content-aware dibungkus
  `_autosave.aroundExternalDraftWrite<void>(entry.sceneId, ...)` (kontrak
  BUG-5 yang sama dengan `_restoreSnapshot`); cabang scene terpilih memasang
  `TextSelection.collapsed(offset: entry.content.length)` +
  `_editorFocus.requestFocus()`.
Perilaku lama dipertahankan: ack content-aware (BUG-6 run257), jalur 'Buang'
tetap blind, guard `_recoveryBusy`, cabang non-selected scene tak berubah.

## Gates (aktual run311, HEAD masuk 80a6467, tree bersih, nol proses Flutter)
- focused: 2/2 PASS (00:01).
- region test/features/story: 216 PASS / 0 FAIL (01:33).
- regression test/features/export + durable_draft_journal + autosave
  coordinator: 69 PASS / 0 FAIL.
- dart analyze scoped (lib/features/story + test/features/story): No issues.
- dart format owned 2 file: gate CI `--set-exit-if-changed` exit 0.
- flutter analyze --no-pub FULL REPO: No issues found! (14.6s).
- git diff --check: exit 0.
- full suite + Windows debug build: lihat ledger entry run311.

## Sisa risiko
- Bukti native Windows penuh (ketikan sungguhan pasca-restore di jendela)
  butuh sesi desktop interaktif — dari cron status native = UNVERIFIABLE;
  widget test mengunci kontrak caret+fokus+koordinasi yang merupakan
  mekanisme yang dilaporkan.
- Restore entri yang scene-nya TIDAK terpilih tidak menyentuh editor (/by
  design, tidak berubah); label 'Belum tersimpan' pasca-restore masih butuh
  satu tick autosave untuk berpindah 'Tersimpan' — perilaku lama, bukan
  bagian bug ini.

## Next action
- Jalankan ulang journey run309 (relaunch -> Pulihkan Draft -> ketik) di sesi
  native Choi untuk konfirmasi visual penutup BUG-303-01.
