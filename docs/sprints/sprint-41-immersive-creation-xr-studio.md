# Sprint 41 — Immersive Creation + XR Studio

> **STATUS: DONE** — 41.1–41.21 GREEN, 779 PASS, analyze 0 issues, build web ✓.

> **Sumber judul kanonik**: uteke memory `90d845b9` ("S41 Immersive Creation+XR Studio") — hanya judul.
> Fondasi audit: render 3D S32 (scene graph, camera, material, light, transform3d, scene node),
> virtual production S35 (stage, shot, camera). Belum ada XR/spatial/stereoscopic/headset.

## Tujuan

Membangun **Immersive Creation + XR Studio** deterministic: spatial scene, stereoscopic
camera, XR session, room-scale transform, headset tracking, passthrough mode. Bukan device I/O real.

## Batas lingkup (jujur)

- **IN**: `SpatialScene` (spatial anchors + content), `StereoscopicCamera` (left/right eye + IPD),
  `XrSession` (state idle/starting/running/paused), `XrHeadsetPose` (position/quaternion),
  `RoomScaleTransform` (origin + bounds), `XrHandPose` (left/right + pinch),
  `PassthroughMode` enum, UI `XrStudioPanel` + route `/xr-studio`.
- **OUT**: real headset device I/O, actual WebXR/OpenXR runtime, live hand tracking.

## Step

### Blok A — Stereoscopic + pose (41.1–41.3)
- **41.1** `XrHeadsetPose` (position + orientation).
- **41.2** `StereoscopicCamera` (left/right eye + IPD).
- **41.3** eye offset calculation.

### Blok B — XR session (41.4–41.6)
- **41.4** `XrSessionState` enum (idle, starting, running, paused, ended).
- **41.5** `XrSession` (start/pause/resume/end transitions).
- **41.6** invalid transition rejection.

### Blok C — Spatial scene + room scale (41.7–41.9)
- **41.7** `SpatialAnchor` (id, position, contentId).
- **41.8** `SpatialScene` (add/query anchors).
- **41.9** `RoomScaleTransform` (origin + bounds + inBounds check).

### Blok D — Hand + passthrough (41.10–41.12)
- **41.10** `XrHandPose` (left/right + pinch).
- **41.11** `PassthroughMode` enum (off, grayscale, color).
- **41.12** `XrInputState` (hands + headset + passthrough).

### Blok E — Persistence (41.13–41.15)
- **41.13** Table `xr_sessions` (schema v51→**v52**).
- **41.14** Table `spatial_anchors`.
- **41.15** `XrRepository` + restart persistence test.

### Blok F — UI (41.16–41.18)
- **41.16** `XrStudioPanel` (session state + anchor count).
- **41.17** `SpatialAnchorList`.
- **41.18** `XrSessionView`.

### Blok G — Demo + wire (41.19–41.21)
- **41.19** Wire route `/xr-studio`.
- **41.20** `DemoXrStudio` built-in.
- **41.21** DoD: full regression gates + commit + tandai DONE.

## Schema v52
- `xr_sessions` (id PK, state, startedAt, endedAt).
- `spatial_anchors` (id PK, sessionId, contentId, x, y, z).

## Risiko jujur
- Deterministic spatial/state model; bukan XR device I/O atau WebXR runtime real.
