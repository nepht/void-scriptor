# Sprint 28 — Advanced AI Studio

> **Sumber judul kanonik**: uteke memory `90d845b9` ("S28 Advanced AI Studio") — hanya judul,
> tanpa step detail. Step di bawah **dirancang oleh nephthys** dari judul kanonik + audit repo
> nyata (fondasi S17/S18 yang sudah LULUS), lalu **disetujui Choirudin**.

## Status: ✅ DONE (28.1–28.24)

- **Schema**: v39 → **v40** (`ai_usage_logs`, `ai_model_catalog`, `ai_output_reviews`).
- **Evidence 28.24**: `flutter analyze` = No issues found; `flutter test` = **504 PASS**;
  `flutter build web --release` = ✓ Built; `dart format --set-exit-if-changed` = clean;
  `git diff --check` = clean.
- Semua commit ter-push ke `origin master`.

## Tujuan

Memperdalam pipeline AI (S17 AI Context + S18 Provider/Queue) menjadi **studio AI tingkat
lanjut** yang andal untuk produksi: streaming, orchestrasi multi-provider, kesadaran token &
biaya, batch generation, model management, output review workflow, dan prompt versioning.

**Batas lingkup (jujur)**: AI Agent / Knowledge Graph / Universe AI adalah S38–40 (judul kanonik
terpisah), BUKAN S28.

---

## Fondasi yang sudah ada (dari audit repo, jangan diulang)

| Komponen | File | Status |
|---|---|---|
| AiContext + resolver scene | `ai/application/ai_context_resolver.dart` | ✅ S17 |
| PromptCompiler (section) | `ai/application/prompt_compiler.dart` | ✅ S17 |
| PromptTarget (13) + PromptPreset (14) | `ai/domain/prompt_target.dart`, `prompt_preset.dart` | ✅ S17 |
| Prompt history + revisions | `ai/application/ai_prompt_history_service.dart` | ✅ S17 |
| AiProvider + Registry (5 provider) | `ai/domain/ai_provider.dart` | ✅ S18 |
| GenerationJob + queue + RetryPolicy | `ai/domain/generation_job.dart`, `application/generation_queue.dart` | ✅ S18 |
| `AiCapability.streaming` / `.remoteCancellation` | `ai/domain/ai_provider.dart` | ⚠️ didefinisikan, **belum dipakai** |

---

## Step (28.1 → 28.24)

### Blok A — Streaming generation (28.1–28.3)

- **28.1** `AiGenerationChunk` model + `Stream<AiGenerationChunk>` pada `AiProvider` (interface
  `streamGenerate`). Enforce `AiCapability.streaming` sebelum memanggil.
- **28.2** Implementasi streaming pada provider yang mendukung (OpenAI/Gemini via SSE; Ollama via
  `/api/chat` stream; ComfyUI/ lainnya fallback chunk tunggal).
- **28.3** UI streaming: teks token-by-token (buffered), progress bar untuk image/video; auto-scroll.

### Blok B — Token & cost awareness (28.4–28.6)

- **28.4** `TokenEstimator` (approx counter, char/4 heuristic + konfigurasi per model).
- **28.5** Context-window budget + strategi truncation (prioritas: canon > preservation rules >
  identity > environment > scene assets), dengan headroom untuk output.
- **28.6** `AiUsageLog` + biaya per generasi; table `ai_usage_logs` (schema v39→v40).

### Blok C — Multi-provider orchestration (28.7–28.9)

- **28.7** `ProviderRouter`: target → provider terbaik (capability + enabled + model tersedia).
- **28.8** Fallback chain: failover otomatis pada error `authentication`/`network`/`provider`
  (bukan rateLimit/invalidRequest), dengan batas hop.
- **28.9** Routing aware biaya: preferensi provider termurah untuk target non-kritis (opsional flag).

### Blok D — Model management (28.10–28.12)

- **28.10** Model catalog + cache (persist `listModels()` per provider; table `ai_model_catalog`).
- **28.11** Model picker UI (per target, menampilkan capabilities).
- **28.12** Default provider+model per `PromptTarget` (override-able, tersimpan).

### Blok E — Batch generation (28.13–28.15)

- **28.13** `AiBatchRequest` model (N prompt → N output).
- **28.14** Batch executor (parallel bounded oleh concurrency; reuse `GenerationQueue`).
- **28.15** Batch result aggregation + UI (progress per item, partial failure tetap menampilkan sukses).

### Blok F — Output review workflow (28.16–28.18)

- **28.16** Review state machine: `pending → approved | rejected`; table `ai_output_reviews`.
- **28.17** Regenerate-with-feedback: rejected output → prompt + feedback sebagai input ulang.
- **28.18** Review UI: side-by-side compare output, approve/reject/feedback.

### Blok G — Prompt versioning & compare (28.19–28.21)

- **28.19** Prompt version diff model (unified diff antar revisi).
- **28.20** Version compare view (split-pane, highlight tambah/hapus).
- **28.21** Restore/revert prompt revision.

### Blok H — AI Studio workspace + integrasi (28.22–28.24)

- **28.22** `AdvancedAiStudioScreen`: unified surface (composer + streaming output + review + usage).
- **28.23** Wire ke navigasi/routes + shell (masuk `WorkspaceLayoutShell` sebagai tab).
- **28.24** DoD: full regression gates + commit.

---

## Schema migration (v39 → v40)

Table baru:

```text
ai_usage_logs      (id, generation_id, provider, model, prompt_tokens, completion_tokens, cost, created_at)
ai_model_catalog   (provider_id, model_id, capabilities_json, cached_at)
ai_output_reviews  (generation_id, status, feedback, created_at, updated_at)
```

Pola migration `if (from < 40)` — konsisten dengan v37/v38/v39.

---

## Regression gates (wajib tiap step)

```text
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
git diff --check
```

## Catatan risiko (jujur)

1. **Streaming** membutuhkan endpoint SSE/stream di provider; ComfyUI tidak stream → fallback chunk.
2. **Token estimator** adalah approx (bukan exact tokenizer) — cukup untuk budgeting, bukan billing.
3. **Biaya** tergantung pricing model per provider yang bisa berubah; disimpan sebagai metadata,
   bukan sumber kebenaran billing.
4. **Model catalog cache** bisa stale; invalidasi manual + TTL.
5. Provider real (OpenAI/Gemini/Ollama/ComfyUI) tetap butuh kredensial live untuk verifikasi e2e —
   test unit/integrasi memakai `MockAiProvider` (pola existing).
