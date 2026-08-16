# Sprint 35 — Virtual Production Studio

> **STATUS: DONE** — 35.1–35.21 GREEN, 666 PASS, analyze 0 issues, build web ✓.

> **Sumber judul kanonik**: uteke memory `90d845b9` ("S35 Virtual Production Studio") — hanya judul.
> Fondasi audit: `CinematicProductionWorkspaceScreen` (VFX/Audio/Timeline cards + validation),
> render engine S32 (camera/pipeline), animasi S33 (keyframe), audio S34 (DSP).

## Tujuan

Membangun **virtual production toolkit** deterministic: shot list + take management,
camera setup (framing/angle/lens), previz scene (scene-graph + camera → draw list),
virtual stage (aktor/light placement), dan validation (shot completeness). Bukan green-screen keying real-time.

## Batas lingkup (jujur)

- **IN**: `ShotList` + `Shot` (frame/duration/camera), `CameraSetup` (fov/position/target/framing),
  `PrevizScene` (renderables + camera → draw list via S32), `VirtualStage` (actor/light placement
  + depth sort), `TakeRecord` + `TakeManager` (record/retake/approve), `ShotValidator`
  (missing camera/coverage checks), UI `VirtualProductionPanel` + route `/virtual-production`.
- **OUT**: real-time green-screen/chroma keying, LED volume, motion capture integration,
  live camera feed, GPU compositing. Ini **previz + shot management** CPU.

## Step

### Blok A — Shot list + camera setup (35.1–35.3)
- **35.1** `Shot` (id, name, startSeconds, durationSeconds, cameraId).
- **35.2** `CameraSetup` (position/target/fov/aspect + framing enum).
- **35.3** `ShotList` (add/remove/find + total duration + validation).

### Blok B — Previz scene (35.4–35.6)
- **35.4** `PrevizScene` (renderables + camera → S32 pipeline).
- **35.5** `evaluate(time)` → draw list + stats.
- **35.6** Coverage check (per-shot draw list non-empty).

### Blok C — Virtual stage (35.7–35.9)
- **35.7** `VirtualStage` (actors + lights placement).
- **35.8** Depth sort + bounds.
- **35.9** Stage → previz scene integration.

### Blok D — Take management (35.10–35.12)
- **35.10** `TakeRecord` (shotId, takeNumber, state, notes).
- **35.11** `TakeManager` (record/retake/approve + latest take).
- **35.12** Take state machine (pending/review/approved/rejected).

### Blok E — Persistence (35.13–35.15)
- **35.13** Table `shots` + `takes` (schema v45→**v46**).
- **35.14** `ShotRepository` (persist shot + take).
- **35.15** Restart persistence test (file-backed).

### Blok F — UI (35.16–35.18)
- **35.16** `VirtualProductionPanel` (shot list + stats).
- **35.17** `ShotDetailView` (camera setup + takes).
- **35.18** `StagePlacementView` (actors + lights).

### Blok G — Demo + wire (35.19–35.21)
- **35.19** Wire route `/virtual-production`.
- **35.20** `DemoVirtualProduction` built-in.
- **35.21** DoD: full regression gates + commit + tandai DONE.

## Schema v46
- `shots` (id PK, name, startSeconds, durationSeconds, cameraId).
- `takes` (id PK, shotId FK, takeNumber, state, notes).

## Risiko jujur
- Previz + shot management CPU; bukan LED volume / green-screen / mocap.
