# Skeptic Report — vs-hunt-20260912-autosave

Peran: SKEPTIC (adversarial reviewer) atas laporan Hunter (21 temuan, 113 pts).
Format verdict mengikuti `references/skeptic.md` (danpeg/bug-hunt): Counter-argument / Evidence / Confidence / Risk calc / Decision. DISPROVE hanya bila EV positif (confidence > 67%).

Catatan basis kode: instruksi menyebut HEAD `4d905ed`; HEAD cabang saat dibaca adalah `4bc3eb9` + commit `8a73a9f`. `git diff --stat 4d905ed..HEAD` atas KEENAM file scope Hunter = KOSONG (nol baris berubah), dan worktree keenam file bersih — jadi semua pembacaan di bawah berlaku persis untuk basis `4d905ed`.

Fakta pemanggilan produksi yang dipakai berulang di verdict ini (hasil grepcallsite read-only):
- `lib/features/story/presentation/story_workspace_screen.dart:322` — `_autosave.onDraftChanged(sceneId: sceneId, content: value);` FIRE-AND-FORGET (tanpa await, tanpa guard nomor urut) dipanggil dari `_count` via `onChanged: _onDraftChanged` (baris 1684). Tidak ada listener `TextEditingController` di layar.
- `lib/features/workspace/presentation/workspace_resolver.dart` — `WorkspaceResolver extends ConsumerWidget` (baris 47) dan `build` (baris 58) MENGKONSTRUKSI ULANG `DurableDraftJournal(...)` (233-239) dan `StoryRepositoryImpl(...)` (240-245) setiap build.
- ID scene hanya diproduksi `create_story_service.createScene`: `final id = const Uuid().v4();` (baris 150) — satu-satunya `StoryScenesCompanion.insert` di seluruh `lib/` (baris 153-155).
- `DraftSnapshotStore` (domain murni) TIDAK PERNAH di-instansiasi di `lib/` — hanya di `test/features/story/draft_snapshots_test.dart`.
- Grep `.close()` di `lib/` untuk journal: tidak ada (hanya `sink.close()` internal file journal dan `close()` objek lain: db, http client, exporter, event bus).

---

**BUG-1** | Original: 5 pts
- **Counter-argument:** Klaimnya valid secara struktural: assignment state terjadi SETELAH `await _journal?.stage(...)`, dan koordinator tidak punya nomor urut/seq-guard, sementara pemanggil layar fire-and-forget — dua panggilan `onDraftChanged` benar-benar bisa interleave dan urutan completion (bukan urutan ketikan) menentukan isi `_pendingContent` terakhir. Saya mencoba membantah dengan argumen "window-nya terlalu kecil", tapi window-nya bukan nol: `stage()` melakukan multi-io await (`_dir.create`, `openWrite`, `flush`, `close`, `rename`) yang latensinya variabel (antivirus/indexer Windows terbukti nyata di repo ini — lihat ladder retry errno 32). Tidak ada disprover di kode. Yang membatasi dampak (bukan meniadakan bug): jurnal menyimpan konten dari stage yang PALING AKHIR selesai (punya `stagedAt` terbaru), dan persist berikutnya menormalkan DB — kerusakan bersifat sementara namun nyata pada DB dan pada konsistensi DB-vs-journal.
- **Evidence:** durable_autosave_coordinator.dart:78-85 — `await _journal?.stage(sceneId: sceneId, content: content);` ... `_pendingSceneId = sceneId; _pendingContent = content; _schedule();`; story_workspace_screen.dart:322 tanpa await; satu-satunya guard di `saveNow` adalah pembandingan `_pendingSceneId == savedSceneId && _pendingContent == savedContent` (baris 132-133), bukan urutan.
- **Confidence:** 80%
- **Risk calc:** EV = (80% x 5) - (20% x 10) = +2.0
- **Decision:** ACCEPT

---

**BUG-2** | Original: 10 pts
- **Counter-argument:** Saya cari pelindungnya dan tidak ada: `_inFlightStages` HANYA wadah pelacak untuk `close()` (baris 66, 72) — ia tidak.await-mengantrekan apa pun; tidak ada mutex, tidak ada per-scene queue, tidak ada temp path unik. Dua `stage()` scene yang sama yang sedang berjalan (kondisi yang justru diterima di verdict BUG-1, dan jendela rename-retry melebarkan jendela hingga ~630 ms saat `sink` stage A sudah tertutup tapi file `.tmp` masih hidup) menulis ke SATU path `<scene>.json.tmp`. Mode `FileMode.write` melakukan truncate, sehingga stage B dapat memotong payload A di tengah (`sink.write` IOSink tidak atomic), dan rename kedua menemukan source hilang -> `FileSystemException` errno 2 yang TIDAK termasuk ladder (hanya 5/32) sehingga rethrow -> stage gagal. Journal adalah last-line-of-defense no-silent-loss; kegagalan diam-diam ini serius dan korbannya persis jendela crash. Tidak ada dasar untuk DISPROVE.
- **Evidence:** durable_draft_journal.dart:78 `final temp = File('${_entryFile(sceneId).path}.tmp');`; :84 `temp.openWrite(mode: FileMode.write)`; :97 `await _renameWithWindowsSharingRetry(temp, _entryFile(sceneId).path);`; :126-134 ladder hanya `errorCode == 5 || errorCode == 32`.
- **Confidence:** 88%
- **Risk calc:** EV = (88% x 10) - (12% x 20) = +6.4
- **Decision:** ACCEPT

