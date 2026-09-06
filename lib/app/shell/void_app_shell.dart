import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../adaptive/void_breakpoints.dart';
import '../routing/app_routes.dart';
import '../../features/projects/presentation/project_persistence_providers.dart';
import 'desktop/void_desktop_shell.dart';
import 'mobile/void_mobile_shell.dart';

class VoidAppShell extends ConsumerStatefulWidget {
  const VoidAppShell({super.key, this.content, this.onLogout, this.projectId});

  final Widget? content;
  final VoidCallback? onLogout;
  final String? projectId;

  @override
  ConsumerState<VoidAppShell> createState() => _VoidAppShellState();
}

class _VoidAppShellState extends ConsumerState<VoidAppShell> {
  bool _opening = false;
  Object? _openError;
  int _openRequest = 0;
  @override
  void initState() {
    super.initState();
    _openProject(widget.projectId);
  }

  @override
  void didUpdateWidget(covariant VoidAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _openProject(widget.projectId);
    }
  }

  void _openProject(String? projectId) {
    final request = ++_openRequest;
    if (projectId == null) {
      _opening = false;
      _openError = null;
      return;
    }
    Future<void>.microtask(() async {
      if (!mounted || request != _openRequest) return;
      setState(() {
        _opening = true;
        _openError = null;
      });
      try {
        await ref.read(projectSessionProvider.notifier).openProject(projectId);
      } catch (error) {
        if (mounted && request == _openRequest) {
          setState(() {
            _openError = error;
          });
        }
      } finally {
        if (mounted && request == _openRequest) {
          setState(() {
            _opening = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_opening || _openError != null) {
      final error = _openError;
      final locked =
          error is StateError &&
          error.message == 'Project has an active or stale session';
      return Scaffold(
        appBar: AppBar(title: const Text('Buka proyek')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _opening ? 'Memuat proyek…' : 'Proyek tidak dapat dibuka',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (_opening)
                    const CircularProgressIndicator()
                  else ...[
                    Text(
                      locked
                          ? 'Proyek memiliki sesi aktif atau penanda sesi lama. Tutup aplikasi lain yang memakai proyek ini. Jika masih terkunci, pulihkan penanda sesi setelah mencadangkan proyek.'
                          : 'Periksa lokasi folder, izin akses, dan kondisi berkas proyek, lalu coba lagi.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _openProject(widget.projectId),
                      child: const Text('Coba lagi'),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.projects),
                      child: const Text('Kembali ke Projects'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < VoidBreakpoints.tablet) {
          return VoidMobileShell(
            content: widget.content,
            onLogout: widget.onLogout,
            projectId: widget.projectId,
          );
        }

        return VoidDesktopShell(
          content: widget.content,
          onLogout: widget.onLogout,
          projectId: widget.projectId,
        );
      },
    );
  }
}
