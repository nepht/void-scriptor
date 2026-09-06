# Sprint 017 — Official JSON Step Ledger

Source: `C:\Users\nepht\Documents\Codex\2026-08-22\referenced-chatgpt-conversation-this-is-an\outputs\MASTER_SPRINT_VOID_SCRIPTOR_JSON\sprint_017.json`

Source completeness: `partial`; declared steps: `38`.

Focused command:

```bash
flutter test test/features/ai test/features/bible/canon_prompt_context_test.dart test/features/creator/domain/ai_context_layer_test.dart
```

Result: `115 tests passed`.

| Step range | Contract evidence | Status |
|---|---|---|
| 17.1–17.4 | AI context domain: character, environment, scene, timeline contexts. | `VERIFIED-LOCAL` |
| 17.5 | Context resolver assembles scene dependencies. | `VERIFIED-PARTIAL` — resolver and scene-asset context services exist; full dependency matrix is not externally exercised. |
| 17.6 | Prompt target type. | `VERIFIED-LOCAL` |
| 17.7–17.10 | Target-specific composer sections/options and prompt compilation. | `VERIFIED-LOCAL` |
| 17.11–17.14 | Preservation rules, canon context, bounded context budget and priority. | `VERIFIED-LOCAL` |
| 17.15–17.18 | Provider registry, routing, defaults, health/diagnostics and cost selection. | `VERIFIED-LOCAL` |
| 17.19–17.22 | Text/image/vision provider request contracts and unsupported media guards. | `VERIFIED-PARTIAL` — request forwarding is tested with fakes; live external providers are not verified. |
| 17.23–17.26 | Generation queue, retry, cancellation, execution and persistence. | `VERIFIED-LOCAL` |
| 17.27–17.30 | Generation output/reference/review/history/revisions. | `VERIFIED-LOCAL` |
| 17.31–17.34 | Prompt composer, streaming output, gallery and comparison UI. | `VERIFIED-PARTIAL` — UI tests pass; one test emitted `NARROW_EXCEPTION: null` while remaining green. |
| 17.35–17.37 | Provider credentials masking, model catalog cache and safe diagnostics. | `VERIFIED-LOCAL` |
| 17.38 | Testing | `VERIFIED-LOCAL` — 115 focused tests passed. |

## Boundary

Provider contract tests use fake clients and do not prove live OpenAI, Gemini, Ollama, ComfyUI, image, or vision connectivity. No credentials were displayed or stored in this ledger.

## Conclusion

Sprint 017 status: `VERIFIED-PARTIAL`. Context composition, prompt compilation, bounded context, provider routing contracts, queue/cancellation, generation persistence, review/history, credential masking, and UI evidence are locally green. Live provider connectivity and the non-fatal narrow exception observation remain unresolved.

Next canonical source: `sprint_018.json`.

No production code was changed in this audit batch.
