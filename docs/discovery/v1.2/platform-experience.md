# 108.12 — Platform Experience Review

> Sprint 108 · disusun 2026-08-25 · kanonik dimensions:
> desktop, mobile, input, filesystem, performance, offline, accessibility

## Realitas utama

Enam direktori platform ada di repo (`android ios linux macos web windows`),
namun **satu-satunya platform dengan bukti siklus penuh adalah Linux x64 via
WSL** (KI-03). Perbandingan antar-platform yang diminta kanonik hanya bisa
jujur untuk platform terbukti; sisanya adalah status scaffold.

| dimensi | Linux x64 (terbukti) | platform lain (scaffold) |
|---|---|---|
| desktop | penuh: build, suite 1735+, watch rilis, paket portable | windows/macos: dir ada, tanpa validasi |
| mobile | n/a | android/ios: dir ada, tanpa bukti run |
| input | keyboard+mouse desktop teruji di suite | touch: tidak terevaluasi nyata |
| filesystem | pola `~/VoidScriptor` + `.voidproject` terbukti (2 proyek nyata) | konvensi path Win/macOS belum diuji |
| performance | baseline S107 (+58 checks) di Linux debug | tanpa profil per-platform lain |
| offline | inti produk offline-by-design (DB lokal, provider lokal) | idem secara desain; tak diuji per-platform |
| accessibility | 1 file uji fokus (`automation_a11y_test.dart`) + praktik Semantics di suite responsif per-sprint | screen reader nyata belum pernah dievaluasi |

## Temuan untuk arah v1.2

1. Klaim multi-platform v1.2 harus dibedakan tajam: **tersedia (dir ada)
   ≠ tervalidasi (bukti run)**. Kontrak C5 sudah mencatat batas ini.
2. Web punya jejak pengujian sendiri (`web_bootstrap_test.dart`,
   `project_web_guard_test.dart`) — kandidat platform kedua termurah untuk
   divalidasi serius karena beban toolchain-nya paling kecil.
3. Mobile shell & navigasi punya uji widget (`void_mobile_shell_test.dart`,
   `mobile_navigation_screen_test.dart`) tapi nol pemakaian nyata.
4. Aksesibilitas adalah dimensi paling tipis dari ketujuhnya — satu file uji
   fokus vs ribuan baris UI.
