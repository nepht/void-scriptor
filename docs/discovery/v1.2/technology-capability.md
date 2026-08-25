# 108.16 — Technology Capability Review

> Sprint 108 · disusun 2026-08-25 · kanonik classification:
> PRODUCTION_READY / LIMITED / EXPERIMENTAL / UNSUITABLE
> Konteks mesin: RX 590 GME 8GB (Polaris), RAM 32GB, WSL Ubuntu; mode OFFLINE.

| teknologi | klasifikasi | dasar bukti |
|---|---|---|
| Flutter Linux x64 desktop | PRODUCTION_READY | build+suite 1735+, rilis v1.1.0 terkirim, watch 8 checkpoint bersih |
| Drift/SQLite project.db (v56) + migrasi | PRODUCTION_READY | migrasi+rollback byte-for-byte lolos RC; 2 proyek nyata |
| Signing RSA-3072 detached + SBOM CycloneDX lokal | PRODUCTION_READY | verifikasi openssl Verified OK; SBOM 125 komponen (KI-01/KI-02 CLOSED) |
| Paket portable ZIP + checksums | PRODUCTION_READY | uji end-to-end ekstraksi→sha256→signature OK (KI-04 parsial) |
| Flutter Windows/macOS target | LIMITED | dir scaffold ada; tanpa toolchain/bukti run di mesin ini |
| Flutter Web | LIMITED | uji bootstrap/guard ada; performa & siklus penuh tak tervalidasi |
| Flutter Mobile (android/ios) | EXPERIMENTAL | dir + uji widget shell; nol run perangkat nyata |
| Plugin API v1 | LIMITED | teruji (+23) dan stabil; ekosistem/dokumentasi publik belum ada |
| Provider AI lokal (ollama/comfyui) di GPU ini | UNSUITABLE | Polaris tanpa ROCm/CUDA modern; LLM lokal dibuktikan tak jalan & dihapus |
| Provider AI remote (gemini/openai) | LIMITED | kode terpasang; belum ada uji end-to-end terukur dari aplikasi |
| Installer MSI/deb + updater | UNSUITABLE (saat ini) | builder tidak tersedia di lingkungan (KI-04 gap) |
| Telemetri produksi | UNSUITABLE (saat ini) | butuh hosting yang belum ada (KI-03 warisan) |
| Verifikasi visual GUI via WSLg | UNSUITABLE (di mesin ini) | render hitam tanpa GPU — deferred ke mesin ber-GPU |

Aturan pakai untuk 108.17+: peluang hanya boleh dibangun di atas komponen
PRODUCTION_READY, atau disertai langkah validasi eksplisit bila LIMITED.
Klasifikasi LIMITED/EXPERIMENTAL bukan hukuman — ia mencegah klaim palsu.
