# Sprint 145.36 — AI Optional Boundary

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json`, item `145.36`.  
Status: **PARTIAL**.

## Kontrak kanonik

`Jika AI implementation exists, keep one BYOK provider optional after Core stability with explicit context, consent, cost, cancellation, redaction, failure fallback, and no startup dependency.`

## Implementasi yang terverifikasi

Live repository memiliki AI runtime di `lib/features/ai/` dengan:

- `AiProvider` dan capability-aware provider registry;
- OpenAI, Gemini, Ollama, dan ComfyUI adapters;
- secure credential store abstraction;
- `AiGenerationRuntime` yang membuka provider runtime setelah project/database tersedia;
- generation queue dan executor dengan bounded lifecycle;
- cancellation, retry, provider failure status, dan late-result protection;
- prompt history dan generation job persistence;
- model catalog cache/fallback;
- local output persistence;
- external transfer gate, provider routing, cost budget, dan audit-oriented integration contracts;
- secret redactor/scanner serta encrypted credential store.

Runtime default tidak memerlukan API key untuk membangun registry object; provider credentials dibaca melalui `CredentialStore`, bukan project database. Tidak ada pemanggilan provider eksternal dalam audit ini.

## Verification terbaru

Command:

```bash
flutter test \
  test/features/ai/ai_provider_test.dart \
  test/features/ai/ai_generation_runtime_test.dart \
  test/features/ai/generation_job_executor_test.dart \
  test/features/ai/application/ai_model_registry_test.dart \
  test/features/ai/domain/provider_registry_lifecycle_test.dart \
  test/features/ai/infrastructure/text_provider_contract_test.dart \
  test/features/ai/infrastructure/image_provider_execution_contract_test.dart \
  test/automation/external_integrations_test.dart \
  test/core/security/secret_vault_test.dart
