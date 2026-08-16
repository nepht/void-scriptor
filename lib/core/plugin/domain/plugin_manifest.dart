import 'plugin_api_version.dart';

class PluginManifestException implements Exception {
  const PluginManifestException(this.message);
  final String message;
  @override
  String toString() => 'PluginManifestException: $message';
}

/// Parsed + validated plugin manifest (Step 31.2).
class PluginManifest {
  const PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.apiVersion,
    required this.capabilities,
    required this.permissions,
    required this.entrypoint,
  });

  final String id;
  final String name;
  final String version;
  final String author;
  final PluginApiVersion apiVersion;
  final List<String> capabilities;
  final List<String> permissions;
  final String entrypoint;

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final version = json['version'];
    final author = json['author'];
    final apiVersion = json['apiVersion'];
    final entrypoint = json['entrypoint'];

    if (id is! String || id.trim().isEmpty) {
      throw const PluginManifestException('missing "id"');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const PluginManifestException('missing "name"');
    }
    if (version is! String || version.trim().isEmpty) {
      throw const PluginManifestException('missing "version"');
    }
    if (author is! String) {
      throw const PluginManifestException('missing "author"');
    }
    if (apiVersion is! String) {
      throw const PluginManifestException('missing "apiVersion"');
    }
    if (entrypoint is! String || entrypoint.trim().isEmpty) {
      throw const PluginManifestException('missing "entrypoint"');
    }

    return PluginManifest(
      id: id,
      name: name,
      version: version,
      author: author,
      apiVersion: PluginApiVersion.parse(apiVersion),
      capabilities: _stringList(json['capabilities']),
      permissions: _stringList(json['permissions']),
      entrypoint: entrypoint,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'author': author,
    'apiVersion': apiVersion.toString(),
    'capabilities': capabilities,
    'permissions': permissions,
    'entrypoint': entrypoint,
  };
}

enum PluginStatus { installed, enabled, disabled, failed }

/// Validated plugin descriptor with runtime status (Step 31.3).
class PluginDescriptor {
  PluginDescriptor({
    required this.manifest,
    this.status = PluginStatus.installed,
  });

  final PluginManifest manifest;
  PluginStatus status;

  String get id => manifest.id;
}
