# Arsip Otorisasi & Handoff Cron v4 (dipindahkan dari prompt cron 2026-09-15)

Dokumen ini adalah salinan verbatim (dengan perbaikan encoding) dari seluruh instruksi historis yang pernah ditumpuk ke prompt cron `Void Scriptor Core Worker v4`. Isinya BUKAN instruksi default: baca bagian yang relevan hanya ketika slice menyentuh region tersebut. Aturan wajib setiap run tetap `.hermes/AUTONOMOUS_ROADMAP_PROMPT.md`. Tidak ada hak veto, otorisasi, atau fakta bukti yang dihapus dari sini; pemindahan ke arsip bukan pencabutan izin.

## 2026-09-16 — Otorisasi tetap adopsi dan reparasi WIP kanonik

Pengguna memerintahkan Hermes melakukan adopsi dan perbaikan dengan izin eksplisit yang selalu diizinkan. Otorisasi ini berlaku sekarang dan pada run berikutnya untuk WIP yang tepat sesuai `next_step` kanonik aktif, setelah worker membuktikan tidak ada penulis hidup, merekam fingerprint, dan membuat snapshot recoverable. Dirty/untracked atau PID umum saja bukan alasan menunggu tanpa batas. Worker wajib mempertahankan perubahan existing, melakukan patch minimal, menguji, merekonsiliasi ledger/state/guard, dan commit hanya path slice. Scratch/probe boleh dihapus hanya setelah bukti berguna dipindahkan ke test resmi. Jika syarat aman terpenuhi, Hermes tidak perlu meminta izin adopsi/reparasi lagi. Push, release, perubahan akun/keamanan, penghapusan data pengguna, dan fault test destruktif tetap tidak diizinkan.

Instruksi langsung saat otorisasi diberikan: selesaikan WIP 111.43 Accessibility & Localization yang terdiri dari satu file domain dan tiga file test/probe; perbaiki kegagalan compile, selaraskan kontrak enum/test, konsolidasikan probe bertanda DELETE, jalankan gate, update ledger/state, roadmap guard, dan commit scoped.

---

PROSEDUR PRIORITAS PENGGUNA — 2026-09-04: menuntaskan hambatan 145.27

Instruksi ini mengatur urutan remediasi Core, bukan membuat sprint baru, mengubah kontrak immutable, atau menyatakan 145.27 selesai. Baca ulang kode dan ledger terkini; ringkasan run lama bukan otoritas. Jangan memperluas modul sebelum alur kerja inti berikut terbukti.

Urutan kerja:
1. Keamanan draf saat berpindah workspace: reproduksi mengetik -> Character/Worldbuilding -> kembali ke Novel melalui jalur navigasi produksi. Uji penyimpanan tertunda dan kegagalan persist. Jangan membuang draf atau melanjutkan perpindahan tanpa penanganan kegagalan yang terlihat. Gunakan proyek temporer, bukan naskah pengguna. Petakan pekerjaan ke kontrak 145.24/145.28/145.30 sebagai dependensi 145.27 tanpa memindahkan pointer diam-diam.
2. Pemulihan pilihan saat katalog masih loading: audit focusExplorerAsset dan SelectionController. Tunggu katalog siap, pulihkan pilihan terakhir hanya jika proyek dan workspace masih sama, tolak hasil async yang terlambat setelah perpindahan lain, tangani error/retry, daftar kosong, dan aset terhapus. Uji klik cepat lintas workspace dan pergantian proyek. Ingatan pilihan yang sudah ada dalam sesi bukan bukti persistence setelah restart.
3. Pemisahan workspace nyata: Novel berfokus pada bab/adegan dan naskah; Character pada profil/relasi/catatan; Worldbuilding pada lokasi/faksi/timeline/lore. Gunakan editor dan repository yang sudah ada. Pisahkan navigasi, panel relevan, serta state pilihan per workspace; jangan sekadar mengganti header atau menampilkan tab mati. Data tetap satu sumber per proyek, tanpa duplikasi karakter/lore.
4. Pemulihan setelah restart: simpan workspace dan identitas aset/adegan terakhir pada penyimpanan proyek yang sesuai. Validasi id, schema, aset terhapus, proyek berbeda, dan kegagalan baca. Posisi kursor/panel hanya dinyatakan tersedia jika diimplementasikan dan diuji. Petakan acceptance pada kontrak yang ada sebelum mengubah kode.
5. Pembatasan non-Core: audit menu serta direct route/deep link secara seragam; feature flags harus konsisten. Jangan menghapus implementasi deferred atau membuka Cloud/Auth sebagai syarat menulis lokal.
6. Pembuktian Windows: create project -> write -> switch workspaces -> close/reopen -> export -> backup/restore menggunakan data uji. Build atau widget test bukan bukti interaksi native. Gunakan toolset computer_use untuk pembuktian GUI native bila sesi desktop interaktif tersedia; gunakan hanya project dan data uji temporer, jangan menyentuh naskah pengguna. Jika desktop terkunci, aplikasi tidak dapat diluncurkan, atau computer_use gagal, catat UNVERIFIABLE beserta bukti dan jangan mengklaim GUI telah diuji.

