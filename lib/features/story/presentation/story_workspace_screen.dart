import 'package:flutter/material.dart';

import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class StoryWorkspaceScreen extends StatelessWidget {
  const StoryWorkspaceScreen({super.key, required this.storyId});
  final String storyId;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.palette.background,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Story Bible — $storyId',
              style:  TextStyle(
                color: context.palette.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Bible')),
                Chip(label: Text('Arcs')),
                Chip(label: Text('Chapters')),
                Chip(label: Text('Scenes')),
                Chip(label: Text('Timeline')),
                Chip(label: Text('Notes')),
              ],
            ),
            const SizedBox(height: 20),
             _StoryPanel(
              title: 'STORY STRUCTURE',
              child: Text(
                'Arcs, chapters, and scenes are persisted in the project database.',
                style: TextStyle(color: context.palette.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
             _StoryPanel(
              title: 'STORY BIBLE',
              child: Text(
                'Premise\nThemes\nTone\nWorld Rules\nCanon Rules',
                style: TextStyle(color: context.palette.textSecondary, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StoryPanel extends StatelessWidget {
  const _StoryPanel({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    color: context.palette.panel,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:  TextStyle(
              color: context.palette.primaryBright,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}
