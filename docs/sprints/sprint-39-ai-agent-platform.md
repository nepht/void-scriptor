# Sprint 39 — AI Agent Platform

> **STATUS: DONE** — 39.1–39.21 GREEN, 738 PASS, analyze 0 issues, build web ✓.

> **Sumber judul kanonik**: uteke memory `90d845b9` ("S39 AI Agent Platform") — hanya judul.
> Fondasi audit: `features/ai` (prompt composer, provider workspace, generation queue,
> gallery), plugin system S31 (host/registry/sandbox). Belum ada agent/tool/orchestration.

## Tujuan

Membangun **AI agent platform** deterministic: agent definition, tool, tool registry,
agent runtime (reasoning loop), task orchestration, agent memory. Bukan LLM API real.

## Batas lingkup (jujur)

- **IN**: `AgentDefinition` (id, name, systemPrompt, tools), `AgentTool` (name, description,
  params), `ToolRegistry` (register/lookup), `AgentMemory` (working memory + turn log),
  `AgentRuntime` (run task → tool calls → result), `AgentState` (idle/running/done/failed),
  `AgentOrchestrator` (multiple agents + task routing), UI `AgentPlatformPanel` + route `/agents`.
- **OUT**: real LLM inference, external model API calls, function-calling against live services.
  Ini **deterministic tool dispatch + simulated reasoning loop** CPU.

## Step

### Blok A — Tool (39.1–39.3)
- **39.1** `AgentTool` (name, description, params).
- **39.2** `ToolResult` (success, output).
- **39.3** `ToolRegistry` (register/lookup/invoke).

### Blok B — Agent definition (39.4–39.6)
- **39.4** `AgentDefinition` (id, name, systemPrompt, toolNames).
- **39.5** `AgentMemory` (working memory + turn log).
- **39.6** `AgentState` enum (idle, running, done, failed).

### Blok C — Agent runtime (39.7–39.9)
- **39.7** `AgentRuntime` (run task → tool dispatch).
- **39.8** Runtime records tool calls + results in memory.
- **39.9** Runtime failure propagation (missing tool → failed).

### Blok D — Orchestrator (39.10–39.12)
- **39.10** `AgentOrchestrator` (register agents).
- **39.11** Task routing by capability.
- **39.12** Orchestrator runs agent and aggregates result.

### Blok E — Persistence (39.13–39.15)
- **39.13** Table `agents` (schema v49→**v50**).
- **39.14** Table `agent_tool_calls`.
- **39.15** `AgentRepository` + restart persistence test.

### Blok F — UI (39.16–39.18)
- **39.16** `AgentPlatformPanel` (agent count + status).
- **39.17** `AgentList`.
- **39.18** `AgentRunView`.

### Blok G — Demo + wire (39.19–39.21)
- **39.19** Wire route `/agents`.
- **39.20** `DemoAgents` built-in.
- **39.21** DoD: full regression gates + commit + tandai DONE.

## Schema v50
- `agents` (id PK, name, systemPrompt, toolNamesJson).
- `agent_tool_calls` (id PK, agentId, toolName, input, output, timestamp).

## Risiko jujur
- Deterministic tool dispatch + simulated reasoning loop; bukan LLM inference real.