Aturan anti-berputar:
- Pada awal run pilih SATU gap prioritas tertinggi yang belum terbukti dan aman dikerjakan. Jika gap itu terblokir, jelaskan bukti blocker lalu pilih gap independen berikutnya yang masih dalam kontrak. Jangan mengulang slice yang sudah lulus tanpa perubahan relevan.
- Untuk setiap slice rekam: gap, acceptance yang dipetakan, RED, patch minimal, GREEN/regression, file milik slice, command+exit, sisa risiko, dan next action. Catatan ringkas dimasukkan ke ledger aktif; tidak perlu membuat dokumen baru setiap run.
- Gunakan scoped regression selama iterasi; jalankan gate lengkap yang diwajibkan saat menutup slice/step. Hasil sebelumnya adalah historis, bukan PASS baru. Jangan menghabiskan setiap run hanya untuk full suite atau merapikan narasi jika ada gap implementasi yang dapat dikerjakan.
- Perubahan pengguna yang belum committed wajib dipreservasi. Bukti file sedang dirty tidak otomatis membuktikan ada eksekutor aktif: audit diff dan aktivitas aktual; jika overlap tidak dapat dipisahkan, jangan overwrite dan laporkan path+keputusan yang dibutuhkan.
- Jika blocker sama bertahan dua run tanpa bukti baru, hentikan remediasi berulang untuk blocker tersebut dan laporkan kebutuhan tindakan pengguna melalui laporan yang sudah dikonfigurasi. Jangan menambah backlog, memperbesar scope, atau menandai PASS untuk menghindari blocker.
- Status 145.27 tetap PARTIAL sampai semua acceptance canonical dipetakan ke bukti dan gap wajib ditutup atau diputuskan eksplisit oleh pengguna. Jangan mengubah pointer demi terlihat maju. Setelah benar-benar selesai, ikuti prosedur ledger -> state -> guard; jangan beralih ke ekspansi sprint 111 sendiri.
- Akhiri laporan Indonesia dengan: perubahan yang terlihat pengguna, bukti aktual, yang belum selesai, dan satu tindakan berikut. Jangan menjanjikan tidak ada kendala.

OTORISASI PENGGUNA 2026-09-04 — PENANGANAN REGION SIBLING

Pengguna secara eksplisit mengizinkan perbaikan terkoordinasi pada region yang sebelumnya diblokir hanya karena uncommitted: project_recovery_services (145.34 assets/emergency), cloud_sync (145.32), void_top_bar serta lib/test settings (145.37/145.38). Status M atau untracked bukan larangan mutlak dan bukan bukti eksekutor aktif. Jangan mengulang klaim "tidak ada aksi aman" tanpa inspeksi baru.

Sebelum menyentuh region tersebut: periksa run aktif, diff aktual, instruksi repo, dan bukti kepemilikan terkini; buat snapshot recoverable di luar source untuk file yang akan disentuh, termasuk file untracked. Kerjakan satu slice dengan patch minimal yang mempertahankan semua perubahan sebelumnya, TDD, regression dan gate wajib. Jangan menghapus, menimpa, mengadopsi massal atau commit seluruh perubahan sibling. Jika region masih sedang ditulis eksekutor aktif, jangan edit bersamaan; tunggu/handoff atau pilih slice independen. Jangan menganggap jeda jadwal menghentikan run aktif.

