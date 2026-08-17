/// Sprint 50 — Step 50.103–50.111 Help, Manuals, About, Licenses.
class HelpArticle {
  const HelpArticle({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String content;
  final List<String> tags;

  bool matches(String query) {
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        content.toLowerCase().contains(q) ||
        tags.any((t) => t.toLowerCase().contains(q));
  }
}

class AboutInfo {
  const AboutInfo({
    required this.version,
    required this.buildNumber,
    this.thirdPartyLicenses = const [],
    this.buildMetadata = const {},
  });

  final String version;
  final String buildNumber;
  final List<String> thirdPartyLicenses;
  final Map<String, String> buildMetadata;
}

enum BugSeverity { blocker, critical, major, minor, cosmetic }

class BugReport {
  const BugReport({
    required this.id,
    required this.severity,
    required this.description,
    required this.reportedAt,
  });

  final String id;
  final BugSeverity severity;
  final String description;
  final DateTime reportedAt;
}