---

**BUG-3** | Original: 10 pts
- **Counter-argument:** Mekanisme yang DITULIS Hunter untuk jalur content-aware lemah: bila entri baru sudah menimpa file sebelum `acknowledge` membaca, maka baca memuat konten BARU, perbandingan `decoded['content'] != content` gagal, dan fungsi return — check-nya justru melindungi. Acknowledge unconditional (`entry.sceneId` tanpa content, layar 1269/1298) adalah keputusan eksplisit pengguna (pulihkan/buang) atas daftar yang dibaca segar sesaat sebelum klik — bukan silent loss. TAPI inti klaim tetap survive terhadap kode: cek dan hapus adalah dua operasi I/O terpisah TANPA penguncian terhadap `stage()`. Skenario konkret: acknowledge membaca + mencocokkan konten V1; sebelum `await file.delete()` sempat dieksekusi, stage konkuren menulis V1 (mis. undo) lalu V2 (file final = V2); delete acknowledge lalu menyapu entry V2 yang sah — suntingan terakhir kehilangan line-of-defense-nya, dan karena DB juga memuat V1, hilang total tanpa jejak. Jendela await-nya nyata pada isolate yang sama.
- **Evidence:** durable_draft_journal.dart:203-214 — `if (decoded['content'] != content) return;` (baca+cek) lalu ... `await file.delete();` — tanpa lock; interleave `stage()` paralel diterima dari verdict BUG-1/BUG-2; jalur unconditional di story_workspace_screen.dart:1269, 1298.
- **Confidence:** 70%
- **Risk calc:** EV = (70% x 10) - (30% x 20) = +1.0
- **Decision:** ACCEPT

---

**BUG-4** | Original: 5 pts
- **Counter-argument:** Fakta kodenya persis seperti klaim dan tidak terbantahkan: `dispose()` = `_timer?.cancel(); await saveNow();` dan `saveNow` yang dipanggil saat `_saving` hanya set `_retryRequested = true; return;` — dispose selesai sebelum save in-flight selesai (kontrak "flush sebelum tutup" jebol di jalur itu), dan `finally` (144-149) dapat memanggil `_schedule()` SETELAH semua awaiter dispose selesai, menghidupkan timer yang fire ~1,5 s kemudian di object yang layarnya sudah mati. Saya pertimbangkan DISPROVE atas dasar "dampaknya benign": timer pasca-dispose justru menyimpan draf terakhir (persist via closure `widget.repository` yang masih hidup; callback layar dijaga `if (!mounted) return`), jadi tidak ada korupsi data — tetapi (a) itu tetap violate kontrak yang didokumentasikan sendiri di header file (baris 16-18), (b) menulis setelah layar tutup membuat status 'Tersimpan' tak pernah terlihat dan bisa race dengan penutupan proyek (DB bisa ditutup sebelum persist sempat jalan -> uncaught), (c) tidak ada flag `_disposed` sama sekali. Tidak cukup yakin bug ini false positive untuk melewati ambang 67%.
- **Evidence:** durable_autosave_coordinator.dart:100-103 `if (_saving) { _retryRequested = true; return; }`; :144-149 `finally { _saving = false; if (_retryRequested) { ... _schedule(); } }`; :154-157 `dispose()`; layar:304 `_autosave.dispose();` TIDAK di-await di dalam `void dispose()`.
- **Confidence:** 68%
- **Risk calc:** EV = (68% x 5) - (32% x 10) = +0.4
- **Decision:** ACCEPT

---

