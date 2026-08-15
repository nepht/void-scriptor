import 'package:flutter/material.dart';

import '../domain/collaborator.dart';

/// Comment thread panel with a compose box (Step 29.18).
class ProjectCommentsPanel extends StatefulWidget {
  const ProjectCommentsPanel({
    super.key,
    required this.comments,
    required this.onPost,
  });

  final List<ProjectComment> comments;
  final void Function(String body) onPost;

  @override
  State<ProjectCommentsPanel> createState() => _ProjectCommentsPanelState();
}

class _ProjectCommentsPanelState extends State<ProjectCommentsPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.comments.isEmpty
              ? const Center(child: Text('No comments yet'))
              : ListView.builder(
                  itemCount: widget.comments.length,
                  itemBuilder: (context, index) {
                    final comment = widget.comments[index];
                    return ListTile(
                      dense: true,
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(comment.body),
                      subtitle: Text(
                        '${comment.authorId} · '
                        '${comment.createdAt.toLocal()}',
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment…',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  widget.onPost(text);
                  _controller.clear();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
