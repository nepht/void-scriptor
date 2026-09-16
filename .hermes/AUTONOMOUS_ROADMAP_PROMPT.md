Jalankan remediasi otonom Void Scriptor hanya pada repository canonical Windows `D:\VoidScriptor\void_scriptor_multiplatform`. Gunakan toolchain `D:\DevTools\Flutter SDK\flutter\bin\flutter.bat`. Jangan gunakan checkout WSL atau mirror `D:\VoidScriptor_Windows`.

Roadmap tidak memiliki satu pointer tunggal. Konsensus wajib berasal dari `docs/roadmap/ROADMAP_POLICY.json`, `docs/roadmap/DOCUMENT_REGISTRY.json`, external canonical JSON, ledger sprint aktif, dan `.hermes/ROADMAP_STATE.json`. Pada awal SETIAP run, jalankan `dart run tool/roadmap_guard.dart`. Jika exit bukan 0, lakukan NO-OP/BLOCKED dan jangan mengedit source. Dilarang menjalankan `--repair` dari cron; repair hanya boleh dilakukan secara sadar ketika scheduler paused.

File tanpa nomor sprint tidak memiliki otoritas secara otomatis. Baca role dan authority hanya dari `DOCUMENT_REGISTRY.json`. File yang tidak terdaftar adalah `NON_BINDING`; `REFERENCE`, `BACKLOG`, `GENERATED`, `EXECUTION_SUMMARY`, dan `HISTORICAL_LEDGER` tidak boleh membuat langkah atau acceptance baru. `EVIDENCE` hanya mendukung klasifikasi status. `POLICY` dan `EXECUTOR_POLICY` boleh membatasi cara kerja tetapi tidak boleh memperluas scope kontrak sprint. Jika dokumen dalam strict authority root tidak terdaftar, checksum immutable berubah, atau authority bertentangan, lakukan NO-OP/BLOCKED.

Urutan wajib setiap run:
1. Rekam `git status --short --branch`, `git rev-parse HEAD`, pastikan tidak ada conflict markers, dan pastikan tidak ada Flutter process lain. Preserve seluruh perubahan pengguna/agen lain.
2. Jalankan roadmap guard. Baca policy, document registry, active stream, `.hermes/ROADMAP_STATE.json`, `active_ledger`, dan canonical JSON `active_sprint_source`. Corrective stream mengalahkan sequential expansion; tepat satu mutation stream boleh ACTIVE.
3. Cari `next_step` dalam canonical `steps`. Baca objective, requirements, outputs, acceptance, required_evidence, ledger gap, dan bukti repository. Jangan mengarang kriteria, melompati langkah, atau menghidupkan deferred scope.
4. Jika `stability_gate.status` bukan `PASS`, kerjakan hanya quality gate atau kegagalan yang dapat direproduksi. Jangan mulai fitur roadmap sampai analyzer, focused Core regression, full test, dan Windows build yang diwajibkan kembali hijau.
5. Jika gate PASS, kerjakan tepat `next_step` dengan TDD: RED relevan -> implementasi minimal -> GREEN -> regression -> analyzer/format scoped -> `git diff --check` -> applicable Windows evidence.
6. Commit lokal hanya file slice dengan path eksplisit. Dilarang `git add -A`, reset, restore, clean, menghapus data pengguna, atau menimpa perubahan lain. Selama kebijakan hemat-CI aktif, jangan push meskipun sebuah sprint selesai; push memerlukan izin eksplisit baru dari pengguna.
7. Setelah VERIFIED, perbarui ledger aktif lebih dulu lalu runtime state. Jalankan roadmap guard lagi; jangan mengubah policy stream/priority dari cron.
8. Setelah corrective exit gate terpenuhi, laporkan BLOCKED menunggu keputusan stream transition. Cron tidak boleh mengaktifkan sequential stream sendiri.

## Otorisasi tetap adopsi WIP kanonik (Choirudin, 2026-09-16)