145.42: label historis "eksekutor lain" harus diverifikasi dengan bukti run/proses/claim aktual. Bila kepemilikan aktif tidak terbukti dan pekerjaan telah idle, izin pengguna ini mencakup melanjutkan failure matrix dengan data temporer, bukan mematikan komputer, memenuhi drive pengguna, atau merusak naskah nyata. Jika kepemilikan tidak dapat dipastikan, sebutkan bukti spesifik dan kebutuhan handoff; jangan menandai selesai.

145.43â€“145.50: baca acceptance canonical satu per satu. Jalankan pekerjaan teknis yang memang tercakup otorisasi pengguna; pisahkan keputusan produk/pilot/release yang membutuhkan jawaban Choi. Ajukan satu keputusan konkret beserta opsi dan konsekuensinya, bukan menyatakan seluruh rentang tidak bisa dikerjakan. Izin memperbaiki bukan izin memalsukan validasi pengguna, menyetujui rilis, mengaktifkan stream ekspansi, atau push.

Mulai setiap run dengan readback instruksi job saat ini dan sumber kanonik; instruksi lama dalam context_from/self tidak boleh mengembalikan larangan sibling menyeluruh yang telah dicabut pengguna. Perbaikan aset checksum yang berada di working tree harus diperiksa dan dipreservasi; bukan otomatis dianggap committed atau menutup seluruh 145.34. Fokus berikut yang belum selesai: failure injection emergency/assets dan rollback seluruh payload saat restore gagal.

HANDOFF TERBARU 2026-09-04 — ROLLBACK PAYLOAD

Pembaruan ini menggantikan next-action rollback di paragraf sebelumnya, bukan menutup 145.34 atau memindahkan pointer 145.27. Perubahan lokal project_recovery_services.dart kini memulihkan manifest, database, assets, dan workspaces secara independen setelah restore gagal. File baru dari restore dihapus saat rollback, file identik tidak ditulis ulang, dan kegagalan rollback dilaporkan melalui BackupRollbackException dengan emergencyBackupPath serta area gagal. Emergency backup tetap dipertahankan.

Bukti aktual sesi Codex: test/features/project_resilience/backup_full_payload_rollback_test.dart mereproduksi RED (aset tertinggal versi backup), lalu GREEN dua tes: kegagalan workspace Windows mengembalikan seluruh payload dan kegagalan emergency backup menghentikan restore sebelum data aktif berubah. Tujuh focused tests PASS; flutter test --no-pub test/features/project_resilience --reporter expanded: 150 PASS; flutter analyze --no-pub: No issues found; dart run tool/roadmap_guard.dart: PASS, recommended_step 145.27; git diff --check: exit 0; flutter build windows --debug --no-pub: PASS. Ini bukti historis saat handoff, bukan hasil run Hermes berikutnya. Jangan commit/adopsi seluruh dirty worktree atau mengulang implementasi ini.

Sisa yang belum dibuktikan: fault injection saat rollback sendiri gagal, penghentian proses/power-loss, dan alur native Windows pengguna. Successful restore saat ini masih merge assets; jangan klaim exact snapshot untuk restore sukses tanpa acceptance dan test. Next action region 145.34: uji kegagalan rollback sendiri dengan data temporer, pastikan error melaporkan area gagal, area lain tetap dicoba, serta emergency backup dipertahankan. Ikuti urutan prioritas Core yang sudah ditetapkan bila gap prioritas lebih tinggi belum selesai. Tidak ada commit/push dilakukan oleh Codex pada slice ini.


OTORISASI COMPUTER USE PENGGUNA — 2026-09-06
Computer Use diizinkan untuk pengujian dan perbaikan Void Scriptor yang berada dalam kontrak roadmap. Gunakan untuk meluncurkan build Windows, mengamati UI, menjalankan alur pengguna dengan project/data uji temporer, mengambil bukti layar, dan mereproduksi kegagalan sebelum patch. Batasi interaksi pada Void Scriptor serta dialog sistem yang langsung dipicu pengujian. Jangan membuka aplikasi, akun, pesan, browser, atau file pribadi lain; jangan mengunggah data; jangan menghapus project pengguna; jangan menyetujui pembayaran, publikasi, perubahan akun, atau tindakan eksternal. Aksi destruktif, kredensial, OTP, penghapusan data, perubahan keamanan, dan penggunaan project nyata tetap memerlukan persetujuan eksplisit. Setelah patch, ulangi alur native dan laporkan langkah, hasil, serta screenshot/bukti; kegagalan tool bukan PASS.

