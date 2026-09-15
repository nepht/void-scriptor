Jalankan remediasi otonom Void Scriptor hanya pada repository canonical Windows `D:\VoidScriptor\void_scriptor_multiplatform`. Gunakan toolchain `D:\DevTools\Flutter SDK\flutter\bin\flutter.bat`. Jangan gunakan checkout WSL atau mirror `D:\VoidScriptor_Windows`.

Roadmap tidak memiliki satu pointer tunggal. Konsensus wajib berasal dari `docs/roadmap/ROADMAP_POLICY.json`, `docs/roadmap/DOCUMENT_REGISTRY.json`, external canonical JSON, ledger sprint aktif, dan `.hermes/ROADMAP_STATE.json`. Pada awal SETIAP run, jalankan `dart run tool/roadmap_guard.dart`. Jika exit bukan 0, lakukan NO-OP/BLOCKED dan jangan mengedit source. Dilarang menjalankan `--repair` dari cron; repair hanya boleh dilakukan secara sadar ketika scheduler paused.

File tanpa nomor sprint tidak memiliki otoritas secara otomatis. Baca role dan authority hanya dari `DOCUMENT_REGISTRY.json`. File yang tidak terdaftar adalah `NON_BINDING`; `REFERENCE`, `BACKLOG`, `GENERATED`, `EXECUTION_SUMMARY`, dan `HISTORICAL_LEDGER` tidak boleh membuat langkah atau acceptance baru. `EVIDENCE` hanya mendukung klasifikasi status. `POLICY` dan `EXECUTOR_POLICY` boleh membatasi cara kerja tetapi tidak boleh memperluas scope kontrak sprint. Jika dokumen dalam strict authority root tidak terdaftar, checksum immutable berubah, atau authority bertentangan, lakukan NO-OP/BLOCKED.

Urutan wajib setiap run:
1. Rekam `git status --short --branch`, `git rev-parse HEAD`, pastikan tidak ada conflict markers, dan pastikan tidak ada Flutter process lain. Preserve seluruh perubahan pengguna/agen lain.
2. Jalankan roadmap guard. Baca policy, document registry, active stream, `.hermes/ROADMAP_STATE.json`, `active_ledger`, dan canonical JSON `active_sprint_source`. Corrective stream mengalahkan sequential expansion; tepat satu mutation stream boleh ACTIVE.
3. Cari `next_step` dalam canonical `steps`. Baca objective, requirements, outputs, acceptance, required_evidence, ledger gap, dan bukti repository. Jangan mengarang kriteria, melompati langkah, atau menghidupkan deferred scope.
4. Jika `stability_gate.status` bukan `PASS`, kerjakan hanya quality gate atau kegagalan yang dapat direproduksi. Jangan mulai fitur roadmap sampai analyzer, focused Core regression, full test, dan Windows build yang diwajibkan kembali hijau.
5. Jika gate PASS, kerjakan tepat `next_step` dengan TDD: RED relevan -> implementasi minimal -> GREEN -> regression -> analyzer/format scoped -> `git diff --check` -> applicable Windows evidence.
6. Commit hanya file slice dengan path eksplisit. Dilarang `git add -A`, reset, restore, clean, menghapus data pengguna, atau menimpa perubahan lain. Jangan push tanpa izin eksplisit pengguna.
7. Setelah VERIFIED, perbarui ledger aktif lebih dulu lalu runtime state. Jalankan roadmap guard lagi; jangan mengubah policy stream/priority dari cron.
8. Setelah corrective exit gate terpenuhi, laporkan BLOCKED menunggu keputusan stream transition. Cron tidak boleh mengaktifkan sequential stream sendiri.

Core yang dilindungi: project registry/database, novel/chapter/scene/character/lore, autosave/snapshot, backup/restore, import/export, migrations, Windows local-first startup, dan seluruh file pengguna. Community, Reader Network, Publishing Network, payment/payout, marketplace, provider expansion, XR, Metaverse, serta sistem non-Core tetap dipreservasi tetapi tidak boleh diperluas sebelum Core gate.

Satu proses Flutter pada satu waktu. Warning database tidak boleh disembunyikan tanpa bukti lifecycle aman. Timeout bukan PASS. Laporan wajib berbahasa Indonesia dengan status VERIFIED/PARTIAL/BLOCKED/DEFERRED/NO-OP, command+exit, file, risiko, dan next action konkret.
