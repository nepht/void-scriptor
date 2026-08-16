import 'package:flutter/material.dart';

/// Publish manifest view (Step 36.17).
class PublishManifestView extends StatelessWidget {
  const PublishManifestView({
    super.key,
    required this.version,
    required this.changelog,
  });

  final String version;
  final String changelog;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(version, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text(changelog),
      ],
    );
  }
}
