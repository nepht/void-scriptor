import 'package:flutter/material.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';
import '../application/debounced_autosave.dart';

import '../data/story_repository_impl.dart';

class StoryWorkspaceScreen extends StatefulWidget {
  const StoryWorkspaceScreen({
    super.key,
    required this.storyId,
    this.repository,
    this.sceneId,
  });
  final String storyId;
  final StoryRepositoryImpl? repository;
  final String? sceneId;
  @override
  State<StoryWorkspaceScreen> createState() => _StoryWorkspaceScreenState();
}

class _StoryWorkspaceScreenState extends State<StoryWorkspaceScreen> {
  final _draft = TextEditingController();
  final _autosave = DebouncedAutosave();
  int _words = 0;
  @override
  void dispose() {
    _autosave.dispose();
    _draft.dispose();
    super.dispose();
  }

  void _count(String value) {
    setState(
      () => _words = value.trim().isEmpty
          ? 0
          : value.trim().split(RegExp(r'\s+')).length,
    );
    final repository = widget.repository;
    final sceneId = widget.sceneId;
    if (repository != null && sceneId != null) {
      _autosave.schedule(() => repository.saveSceneDraft(sceneId, value));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Story Bible — ${widget.storyId}',
                style: TextStyle(
                  color: p.textPrimary,
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
                ],
              ),
              const SizedBox(height: 20),
              _Panel(
                title: 'STORY STRUCTURE',
                child: Text(
                  'Story → Arc 1 → Chapter 1 → Scene',
                  style: TextStyle(color: p.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              const _Panel(
                title: 'CHAPTERS',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Row(label: 'Chapter 1 — Awal Perjalanan'),
                    _Row(label: 'Scene 1 — Pembukaan', indent: true),
                    _Row(label: 'Chapter 2 — Konsekuensi'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                title: 'SCENE EDITOR',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scene 1 — Pembukaan',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _draft,
                      minLines: 7,
                      maxLines: 14,
                      onChanged: _count,
                      decoration: const InputDecoration(
                        hintText: 'Tulis draft scene di sini...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '$_words kata',
                          style: TextStyle(color: p.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          'Autosave aktif',
                          style: TextStyle(color: p.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                title: 'STORY BIBLE',
                child: Text(
                  'Premise\nThemes\nTone\nWorld Rules\nCanon Rules',
                  style: TextStyle(color: p.textSecondary, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, this.indent = false});
  final String label;
  final bool indent;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: indent ? 24 : 0, top: 7, bottom: 7),
    child: Row(
      children: [
        Icon(
          indent ? Icons.description_outlined : Icons.menu_book_outlined,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
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
            style: TextStyle(
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

class StoryEditorDraft {
  const StoryEditorDraft({required this.sceneId, required this.content});
  final String sceneId;
  final String content;
}
