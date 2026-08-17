/// Sprint 50 — Step 50.63–50.75 Crash Marker, Safe Mode, Diagnostics, Logging.
class CrashMarker {
  const CrashMarker({
    required this.id,
    required this.lastSessionCrashed,
    required this.version,
  });

  final String id;
  final bool lastSessionCrashed;
  final String version;

  bool get shouldSuggestSafeMode => lastSessionCrashed;
}

class SafeModeOptions {
  const SafeModeOptions({
    required this.id,
    this.disablePlugins = false,
    this.disableAi = false,
    this.useFallbackTheme = false,
  });

  final String id;
  final bool disablePlugins;
  final bool disableAi;
  final bool useFallbackTheme;
}

class DiagnosticReport {
  const DiagnosticReport({
    required this.id,
    required this.generatedAt,
    required this.osInfo,
    required this.appVersion,
    this.sections = const {},
  });

  final String id;
  final DateTime generatedAt;
  final String osInfo;
  final String appVersion;
  final Map<String, String> sections;
}

enum LogLevel { debug, info, warn, error, fatal }

class LogEntry {
  const LogEntry({
    required this.id,
    required this.level,
    required this.message,
    required this.timestamp,
  });

  final String id;
  final LogLevel level;
  final String message;
  final DateTime timestamp;
}