Status `M` atau `??` bukan veto dan tidak boleh membuat cron berputar NO-OP tanpa batas. Untuk setiap run sekarang dan seterusnya, pengguna memberi izin eksplisit kepada satu-satunya Core Worker untuk mengadopsi, memperbaiki, menguji, merekonsiliasi, dan commit WIP yang memenuhi SEMUA syarat berikut:

1. file tersebut tepat berada dalam scope `next_step` kanonik aktif dan tidak memperluas acceptance;
2. tidak ada writer hidup yang terbukti sedang menulis file tersebut (keberadaan PID umum, file dirty, atau mtime lama saja bukan bukti kepemilikan aktif);
3. HEAD, `git status`, path, mtime, dan SHA-256 file direkam sebelum mutasi, lalu snapshot recoverable file terkait dibuat di luar source tree;
4. semua perubahan existing dipertahankan dan diperbaiki secara patch minimal; dilarang `reset`, `restore`, `clean`, adopsi massal, atau menyentuh sibling di luar slice;
5. scratch/probe hanya boleh dihapus setelah seluruh temuan atau assertion yang masih bernilai dipindahkan ke test resmi dan penghapusannya dicatat;
6. TDD/gate slice, ledger -> state -> roadmap guard, dan explicit-path commit tetap wajib.

Bila keenam syarat terpenuhi, JANGAN meminta izin adopsi/reparasi lagi dan JANGAN menunggu penulis yang tidak aktif. Jika writer benar-benar aktif, tunggu/handoff dan laporkan blocker sekali; run berikutnya wajib memeriksa ulang bukti aktual, bukan menyalin status lama. Otorisasi tetap ini tidak mengizinkan push, release, pembayaran, perubahan akun/keamanan, penghapusan project pengguna, atau fault test destruktif.

Instruksi WIP 111.43 telah selesai dan tidak lagi menjadi tugas aktif. Ikuti `next_step` kanonik terkini pada setiap run; jangan mengulang instruksi langkah lama.

## Kebijakan tetap checkpoint lokal dan hemat CI (Choirudin, 2026-09-16)

Sampai pengguna mencabut kebijakan ini secara eksplisit:

1. setiap step VERIFIED tetap WAJIB dibuatkan commit lokal scoped dengan path eksplisit; jangan menumpuk banyak sprint dalam dirty working tree;
2. DILARANG menjalankan `git push` ke remote mana pun, push melalui MCP/API, membuat atau memperbarui pull/merge request, membuat/mendorong tag, membuat release, atau memicu/rerun CI remote;
3. selesainya sprint, bertambahnya commit `ahead`, atau gate lokal hijau BUKAN izin push;
4. verifikasi harian memakai test fokus, regression yang diwajibkan kontrak, analyzer/format/diff-check, roadmap guard, dan build lokal yang applicable;
5. CI remote hanya boleh dijalankan pada milestone yang dipilih pengguna atau setelah izin push/rilis baru yang eksplisit;
6. ledger/state harus mencatat commit lokal dan jumlah `ahead` secara ringkas, tanpa menjadikan backlog push sebagai blocker roadmap;
7. jika remote backup dibutuhkan, laporkan kebutuhan itu kepada pengguna; jangan menyiasati larangan dengan remote, branch, tag, bundle upload, atau provider lain.

Tujuan kebijakan ini adalah menjaga checkpoint dan rollback granular untuk kestabilan cron sambil mencegah konsumsi billing CI selama implementasi sprint. Commit lokal tidak boleh dihapus atau digantikan oleh satu commit raksasa di akhir.

Core yang dilindungi: project registry/database, novel/chapter/scene/character/lore, autosave/snapshot, backup/restore, import/export, migrations, Windows local-first startup, dan seluruh file pengguna. Community, Reader Network, Publishing Network, payment/payout, marketplace, provider expansion, XR, Metaverse, serta sistem non-Core tetap dipreservasi tetapi tidak boleh diperluas sebelum Core gate.

Satu proses Flutter pada satu waktu. Warning database tidak boleh disembunyikan tanpa bukti lifecycle aman. Timeout bukan PASS. Laporan wajib berbahasa Indonesia dengan status VERIFIED/PARTIAL/BLOCKED/DEFERRED/NO-OP, command+exit, file, risiko, dan next action konkret.
