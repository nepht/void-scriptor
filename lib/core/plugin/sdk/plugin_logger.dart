enum PluginLogLevel { info, warn, error }

class PluginLogEntry {
  const PluginLogEntry(this.level, this.message);
  final PluginLogLevel level;
  final String message;
}

/// Scoped logger for a plugin (Step 31.4).
class PluginLogger {
  PluginLogger({required this.pluginId, this.maxEntries = 200});

  final String pluginId;
  final int maxEntries;
  final List<PluginLogEntry> _entries = [];

  List<PluginLogEntry> get entries => List.unmodifiable(_entries);

  void info(String message) => _log(PluginLogLevel.info, message);
  void warn(String message) => _log(PluginLogLevel.warn, message);
  void error(String message) => _log(PluginLogLevel.error, message);

  void _log(PluginLogLevel level, String message) {
    _entries.add(PluginLogEntry(level, '[$pluginId] $message'));
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
  }
}
