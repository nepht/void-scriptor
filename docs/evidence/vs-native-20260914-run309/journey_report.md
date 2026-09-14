# Native Journey run309 — verifikasi UI Windows 145.27/145.42/145.44 (Mode B, 2026-09-14)

Aplikasi: build Debug `build/windows/x64/runner/Debug/void_scriptor.exe` (rebuild 15:5x, HEAD f0724a5 saat sesi).
Proyek uji: `Journey303 Choi` (satu-satunya objek destruktif). Salinan Saga `d53c8787` hanya dibaca/dibuka, tidak dimutasi.
Runbook: `~/.hermes/plans/2026-09-14_runbook-native-journey-14527-14542-14544.md`.

## Hasil per journey

- J1 create+autosave+restart VERIFIED. Paket `5f55bb9c-3f18-4803-b954-3c009d78ccc8.voidproject` dibuat via UI; novel+chapter+scene atomik; 3 paragraf tersimpan (label "Tersimpan HH:MM" + draft journal); close graceful -> nol session.lock; relaunch -> state pulih. Catatan: drop ~40 char pada burst SendInput panjang = artefak input driver (bukti: teks pendek berikutnya tersimpan utuh 207->233), BUKAN cacat app.
- J4 character/relationship/cast VERIFIED. Uji-A + Uji-B dibuat via dialog; relasi `related_to` Uji-A->Uji-B di DB (`asset_relations`); chip tampil di Inspector; role Protagonist tersimpan di cast (`projects.json` lokal DB `character_cast` via Save). Picker target relasi mengeksklusi aset sumber (benar).
- J5 lock contention VERIFIED. Instance-2 atas proyek terbuka -> layar Project Lock (tanpa crash); retry fail-closed; holder mati -> takeover (sessionId baru tercatat di session.lock). Kill-paksa meninggalkan lock -> takeover stale juga benar.
- J2 Move Project VERIFIED. Menu `…` kartu -> Move Project… -> folder picker native -> `D:\VS_MoveTest`. Paket berpindah fisik; registry `D:/VoidScriptor_Data/projects.json` localPath ter-repoint; proyek dibuka kembali dari lokasi baru dengan isi utuh.
- J3 Storage Locations VERIFIED. Pintu masuk: Account menu -> Settings -> About & Diagnostics -> "Lokasi penyimpanan kustom". Layar menunjukkan status healthy + panel Set/Relink/Probe.
- J6 drive-hilang VERIFIED. `subst X:` berisi 2 paket probe -> Probe UI: `writable: true · gratis: 199.0 GB · ok.`; drive dicabut saat app hidup (`subst X: /D`) -> refresh + Probe ulang: `writable: false · gratis: 0 B · driveMissing` — fail-closed tanpa crash. Screenshots: j3_probe_x_ok.png, j6_drive_missing_failclosed.png.
- J7.1 regresi lintas proyek VERIFIED (parsial penuh): salinan Saga (baca-saji) pilih karakter Lumi -> Inspector bersih tanpa jejak proyek uji; pindah ke Journey303 Choi -> tidak ada sisa state Saga. J7.2 build web release PASS (`√ Built build\web`, log build_web.log).

## Bug native ditemukan

- **BUG-303-01 (Medium)** — setelah klik "Pulihkan Draft", editor membisu input: ketikan pasca-restore tidak muncul dan label beku "Belum tersimpan"; data DB aman. Repro: ketik scene -> tutup saat draft ada -> relaunch -> Pulihkan Draft -> ketik. Screenshot era run303 pid 24596/14096.
- ~~BUG-303-02~~ **DICABUT** — "Manage local storage" dashboard memang mengarah ke Project Resilience, TAPI pintu masuk Storage Locations ADA dan berfungsi: Account menu (avatar) -> Settings -> Lokasi penyimpanan kustom (SettingsHub -> AppRoutes.storageLocations, terverifikasi live di layar). Rekomendasi Low-sekadar-UX: jadikan link dashboard mengarah langsung ke Settings Hub storage. Bukan bug fungsional.

## Pitfall driver (untuk agensi berikutnya)

- UIA Flutter hanya mengekspos ~5-25 elemen; gunakan screenshot SOM + skala: native = param_klik x 1.066 + offset (18,11) pada window non-maximized; popup menutup bila foreground di-raise sebelum item diklik — klik item tanpa delivery_mode foreground.
- TextField di panel storage: zona klik = baris input bagian BAWAH kotak (label atas); verifikasi isi via vision sebelum Jalankan.
- `coordinate=` bekerja andal bila dikalibrasi per-sesi dengan tombol ukur (Close/Maximize).