**BUG-5** | Original: 5 pts
- **Counter-argument:** Interleaving dua `saveSceneDraft` konkuren benar-benar ada jalurnya di SATU isolate: `get` select dan `insert` dipisah await boundary, jadi dua pemanggil yang overlap untuk scene yang BELUM punya baris draft sama-sama melihat `existing == null` lalu beradu INSERT dengan PK deterministik `'${sceneId}_draft'` -> `SqliteException` constraint-violation. Pemanggil yang overlap itu nyata: persist debounce (closure layar:248), tombol 'Simpan ulang' (`onPressed: () => _autosave.saveNow()`, layar:1729 yang dengan `_saving` saat itu juga membuat save kedua berjalan sekuensial OK, tapi `_restorePendingDraft` (layar:1268) menulis repository LANGSUNG tanpa lewat koordinator, dan tombol Restore/Restore-pending bisa diklik selama debounce persist sedang berlangsung. Tidak ada `transaction()` maupun `insertOnConflictUpdate` (preseden pola aman justru dipakai di file sebelah, create_story_service.dart:196). Konsekuensinya gagal-simpan dengan banner (bukan korup) — severity Medium wajar, bukan Critical.
- **Evidence:** story_repository_impl.dart:72-94 — select `getSingleOrNull()` -> if null `insert(SceneBeatsCompanion.insert(id: '${sceneId}_draft', ...))` else update; tanpa transaction; callsite paralel story_workspace_screen.dart:248 vs :1268.
- **Confidence:** 72%
- **Risk calc:** EV = (72% x 5) - (28% x 10) = +0.8
- **Decision:** ACCEPT

---

**BUG-6** | Original: 10 pts
- **Counter-argument:** Saya coba patahkan dengan memeriksa apakah pending lama benar-benar bisa menimpa hasil restore. `restoreSceneDraftSnapshot` tidak menyentuh koordinator sama sekali (grep: nol interaksi), dan UI restore menulis editor lewat `_draft.value = ...` (layar:1472) yang TIDAK memicu `onChanged` (TextField onChanged hanya untuk input pengguna — controller yang di-set programatis tidak memanggilnya; tidak ada `addListener` pada `_draft`). Sisa `_pendingContent` dari sebelum restore tetap ada di koordinator: bila debounce fire SETELAH restore menulis DB, persist menyimpan teks LAMA ke repository — hasil restore tertimpa. Satu pembatas yang saya temukan (bukan disprover): dalam kondisi normal `_pendingContent` == teks yang sudah ter-persist sebelum restore, sehingga write ulang bersifat no-op; kerugian data nyata muncul saat restore diklik di tengah jendela debounce (sejak keystroke terakhir < 1,5 s) dengan teks pasca-restore yang lebih baru — window sempit tapi nyata, dan callback persist closure memakai `widget.repository` yang tetap hidup. Bagian kedua klaim (entri journal basi tetap ditawarkan) juga valid untuk jalur snapshot-restore: `restoreSceneDraftSnapshot` tidak acknowledge jurnal, sedangkan jalur `_restorePendingDraft` sendiri sudah benar (save dulu, acknowledge kemudian, dan ia sendiri yang memicu timer debounce lewat `onDraftChanged`? — tidak: ia menulis `_draft.value` langsung (layar:1272) tanpa memanggil `onDraftChanged`, sehingga pending jurnal entri itu sudah dihapus dan DB sudah cocok — tidak ada tambahan kerugian di jalur itu). Overall: cacat nyata pada ketiadaan flush/invalidasi state koordinator saat restore; severity Critical agak tinggi tapi klaimnya bukan false positive.
- **Evidence:** story_repository_impl.dart:351-380 (tanpa referensi koordinator/journal sama sekali); layar:1460-1484 `_restoreSnapshot` -> `_draft.value = ...` tanpa `_autosave.saveNow()`/`onDraftChanged`; koordinator menyimpan `_pendingSceneId/_pendingContent` lintas restore (baris 54-55, 132-136).
- **Confidence:** 70%
- **Risk calc:** EV = (70% x 10) - (30% x 20) = +1.0
- **Decision:** ACCEPT

---

**BUG-7** | Original: 5 pts
- **Counter-argument:** Premis "begitu baris duplikat terbentuk" TIDAK punya jalur pembentukan di production wiring, dan itu bisa dibuktikan positif, bukan diasumsikan: (1) satu-satunya writer `beatType='draft'` adalah `saveSceneDraft` dengan id DETERMINISTIK `'${sceneId}_draft'` — select-then-insert yang kalah balap sekalipun menabrak PK yang SAMA (satu baris, bukan duplikat) — bug race-nya adalah BUG-5, bukan duplikasi; (2) Hunter sendiri menunjuk `addBeat(beatType: 'draft')` sebagai mekanisme, tapi UI `scene_workspace_screen._addBeat` memanggil `.addBeat(sceneId: widget.sceneId, content: content)` TANPA beatType (default 'action', create_story_service.dart:211); grep `beatType:` di seluruh `lib/` menunjukkan tidak ada SATU pun pemanggil yang pernah mengirim `'draft'`; (3) `id` UUIDv4 dari `createScene` tidak pernah bernilai `'..._draft'` milik scene lain, dan tidak ada kode yang menghapus scene (grep `delete(sceneScenes`, `deleteScene` = nol) sehingga id lama tak dapat di-reuse; (4) tidak ada importer yang menulis `story_scenes`/`scene_beats` dengan id eksternal (satu-satunya `StoryScenesCompanion.insert` di lib adalah createScene). Tanpa duplikat yang dapat terbentuk, `getSingleOrNull()` tak pernah melihat >1 baris dan StateError permanen yang diklaim tidak terjangkau. Sisa risikonya hanya DB yang diedit manual di luar aplikasi — di luar kontrak production wiring.
- **Evidence:** create_story_service.dart:208-229 (beatType parameter tak pernah diisi 'draft'); story_workspace_screen.dart:111-142 (UI addBeat tanpa beatType); story_repository_impl.dart:84 (id deterministik); grep `delete(sceneScenes` -> nol hasil.
- **Confidence:** 80%
- **Risk calc:** EV = (80% x 5) - (20% x 10) = +2.0
- **Decision:** DISPROVE

---

**BUG-8** | Original: 5 pts
- **Counter-argument:** Tidak ada disprover di kode: ORDER BY tunggal `createdAt` (naik), dan `createdAt` diisi `DateTime.now()` wall-clock lokal presisi milidetik; `take(excess)` memotong dari kepala (tertua-menurut-jam). Jam Windows bisa mundur (NTP/DST/manual) dan dua capture dalam milidetik sama terurut nondeterministik (UUID id bukan tie-breaker monotonik — SQLite rowid tidak di-select ke urutan). Hasilnya: snapshot paling baru bisa jadi yang pertama dipangkas. Probabilitasnya rendah tetapi klaimnya adalah kebenaran struktural "satu-satunya penanda urutan adalah jam sistem" — dan untuk fitur snapshot cadangan-naskah, memangkas yang SALAH adalah kerugian data permanen. Tabel punya kolom rowid implisit yang bisa jadi tie-breaker; ketiadaannya di urutan = gap nyata.
- **Evidence:** story_dao.dart:72-76 `..orderBy([(t) => OrderingTerm(expression: t.createdAt)])`; story_repository_impl.dart:306, 374 `createdAt: DateTime.now()`; :319 `all.take(excess)`; scene_draft_snapshots.dart:15 `DateTimeColumn get createdAt => dateTime()();` tanpa autoincrement.
- **Confidence:** 72%
- **Risk calc:** EV = (72% x 5) - (28% x 10) = +0.8
- **Decision:** ACCEPT

---

**BUG-9** | Original: 5 pts
- **Counter-argument:** Klaim tervalidasi penuh oleh wiring: `_retentionLimits` hanya `Map` per-instance (baris 70) dan `_enforceRetention` no-op saat `limit == null` (313-315), sementara `WorkspaceResolver` adalah `ConsumerWidget` yang `build`-nya (baris 58) mengkonstruksi `StoryRepositoryImpl(...)` BARU setiap rebuild — setiap rebuild parent/`ref` mengganti `widget.repository` di layar (initState TIDAK meng-cache instance; semua handler memakai `widget.repository`). Praktisnya: setelah `setDraftSnapshotRetention` melakukan trim sekali di tempat, instance berikutnya tidak tahu apa-apa dan capture-capture berikutnya tidak pernah dipangkas lagi. Tidak ada persistensi batas di DB/schema. Tidak ada dasar disprove.
- **Evidence:** workspace_resolver.dart:47,58,240-245; story_repository_impl.dart:69-70, 313-315, 384-393.
- **Confidence:** 85%
- **Risk calc:** EV = (85% x 5) - (15% x 10) = +2.75
- **Decision:** ACCEPT

---

**BUG-10** | Original: 5 pts
- **Counter-argument:** Sesuai kode: `captureSceneDraftSnapshot` membaca `getSceneDraft(sceneId)` dari DB (baris 292) dan API-nya tidak menerima konten dari pemanggil; UI `_showSnapshotDialog` (layar:1409-1453) tidak mem-flush `_autosave` sebelum capture (grep callsite: tidak ada `saveNow()` di jalur itu — hanya tombol banner error:1729). Dalam jendela debounce 1,5 s pasca-keystroke, snapshot yang dihasilkan adalah teks lama, dan saat persist sedang error (banner aktif) snapshot bahkan lebih basi lagi — padahal kontrak kanonik menyebut snapshot = rekaman "teks kini" verbatim (dok file: 'konten verbatim'). Mitigasi yang saya cek: tidak ada kerugian data (teks terbaru masih di editor + journal), hanya artefak snapshot yang tidak mewakili momen klik. Severity Medium tepat; klaim bukan false positive.
- **Evidence:** story_repository_impl.dart:287-295; layar:1440-1453 (dialog -> capture tanpa flush); tidak ada `updateCurrent`/`_pendingContent` yang di-pass ke capture.
- **Confidence:** 80%
- **Risk calc:** EV = (80% x 5) - (20% x 10) = +2.0
- **Decision:** ACCEPT

---

**BUG-11** | Original: 5 pts
- **Counter-argument:** Ini kritik desain terhadap kode MATI, bukan bug perilaku sistem. `DraftSnapshotStore` tidak pernah di-instansiasi di `lib/` (grep: hanya `test/features/story/draft_snapshots_test.dart`) — tidak ada satu pun jalur produksi yang bisa "tidak pernah mencatat draf kosong" lewat store ini; sistem nyata menyimpan draf kosong dengan baik (`saveSceneDraft('')` tak dibatasi; koordinator justru MEMPERLAKUKAN kosong sebagai transisi sah di :76 dan :122). Argumen Hunter sendiri ("seharusnya sama dengan layer koordinator") salah layer: koordinator + repository adalah stack produksi; store 109.22 adalah kontrak domain murni hasil TDD sprint yang di-ACCEPT ledger dengan guard `current text must not be empty` sebagai perilaku tersurat yang dikehendaki (ledger 109.22: 'teks kini' = naskah; `setRetention` juga 'dikeraskan' mengikuti tes). Dan klaim 'dipulihkan lewat kontrak ini' bahkan keliru di dalam kontrak itu sendiri: `captureManual` TIDAK menolak konten kosong (tak ada guard) — hanya `updateCurrent`. Sisa-sisa ketidakselarasan ini tidak punya efek teramati di produk.
- **Evidence:** draft_snapshots.dart:97-104 vs :129-147 (captureManual tanpa guard konten); grep `DraftSnapshotStore(` di lib -> nol; ledger sprint-109 baris 34 memverifikasi perilaku ini sebagai penerimaan.
- **Confidence:** 72%
- **Risk calc:** EV = (72% x 5) - (28% x 10) = +0.8
- **Decision:** DISPROVE

---

**BUG-12** | Original: 5 pts
- **Counter-argument:** Sekali lagi menargetkan domain store yang tidak dipakai produksi, dan menuntut perilaku yang TIDAK pernah menjadi kontraknya. Teks kanonik retention_controls (docs/sprints/sprint-109, ledger 109.22): "batas per draf memangkas tertua; teks kini tak tersentuh; limit non-positif ditolak ArgumentError" — dan tesnya (`retention_controls` di draft_snapshots_test.dart) menetapkan limit SEBELUM capture apa pun lalu memverifikasi pemangkasan pada capture; tidak ada acceptance yang menuntut trim-immediat-saat-batas-diturunkan. Docstring `setRetention` juga tidak menjanjikannya. Hunter membandingkannya dengan `setDraftSnapshotRetention` di lapisan repository (yang memang trimmed即时, karena lapisan itu yang melayani UI) dan menyebut 'dua implementasi kontrak sama berperilaku beda' — tetapi tes yang di-verify hanyalah baseline behavior store, bukan klaim produk. Konsekuensi terlemahnya: store tidak terpakai -> nol dampak pengguna. Di bawah ambang 67% untuk 'bukan bug'? Perhitungan: keyakinan saya bahwa ini bukan defect = 74%.
- **Evidence:** draft_snapshots.dart:149-156; draft_snapshots_test.dart group retention_controls; story_repository_impl.dart:382-393; grep instansiasi store di lib -> nol.
- **Confidence:** 74%
- **Risk calc:** EV = (74% x 5) - (26% x 10) = +1.1
- **Decision:** DISPROVE

---

**BUG-13** | Original: 5 pts
- **Counter-argument:** Fungsinya memang tidak injektif secara matematis, TAPI premis "dua sceneId berbeda berbagi satu file" tidak terjangkau di produksi: satu-satunya generator ID scene adalah `Uuid().v4()` (create_story_service.dart:150; satu-satunya insert `story_scenes` di `lib/`), yang charset-nya hex + tanda hubung `-` — dan `-` TERMASUK whitelist `[A-Za-z0-9_-]`, sehingga `_safeSceneId` adalah IDENTITY pada seluruh ruang ID yang dapat dihasilkan sistem (dua UUIDv4 berbeda tidak pernah collide setelah filter). Tidak ada jalur yang memberi sceneId arbitrer ke journal: jurnal hanya di-stage dengan `_selectedSceneId`/`entry.sceneId` yang berasal dari DB/import paket proyek itu sendiri (UUID juga). Klaim 'acknowledge ikut menghapus file scene lain' ikut runtuh karena tidak ada pasangan sceneId yang ter-folding. Hunter bahkan memberi contoh `scene.a`/`scene/a` — bentuk itu tidak dapat diciptakan aplikasi.
- **Evidence:** durable_draft_journal.dart:52-53; create_story_service.dart:143-167; grep callsite stage/acknowledge -> sceneId selalu dari model scene UUID.
- **Confidence:** 85%
- **Risk calc:** EV = (85% x 5) - (15% x 10) = +2.75
- **Decision:** DISPROVE

---

**BUG-14** | Original: 5 pts
- **Counter-argument:** Perilaku default-arm persis seperti dikutip, dan tidak ada CHECK constraint di kolom kind (scene_draft_snapshots.dart:12). Counter saya: saat ini tidak ada PRODUSEN kind tak dikenal di dalam aplikasi — semua insert menulis `kind.name` (auto|manual) atau literal 'restoreBackup' — sehingga mislabel hanya terjadi pada data korup/masa depan. Tetapi justru itu isi claim-nya: korup/migrasi tak valid_disembunyikan sebagai label restoreBackup yang tampak sah di panel pemulihan, alih-alih ditolak/di-surface (dan pola repo untuk korup justru 'jangan sembunyikan' — lihat `PendingDraftEntry.corrupt`, no-silent-loss). Ini defect defensibility/error-handling kecil yang faktual di kode, bukan false positive; severity Medium di sisi atas tapi dapat diperdebatkan Low. ACCEPT (tidak yakin cukup tinggi untuk membantah).
- **Evidence:** story_repository_impl.dart:340-349 `default: return DraftSnapshotKind.restoreBackup;`; tabel tanpa constraint; bandingkan filosofi no-silent-loss durable_draft_journal.dart:171-186.
- **Confidence:** 70%
- **Risk calc:** EV = (70% x 5) - (30% x 10) = +0.5
- **Decision:** ACCEPT

---

**BUG-15** | Original: 5 pts
- **Counter-argument:** Tidak ada bantahan yang tersedia — semuanya terverifikasi: `captureSceneDraftSnapshot` punya parameter `kind` dengan default manual, tetapi grep seluruh `lib/` menemukan SATU callsite produksi (story_workspace_screen.dart:1445) yang tidak pernah mengirim `kind` lain, dan `DraftSnapshotKind.auto` hanya muncul di definisi enum + `captureAuto` (store mati). Layer persistensi mengklaim mengikuti 'kontrak DraftSnapshotStore' (komentar baris 286 + doc tabel) sementara kemampuan kanonik #1 (automatic_snapshot) tidak pernah dipancarkan dari jalur persistensi — sehingga `_enforceRetention` untuk stream auto benar-benar menganggur. Gap klaim-kontrak vs implementasi ini nyata di wiring, bukan spekulasi. (Hunter tidak mengklaim ini data loss — benar, kategorinya logic/fitur.)
- **Evidence:** story_repository_impl.dart:287-291; layar:1445; grep `DraftSnapshotKind.auto` -> hanya 2 hasil non-produksi.
- **Confidence:** 85%
- **Risk calc:** EV = (85% x 5) - (15% x 10) = +2.75
- **Decision:** ACCEPT

---

**BUG-16** | Original: 1 pts
- **Counter-argument:** Fakta kodenya benar (tanpa FK, tanpa indeks — satu baris tabel). Saya periksa dua bantahan potensial. Bantahan pertama (klaim Hunter soal pola tabel lain) gugur: grep `.references(` di `lib/database/project/tables/` = NOL — FK bukan konvensi repo ini, jadi 'bandingkan pola lazim' salah fakta. Bantahan kedua lebih kuat: 'snapshot yatim (scene dihapus)' saat ini TIDAK dapat terjadi karena tidak ada satu pun jalur hapus scene di `lib/` (grep `deleteScene`/`delete(storyScenes` -> nol; DAO `deleteSceneDraftSnapshotsForScene`/`...Before` tersedia tapi tak berpemanggil produksi), dan 'full-scan' untuk DB per-proyek dengan puluhan snapshot praktis nol dampaknya. Namun inti klaim tetap benar secara apa-adanya: tabel aset-naskah-penting tanpa relasi dan tanpa indeks pembersihan; kerugian barunya laten (menunggu fitur hapus scene pertama) dan cleanup-helper yang tak terhubung adalah temuan hygiene yang sama validnya. Untuk 1 pt, klaimnya tidak memuat mekanisme mustahil — di bawah ambang 67% untuk dibantah dengan aman. ACCEPT dengan catatan: dua sub-klaim dampaknya (yatim, full-scan) saat ini tidak termanifestasi.
- **Evidence:** scene_draft_snapshots.dart:8-19; story_dao.dart:81-97 (deleter tanpa callsite produksi); grep `references(` di tables -> nol.
- **Confidence:** 62%
- **Risk calc:** EV = (62% x 1) - (38% x 2) = -0.14
- **Decision:** ACCEPT

---

**BUG-17** | Original: 1 pts
- **Counter-argument:** Kode persis seperti dikutip: `diffWithCurrent` memakai `_stateFor` (creator bersisi-efek) tanpa `_requireCurrent`, `state.current` default `''`, dan indeks mentang-mentah ke `List` -> `RangeError` tanpa pesan. Fakta bahwa store ini tidak terhubung produksi membatasi DAMPAKNYA, tetapi claim-nya error-handling pada API publik yang sudah diuji dan akan dipakai lapisan integrasi ('persistensi DB/UI menyusul' — baris 77), dan inkonsistensi internal dengan `captureAuto`/`restoreTo` nyata. Tidak layak dibantah pada 1 pt.
- **Evidence:** draft_snapshots.dart:168-171 vs :115-116, :209-210, :70-72.
- **Confidence:** 70%
- **Risk calc:** EV = (70% x 1) - (30% x 2) = +0.1
- **Decision:** ACCEPT

---

**BUG-18** | Original: 5 pts
- **Counter-argument:** Klaim 'tumbuh TANPA BATAS meski batas retensi aktif' dan 'tidak pernah dipangkas selamanya' TERBANTAHKAN oleh kode dalam satu langkah: baris `restoreBackup` ditulis ke tabel yang sama (`insertSceneDraftSnapshot`), dan `getSceneDraftSnapshots` TIDAK memfilter kind — `restoreBackup` ikut masuk daftar `all` yang dihitung dan dipangkas oleh `_enforceRetention` pada capture berikutnya (story_repository_impl.dart:316-321). Jadi setelah restore: daftar boleh overshoot +1 selama sesaat, lalu kembali dibatasi begitu capture berikutnya terjadi. Persis itu pula yang ditulis docstring domain — 'dikecualikan dari pemangkasan retensi PADA SAAT ITU' — Hunter sendiri mengutip pengecualiannya lalu salah menyimpulkannya jadi pengecualian permanen. Untuk sisi domain store (kode tak terpakai produksi), perilaku tanpa-trim-at-restore itu tersurat di kontrak internalnya dan spec kanonik tidak menuntut trim pada operasi restore (restore = operasi non-destruktif yang wajib mencadangkan; memotong backup yang BARU dibuat saat restore justru melawan tujuan cadangan). Tidak ada kerugian data: limit tetap ditegakkan pada stream capture. Keyakinan 'bukan bug' > ambang.
- **Evidence:** story_repository_impl.dart:364-377 (insert restoreBackup ke tabel yang sama) -> :309/:313-321 (_enforceRetention menghitung SEMUA kind, urut createdAt); draft_snapshots.dart:206-221 docstring vs klaim; ledger sprint-109 acceptance restore_creates_backup.
- **Confidence:** 75%
- **Risk calc:** EV = (75% x 5) - (25% x 10) = +1.25
- **Decision:** DISPROVE

---

**BUG-19** | Original: 5 pts
- **Counter-argument:** Ketiga kaki klaim saya verifikasi dan semuanya benar: (1) `close()` tidak pernah dipanggil di `lib/` — grep `.close()` menemukan hanya sink/exporter/db/eventBus; (2) satu-satunya konstruktor jurnal adalah `workspace_resolver.dart:233-239` yang dievaluasi ulang per `build` ConsumerWidget; (3) `_staleTmpSwept` dan `_inFlightStages` per-instance, jadi semantik 'sweep sekali' dan 'drain sebelum tutup' (perbaikan bug-hunt-run197 BUG-4) tidak pernah ditegakkan di produksi — setiap rebuild meninggalkan instance lama tanpa drain dan membuat instance baru yang flag sweep-nya reset (sweep berulang lintas instance tetap aman secara I/O, tapi jaminan yang ditulis di komentar tidak ada gunanya). Bantahan potensial 'dampaknya nol karena objek jurnal stateless' hanya benar sebagian: tidak ada kebocoran handle, memang, tapi guarantee yang dijanjikan komentar run197 adalah kontrak yang kini mati — itu sendiri defect wiring (bukan data-loss; severity Medium di sisi atas). ACCEPT.
- **Evidence:** durable_draft_journal.dart:37-41, 47, 220-232; workspace_resolver.dart:58, 233-239; grep close() -> nol callsite jurnal.
- **Confidence:** 75%
- **Risk calc:** EV = (75% x 5) - (25% x 10) = +1.25
- **Decision:** ACCEPT

---

**BUG-20** | Original: 5 pts
- **Counter-argument:** Fakta kode terverifikasi semua: `acknowledge` memakai `await file.delete()` telanjang (:214) sementara rename punya ladder ERROR_SHARING_VIOLATION (:97/:110-136) — asimetri nyata di file yang sama; dan di koordinator, acknowledge + `onSaved` berada DALAM blok try yang sama dengan persist (:109-142), sehingga kegagalan delete memicu `onPersistError` -> banner 'Gagal menyimpan draf' padahal konten sudah durable di DB, plus entri jurnal basi tersisa. Saya cek eksposur 'double-apply': entri basi itu memuat konten yang SAMA dengan yang sudah tersimpan, dan `_restorePendingDraft` menulis konten itu lagi (idempoten secara isi) — jadi kerugian utamanya adalah status palsu + prompt recovery basi, bukan korup teks; dan pemicunya butuh sharing-violation pada DELETE (AV/indexer menahan file sesaat) yang frekuensinya jelas lebih rendah dari rename. Tetap: jalur gagal-salah-label ini nyata, asimetri retry-nya jelas bukan disengaja (komentar ladder menyebut jalur no-silent-loss), dan Hunter tidak melebih-lebihkan mekanismenya. ACCEPT.
- **Evidence:** durable_draft_journal.dart:200-215; durable_autosave_coordinator.dart:110-142; layar:269.
- **Confidence:** 72%
- **Risk calc:** EV = (72% x 5) - (28% x 10) = +0.8
- **Decision:** ACCEPT

---

**BUG-21** | Original: 1 pts
- **Counter-argument:** Premis teknis benar (wall clock + `stat.modified` adalah satu-satunya pelindung), tetapi skenario kerusakannya tidak memenuhi syarat yang dituliskan kode sendiri, dan dampak terburuknya bukan 'kegagalan diam-diam': (1) sweep hanya berjalan SEKALI PER INSTANCE (`_staleTmpSwept` guard :245-246) dan pemicu produksinya satu-satunya adalah `_loadPendingRecovery()` saat layar dibuka (layar:1254) — supaya writer hidup terhapus, `.tmp`-nya harus tertahan > 60 detik TEPAT saat recovery panel sedang dimuat; sementara jendela tulis `.tmp` normal adalah milidetik (diakui di komentar desain :26-28, :43-45) dan bahkan rename dengan ladder retry penuh hanya ~0,72 s; (2) kalaupun kena, `source.rename` gagal dengan `FileSystemException` errno 2 yang TIDAK senyap — ia mengalir ke `onPersistError` (banner terlihat + draf tetap pending + DB menyimpan saat debounce berikutnya): kegagalan stage yang visible, bukan silent loss; (3) clock-rewind tidak relevan karena perbandingan memakai selisih satu snapshot `now` vs mtime — kemunduran jam justru MELEBARKAN usia semu hanya bila mundur terjadi di antara keduanya dan tetap terkurung probabilitas yang sama kecilnya. Kombinasi 'prasyarat mustahil relatif desain + kegagalan tetap visible + didokumentasikan eksplisit sebagai asumsi single-writer best-effort' membuat ini limitation yang sudah diterima penulis kode, bukan bug. Confidence disprove 70% (>67%).
- **Evidence:** durable_draft_journal.dart:234-259 (guard + docstring asumsi); layar:1251-1257 (satu-satunya pemicu); ladder retry max 630 ms di :114-121.
- **Confidence:** 70%
- **Risk calc:** EV = (70% x 1) - (30% x 2) = +0.1
- **Decision:** DISPROVE

---

**SUMMARY:**
- Bugs disproved: 6 (BUG-7, BUG-11, BUG-12, BUG-13, BUG-18, BUG-21; total points claimed: 26)
- Bugs accepted as real: 15 (total points claimed: 87)
- Your final score: +26

**ACCEPTED BUG LIST:**
- BUG-1 (Medium, 5) — race urutan `onDraftChanged` tanpa seq-guard: `_pendingContent` ditentukan urutan selesai.
- BUG-2 (Critical, 10) — dua `stage()` paralel scene sama berbagi satu `<scene>.json.tmp` tanpa mutex; rename kedua gagal permanen (errno 2 tak di-retry).
- BUG-3 (Critical, 10) — acknowledge read-then-delete tanpa lock vs stage konkuren: jendela hapus entri jurnal teranyar.
- BUG-4 (Medium, 5) — `dispose()` kembali saat save in-flight; timer retry dapat di-schedule SETELAH dispose; tak ada `_disposed`.
- BUG-5 (Medium, 5) — select-then-insert `saveSceneDraft` tanpa transaction/upsert; dua writer sah (persist autosave vs `_restorePendingDraft`) bisa tabrakan PK draft.
- BUG-6 (Critical, 10) — jalur restore snapshot tidak mem-flush/invalidasi pending koordinator: debounce lama bisa menggerojok hasil restore; entri jurnal basi tak dibersihkan jalur snapshot-restore.
- BUG-8 (Medium, 5) — urutan retensi hanya wall-clock `createdAt` tanpa tie-breaker monotonik; clock rewind/kolisi ms memangkas snapshot yang salah.
- BUG-9 (Medium, 5) — batas retensi hanya di memori per-instance `StoryRepositoryImpl` yang dikonstruksi ulang tiap build resolver; retensi mati pasca-set.
- BUG-10 (Medium, 5) — snapshot manual merekam draf TER-PERSIST dari DB, bukan teks editor terkini; tanpa flush sebelum capture.
- BUG-14 (Medium, 5) — kind tak dikenal dipetak diam-diam ke `restoreBackup` (default arm tanpa CHECK), bertentangan dengan filosofi no-silent-loss repo.
- BUG-15 (Medium, 5) — `automatic_snapshot` tidak pernah dipancarkan jalur persistensi (tak ada callsite `kind: auto`); klaim kepatuhan kontrak tidak berlaku.
- BUG-16 (Low, 1) — tabel snapshot tanpa FK/indeks; helper pembersih (`deleteSceneDraftSnapshotsForScene/Before`) tanpa pemanggil produksi (catatan skeptic: dampak yatim/full-scan laten, belum termanifestasi karena tak ada fitur hapus scene).
- BUG-17 (Low, 1) — `diffWithCurrent` tanpa `_requireCurrent` (silent-empty diff) dan `RangeError` mentah untuk indeks luar.
- BUG-19 (Medium, 5) — `DurableDraftJournal.close()` tak pernah dipanggil produksi; instance baru per build; drain-guarantee run197 + flag per-instance kehilangan makna.
- BUG-20 (Medium, 5) — `acknowledge`/`file.delete()` tanpa sharing-retry padahal rename punya; kegagalan hapus dilaporkan sbg 'Gagal menyimpan' dan meninggalkan entri jurnal basi.
