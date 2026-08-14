import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../application/portable_project_service.dart';
import '../application/project_resilience_controller.dart';
import '../application/project_session_manager.dart';
import '../application/project_storage_analyzer.dart';

enum ProjectResilienceView {
  diagnostics,
  repair,
  backups,
  export,
  import,
  storage,
  cache,
  trash,
}

class ProjectResilienceAction {
  const ProjectResilienceAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });
  final String label;
  final IconData icon;
  final Future<void> Function()? onPressed;
  final bool destructive;
}

class ProjectResilienceCenterScreen extends StatelessWidget {
  const ProjectResilienceCenterScreen({
    super.key,
    required this.title,
    required this.items,
    this.onAction,
    this.actions = const [],
    this.busy = false,
    this.message,
  });
  final String title;
  final List<String> items;
  final VoidCallback? onAction;
  final List<ProjectResilienceAction> actions;
  final bool busy;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 3 : 1;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Project resilience',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message!),
              ],
              const SizedBox(height: 16),
              if (busy) const LinearProgressIndicator(),
              GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 4.5 : 2.2,
                children: [
                  for (final item in items)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.verified_outlined),
                        title: Text(item),
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
                    onPressed: busy ? null : onAction,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Scan Again'),
                  ),
                  for (final action in actions)
                    action.destructive
                        ? OutlinedButton.icon(
                            onPressed: busy || action.onPressed == null
                                ? null
                                : action.onPressed,
                            icon: Icon(action.icon),
                            label: Text(action.label),
                          )
                        : FilledButton.tonalIcon(
                            onPressed: busy || action.onPressed == null
                                ? null
                                : action.onPressed,
                            icon: Icon(action.icon),
                            label: Text(action.label),
                          ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProjectResilienceWorkspaceScreen extends ConsumerStatefulWidget {
  const ProjectResilienceWorkspaceScreen({
    super.key,
    required this.view,
    this.session,
  });

  final ProjectResilienceView view;
  final ProjectSession? session;

  @override
  ConsumerState<ProjectResilienceWorkspaceScreen> createState() =>
      _ProjectResilienceWorkspaceScreenState();
}

class _ProjectResilienceWorkspaceScreenState
    extends ConsumerState<ProjectResilienceWorkspaceScreen> {
  ProjectResilienceSnapshot? _snapshot;
  String? _projectId;
  String? _message;
  bool _busy = false;
  final _archivePath = TextEditingController();

  @override
  void dispose() {
    _archivePath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session =
        widget.session ?? ref.watch(projectSessionProvider).valueOrNull;
    if (session == null) {
      return const ProjectResilienceCenterScreen(
        title: 'Project Resilience',
        items: ['No active project'],
        message: 'Open a project before using diagnostics and recovery tools.',
      );
    }
    if (_projectId != session.package.projectId) {
      _projectId = session.package.projectId;
      Future<void>.microtask(() => _scan(session));
    }
    final snapshot = _snapshot;
    final content = _content(session, snapshot);
    return ProjectResilienceCenterScreen(
      title: content.title,
      items: content.items,
      actions: content.actions,
      busy: _busy,
      message: _message,
      onAction: () => _scan(session),
    );
  }

  _ViewContent _content(
    ProjectSession session,
    ProjectResilienceSnapshot? snapshot,
  ) {
    final controller = ProjectResilienceController(session);
    if (snapshot == null) {
      return _ViewContent(
        title: _title(widget.view),
        items: const ['Scanning…'],
      );
    }
    switch (widget.view) {
      case ProjectResilienceView.diagnostics:
        return _ViewContent(
          title: 'Project Diagnostics',
          items: [
            'Manifest: ${snapshot.integrity.manifestValid ? 'valid' : 'invalid'}',
            'Database: ${snapshot.integrity.databaseValid ? 'healthy' : 'damaged'}',
            'Portable: ${snapshot.integrity.portable ? 'yes' : 'needs attention'}',
            'Storage: ${_formatBytes(snapshot.storage.totalBytes)}',
          ],
        );
      case ProjectResilienceView.repair:
        return _ViewContent(
          title: 'Project Repair',
          items: [
            'Missing files: ${snapshot.integrity.missingFiles}',
            'Orphan files: ${snapshot.integrity.orphanFiles}',
            'External dependencies: ${snapshot.integrity.externalFiles}',
          ],
          actions: [
            ProjectResilienceAction(
              label: 'Move Orphans to Trash',
              icon: Icons.auto_fix_high,
              onPressed: snapshot.integrity.orphanFiles == 0
                  ? null
                  : () => _run(
                      session,
                      () async =>
                          'Moved ${await controller.moveOrphansToTrash()} orphan files to trash.',
                    ),
            ),
          ],
        );
      case ProjectResilienceView.backups:
        return _ViewContent(
          title: 'Project Backups',
          items: [
            'Available backups: ${snapshot.backupItems}',
            'Database: ${_formatBytes(snapshot.storage.bytesFor(ProjectStorageCategory.database))}',
          ],
          actions: [
            ProjectResilienceAction(
              label: 'Create Backup',
              icon: Icons.backup,
              onPressed: () => _run(session, () async {
                final backup = await controller.createBackup(
                  note: 'Manual UI backup',
                );
                return 'Backup created: ${backup.path}';
              }),
            ),
          ],
        );
      case ProjectResilienceView.export:
        return _ViewContent(
          title: 'Project Export',
          items: const [
            'Manifest',
            'Database',
            'Managed assets',
            'Cache excluded',
          ],
          actions: [
            ProjectResilienceAction(
              label: 'Export Portable Package',
              icon: Icons.archive_outlined,
              onPressed: () => _run(session, () async {
                final archive = await controller.exportPortable();
                return 'Portable package exported: ${archive.path}';
              }),
            ),
          ],
        );
      case ProjectResilienceView.import:
        return _ViewContent(
          title: 'Project Import',
          items: [
            'Archive path: ${_archivePath.text.isEmpty ? 'not selected' : _archivePath.text}',
            'Import mode: copy with a new project ID',
          ],
          actions: [
            ProjectResilienceAction(
              label: 'Enter Archive Path',
              icon: Icons.edit,
              onPressed: () => _requestArchivePath(context),
            ),
            ProjectResilienceAction(
              label: 'Import as Copy',
              icon: Icons.unarchive_outlined,
              onPressed: _archivePath.text.isEmpty
                  ? null
                  : () => _run(session, () async {
                      final imported =
                          await PortableProjectImportCoordinator(
                            registry: ref.read(projectRegistryServiceProvider),
                          ).importAndRegister(
                            File(_archivePath.text),
                            destination: session.package.root.parent,
                            asCopy: true,
                          );
                      return 'Imported project: ${imported.root.path}';
                    }),
            ),
          ],
        );
      case ProjectResilienceView.storage:
        return _ViewContent(
          title: 'Project Storage',
          items: [
            'Total: ${_formatBytes(snapshot.storage.totalBytes)}',
            for (final category in ProjectStorageCategory.values)
              '${category.name}: ${_formatBytes(snapshot.storage.bytesFor(category))}',
            ...snapshot.storage.largestFiles
                .take(5)
                .map(
                  (file) => '${file.relativePath}: ${_formatBytes(file.bytes)}',
                ),
          ],
        );
      case ProjectResilienceView.cache:
        return _ViewContent(
          title: 'Project Cache',
          items: [
            'Cache size: ${_formatBytes(snapshot.storage.bytesFor(ProjectStorageCategory.cache))}',
            'Safe to regenerate after deletion',
          ],
          actions: [
            ProjectResilienceAction(
              label: 'Clear Cache',
              icon: Icons.cleaning_services,
              onPressed: () => _run(session, () async {
                await controller.clearCache();
                return 'Project cache cleared.';
              }),
            ),
          ],
        );
      case ProjectResilienceView.trash:
        return _ViewContent(
          title: 'Project Trash',
          items: ['Trash items: ${snapshot.trashItems}'],
          actions: [
            ProjectResilienceAction(
              label: 'Restore Latest',
              icon: Icons.restore,
              onPressed: snapshot.trashItems == 0
                  ? null
                  : () => _run(session, () async {
                      final restored = await controller.restoreLatestTrash();
                      return restored
                          ? 'Latest item restored.'
                          : 'No item restored.';
                    }),
            ),
            ProjectResilienceAction(
              label: 'Empty Trash',
              icon: Icons.delete_forever,
              destructive: true,
              onPressed: snapshot.trashItems == 0
                  ? null
                  : () => _run(session, () async {
                      final removed = await controller.emptyTrash();
                      return 'Permanently removed $removed trash items.';
                    }),
            ),
          ],
        );
    }
  }

  Future<void> _scan(ProjectSession session) async {
    if (!mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final snapshot = await ProjectResilienceController(session).scan();
      if (mounted) setState(() => _snapshot = snapshot);
    } catch (error) {
      if (mounted) setState(() => _message = 'Scan failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run(
    ProjectSession session,
    Future<String> Function() operation,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final message = await operation();
      final snapshot = await ProjectResilienceController(session).scan();
      if (mounted) {
        setState(() {
          _message = message;
          _snapshot = snapshot;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _message = 'Operation failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestArchivePath(BuildContext context) async {
    final controller = TextEditingController(text: _archivePath.text);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Portable archive path'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'C:\\Projects\\MyProject.voidproject',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Use Path'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty && mounted) {
      setState(() => _archivePath.text = value);
    }
  }

  String _title(ProjectResilienceView view) => switch (view) {
    ProjectResilienceView.diagnostics => 'Project Diagnostics',
    ProjectResilienceView.repair => 'Project Repair',
    ProjectResilienceView.backups => 'Project Backups',
    ProjectResilienceView.export => 'Project Export',
    ProjectResilienceView.import => 'Project Import',
    ProjectResilienceView.storage => 'Project Storage',
    ProjectResilienceView.cache => 'Project Cache',
    ProjectResilienceView.trash => 'Project Trash',
  };

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _ViewContent {
  const _ViewContent({
    required this.title,
    required this.items,
    this.actions = const [],
  });
  final String title;
  final List<String> items;
  final List<ProjectResilienceAction> actions;
}
