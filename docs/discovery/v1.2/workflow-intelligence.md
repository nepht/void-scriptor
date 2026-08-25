# 108.10 — Workflow Intelligence Evaluation

> Sprint 108 · disusun 2026-08-25 · kanonik metrics:
> workflow_creation, successful_runs, failure_rate, recovery_rate,
> approval_wait, abandonment, repeat_use
> Objektif: menilai penggunaan, keberhasilan, dan batas fitur workflow v1.1.

## Hasil evaluasi: hasil NEGATIF yang penting

Bukti langsung (read-only, 2026-08-25): seluruh 10 tabel berpola
workflow/automation/approval/job/command di DB proyek nyata "Test Novel"
berisi **0 baris** (`ai_generation_jobs`, `background_jobs`,
`command_history_entries`, `job_dependencies`, dst.). Proyek "jj" bahkan tak
punya aktivitas apa pun pasca-pembuatan. Ditambah nol sesi aplikasi sejak
rilis (pgrep NO_PROCESS di semua checkpoint):

| metrik | nilai teramati | dasar |
|---|---|---|
| workflow_creation | **0** kejadian nyata | hitung baris DB = 0 di semua tabel terkait |
| successful_runs | tidak terdefinisi (penyebut 0) | tidak ada run nyata |
| failure_rate | tidak terdefinisi (0/0) | idem |
| recovery_rate | tidak terdefinisi | idem |
| approval_wait | tidak teramati | tidak ada approval nyata |
| abandonment | **100% pada level subsistem**: subsistem workflow tidak pernah disentuh sama sekali | 0 baris; pemakaian nyata hanya naratif (5/157 tabel) |
| repeat_use | **0** | tidak ada penggunaan pertama untuk diulang |

## Yang tetap bisa dinilai dari bukti

- **Kapabilitas TERBUKTI di kondisi uji**: regresi approval/duplicate/safety
  hijau di atas stable (checkpoint 1–7), suite automation penuh 24/24 termasuk
  bridge event bus 104.8, analyzer bersih. Fitur bekerja saat dipanggil.
- **Adopsi nyata NOL**: fitur workflow v1.1 tidak pernah keluar dari lab uji.
  Nilai produknya bagi pengguna tunggal S1: BELUM TERBUKTI.
- **Batas evaluasi**: tanpa telemetri (KI-03/KI-04 warisan), metrik kanonik
  hanya bisa proxy filesystem/DB — dan proxynya menghasilkan nol di mana-mana.

## Implikasi arah (input untuk 108.12+, bukan kesimpulan)

Investasi lanjutan pada subsistem workflow tidak boleh didasarkan pada asumsi
adopsi; pertanyaan yang lebih dahulu terjawab adalah MENGEMANA pengguna inti
yang aktif menulis cerita tidak menyentuhnya sama sekali (F-01/F-03, UN-02).
