# Sprint 34 — Audio Engine Pipeline

> **STATUS: PROPOSAL**
> **Sumber judul kanonik**: uteke memory `90d845b9` ("S34 Advanced Audio Engine") — hanya judul.
> Step dirancan dari judul + audit repo nyata: `AudioMixer` (gain/solo/mute/ducking — model),
> `AudioTimelineClipModel` (fade/pan/gain), `AudioAutomationKeyframeModel`, `AudioFileModel`.

## Tujuan

Membangun **audio DSP pipeline CPU** yang deterministic dan teruji unit-level: sample buffer,
resampling, channel mixing, gain envelope (linear/exponential), LFO modulasi, RMS metering,
dan bus routing. Bukan pemutaran audio real-time ( tetap di belakang platform player boundary).

## Batas lingkup (jujur)

- **IN**: `SampleBuffer` (float32 mono/stereo), `Resampler` (linear), `ChannelMixer` (mono↔stereo),
  `GainEnvelope` (linear gain ramp + fade in/out), `LFO` (sine/square/triangle), `RmsMeter` (RMS
  window), `AudioBus` (bus routing + send level), `AudioRenderContext` (pipeline evaluate → buffer).
- **OUT**: real-time audio thread, WASAPI/CoreAudio callback, codec decode (MP3/AAC),
  convolution reverb, spectral FFT, dynamic range compressor. Ini **synthetic DSP engine**
  untuk drive gain/volume automation + metering.

## Step

### Blok A — Sample buffer + resampling (34.1–34.3)
- **34.1** `SampleBuffer` (float32, channels, sampleRate, frameCount).
- **34.2** `Resampler` (linear interpolation, rate convert).
- **34.3** `ChannelMixer` (mono→stereo, stereo→mono, stereo pan law).

### Blok B — Envelope + LFO (34.4–34.6)
- **34.4** `GainEnvelope` (linear ramp + fade in/out).
- **34.5** `LFO` (sine/square/triangle, frequency, phase).
- **34.6** `AutomationCurve` (linear/exponential segment).

### Blok C — Bus + metering (34.7–34.9)
- **34.7** `AudioBus` (name, gain, sends).
- **34.8** `RmsMeter` (rolling window RMS).
- **34.9** `AudioBusRouter` (main + sends routing).

### Blok D — Pipeline evaluate (34.10–34.12)
- **34.10** `AudioRenderContext` (clip + bus evaluate).
- **34.11** `evaluate` returns buffer + stats.
- **34.12** Pipeline with multiple clips + mixdown.

### Blok E — Persistence (34.13–34.15)
- **34.13** Table `audio_automation_curves` (schema v44→**v45**).
- **34.14** `AutomationRepository` (persist curve points).
- **34.15** Restart persistence test (file-backed).

### Blok F — UI (34.16–34.18)
- **34.16** `AudioMeterPanel` (RMS bar + gain).
- **34.17** `AutomationCurveEditor` (points + segments).
- **34.18** `BusControlsPanel`.

### Blok G — Demo + wire (34.19–34.21)
- **34.19** Wire route `/audio`.
- **34.20** `DemoAudioScene` built-in.
- **34.21** DoD: full regression gates + commit + tandai DONE.

## Schema v45

- `audio_automation_curves` (id PK, clipId FK, parameter, interpolation, timeSeconds, value).

## Risiko jujur

- CPU DSP engine; bukan real-time audio thread (tetap di belakang platform player).
- Resampling linear (bukan sinc/FFT).
- Metering RMS (bukan perceptually-weighted LUFS).
