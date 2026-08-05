# Void Scriptor

Void Scriptor adalah aplikasi desktop Flutter untuk worldbuilding novel **Void Cube Saga** karya Choirudin.

## Fitur Utama

- **8 Mode Workspace**: Character, World, Story, Timeline, AI, Database, Assets, Settings
- **5 Engine Terintegrasi**:
  - Dock Layout (toggle Explorer/Inspector/TopBar + save/restore)
  - Repository (CharacterRepository + JSON persistence)
  - Event Bus (StatusBar live feedback + AiPanel aiRefresh)
  - Theme (6 palet, ThemePicker TopBar, persist on mode change)
  - AI (LocalAiProvider SVG output di `%TEMP%/void_ai_out`)
- **Fitur Lanjutan**: Asset + Relation, Plugin System, Cloud Sync, AI Prompt Builder

## Arsitektur

```
lib/
├── main.dart                    # Entry point
├── core/
│   ├── router.dart              # Navigation
│   ├── theme.dart               # Theme system + SemanticColors
│   ├── event_bus.dart           # Event-driven architecture
│   └── dock_layout.dart         # Dock panel management
├── models/
│   ├── character/character.dart
│   ├── world/world.dart
│   ├── story/story.dart
│   ├── timeline/timeline.dart
│   └── asset/asset.dart
├── services/
│   ├── repository/character_repository.dart
│   ├── ai/ai_provider.dart
│   ├── database/database_service.dart
│   ├── cloud/cloud_service.dart
│   └── plugin/plugin_system.dart
├── widgets.dart                 # Reusable UI components
└── utils.dart                   # Utility functions
```

## Getting Started

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter test
```

## License

MIT
