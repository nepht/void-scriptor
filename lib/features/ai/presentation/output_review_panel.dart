import 'package:flutter/material.dart';

/// Approve/reject/feedback controls for an AI output (Step 28.18).
class OutputReviewPanel extends StatefulWidget {
  const OutputReviewPanel({
    super.key,
    required this.onApprove,
    required this.onReject,
    required this.onFeedback,
  });

  final VoidCallback onApprove;
  final VoidCallback onReject;
  final ValueChanged<String> onFeedback;

  @override
  State<OutputReviewPanel> createState() => _OutputReviewPanelState();
}

class _OutputReviewPanelState extends State<OutputReviewPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendFeedback() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onFeedback(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: widget.onApprove,
              icon: const Icon(Icons.check),
              label: const Text('Approve'),
            ),
            TextButton.icon(
              onPressed: widget.onReject,
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Feedback for regeneration',
                ),
                onSubmitted: (_) => _sendFeedback(),
              ),
            ),
            IconButton(onPressed: _sendFeedback, icon: const Icon(Icons.send)),
          ],
        ),
      ],
    );
  }
}