OTORISASI BUG-HUNT PENGGUNA — 2026-09-06
Pengguna secara eksplisit meminta satu pelaksanaan `adversarial-bug-hunt` pada target Core prioritas tertinggi yang belum selesai dan aman diaudit. Jalankan sekali pada run eligible berikutnya, setelah roadmap guard PASS dan sebelum mutasi slice: tetapkan scope sempit (maksimal 20 file atau satu region/branch diff), rekam branch/HEAD/status, lalu ikuti Hunter -> Skeptic -> Referee secara berurutan dan scan-only. Gunakan file-path handoff untuk laporan; jangan menempel payload besar. Hanya verdict Referee = REAL BUG yang menjadi kandidat perbaikan. Setelah laporan selesai, tandai permintaan one-shot ini `COMPLETED` pada ledger/notepad job agar cron berikutnya tidak mengulang bug-hunt tanpa permintaan eksplisit baru. Perbaikan bug bukan bagian dari child bug-hunt: agen utama harus memetakan bug terkonfirmasi ke acceptance roadmap, mereproduksi RED, menerapkan patch minimal, lalu GREEN/regression/analyze/build/native evidence sesuai risiko. Jika delegasi tidak tersedia atau scope tidak dapat dibaca penuh, laporkan PARTIAL/BLOCKED; jangan mengarang temuan dan jangan menunda gap independen yang masih aman dikerjakan.



HANDOFF UI ASSET & LOADOUT — 2026-09-07

Implementasi pengguna ini sudah berada di working tree dan tidak boleh diulang atau ditimpa: sidebar workspace kini berhierarki NOVEL & STORY, CAST & CHARACTERS, WORLD & CREATURES, OBJECTS & LOADOUT; top bar desktop memakai label global Projects dan tetap tidak menampilkan Character/World.

UI nyata yang sudah terhubung: Wardrobe dan Weapon memakai workspace khusus; Armor dan Accessory memakai supporting asset workspace dengan detail/edit/favorite; Item/Prop memilih workspace detail; Creature/Companion memakai creature workspace dan repository; Character memiliki tab Appearance & Gear serta Companions & Carry. Slot wardrobe, armor, weapons, accessory, hair_variant, companion, dan carried_item menggunakan Character Mode/loadout persisten. Create Asset mendukung Armor, Accessory, Item/Prop, serta Creature/Companion dengan role.

Bukti historis Codex (wajib diuji ulang jika area disentuh): dart analyze seluruh repo PASS; focused UI/persistence 9 PASS; regression CharacterMode+Creature+Workspace+Preferences 35 PASS; Windows debug build PASS pada build/windows/x64/runner/Debug/void_scriptor.exe; git diff --check exit 0. Native interaction UNVERIFIABLE karena sesi computer-use Codex hanya mengekspos browser, bukan app Windows.

File scope utama: lib/features/explorer/presentation/explorer_panel.dart; lib/features/workspace/presentation/workspace_panel.dart; lib/features/workspace/presentation/workspace_resolver.dart; lib/features/character/presentation/character_workspace_screen.dart; lib/features/character_mode/presentation/widgets/character_mode_section.dart; lib/features/assets/presentation/supporting_asset_workspace_screen.dart; lib/features/creatures/presentation/creature_workspace_screen.dart; lib/features/creatures/data/creature_repository.dart; lib/database/project/daos/asset_dao.dart; lib/app/navigation/app_navigation_registry.dart.

Pada run berikutnya: roadmap guard tetap menguasai scope. Jika menyentuh UI ini, gunakan adversarial-bug-hunt sekali sesuai otorisasi yang sudah ada, reproduksi bug sebelum patch, pertahankan semua dirty sibling, dan prioritaskan verifikasi native dengan data uji. Jangan menandai 145.27 selesai hanya berdasarkan handoff ini; petakan bukti ke acceptance canonical.
HANDOFF HARD-KILL WINDOWS VERIFIED — 2026-09-07
Dua blocker test lama telah diperbaiki di working tree canonical. Akar masalah: FLUTTER_ROOT tidak selalu diekspor oleh flutter test sehingga fallback Platform.resolvedExecutable menjalankan flutter_tester.exe sebagai Dart VM; Completer kosong juga tidak menjaga child process tetap hidup. Patch menambahkan test/support/real_dart_executable.dart, memakai resolver itu di database dan durable-draft process-kill harness, serta mengganti penahan child dengan ReceivePort aktif. Bukti terbaru: focused kedua file hard-kill 4/4 PASS; regression test/features/project_resilience + database process-kill 185 PASS, 1 platform skip, 0 FAIL; flutter analyze --no-pub PASS; flutter build windows --debug --no-pub PASS; git diff --check exit 0. Jangan ulangi atau timpa patch ini. Pada run berikutnya, rekonsiliasi bukti tersebut ke acceptance/checklist canonical Sprint 145.27/145.42, lalu pilih next incomplete step dari roadmap guard. Pertahankan dirty sibling dan jangan commit/push tanpa scope yang jelas.

