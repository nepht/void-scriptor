import 'package:flutter/material.dart';

import '../../../features/collaboration/domain/collaborator.dart';
import '../../../features/collaboration/presentation/project_comments_panel.dart';

/// Collaboration comments surface wired into the router (Step 29.20).
class CollaborationCommentsScreen extends StatefulWidget {
  const CollaborationCommentsScreen({
    super.key,
    this.initialComments = const [],
  });

  final List<ProjectComment> initialComments;

  @override
  State<CollaborationCommentsScreen> createState() =>
      _CollaborationCommentsScreenState();
}

class _CollaborationCommentsScreenState
    extends State<CollaborationCommentsScreen> {
  late final List<ProjectComment> _comments = [...widget.initialComments];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Comments')),
      body: ProjectCommentsPanel(
        comments: _comments,
        onPost: (body) {
          setState(() {
            _comments.add(
              ProjectComment(
                id: 'local-${_comments.length}',
                projectId: 'current',
                authorId: 'me',
                targetType: 'project',
                targetId: 'current',
                body: body,
                createdAt: DateTime.now().toUtc(),
              ),
            );
          });
        },
      ),
    );
  }
}
