/// SDK API version with semver-style compatibility (Step 31.1).
class PluginApiVersion implements Comparable<PluginApiVersion> {
  const PluginApiVersion(this.major, this.minor);

  final int major;
  final int minor;

  factory PluginApiVersion.parse(String value) {
    final parts = value.split('.');
    if (parts.length != 2) {
      throw const FormatException('expected "major.minor"');
    }
    final major = int.tryParse(parts[0]);
    final minor = int.tryParse(parts[1]);
    if (major == null || minor == null) {
      throw const FormatException('expected integer major.minor');
    }
    return PluginApiVersion(major, minor);
  }

  bool isCompatibleWith(PluginApiVersion host) =>
      major == host.major && minor <= host.minor;

  @override
  int compareTo(PluginApiVersion other) {
    final c = major.compareTo(other.major);
    return c != 0 ? c : minor.compareTo(other.minor);
  }

  @override
  String toString() => '$major.$minor';

  @override
  bool operator ==(Object other) =>
      other is PluginApiVersion && other.major == major && other.minor == minor;

  @override
  int get hashCode => Object.hash(major, minor);
}
