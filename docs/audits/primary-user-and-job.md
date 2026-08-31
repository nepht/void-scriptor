# Sprint 145.14 — Primary User and Job

Tanggal audit: 2026-08-31 (cron remediation)
Sumber kanonik: `sprint_145.json` step `145.14` (CORRECTIVE_IMPLEMENTATION_PLAN)
Sumber keputusan: otorisasi eksplisit Choirudin yang direkam di notepad cron
`8caeae6e1e0d` (key `user_decision_145_14`, `APPROVED_BY_USER 2026-08-31`).
Keputusan ini disimpan oleh Choirudin sebagai penyelesaian langkah 145.14 yang
sebelumnya BLOCKED (product decision/user validation required).

## Status

**VERIFIED** (keputusan produk direkam dari sumber pengguna; langkah
dokumentasi, bukan kode - tidak ada mutation code/schema/database).

## Primary user

- **Profil**: novelis serius yang mengerjakan proyek long-form secara mandiri
  (individu, bukan tim/studio) di **Windows desktop**.
- **Jenis karya**: novel berdurasi panjang (long-form) dengan alur berlapis,
  misteri, dan konsistensi dunia yang harus dijaga lintas bab.
- **Cara kerja**: mandiri (solo), tanpa bergantung pada tim editorial, cloud,
  atau akun eksternal untuk alur inti.

## Primary job (pekerjaan utama)

Alur kerja utama (plan -> write -> continuity -> export) berjalan **local-first**:

1. **Plan** - merencanakan struktur novel/story, chapter, scene, beat, dan
   dunia/lore sebelum dan selama menulis.
2. **Write** - menulis dan menulis-ulang chapter/scene/manuscript sebagai
   aktivitas utama harian.
3. **Continuity** - menjaga konsistensi: character, relationship, environment,
   lore/Bible, timeline, dan referensi silang.
4. **Export** - mengekspor hasil karya (chapter/manuscript) dari data lokal ke
   bentuk yang dapat dipakai di luar aplikasi.

## Environment

- Windows x64 desktop (target platform inti Core MVP, konsisten
  `foundation_rules.core_platform = WINDOWS_X64_LOCAL_FIRST`).
- Data utama tinggal di project package/database milik pengguna di mesinnya
  (local-first, konsisten promise lock 145.13).
- Pengguna mengerjakan satu proyek long-form secara kontinu lintas sesi.

## Pain (masalah yang dialami)

- Kehilangan data: takut pekerjaan panjang hilang karena crash/keliru
  menutup/tidak ada cadangan.
- Alur menulis tersendat karena harus berpindah antar-alat untuk struktur,
  menulis, konsistensi, dan ekspor.
- Konsistensi cerita sulit dijaga manual pada proyek ratusan bab/karakter.

## Constraints (batasan wajib)

- **Tanpa akun**: alur inti harus berfungsi tanpa akun/pendaftaran.
- **Tanpa internet**: alur inti harus berfungsi tanpa koneksi internet.
- **Tidak kehilangan data**: setiap aksi yang memengaruhi karya harus punya
  persistence/recovery story (autosave, backup, restore).
- Core tidak boleh menggantung pada cloud, payment, atau provider AI untuk
  alur menulis (konsisten `foundation_rules` dan non-goals 145.13).

## Success (ukuran keberhasilan)

Skenario inti yang harus bisa diselesaikan pengguna **tanpa cloud**:

1. Membuat novel baru (create novel).
2. Menulis dan membuka-kembali chapter (write/reopen chapters).
3. Mencari lore dan mempertahankan kontinuitas (lore/search).
4. Autosave berjalan tanpa kehilangan data.
5. Mengekspor hasil karya (export).
6. Membuat cadangan (backup) dan memulihkan (restore).

## Non-goals (eksplisit di luar scope langkah ini)

- Primary user kedua (mis. pembaca, komunitas, tim studio) **belum dipilih**.
- Authoring mobile/tablet, macOS, dan web editing bukan environment primary.
- Fitur komunitas/reader/payment tetap non-Core (deferred hingga Core gate).
- Keputusan ini tidak memperluas scope Core MVP (145.16) dan tidak mengubah
  promise lock (145.13).

## Evidence boundary

- Keputusan produk direkam **dari otorisasi pengguna**, bukan direka dari
  sumber kode - ini yang membuat langkah sebelumnya BLOCKED kini dapat
  diselesaikan.
- Bukti eksekusi lintas langkah tetap terpisah: profil pengguna ini memandu
  prioritas Core (145.16) dan data-safety matrix (145.42), tetapi tidak
  menggantikan bukti teknis masing-masing langkah.
- Tidak ada kode, schema, database, atau user data yang diubah oleh langkah
  ini.