PEDOMAN GLOBAL BARU — 2026-09-07
Gunakan SOUL.md global terbaru dan skill hermes-readiness saat ada masalah kesiapan alat. Pemeriksaan versi bukan bukti native workflow; jangan mengklaim kemampuan yang belum diuji. Terapkan catatan pemulihan task, verifikasi hasil nyata, dan batas pengulangan kegagalan. Setelah tiga percobaan dengan blocker sama tanpa bukti baru, catat BLOCKED beserta input yang diperlukan, jangan mengulang perbaikan identik. Baca notepad/ledger sebelumnya untuk menghindari pengulangan bug-hunt one-shot; riwayat job lama tetap tersedia sebagai bukti historis, bukan instruksi terbaru. Pertahankan otoritas roadmap dan seluruh batas izin. Kirim laporan Telegram yang ringkas dan bermakna, tanpa kredensial. Tidak ada izin baru untuk push, rilis, pembayaran atau perubahan keamanan.

OTORISASI BUG HUNT BERULANG DAN PERBAIKAN OTOMATIS — 2026-09-07
Pengguna meminta cron bug hunter, perbaikan otomatis, pembaruan konten dan live update. Instruksi ini menggantikan batas one-shot bug-hunt lama, tetapi tidak mengubah kontrak roadmap atau izin rilis. Job ini adalah satu-satunya eksekutor mutasi proyek; jangan membuat cron penulis kode tambahan. Run yang sudah aktif tidak boleh diganggu.

Pada tiap run eligible, baca roadmap guard dan kondisi worktree terbaru. Kerjakan maksimum satu slice Core: bila ada bug terkonfirmasi yang belum diperbaiki, prioritaskan perbaikannya; bila tidak, lakukan adversarial-bug-hunt pada satu region relevan maksimal 20 file. Pilih scope baru dari gap acceptance atau diff berubah; jangan memindai ulang scope identik tanpa perubahan/evidence baru. Catat HEAD dan hash file scope agar perubahan uncommitted juga terdeteksi. Instruksi one-shot historis tidak membatalkan izin berulang ini.

Ikuti skill adversarial-bug-hunt: Hunter, Skeptic, Referee berurutan dan scan-only, bukan tiga penulis kode. Muat referensi skill aktual. Verifikasi file laporan sebelum handoff. Jika delegasi tidak tersedia atau laporan rusak, tandai PARTIAL; jangan mengarang verdict. Hanya REAL BUG dari Referee menjadi kandidat perbaikan, dan harus sesuai acceptance serta izin proyek.

Perbaikan dilakukan oleh eksekutor utama setelah reproduksi dengan data uji: RED, patch minimal, GREEN, regresi relevan, analisis, diff check, dan build yang sesuai. Pengujian native hanya jika backend nyata tersedia; unit test bukan bukti interaksi native. Preserve semua perubahan pengguna/agen lain. Jangan mengubah tes agar menutupi kegagalan. Sebelum menyunting ulang area, periksa hash/diff untuk konflik concurrent; berhenti jika kepemilikan bertabrakan.

Izin pembaruan konten mencakup teks UI, dokumentasi teknis, test fixture, dan laporan yang langsung berkaitan dengan perbaikan. Tidak mencakup menulis ulang/menghapus naskah novel, data karakter, gambar milik pengguna, atau sumber kontrak immutable. Jangan memperluas fitur di luar roadmap, memindahkan pointer tanpa evidence, push, menerbitkan build, deploy, menerima pembayaran, mengubah akun/credential, mematikan keamanan, atau restart komputer. Izin penuh perbaikan berarti mandiri dalam batas ini, bukan meniadakan pengamanan.

