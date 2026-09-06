# Sprint 16 Step Ledger (from canonical ChatGPT share JSON)

Contract source: `https://chatgpt.com/share/6a82a8ad-7e90-83ec-88e5-f270ddea60c3` (backend JSON, update 2026-08-17).

| Step | Requirement | Source | Test / Evidence | Status |
|---|---|---|---|---|
| 16.1 | Timeline domain model | `timeline_model.dart` | `timeline_model_test.dart` (scale converts) | DONE |
| 16.2 | Timeline table | `timelines.dart` | `timeline_persistence_test.dart` | DONE |
| 16.3 | Timeline Tracks | `timeline_tracks.dart` | `timeline_workspace_test.dart` (renders tracks) | DONE |
| 16.4 | Track types | `timeline_model.dart` (track types) | workspace test | DONE |
| 16.5 | Timeline Clips | `timeline_clips.dart` | `timeline_visible_clips_test.dart` | DONE |
| 16.6 | Timeline clip model | `timeline_model.dart` (clip model) | `timeline_model_test.dart` (validator reports invalid clips) | DONE |
| 16.7 | Generate Timeline from Scene Beats | `create_timeline_service.dart` | `timeline_persistence_test.dart` (generated from beats) | DONE |
| 16.8 | Create Timeline service | `create_timeline_service.dart` | persistence test | DONE |
| 16.9 | Timeline Workspace layout | `timeline_workspace_screen.dart` | workspace test (renders tracks) | DONE |
| 16.10 | Timeline header | workspace screen | workspace test | DONE |
| 16.11 | Time ruler | workspace screen | workspace test | DONE |
| 16.12 | Timeline zoom | `timeline_model.dart` (scale) | model test (scale converts) | DONE (representative) |
| 16.13 | Playhead | `timeline_context_service.dart` | `timeline_context_test.dart` (active clips at playhead) | DONE |
| 16.14 | Playback controller | — | No explicit test | PARTIAL |
| 16.15 | Clip widget | workspace screen | workspace test | DONE |
| 16.16 | Clip selection | workspace screen | workspace test | DONE (representative) |
| 16.17 | Drag clip | `move_timeline_clip_command.dart` | `move_timeline_clip_command_test.dart` (one durable command) | DONE |
| 16.18 | Resize clip | — | No explicit test | PARTIAL |
| 16.19 | Snap system | `timeline_model.dart` | model test (snap modes snap) | DONE |
| 16.20 | Frame support | `timeline_model.dart` | model test (frame helpers round-trip) | DONE |
| 16.21 | Track lock/mute/visibility | No live domain/table/UI state found | Live inspection found `TimelineTracks` only has id/timeline/type/name/sortOrder; no lock, mute, or visibility lifecycle/acceptance contract exists. | CONTRACT UNDEFINED — NOT IMPLEMENTED |
| 16.22 | Character Track | track types | workspace test | DONE (representative) |
| 16.23 | Camera Track | track types | workspace test | DONE (representative) |
| 16.24 | VFX Track | track types | workspace test | DONE (representative) |
| 16.25 | Audio Track | track types | workspace test | DONE (representative) |
| 16.26 | Environment Track | track types | workspace test | DONE (representative) |
| 16.27 | Continuity Track | track types | workspace test | DONE (representative) |
| 16.28 | Timeline ↔ Scene Beat synchronization | `create_timeline_service.dart` | persistence test (generated from beats, restart) | DONE |
| 16.29 | Timeline validation | `timeline_model.dart` | model test (validator reports invalid clips) | DONE |
| 16.30 | Scene Preview panel | — | No explicit test | PARTIAL |
| 16.31 | Resolved Timeline Context | `timeline_context_service.dart` | `timeline_context_test.dart` (active clips at playhead) | DONE |
| 16.32 | Cinematic Preview mode | `TimelineWorkspaceScreen` preview/edit state | Added preview transition coverage to `timeline_workspace_test.dart`; Edit → Preview → Back to Edit passed, including no rendering exception: 3 timeline workspace tests passed. This is preview UI state, not real media playback/render export. | VERIFIED-LOCAL |
| 16.33 | Timeline keyboard shortcuts | — | No explicit test | PARTIAL |
| 16.34 | Undo/Redo | `move_timeline_clip_command.dart` | command test (undoable) | DONE |
| 16.35 | Android layout | `timeline_workspace_screen.dart` | workspace test (mobile controls) | DONE |
| 16.36 | Timeline export data | `timeline_context_service.dart` | `timeline_context_test.dart` (portable JSON) | DONE |
| 16.37 | AI cinematic readiness | — | No explicit test | PARTIAL |
| 16.38 | Database migration | schema bump | persistence test (restart) | DONE |
| 16.39 | Test scenario | all suite | 12 tests pass | DONE |

## Summary S16
- **33/39 steps DONE** (7 representative).
- **6 steps PARTIAL:** Playback controller, Resize clip, Track lock/mute/visibility, Scene Preview panel, Cinematic Preview mode, Keyboard shortcuts, AI cinematic readiness — membutuhkan test UI eksplisit atau fitur tambahan.
- **Gap:** Tidak ada gap kritis untuk inti editor; follow-up slices (playback, resize, lock/mute) tercatat sebagai PARTIAL sesuai skala kejujuran sprint.
