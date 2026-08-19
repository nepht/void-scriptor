import 'dart:io';

import 'package:flutter/material.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';
import 'package:void_scriptor/design_system/theme/void_palette.dart';
import '../application/debounced_autosave.dart';
import '../application/story_docx_exporter.dart';
import '../application/story_markdown_exporter.dart';

import '../data/story_repository_impl.dart';

class StoryWorkspaceScreen extends StatefulWidget {
  const StoryWorkspaceScreen({
    super.key,
    required this.storyId,
    this.repository,
    this.sceneId,
    this.exportDirectory,
  });
  final String storyId;
  final StoryRepositoryImpl? repository;
  final String? sceneId;
  final Directory? exportDirectory;
  @override
  State<StoryWorkspaceScreen> createState() => _StoryWorkspaceScreenState();
}

class _StoryWorkspaceScreenState extends State<StoryWorkspaceScreen> {
  final _draft = TextEditingController();
  final _autosave = DebouncedAutosave();
  int _words = 0;
  String? _selectedSceneId;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final repository = widget.repository;
    final sceneId = widget.sceneId;
    if (repository == null || sceneId == null) return;
    final content = await repository.getSceneDraft(sceneId);
    if (!mounted || content == null) return;
    _draft.value = TextEditingValue(text: content);
    setState(() => _updateWordCount(content));
  }

  void _updateWordCount(String value) {
    _words = value.trim().isEmpty
        ? 0
        : value.trim().split(RegExp(r'\s+')).length;
  }

  @override
  void dispose() {
    _autosave.dispose();
    _draft.dispose();
    super.dispose();
  }

  void _count(String value) {
    setState(() => _updateWordCount(value));
    final repository = widget.repository;
    final sceneId = widget.sceneId;
    if (repository != null && sceneId != null) {
      _autosave.schedule(() => repository.saveSceneDraft(sceneId, value));
    }
  }

  Future<void> _exportMarkdown() async {
    final repository = widget.repository;
    final directory = widget.exportDirectory;
    if (repository == null || directory == null) return;
    final file = await const StoryMarkdownExporter().writeExport(
      repository,
      widget.storyId,
      exportDirectory: directory,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Markdown diekspor: ${file.path}')));
  }

  Future<void> _exportDocx() async {
    final repository = widget.repository;
    final directory = widget.exportDirectory;
    if (repository == null || directory == null) return;
    final file = await const StoryDocxExporter().writeExport(
      repository,
      widget.storyId,
      exportDirectory: directory,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('DOCX diekspor: ${file.path}')));
  }

  Widget _exportActions() => Wrap(
    spacing: 8,
    children: [
      OutlinedButton.icon(
        onPressed: widget.repository == null || widget.exportDirectory == null
            ? null
            : _exportMarkdown,
        icon: const Icon(Icons.download_outlined),
        label: const Text('Export Markdown'),
      ),
      OutlinedButton.icon(
        onPressed: widget.repository == null || widget.exportDirectory == null
            ? null
            : _exportDocx,
        icon: const Icon(Icons.article_outlined),
        label: const Text('Export DOCX'),
      ),
    ],
  );

  Widget _buildLiveChapters(VoidPalette p) {
    final repository = widget.repository;
    if (repository == null) {
      return const Text('Belum ada session project aktif.');
    }
    return FutureBuilder<StoryHierarchy>(
      future: repository.getStoryHierarchy(widget.storyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            snapshot.hasError
                ? 'Story belum memiliki struktur.'
                : 'Memuat struktur story...',
          );
        }
        final hierarchy = snapshot.data!;
        final rows = <Widget>[];
        for (final chapter in hierarchy.chapters) {
          rows.add(_Row(label: chapter.title));
          for (final scene in chapter.scenes) {
            rows.add(
              _Row(
                label: scene.title,
                indent: true,
                selected: scene.id == (_selectedSceneId ?? widget.sceneId),
                onTap: () {
                  setState(() => _selectedSceneId = scene.id);
                  _loadDraftFor(scene.id);
                },
              ),
            );
          }
        }
        return rows.isEmpty
            ? const Text('Belum ada chapter atau scene.')
            : Column(children: rows);
      },
    );
  }

  Future<void> _loadDraftFor(String sceneId) async {
    final content = await widget.repository?.getSceneDraft(sceneId);
    if (!mounted) return;
    _draft.value = TextEditingValue(text: content ?? '');
    setState(() => _updateWordCount(content ?? ''));
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
              Column(
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
                  const SizedBox(height: 10),
                  _exportActions(),
                ],
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
              _Panel(title: 'CHAPTERS', child: _buildLiveChapters(p)),
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
  const _Row({
    required this.label,
    this.indent = false,
    this.selected = false,
    this.onTap,
  });
  final String label;
  final bool indent;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      color: selected ? context.palette.panelSecondary : null,
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