Batasi satu run pada satu slice dan sekitar 30 menit kerja; simpan checkpoint sebelum budget habis, jangan menghentikan proses penyimpanan di tengah. Maksimal dua percobaan pendekatan yang sama, lalu diagnosis berbeda; setelah tiga kegagalan identik tanpa bukti baru tandai BLOCKED dengan tindakan pengguna yang diperlukan. Jika tidak ada perubahan atau scope aman, lakukan NO-OP singkat dan jangan mengarang kesibukan. Jangan menginstal tool/dependency global dari job proyek.

Live update berarti status lokal dan progres Telegram, bukan hot-reload paksa aplikasi pengguna. Tulis checkpoint ringkas ke ledger/progress proyek yang sudah dipakai reporter: scope, tahap berjalan, temuan terkonfirmasi, hasil tes aktual, file berubah, blocker, dan next action. Perbarui pada transisi tahap bermakna. Gunakan reporter Telegram yang ada setiap 15 menit serta laporan akhir job; jangan membuat loop pesan sendiri. Jangan klaim realtime detik demi detik. Jangan masukkan rahasia atau teks naskah pengguna ke Telegram.


OTORISASI UI/UX CONTINUOUS — 2026-09-07
Pengguna secara eksplisit meminta perbaikan otomatis berkelanjutan UI/UX Dashboard, Sidebar, Top Bar dan Workspace Void Scriptor agar nyaman, terstruktur, tidak tumpang tindih dan tidak duplikat. Ini tambahan scope pemeliharaan UI Core pada eksekutor yang sama, bukan alasan membuat eksekutor/cron penulis kedua. Instruksi ini mengizinkan perubahan scoped pada dashboard dan shell yang sebelumnya protected; preservasi perubahan pengguna tetap wajib. Jangan mengganti produk atau mengembangkan modul non-Core.

Setelah stability gate dan roadmap guard lolos, prioritaskan hambatan nyata pada alur buka proyek -> lanjut menulis -> berpindah Novel/Character/Worldbuilding -> simpan -> buka kembali. Pilih satu perbaikan terukur per run. Jika mapping roadmap tidak mengizinkan perubahan, laporkan konflik spesifik; jangan memalsukan kontrak/acceptance atau memindahkan pointer. Bug risiko kehilangan data tetap lebih penting daripada kosmetik.

Kriteria UI:
- Dashboard global menonjolkan lanjut proyek terakhir, proyek terbaru dan status nyata. Pertahankan implementasi terbaru sebelum merancang ulang; jangan mengulang pekerjaan yang sudah selesai.
- Top bar untuk navigasi global; Character dan Worldbuilding berada dalam konteks proyek melalui sidebar. AI Studio menyediakan jalur Image/Video dan back hanya jika rutenya sudah ada. Hindari tombol identik yang tidak punya tujuan berbeda; jangan menghapus tombol kembali yang dibutuhkan pengguna.
- Sidebar sesuai proyek dan pilihan modul pengguna. Menyembunyikan modul bukan menghapus datanya. Hormati preset dan preferensi tersimpan, jangan memaksa semua novel memakai faksi, senjata atau makhluk.
- Workspace Novel, Character, Worldbuilding berbeda sesuai tugasnya. Tab harus mengubah konten nyata; pertahankan draft, pilihan, dan posisi kerja. Jangan menggabungkan Profile/Identity hanya karena label mirip; periksa fungsi aktual.
- Inspector ringkas dan kontekstual, bukan formulir duplikat. Hindari ruang kosong besar, nested scrolling bermasalah, panel menutupi editor, overflow, kontrol offscreen, serta header berulang tanpa fungsi.
- Ikuti tema/design-system Void Scriptor; jaga aksen ungu, keterbacaan, kontras, fokus keyboard, ukuran target, tooltip kontrol ikon, pembesaran teks, dan layout sempit. Jangan menambah glow/animasi dekoratif, angka palsu, atau kontrol yang tidak berfungsi.

Gunakan skill antislop-ui, antislop-human, antislop-layoutmobile hanya saat slice relevan; baca instruksi dan referensi aktual. Jika core/referensi tidak tersedia, laporkan keterbatasan dan gunakan design-system repository, jangan mengarang panduan. Bug-hunt tetap scan-only; eksekutor utama melakukan perbaikan yang diizinkan setelah verifikasi.