```

Result:

```text
All tests passed! — 39 tests
```

Evidence yang lulus:

- duplicate provider IDs ditolak;
- credential store read/write/delete dan encrypted storage;
- secret redaction dan pattern scanning;
- runtime recovery untuk queued/running jobs tanpa auto-run langsung;
- provider routing melalui registry;
- unsupported target ditolak sebelum I/O;
- output provider tersimpan melalui executor;
- provider failure tidak menyimpan output palsu;
- cancellation diteruskan dan late result tidak menghidupkan job cancelled;
- model catalog cache fallback;
- external transfer denial sebelum provider call;
- cost budget wajib dan publishing/network allowlist;
- capability preflight dan plugin permission checks.

## Evidence boundary

| Acceptance | Status | Evidence / gap |
|---|---|---|
| Optional BYOK provider | PARTIAL | CredentialStore dan provider adapters ada; satu explicit BYOK policy/UX belum |
| Explicit context | PARTIAL | Prompt history/target/runtime ada; boundary context yang wajib sebelum provider call belum satu contract universal |
| Consent | PARTIAL | External transfer check dan confirmation contracts ada; consent state belum menjadi shared AI runtime policy |
| Cost | VERIFIED (local) | Budget/cost integration contracts pass; live billing/provider cost tidak dipanggil |
| Cancellation | VERIFIED (local) | Queue/executor/provider cancellation tests pass |
| Redaction | VERIFIED (local) | SecretRedactor/SecretScanner/encrypted store tests pass; all provider payloads belum property-tested |
| Failure fallback | VERIFIED (local) | Provider failure, cached model fallback, retry, and interrupted job recovery pass |
| No startup dependency | PARTIAL | Runtime opens after database/package; dedicated bootstrap test proving Core starts with unavailable AI services belum |
| Credential isolation | VERIFIED (local) | Credentials go through secure store; no project-database API-key field evidence |
| Native/provider live execution | DEFERRED | No live third-party credential or network call used; native UI remains `UNVERIFIABLE` (`snapshot_id_required`) |

## Safety boundary

Tidak ada API key yang dibaca atau ditampilkan, tidak ada provider eksternal yang dipanggil, dan tidak ada network upload. Test memakai memory credential store, fake clients, temporary project/database, dan local adapters.

## Verdict

**PARTIAL — AI sudah optional secara arsitektur lokal dengan secure credentials, routing, budget, cancellation, redaction, dan fallback primitives; explicit unified BYOK/context/consent policy dan proof bahwa Core startup tidak bergantung pada AI masih terbuka.**

Next canonical step: `145.37 Navigation Reduction`.

145.42 tetap tidak disentuh karena milik eksekutor lain.

## Update 2026-09-03 (nephthys cron, unified BYOK/context/consent policy + no-startup-dependency proof)

Step 145.36 AI Optional Boundary — dua gap audit ditutup tanpa menyentuh file
AI concurrent (semua file produksi/tests milik slice ini adalah file BARU
untracked; `lib/features/ai/domain/ai_provider.dart`,
`ai_generation_runtime.dart`, `provider_router.dart` dll milik sibling TIDAK
disentuh):

- **Unified BYOK/context/consent policy** — `lib/features/ai/domain/ai_policy.dart`
  (baru): satu rulebook stateless `AiPolicy.byDefault()` yang menutup tiga
  sumbu boundary sekaligus sebelum provider call:
  - BYOK: `byokReady=false` -> `PolicyResultDenied` (kredensial dari secure
    store user, tidak pernah dari project database);
  - Explicit context: `contextSummary` kosong/whitespace -> denied (prompt
    "kirim semua" tanpa ringkasan tidak mungkin);
  - Consent: `externalTransfer=true` tanpa `externalTransferConsent=true` ->
    denied (fail-closed); provider lokal (Ollama/ComfyUI localhost) tetap
    bisa tanpa consent.
  `test/features/ai/domain/ai_policy_test.dart` 6 PASS, RED terverifikasi
  (semua simbol undefined saat file produksi belum ada).
- **No-startup-dependency proof** — `test/features/ai/ai_no_startup_dependency_test.dart`
  4 PASS: (1) struktural — 7 file bootstrap inti (`main.dart`,
  `app/bootstrap/*`, `app/void_app.dart`, `app/void_scriptor_app.dart`) TIDAK
  mengimpor modul AI sama sekali; (2) perilaku — `AiPolicy` fail-closed saat
  AI tidak tersedia tanpa exception, request tidak pernah mencapai provider
  eksternal tanpa consent; (3) policy murni kontrak, bisa dijawab tanpa
  runtime/credential store/network (inilah yang dibutuhkan alur Core).

Bukti run ini: focused AI suite 125 PASS (termasuk 6+4 baru, delta +10),
`flutter analyze` scoped No issues (9.6s), windows debug build PASS (lihat
ledger), `git diff --check` PASS, roadmap guard PASS pre+post (pointer tetap
145.27).

Sisa 145.36 yang tetap open: dedicated BYOK UX/flow belum (butuh keputusan UI
Choirudin), provider payload property-test redaction menyeluruh, native
interaction UNVERIFIABLE dari cron.

## Update 2026-09-03b (nephthys cron, update status setelah ledger)

Status ledger 145.36 dinaikkan menjadi PARTIAL dengan gap BYOK/context/consent
policy + no-startup-dependency proof TERTUTUP (lihat update di atas); sisa
open: BYOK UX, redaction property-test menyeluruh, native interaction.
## Update 2026-09-03c (nephthys cron, redaction property-test menyeluruh)

Gap audit "all provider payloads belum property-tested" ditutup sebagai bukti
property-level atas primitif redaction yang menjadi sandaran seluruh jalur
payload/credential (SecretRedactor + SecretScanner). Slice test-only:

- `test/core/security/secret_redaction_property_test.dart` 12 PASS:
  - `mask`: exhaustive lengths 1..64 (setiap nilai pendek 1..4 -> `****`,
    nilai >= 5 -> `3-char + ****` length 7, deterministik, tidak pernah
    memuat full secret, `mask(mask(x))` stabil);
  - `redact`: replace SEMUA kemunculan setiap secret (10 secret acak x2),
    daftar kosong = identity, idempoten (token `[REDACTED]` tidak pernah
    di-rescan menjadi `[REDACTED][REDACTED]`), overlapping secret lebih
    panjang menang tanpa residue parsial;
  - `scanner`: deteksi 4 format credential nyata (OpenAI `sk-`, AWS
    `AKIA`, GitHub `ghp_`, Slack `xoxb`) di dalam free text + zero
    false-positive pada prosa/teks pendek.
- Temuan investigasi: `SecretRedactor`/`SecretScanner` saat ini TIDAK
  dipanggil dari kode produksi mana pun di luar definisinya - primitif
  tersedia dan benar, tapi belum ter-wire ke jalur logging/ekspor payload.
  Wiring ke jalur produksi adalah pekerjaan terpisah (file AI concurrent)
  dan tetap tercatat sebagai gap.

RED terverifikasi dua lapis: (1) test baru awalnya gagal karena test-bug
(harapan startsWith salah + generator body memuat '-'/'_' yang mematahkan
regex format, + body AKIA harus uppercase) - diperbaiki di test, bukan di
produksi; (2) setelah koreksi, seluruh property PASS menunjukkan primitives
produksi sudah memenuhi kontrak. Tidak ada perubahan production code.

Bukti: focused 12 PASS + security suite 42 PASS + ai policy 10 PASS =
52 PASS; `flutter analyze` full No issues found! (113.7s); `git diff --check`
PASS. Pointer tetap 145.27.
