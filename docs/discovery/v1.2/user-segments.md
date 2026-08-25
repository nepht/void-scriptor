# 108.5 — User Segment Review

> Sprint 108 · disusun 2026-08-25 · kanonik required_dimensions: workflow,
> experience_level, project_scale, platform, collaboration_mode,
> compute_environment
> Metode: segmen DIDEFINISIKAN dari bukti pemakaian nyata (registry
> `~/VoidScriptor/projects.json`, aktivitas filesystem, isi baris DB proyek),
> bukan persona fiktif.

## Segmen S1 — Penulis-tunggal teknis (TERBUKTI ADA: Choirudin)

| Dimensi | Bukti |
|---|---|
| workflow | menulis novel + worldbuilding (Void Cube Saga) sambil mengembangkan produknya sendiri; satu-satunya alur yang benar-benar dieksekusi di proyek nyata: buat proyek → story → chapter → scene (+1 siklus backup) |
| experience_level | expert / developer-user: membangun IDE-nya sendiri, membaca kontrak skema, mengelola rilis & signing |
| project_scale | hari ini: proyek kecil level smoke ("Test Novel": 1 story, 1 chapter, 1 scene; proyek "jj" dibuat & tak pernah disentuh lagi); target: VCS penuh (belum pernah diimpor) |
| platform | Linux x64 via WSL — satu-satunya platform dengan pemakaian nyata; Windows host tersedia tapi tanpa jejak sesi aplikasi |
| collaboration_mode | solo penuh — tidak ada tabel kolaborasi/relasi lintas-pihak yang terisi |
| compute_environment | AMD RX 590 GME 8GB tanpa LLM lokal (keputusan 25 Agu), RAM 32GB, preferensi OFFLINE-first |

## Segmen S2 — Penulis eksternal (HIPOTESIS — belum punya bukti)

Akan muncul lewat rollout tahap-2 (undangan manual, kontrak §Staged rollout).
Karakteristiknya BELUM DAPAT dinyatakan — setiap klaim tentang kebutuhan penulis
lain tertahan sampai A-01 (assumption register) teruji. Disengaja kosong:
mendaftarkan persona imajiner justru melanggar objektif langkah ini.

## Implikasi ke arah v1.2

1. Nilai terbukti hari ini terkonsentrasi pada **alur menulis inti** (story →
   chapter → scene) dan **resiliensi paket proyek** (backup nyata) — dua hal ini
   adalah yang bertahan dari kontak dengan pengguna sungguhan.
2. Keluasan subsistem (157 tabel) belum berarti nilai: 152 tabel kosong di
   pemakaian nyata. Discovery harus menguji MENGAPA kosong (tidak dibutuhkan?
   tidak ketemu? tidak onboarding?) — bukan menganggapnya otomatis berhasil.
3. Segmen tunggal = setiap keputusan desain v1.2 berisiko over-fit pada satu
   orang; gate 108.31 harus menuntut minimal satu uji eksternal untuk tema yang
   menyasar di luar S1.
