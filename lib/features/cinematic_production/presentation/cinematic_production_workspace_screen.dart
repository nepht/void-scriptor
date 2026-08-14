import 'package:flutter/material.dart';

class CinematicProductionWorkspaceScreen extends StatelessWidget {
  const CinematicProductionWorkspaceScreen({
    super.key,
    required this.onImportAudio,
    required this.onOpenValidation,
  });
  final VoidCallback onImportAudio;
  final VoidCallback onOpenValidation;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cinematic Production')),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final cards = [
          const _ProductionCard(
            title: 'VFX',
            subtitle: 'States, behavior, keyframes',
            icon: Icons.auto_awesome,
          ),
          const _ProductionCard(
            title: 'Audio',
            subtitle: 'Dialogue, SFX, ambience, music',
            icon: Icons.graphic_eq,
          ),
          const _ProductionCard(
            title: 'Timeline',
            subtitle: 'Clips, automation, intent',
            icon: Icons.timeline,
          ),
        ];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Cinematic Production Database',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage VFX and audio as reusable production assets connected to scenes.',
            ),
            const SizedBox(height: 20),
            if (compact) ...[
              for (final card in cards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: card,
                ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final card in cards)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: card,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onImportAudio,
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Import Audio'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenValidation,
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text('Validation Center'),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _ProductionCard extends StatelessWidget {
  const _ProductionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title, subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle),
        ],
      ),
    ),
  );
}

class ProductionValidationCenterScreen extends StatelessWidget {
  const ProductionValidationCenterScreen({
    super.key,
    required this.issues,
    required this.onRefresh,
  });
  final List<ProductionValidationIssue> issues;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Production Validation Center'),
      actions: [
        IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '${issues.length} validation issue(s)',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (issues.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('No production issues found.'),
            ),
          )
        else ...[
          for (final issue in issues)
            Card(
              child: ListTile(
                leading: Icon(
                  issue.severity == ProductionValidationSeverity.error
                      ? Icons.error
                      : Icons.warning,
                  color: issue.severity == ProductionValidationSeverity.error
                      ? Colors.red
                      : Colors.orange,
                ),
                title: Text(issue.title),
                subtitle: Text(issue.detail),
              ),
            ),
        ],
      ],
    ),
  );
}

enum ProductionValidationSeverity { warning, error }

class ProductionValidationIssue {
  const ProductionValidationIssue({
    required this.title,
    required this.detail,
    required this.severity,
  });
  final String title, detail;
  final ProductionValidationSeverity severity;
}
