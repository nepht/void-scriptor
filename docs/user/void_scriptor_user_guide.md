# Void Scriptor — Panduan Pengguna

## Mulai cepat

1. Buka atau buat project lokal.
2. Gunakan Explorer untuk memilih workspace: Character, Story, World, Assets,
   atau fitur lain.
3. Simpan perubahan melalui aksi Save atau shortcut yang ditampilkan UI.
4. Gunakan Inspector untuk memeriksa metadata dan aksi entity yang dipilih.

## Feature guides

- **Story & Lore:** tulis scene, gunakan `[[Entity]]` untuk lore link, dan
  periksa backlink/continuity sebelum export.
- **Mission Board:** gunakan board view untuk status quest, dependency, dan
  link ke scene, character, location, atau arc.
- **Assets & media:** simpan media sebagai file lokal project dan gunakan
  reference manifest bila tidak ingin embedding.
- **AI workflows:** tinjau context, provider, permission, dan output sebelum
  menggunakan hasil generasi.

## Analisis dan batasnya

Analisis contradiction, backlink, continuity, dan preflight bersifat rule-based
serta bergantung pada data yang tersedia. Hasil analisis bukan jaminan bahwa
cerita benar secara editorial. Native screen-reader certification, physical
display contrast measurement, penetration testing, dan production endpoint
validation berada di luar development verification.

## Privasi

- Mode lokal tidak mengharuskan konten dikirim ke layanan eksternal.
- Jangan memasukkan API key, password, atau credential ke story, metadata,
  project database, atau export.
- Reader/share export meredaksi spoiler dan metadata internal sesuai clearance.
- Permission lintas workspace harus eksplisit; revoke/expiry harus diperlakukan
  sebagai akses yang sudah tidak berlaku.

## Backup dan restore

Backup harus disimpan sebagai salinan project yang dapat diverifikasi, bukan
sekadar screenshot atau daftar file. Sebelum restore, tutup session aktif dan
buat backup baru dari data saat ini. Restore ke salinan disposable terlebih
 dahulu, buka ulang database, lalu periksa manifest, story, assets, dan relasi.
Jika validasi gagal, pertahankan salinan original dan gunakan recovery/repair
flow; jangan menimpa data sumber secara buta.

## Sharing dan export

1. Jalankan preflight sebelum export.
2. Periksa blocking errors, warnings, preview, dan manifest.
3. Pilih reference-manifest sebagai default bila media tidak perlu di-embed.
4. Bagikan hanya paket yang sudah disanitasi dan periksa expiry/revoke.
5. Jangan menganggap export berhasil hanya karena file terbentuk; baca report
   dan verifikasi isi paket.

## Known limits

- Benchmark performance saat ini adalah development-only dan menghasilkan
  microsecond results untuk query yang diuji; belum merupakan SLO production.
- E2E contract test berjalan in-process, bukan sertifikasi native desktop/OS.
- Dukungan locale yang diverifikasi adalah English dan Indonesian; fallback
  bukan terjemahan penuh untuk semua locale.
- Native AT certification, sandbox audit, encrypted-at-rest review, serta
  external sharing endpoint review memerlukan release/operational validation.

## In-product guidance

Tooltip dan label aksi adalah petunjuk kontekstual. Jika aksi berhubungan dengan
sharing, deletion, restore, atau export, baca confirmation/report sebelum
melanjutkan. Untuk masalah yang tidak dapat dipulihkan, simpan log diagnostik
non-rahasia dan gunakan salinan disposable saat melakukan eksperimen.

Dokumen ini menjelaskan perilaku yang telah diverifikasi pada development scope;
ia tidak menggantikan acceptance gate atau backup yang teruji.
