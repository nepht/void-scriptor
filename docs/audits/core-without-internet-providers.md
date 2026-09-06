# Sprint 145.21 — Core Without Internet or Providers

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json` langkah 145.21 dan `core_mvp_scope_reset_spec.json`.

## Contract

Offline launch and the complete Core journey must survive DNS, network, Cloud, and AI provider failures without delay, data loss, modal traps, or misleading Core errors.

## Live evidence

The AI layer contains real optional-provider seams:

- `lib/features/ai/application/provider_router.dart` resolves capable providers and falls back after provider failure.
- `lib/features/ai/application/provider_timeout.dart` converts timeout into a safe provider-specific exception.
- `AiProviderHealthProbe` reports unavailable providers with a redacted stable message.
- `AiModelRegistry` has cached-model fallback when a provider is unavailable.
- Generation executor tests cover provider failure without saving outputs.
- Retry policy distinguishes network/timeout from non-retryable authentication/invalid-request errors.

Relevant tests include:

- `test/features/ai/application/provider_router_test.dart`
- `test/features/ai/application/provider_health_test.dart`
- `test/features/ai/application/provider_timeout_test.dart`
- `test/features/ai/application/ai_model_registry_test.dart`
- `test/features/ai/generation_job_executor_test.dart`
- `test/features/ai/generation_queue_test.dart`

## Evidence boundary

These tests prove optional AI behavior in isolation. They do not prove that Core project open, edit, save, search, export, backup, or restore remains usable while DNS/network/Cloud/AI is unavailable. No dedicated Core network-failure matrix was found in the current test tree.

The router and startup composition still import optional feature surfaces directly. Combined with the blocked dependency-direction step (145.19), startup non-blocking behavior is not fully certified.

## Required missing tests

1. Boot Core with a provider/network failure injected and assert no Core modal trap.
2. Open and edit a local project while the optional provider fails.
3. Save/autosave while DNS/network is unavailable.
4. Search, lore link, clean export, backup, and restore while optional services fail.
5. Assert no API key, token, cloud credential, payment data, or provider exception is persisted.
6. Assert timeout/error UI is bounded, honest, dismissible, and does not corrupt Core state.

## Decision

`145.21 Core Without Internet or Providers` berstatus **PARTIAL**. Optional AI failure seams and tests exist, but the release-blocking Core journey has no dedicated network/provider-failure proof. The correct next action is a Core isolation test slice after the architecture/startup seams are contractually defined; do not add a mandatory provider or network dependency.

Next: `145.22 Module Boundary and Feature Flags`.

## Evidence paths

- `lib/features/ai/application/provider_router.dart`
- `lib/features/ai/application/provider_timeout.dart`
- `test/features/ai/application/provider_router_test.dart`
- `test/features/ai/application/provider_health_test.dart`
- `test/features/ai/application/provider_timeout_test.dart`
- `test/features/ai/application/ai_model_registry_test.dart`
- `test/features/ai/generation_job_executor_test.dart`
- `test/features/ai/generation_queue_test.dart`
- `docs/audits/core-dependency-direction.md`
- `docs/audits/core-mvp-vertical-slice-contract.md`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`

Catatan: path export `C:/Users/nepht/...` adalah sumber kanonik eksternal; source-of-truth aplikasi tetap `/home/nepht/Projects/void_scriptor_multiplatform`.

## Update 2026-09-01 (nephthys cron, commit 87f1e19)

The previously missing Core network-failure proof now exists:
`test/features/projects/core_without_internet_providers_test.dart` (2 tests, PASS).

Covered acceptance from "Required missing tests" above:

1. Core boot/journey with provider/network failure injected - the journey test
   wraps the whole run in a DNS-failing transport (`ApiClient` with
   `SocketException`) and an AI provider whose `listModels`/`generate` throw
   `SocketException`, wrapped in `AiProviderWithTimeout` (50 ms). No hang.
2. Project open + edit while the optional provider fails - create/open +
   story/chapter/scene + draft save/read all complete locally.
3. Save/autosave while the network is unavailable - `DebouncedAutosave`
   schedules a local save that completes and is readable afterward.
4. Search (scene query via repository), lore-free clean export
   (`StoryMarkdownExporter` includes saved drafts), backup, and restore while
   providers are down - backup + content-loss (corrupted db, wiped
   workspaces) restore + reopen verified.
5. No credential/provider exception persisted - project manifest asserted
   free of `SocketException`, `TimedOutException`, `apiKey`, `token`.
6. Bounded, honest, non-modal failure UI - widget test on
   `AiGenerationQueueScreen` renders a failed job with an explicit retry
   action and no `AlertDialog` (no modal trap); `AiProviderHealthProbe`
   reports `unavailable` with a redacted message; `AiModelRegistry.refresh`
   rethrows instead of silently blocking when no cached model exists.

Still outside this step's evidence boundary:

- Native interaction (a real Windows window driven by hand) remains
  UNVERIFIABLE from cron; no `computer_use` driver in this run.
- The test injects failures at the provider/transport seam, not by pulling
  the physical network cable; OS-level DNS/cache behavior is therefore not
  exercised.

Status: **VERIFIED** for the Core journey under injected provider/network
failure, within the evidence boundaries above.