Untuk setiap slice: catat kondisi sebelum, reproduksi masalah, test regresi RED yang relevan, patch kecil, GREEN, analyzer, diff check, dan Windows build sesuai risiko. Uji empty/loading/error/populated, judul panjang, skala teks besar, keyboard dan navigasi. Computer-use hanya untuk aplikasi/proyek uji yang diizinkan; gunakan data temporer. Jika tidak tersedia, status native UNVERIFIABLE, jangan klaim nyaman secara visual sudah terbukti. Jangan menghentikan aplikasi pengguna atau hot-reload paksa.

Continuous berarti melanjutkan backlog konkret lintas run, bukan redesign tanpa akhir. Simpan checklist temuan, scope/hash terakhir, bukti selesai dan next action. Jangan memindai ulang UI identik atau mengubah gaya bolak-balik tanpa temuan baru. Setelah checklist habis, NO-OP/monitor; jika blocker sama berulang tanpa evidence, laporkan kebutuhan pengguna. Tidak boleh menambah fitur baru tanpa kebutuhan/otorisasi. Reporter Telegram yang ada mengirim progres berkala dan laporan akhir; jangan membuat spam atau mengklaim live per detik. Run aktif membaca instruksi lamanya; instruksi baru berlaku pada run berikutnya.


PERMINTAAN PENGGUNA 2026-09-07: Baca docs/backlog/character-roles-support.json di repository canonical. Pengguna meminta Hermes mengimplementasikan phase_one: role karakter per novel, importance, POV, support type, duration tetap/sementara/berulang dan status hubungan. Satu karakter tetap satu profil. Mulai dengan inspeksi fitur existing dan mapping canonical; jika di luar kontrak, laporkan keputusan pemetaan yang dibutuhkan, jangan mengarang sprint atau mengubah immutable policy. Kerjakan bertahap setelah gate mengizinkan, dengan data-safety prioritas utama. Riwayat arc/timeline deferred. Laporkan bukti aktual ke Telegram; keberadaan spesifikasi bukan bukti implementasi selesai.

# Permintaan pengguna — rekonsiliasi 145.27 dan 145.42

Tanggal pencatatan: 2026-09-08, Asia/Jakarta.

## Bukti pengguna, bukan pengukuran agen

Pengguna melaporkan pekerjaan tidak hilang setelah: menutup aplikasi normal,
mematikan aplikasi paksa, me-restart PC, dan mematikan PC. Simpan empat kasus
sebagai USER_REPORTED_PASS dengan sumber percakapan ini. Versi/build, waktu
kejadian, dataset, metode penghentian, dan hash sebelum/sesudah tidak diberikan;
catat unknown, jangan mengarang. Mematikan PC tidak membuktikan pencabutan
listrik mendadak, dan mematikan aplikasi paksa belum membuktikan transaksi WAL
terputus pada titik tertentu. Pertahankan batas cakupan ini.

Pengguna juga sudah melaporkan pengujian Windows berhasil untuk 145.27.
Jangan meminta konfirmasi umum yang sama lagi. Rekonsiliasi bukti native yang
ada dengan baris spesifik; persetujuan pengguna tidak otomatis menutup semua
route gating ataupun kriteria keamanan data.

## Otorisasi dan batas keselamatan

Pengguna meminta Hermes menguji sisa skenario satu per satu dan memberikan
laporan nyata agar pekerjaan tidak diulang. Drive umum sedang digunakan:
JANGAN melepas/offline/unmount drive tersebut, mengubah izin disk pengguna,
mengisi disk nyata sampai penuh, mematikan/restart PC, atau menghentikan proses
aplikasi pengguna. Uji destruktif hanya pada fixture disposable dan proses anak
yang dibuat oleh pengujian sendiri. Tidak ada otorisasi pemutusan listrik.

Gunakan injeksi kegagalan atau media virtual terisolasi jika aman dan sudah
tersedia. Labeli SIMULATED_PASS, bukan bukti pelepasan perangkat fisik.
Uji fisik yang memerlukan perangkat khusus tetap UNVERIFIABLE dengan kebutuhan
konkret; tidak boleh menghambat skenario independen yang aman.

## Urutan pelaksanaan pada run berikutnya

1. Jalankan roadmap guard dan periksa kepemilikan kerja aktif. Jangan memulai
   eksekutor kedua atau menyentuh perubahan sibling.
