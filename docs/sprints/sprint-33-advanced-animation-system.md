# Sprint 33 — Advanced Animation System

> **STATUS: PROPOSAL**
> **Sumber judul kanonik**: uteke memory `90d845b9` ("S33 Advanced Animation System") — hanya judul.
> Step dirancang oleh nephthys dari judul + audit repo nyata: `VfxKeyframeModel` (keyframe data single-value),
> `TimelineModel` (fps/time), `TimelineClipModel` (start/duration), `audio_timeline`, `timeline_clips`.

## Tujuan

Membangun **sistem animasi keyframe** yang deterministic dan teruji unit-level: easing curve,
interpolator (scalar/vector/color), keyframe track + evaluation, animation clip (multi-track),
playback state machine, dan UI preview + route. Murni CPU/evaluasi — bukan GPU skinning.

## Batas lingkup (jujur)

- **IN**: `EasingCurve` (linear/easeIn/easeOut/easeInOut + custom), `Interpolator`
  (scalar lerp, vector lerp, color lerp), `Keyframe<T>` + `KeyframeTrack<T>` (evaluate at time,
  with easing), `AnimationClip` (multi-track, duration, evaluate pose), `AnimationPlayer`
  (play/pause/seek/loop + state), UI `AnimationPreviewPanel`, route `/animation`.
- **OUT**: skeletal/skinning rig, inverse kinematics (IK), physics simulation, GPU vertex
  animation, blend trees, mocap retargeting. Ini sistem **keyframe evaluation + playback**
  untuk drive properti scene-graph S32.

## Step

### Blok A — Easing + interpolator (33.1–33.3)
- **33.1** `EasingCurve` (linear, easeIn, easeOut, easeInOut + apply(t)).
- **33.2** `Interpolator` scalar lerp.
- **33.3** `Interpolator` vector lerp (Vector3) + color lerp (RenderColor).

### Blok B — Keyframe track (33.4–33.6)
- **33.4** `Keyframe<T>` (time + value).
- **33.5** `KeyframeTrack<T>` (sorted keyframes, evaluate at time with easing).
- **33.6** Track validation (sorted, unique times, non-negative).

### Blok C — Animation clip (33.7–33.9)
- **33.7** `AnimationClip` (tracks by name + duration).
- **33.8** `evaluate(time)` → pose (Map<String, Object> sampled values).
- **33.9** Loop/wrap + clamp sampling modes.

### Blok D — Playback (33.10–33.12)
- **33.10** `AnimationPlayer` (play/pause/stop/seek).
- **33.11** Playback state (playing/paused/stopped + current time).
- **33.12** Loop mode (once/loop/ping-pong).

### Blok E — Persistence (33.13–33.15)
- **33.13** Table `animation_tracks` + `animation_keyframes` (schema v43→**v44**).
- **33.14** `AnimationRepository` (persist clip + keyframes).
- **33.15** Restart persistence test (file-backed).

### Blok F — UI (33.16–33.18)
- **33.16** `AnimationPreviewPanel` (stats + current time).
- **33.17** `AnimationTimelineView` (tracks + keyframes visual).
- **33.18** Playback controls widget.

### Blok G — Wire + DoD (33.19–33.21)
- **33.19** Wire route `/animation`.
- **33.20** Demo animation clip (built-in).
- **33.21** DoD: full regression gates + commit + push + tandai DONE.

## Schema v44
- `animation_tracks` (id PK, clipId, name, targetProperty, interpolation, durationSeconds).
- `animation_keyframes` (id PK, trackId FK, timeSeconds, value; PK composite trackId+timeSeconds).

## Risiko jujur
- Evaluasi keyframe CPU, deterministic; bukan skeletal/skinning GPU.
- Playback real-time frame loop butuh ticker Flutter (UI layer); core player advance via `advance(delta)`.
