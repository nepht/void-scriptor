# Sprint 40 — AI Creative OS

> **STATUS: PROPOSAL**
> **Sumber judul kanonik**: uteke memory `90d845b9` ("S40 AI Creative OS") — hanya judul.
> Fondasi audit: `features/ai` (prompt composer, compiler, differ, provider router,
> streaming, generation job, gallery, context resolver). S39 agent platform.

## Tujuan

Membangun **AI Creative OS** deterministic di atas fondasi AI: command system,
creative brief, idea bank, creative pipeline. Bukan LLM inference real.

## Batas lingkup (jujur)

- **IN**: `CreativeCommand` (name, description, params), `CommandRegistry` (register/invoke),
  `CreativeBrief` (title, genre, tone, goals), `Idea` + `IdeaBank` (add/query ideas),
  `CreativePipeline` (stages idea→outline→draft→polish), `PipelineStage` enum,
  `CreativeOsShell` (central dispatch), UI `CreativeOsPanel` + route `/creative-os`.
- **OUT**: real LLM inference, external model API, actual text generation.

## Step

### Blok A — Command system (40.1–40.3)
- **40.1** `CreativeCommand` (name, description, params).
- **40.2** `CommandRegistry` (register/lookup/invoke).
- **40.3** unknown command → failure result.

### Blok B — Creative brief (40.4–40.6)
- **40.4** `CreativeBrief` (title, genre, tone, goals).
- **40.5** `brief` validation (empty title/tone → invalid).
- **40.6** `CreativeBrief.fromMap`.

### Blok C — Idea bank (40.7–40.9)
- **40.7** `Idea` (id, title, description, tags).
- **40.8** `IdeaBank` (add/query by tag).
- **40.9** idea dedupe by title.

### Blok D — Creative pipeline (40.10–40.12)
- **40.10** `PipelineStage` enum (idea, outline, draft, polish).
- **40.11** `CreativePipeline` (advance stage).
- **40.12** pipeline stage order validation.

### Blok E — Persistence (40.13–40.15)
- **40.13** Table `creative_briefs` (schema v50→**v51**).
- **40.14** Table `creative_ideas`.
- **40.15** `CreativeRepository` + restart persistence test.

### Blok F — UI (40.16–40.18)
- **40.16** `CreativeOsPanel` (brief count + stage).
- **40.17** `IdeaList`.
- **40.18** `PipelineView`.

### Blok G — Demo + wire (40.19–40.21)
- **40.19** Wire route `/creative-os`.
- **40.20** `DemoCreativeOs` built-in.
- **40.21** DoD: full regression gates + commit + tandai DONE.

## Schema v51
- `creative_briefs` (id PK, title, genre, tone, goalsJson).
- `creative_ideas` (id PK, briefId, title, description, tagsJson).

## Risiko jujur
- Deterministic command dispatch + pipeline state machine; bukan LLM inference real.
