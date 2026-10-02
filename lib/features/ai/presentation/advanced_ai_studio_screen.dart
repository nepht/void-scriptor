import 'package:flutter/material.dart';

import '../application/output_review_controller.dart';
import '../domain/output_review.dart';
import 'output_review_panel.dart';

/// Unified advanced AI studio surface (Step 28.22).
///
/// Composes the prompt composer, streaming output, review, and usage panels in
/// one workspace. Full wiring to provider/router/queue happens in the app
/// shell; this screen is the presentation host.
class AdvancedAiStudioScreen extends StatefulWidget {
  const AdvancedAiStudioScreen({
    super.key,
    this.onOpenImageGenerator,
    this.onOpenVideoGenerator,
    this.reviewController,
    this.reviewedGenerationId,
  });

  final VoidCallback? onOpenImageGenerator;
  final VoidCallback? onOpenVideoGenerator;

  /// Records review decisions. Null when the host has no project database
  /// wired, and the review controls are then disabled rather than accepting a
  /// tap that goes nowhere.
  final OutputReviewController? reviewController;

  /// Which generation the review controls act on.
  ///
  /// Separate from [reviewController] on purpose: a repository with no target is
  /// a wiring mistake, and it should read differently on screen from a target
  /// that has not been generated yet.
  final String? reviewedGenerationId;

  @override
  State<AdvancedAiStudioScreen> createState() => _AdvancedAiStudioScreenState();
}

class _AdvancedAiStudioScreenState extends State<AdvancedAiStudioScreen> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced AI Studio')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onOpenImageGenerator,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Image Generator'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenVideoGenerator,
                    icon: const Icon(Icons.movie_creation_outlined),
                    label: const Text('Video Generator'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _promptController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Prompt',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: _Section(title: 'Output', child: SizedBox()),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _Section(
                    title: 'Review',
                    child: _ReviewSection(
                      controller: widget.reviewController,
                      generationId: widget.reviewedGenerationId,
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                const Expanded(
                  child: _Section(title: 'Usage', child: SizedBox()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// Wires the review controls to a real decision surface.
///
/// The controls are only live when there is somewhere to write. With no
/// controller or no target they are disabled and the reason is on screen,
/// because a button that accepts a tap and records nothing is worse than one
/// that visibly cannot be pressed.
class _ReviewSection extends StatefulWidget {
  const _ReviewSection({this.controller, this.generationId});

  final OutputReviewController? controller;
  final String? generationId;

  @override
  State<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<_ReviewSection> {
  String? _message;
  bool _messageIsError = false;

  String? get _target {
    final id = widget.generationId?.trim();
    return (id == null || id.isEmpty) ? null : id;
  }

  String? get _unavailableReason {
    if (widget.controller == null) {
      return 'Review is unavailable: no review store is connected.';
    }
    if (_target == null) {
      return 'Review is unavailable: no generation is selected.';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_ReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generationId != widget.generationId) {
      _message = null;
      _load();
    }
  }

  Future<void> _load() async {
    final controller = widget.controller;
    final target = _target;
    if (controller == null || target == null) return;
    await controller.load(target);
    if (mounted) setState(() {});
  }

  Future<void> _decide(OutputReviewState next) async {
    final controller = widget.controller;
    final target = _target;
    if (controller == null || target == null) return;
    final ok = switch (next) {
      OutputReviewState.approved => await controller.approve(target),
      OutputReviewState.rejected => await controller.reject(target),
      OutputReviewState.pending => await controller.reopen(target),
    };
    if (!mounted) return;
    setState(() {
      _messageIsError = !ok;
      _message = ok
          ? 'Recorded ${next.name}.'
          : controller.lastError ?? 'The decision was not recorded.';
    });
  }

  void _stageFeedback(String text) {
    final controller = widget.controller;
    final target = _target;
    if (controller == null || target == null) return;
    controller.stageFeedback(target, text);
    setState(() {
      _messageIsError = false;
      _message = controller.hasUnsavedFeedback(target)
          ? 'Feedback noted. It is recorded with your next decision.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unavailable = _unavailableReason;
    final controller = widget.controller;
    final target = _target;
    final decision = target == null || controller == null
        ? OutputReviewDecision.unknown
        : controller.decisionFor(target);
    final unsaved =
        target != null && controller?.hasUnsavedFeedback(target) == true;

    // `_Section` hands its child an `Expanded`, so this column is given a
    // bounded box and must fill it: a `mainAxisSize.min` column inside a tight
    // height overflowed as soon as real status lines were added. The body
    // scrolls instead of overflowing, and the review panel keeps its own
    // natural height.
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (unavailable != null)
            Text(unavailable, style: Theme.of(context).textTheme.bodySmall)
          else
            OutputReviewPanel(
              onApprove: () => _decide(OutputReviewState.approved),
              onReject: () => _decide(OutputReviewState.rejected),
              onFeedback: _stageFeedback,
            ),
          if (unsaved)
            const Text(
              'Unsaved feedback will be recorded with the next decision.',
            ),
          if (_message != null)
            Text(
              _message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _messageIsError
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
          if (target != null && unavailable == null)
            Text('Reviewing generation $target (${decision.name}).'),
        ],
      ),
    );
  }
}
