# 108.14 — AI & Compute Direction Review

> Sprint 108 · disusun 2026-08-25 · kanonik dimensions:
> capability, quality, latency, cost, privacy, offline, hardware,
> provider_reliability · menjawab charter Q3

## Permukaan nyata di repo

Empat provider terpasang di `lib/features/ai/infrastructure/providers/`:
**ollama** (default `http://localhost:11434`), **comfyui**
(default `http://localhost:8188`), **gemini**, **openai**. Registry +
settings UI ada; tabel `ai_generation_jobs` di proyek nyata = **0 baris**
(nol generasi nyata pernah dicatat).

## Penilaian per dimensi (mesin Choi: RX 590 GME 8GB Polaris, RAM 32GB)

| dimensi | penilaian jujur |
|---|---|
| capability | jalur lokal (ollama LLM / comfyui SDXL) TERPASANG tapi **tidak layak pada GPU ini**: Polaris tanpa dukungan ROCm/CUDA modern — LLM lokal sudah dibuktikan tidak jalan & dihapus dari mesin (keputusan 25 Agu); jalur remote (gemini/openai) kapabel |
| quality | tak terukur di konteks produk (nol job nyata); kualitas teoretis bergantung model remote yang dipilih |
| latency | lokal: tak relevan (tak jalan); remote: tergantung jaringan/provider — belum diukur |
| cost | remote = biaya token/gambar per pemakaian (model pay-as-you-go); lokal = Rp0 tapi kapabilitas nol di mesin ini |
| privacy | novel belum terbit = aset sensitif; mengirim konten ke API remote butuh persetujuan eksplisit per-konten; lokal ideal secara privasi tapi mustahil di hardware ini |
| offline | inti aplikasi tetap offline penuh; AI adalah fitur opsional-online — desainnya sudah benar |
| hardware | RX 590 8GB: tidak sanggup LLM lokal; SDXL via Polaris tidak didukung resmi — asumsi A-02/A-03 di register menutup ini |
| provider_reliability | gemini/openai = SLA komersial (belum diuji dari aplikasi); ollama/comfyui = reliabilitas setara mesin sendiri |

## Arah yang dibenamkan bukti (draft untuk Q3)

1. **Jangan klaim fitur AI lokal** pada hardware ini — bertentangan bukti.
2. Jalur realistis: **remote provider opt-in** dengan gerbang privasi
   eksplisit (persetujuan sebelum konten keluar) + tetap memelihara antarmuka
   provider lokal agar tidak mati bila hardware berganti.
3. Sebelum investasi besar: satu eksperimen kecil end-to-end (satu prompt,
   satu provider remote, ukur latensi+biaya+kualitas) — selaras rencana
   108.25–27; tanpa itu semua angka quality/latency/cost tetap kosong.
