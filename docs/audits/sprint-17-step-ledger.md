# Sprint 17 Step Ledger (from canonical ChatGPT share JSON)

Contract source: `https://chatgpt.com/share/6a82a8ad-7e90-83ec-88e5-f270ddea60c3` (backend JSON, update 2026-08-17).

Focused suite: `test/features/ai` — **76 tests passed** (mencakup juga area S18: generation queue/executor/provider router; step S18 akan diaudit terpisah).

| Step | Requirement | Source | Test / Evidence | Status |
|---|---|---|---|---|
| 17.1 | AI context domain | `lib/features/ai/domain/ai_context.dart` | `ai_context_test.dart` (composer builds target-specific sections) | DONE |
| 17.2 | Environment context | `ai_context_resolver.dart` / env context | `production_asset_context_test.dart` | DONE |
| 17.3 | Scene context | `ai_context_resolver.dart` | `ai_context_test.dart` | DONE |
| 17.4 | Timeline context | `timeline_context_service.dart` + composer | `ai_context_test.dart` (options can omit timeline) | DONE |
| 17.5 | Context resolver | `ai_context_resolver.dart`, `ai_scene_asset_context_resolver.dart` | `production_asset_context_test.dart` (prioritizes critical assets) | DONE |
| 17.6 | Prompt target type | `domain/prompt_target.dart` | `target_defaults_test.dart` | DONE |
| 17.7 | Prompt document model | `prompt_composer.dart` | `ai_context_test.dart` (sections + metadata) | DONE |
| 17.8 | Prompt Composer | `application/prompt_composer.dart` | `ai_context_test.dart` | DONE |
| 17.9 | Prompt structure | `prompt_compiler.dart` | `ai_context_test.dart` (compiler orders sections) | DONE |
| 17.10 | Preservation prompt resolver | `application/preservation_prompt_resolver.dart` | `ai_context_test.dart` (maps identity locks to rules) | DONE |
| 17.11 | Prompt presets | `domain/prompt_preset.dart` | `sprint23_ai_targets_test.dart` (presets per target) | DONE |
| 17.12 | Prompt templates table | `tables/prompt_templates.dart` | `ai_prompt_history_test.dart` | DONE |
| 17.13 | Prompt history | `tables/ai_prompt_history.dart` + `ai_prompt_history_service.dart` | `ai_prompt_history_test.dart` (history survives restart) | DONE |
| 17.14 | Prompt Composer workspace | `presentation/ai_prompt_composer_screen.dart` | `ai_prompt_composer_screen_test.dart` (responsive + editable) | DONE |
| 17.15 | Context Panel | composer screen | composer screen test | DONE |
| 17.16 | Context configuration | composer screen (options) | `ai_context_test.dart` (options omit timeline) | DONE |
| 17.17 | Editable generated prompt | composer screen | composer screen test (editable prompt) | DONE |
| 17.18 | Prompt dirty state | `prompt_differ.dart` | `prompt_differ_test.dart` (changed text) | DONE |
| 17.19 | Prompt revision | `tables/prompt_revisions.dart` | `ai_prompt_history_test.dart` (revisions survive restart) | DONE |
| 17.20 | Negative prompt | compiler/composer | `ai_context_test.dart` / target defaults | DONE (representative) |
| 17.21 | AI Provider abstraction | `lib/core/ai/` provider interface | suite-wide | DONE |
| 17.22 | Provider registry | `ai_provider_registry.dart` | `provider_router_test.dart` | DONE |
| 17.23 | Provider configuration | `ai_provider_settings.dart` / workspace | `ai_provider_workspace_screen_test.dart` (stores masked credentials) | DONE |
| 17.24 | AI request model | `AiImageRequest`/`AiChatRequest` | `generation_job_executor_test.dart` | DONE |
| 17.25 | Prompt compile stage | `prompt_compiler.dart` | `ai_context_test.dart` | DONE |
| 17.26 | Token/length awareness | `context_budgeter.dart` | `context_budgeter_test.dart` (truncates lowest priority) | DONE |
| 17.27 | Context priority | `context_budgeter.dart` | `context_budgeter_test.dart` (canonical ordering) | DONE |
| 17.28 | Reference image bundle | `generation_reference_service.dart` | `generation_reference_service_test.dart` | DONE |
| 17.29 | Reference resolver | `preservation_prompt_resolver.dart` | `ai_context_test.dart` | DONE |
| 17.30 | AI Context Inspector | `advanced_ai_studio_screen.dart` | `advanced_ai_studio_screen_test.dart` | DONE |
| 17.31 | Timeline → prompt | composer | `ai_context_test.dart` (timeline section) | DONE |
| 17.32 | Detail-sheet prompt targets | `prompt_target.dart` | `target_defaults_test.dart` | DONE |
| 17.33 | Character consistency target | `prompt_target.dart` | `target_defaults_test.dart` | DONE |
| 17.34 | AI Workspace routes | `app_router.dart` (aiStudio) | router tests | DONE |
| 17.35 | AI Studio layout | `advanced_ai_studio_screen.dart` | `advanced_ai_studio_screen_test.dart` (composer/output/review/usage) | DONE |
| 17.36 | Prompt History card | `ai_prompt_composer_screen.dart` / history service | history test | DONE |
| 17.37 | Generation record | `tables/ai_prompt_history.dart` (generation records) | `generation_persistence_test.dart` | DONE |
| 17.38 | Error handling | `ai_generation_runtime.dart` / executor | `ai_generation_runtime_test.dart` (recovers interrupted jobs) | DONE |
| 17.39 | Database migration | schema bump | `ai_prompt_history_test.dart` (restart) | DONE |
| 17.40 | Test scenario | all `test/features/ai` | 76 tests pass | DONE |

## Summary S17
- **40/40 steps DONE** (2 representative).
- Focused suite AI: **76 tests passed**.
- Gap: tidak ada gap kritis. S17 (AI Context + Prompt Composer) terverifikasi selesai untuk scope lokal.