2. Inventarisasi bukti lama, tes, ledger, dan hash sumber terkait sebelum
   menjalankan ulang. Tutup gap pencatatan terlebih dahulu, bukan ulang semua tes.
3. Buat satu matriks durable untuk normal close, forced process termination,
   OS restart/shutdown, process crash/WAL, explicit disk_full, permission_loss,
   unavailable/removed drive, interrupted move/import/export/restore, corruption,
   dan device validation. Cocokkan daftar ini dengan kontrak 145.42 yang asli;
   daftar ini tidak mengubah acceptance kanonis.
4. Pada setiap kasus simpan: case_id, status, evidence_type, tanggal, sumber
   konfirmasi, commit dan dirty-scope hash, fixture, exact command, exit code,
   expected/actual result, log/screenshot path, integrity/hash checks bila
   relevan, keterbatasan, next action, dan alasan retest bila ada.
5. Jalankan hanya gap yang aman dan belum terbukti pada sumber relevan saat ini.
   Gunakan bukti lama jika tetap relevan; retest hanya karena perubahan terkait,
   regresi, bukti tidak memadai, atau gate rilis yang memang mengharuskannya.
6. Perbaiki bug terkonfirmasi secara scoped dengan TDD dan gate AGENTS.md.
   Simpan bukti setiap kasus sebelum melanjutkan kasus berikutnya, termasuk
   kegagalan/timeout; jangan menimpa riwayat gagal dengan hasil lulus.
7. Perbarui ledger/audit turunan sesuai hasil. Jangan mengubah immutable policy,
   kontrak sprint, atau menaikkan pointer tanpa seluruh syaratnya terpenuhi.
8. Laporkan ke Telegram yang sudah dikonfigurasi saat kasus menghasilkan bukti
   baru/bug/blocker dan ketika batch selesai: kasus, hasil nyata, lokasi bukti,
   sisa pekerjaan. Jangan mengirim daftar lama yang sama sebagai progres baru.

Status dokumen ini: handoff permintaan pengguna; bukan hasil eksekusi tes dan
bukan bukti bahwa 145.27/145.42 selesai. Catat penerimaan handoff di run pertama.


USER REQUEST 2026-09-08: Read and execute C:\Users\nepht\Documents\Codex\2026-08-22\referenced-chatgpt-conversation-this-is-an-2\HERMES_WEBSITE_DOWNLOAD_HANDOFF_2026-09-08.md at next safe run boundary. Verify existing Cloudflare connection, prepare website download structure and connect only verified release artifacts. Preserve safety assignment; report actual evidence to Telegram.

USER-APPROVED COORDINATION OVERRIDE: Before any mutation or codex exec, obey C:\Users\nepht\Documents\Codex\2026-08-22\referenced-chatgpt-conversation-this-is-an-2\HERMES_SINGLE_WRITER_HANDOFF.md. Current status RELEASED_TO_HERMES (2026-09-08): interactive owner stopped source edits; read the updated handoff and baseline, acknowledge acceptance, then continue. Codex PID or dirty files alone do not block. No duplicate writer in same worktree; no PID/mtime takeover; preserve all changes. Do not bypass paused writer job. Earlier autonomous continuation instructions remain subordinate to this admission rule.
Follow notification policy: C:\Users\nepht\Documents\Codex\2026-08-22\referenced-chatgpt-conversation-this-is-an-2\HERMES_PROGRESS_DELTA_POLICY.md . Report only new results; no repeated completed evidence.

# Otorisasi pengguna 2026-09-16 — checkpoint lokal, seluruh push ditahan

Choirudin memerintahkan Hermes menghemat billing CI selama implementasi sprint.
Kebijakan efektif sampai dicabut eksplisit:

- tetap buat commit lokal scoped setelah step VERIFIED agar rollback, provenance,
  dan kestabilan cron terjaga;
- jangan push ke GitHub, GitLab, atau remote lain; jangan membuat PR/MR, tag,
  release, atau memicu/rerun CI remote;
- sprint selesai, commit ahead, dan gate lokal hijau bukan izin push;
- jalankan gate yang diwajibkan secara lokal dan lanjutkan roadmap walaupun
  commit lokal belum tersalur ke remote;
- push/CI remote berikutnya hanya pada milestone yang dipilih Choirudin melalui
  izin baru yang eksplisit.

Larangan ini tidak menunda commit lokal dan tidak mengubah acceptance sprint.
