import '../domain/output_review.dart';
import 'output_review_repository.dart';

/// Decides and records output reviews for the AI studio.
///
/// The domain already knows which state changes are legal
/// ([OutputReviewState.canTransitionTo]) and the repository already refuses an
/// illegal write, so this controller adds no new rules. What it adds is the
/// thing that was missing between the two: a decision surface that refuses
/// before it writes, reports why, and never leaves a control that looks
/// finished while doing nothing.
///
/// Three failure modes it exists to prevent:
///
/// * **A tap that silently does nothing.** Every entry point returns false and
///   sets [lastError] instead of throwing past the UI, so a caller that forgets
///   to check the result still has a recorded reason to show.
/// * **A double tap writing twice.** [isBusy] is set for the whole write, and
///   [refusalFor] reports "a decision is already being recorded" rather than
///   letting the second tap reach the repository.
/// * **A cached belief that outruns the stored row.** The repository is the
///   source of truth. If it rejects a write this controller believed legal,
///   that disagreement is surfaced and the cached state is reloaded rather than
///   quietly overwritten.
///
/// Feedback is staged rather than written. [OutputReviewRepository.setReview]
/// only accepts feedback alongside a state change - a same-state write is not a
/// transition and is rejected - so feedback typed on its own has nowhere legal
/// to go yet. Staging it here keeps the note intact and lets it ride along with
/// the next decision, and [hasUnsavedFeedback] lets the UI say out loud that it
/// is not yet recorded instead of implying it was saved.
final class OutputReviewController {
  OutputReviewController({
    // `prefer_initializing_formals` is suppressed on the initializer below:
    // Dart forbids `this._repository` in a *named* parameter list, and the
    // public parameter must keep the name `repository` so call sites read the
    // way the rest of the codebase constructs these. The field stays private
    // on purpose: a public one would let a caller swap the repository out from
    // under the controller and invalidate its cache without the controller
    // ever knowing.
    required OutputReviewRepository repository,
    // ignore: prefer_initializing_formals
  }) : _repository = repository;

  final OutputReviewRepository _repository;

  final Map<String, OutputReviewState> _states = <String, OutputReviewState>{};
  final Map<String, String> _pendingFeedback = <String, String>{};
  // Marks states that were read and may since have been changed by another
  // writer. A cache alone is never proof; a cache plus a write since is a
  // specific reason to go check.
  final Map<String, bool> _mayBeStale = <String, bool>{};
  String? _lastError;
  String? _errorGenerationId;
  bool _busy = false;

  /// True while a write is in flight. Controls should be disabled.
  bool get isBusy => _busy;

  /// The most recent refusal, or null after a success. Never cleared by a read.
  String? get lastError => _lastError;

  /// Which generation [lastError] refers to, so a message cannot be misread as
  /// belonging to a different review on the same screen.
  String? get errorGenerationId => _errorGenerationId;

  /// The state this controller believes is stored, or null if never loaded.
  ///
  /// A cache, not an authority: [load] and a rejected write both refresh it.
  OutputReviewState? stateFor(String generationId) => _states[generationId];

  /// The decision this controller believes is stored, or null if unknown.
  OutputReviewDecision decisionFor(String generationId) =>
      switch (_states[generationId]) {
        OutputReviewState.approved => OutputReviewDecision.approved,
        OutputReviewState.rejected => OutputReviewDecision.rejected,
        OutputReviewState.pending => OutputReviewDecision.pending,
        null => OutputReviewDecision.unknown,
      };

  /// Feedback typed but not yet written to the repository.
  String? pendingFeedbackFor(String generationId) =>
      _pendingFeedback[generationId];

  /// Whether feedback is waiting to be recorded.
  ///
  /// The UI must surface this. A staged note that looks saved is the same silent
  /// no-op this controller was written to prevent, one level up.
  bool hasUnsavedFeedback(String generationId) =>
      (_pendingFeedback[generationId] ?? '').isNotEmpty;

  /// Why a decision cannot be taken right now, or null if it can.
  ///
  /// Checked before every write so an illegal tap produces a message instead of
  /// an exception the widget tree has to catch.
  String? refusalFor(String generationId, OutputReviewState next) {
    if (generationId.trim().isEmpty) {
      return 'No generation is selected, so there is nothing to review.';
    }
    if (_busy) {
      return 'A review decision for this generation is already being recorded.';
    }
    final current = _states[generationId];
    if (current != null && !current.canTransitionTo(next)) {
      final reason = current == OutputReviewState.approved
          ? 'An approved output has to be rejected before it can change again.'
          : 'A rejected output has to be approved or reopened before it can '
                'change again.';
      return reason;
    }
    return null;
  }

  /// Whether a cached state might no longer match the stored row.
  ///
  /// True only for a state this controller has read and then written. A
  /// decision can change underneath us at any moment, but a refusal backed by
  /// a value we ourselves just wrote is worth re-checking; one backed only by
  /// a load is not, and re-reading on every keystroke-adjacent path would turn
  /// a refusal into a query.
  bool _stateMayBeStale(String generationId) =>
      _mayBeStale[generationId] ?? false;

  /// Whether a decision is currently possible at all.
  bool canDecide(String generationId, OutputReviewState next) =>
      refusalFor(generationId, next) == null;

  /// Records feedback without a decision, keeping it until the next write.
  ///
  /// Returns false for an unknown generation, because staging a note against a
  /// generation that does not exist is how notes go missing.
  bool stageFeedback(String generationId, String feedback) {
    final text = feedback.trim();
    if (generationId.trim().isEmpty) {
      _lastError =
          'No generation is selected, so the feedback has nowhere to go.';
      _errorGenerationId = generationId;
      return false;
    }
    if (text.isEmpty) {
      _pendingFeedback.remove(generationId);
      return true;
    }
    _pendingFeedback[generationId] = text;
    // Staging is not a decision and not a write, so a previous failure stays
    // visible; clearing it here would hide a real error behind a keystroke.
    return true;
  }

  /// Loads the stored review so [stateFor] reflects the database.
  Future<void> load(String generationId) async {
    if (generationId.trim().isEmpty) return;
    try {
      final review = await _repository.getReview(generationId);
      _states[generationId] = review?.state ?? OutputReviewState.pending;
      _mayBeStale[generationId] = false;
    } catch (error) {
      _lastError = 'Could not read the recorded review: $error';
      _errorGenerationId = generationId;
    }
  }

  /// Approves [generationId], writing any staged feedback with it.
  Future<bool> approve(String generationId) =>
      _decide(generationId, OutputReviewState.approved);

  /// Rejects [generationId], writing any staged feedback with it.
  Future<bool> reject(String generationId) =>
      _decide(generationId, OutputReviewState.rejected);

  /// Reopens [generationId] for review.
  ///
  /// Only reachable from a decided state, which is why it is separate from
  /// [approve] and [reject]: it is the one transition a reviewer needs after
  /// changing their mind, and [refusalFor] still guards it.
  Future<bool> reopen(String generationId) =>
      _decide(generationId, OutputReviewState.pending);

  Future<bool> _decide(String generationId, OutputReviewState next) async {
    var refusal = refusalFor(generationId, next);
    if (refusal != null && _stateMayBeStale(generationId)) {
      // The refusal came from a cached state, not from the stored row. Reload
      // before reporting: otherwise the UI explains a decision it believes in
      // while storage says something else, and the reviewer is told to do
      // something that would have been perfectly legal against the real record.
      await load(generationId);
      refusal = refusalFor(generationId, next);
    }
    if (refusal != null) {
      _lastError = refusal;
      _errorGenerationId = generationId;
      return false;
    }

    _busy = true;
    _lastError = null;
    _errorGenerationId = generationId;
    final feedback = _pendingFeedback[generationId];
    try {
      await _repository.setReview(
        generationId: generationId,
        state: next,
        feedback: feedback,
      );
      _states[generationId] = next;
      _pendingFeedback.remove(generationId);
      // Another writer can move the row from here on, so the next refusal has
      // to be checked against storage rather than assumed from this cache.
      _mayBeStale[generationId] = true;
      return true;
    } on OutputReviewTransitionError catch (error) {
      // The stored row disagreed with the cached state. The row wins; reload it
      // so the UI stops offering transitions the database will not accept.
      _lastError =
          '${error.toString()} The recorded decision was reloaded from storage.';
      await load(generationId);
      return false;
    } catch (error) {
      _lastError = 'Could not record the review decision: $error';
      return false;
    } finally {
      _busy = false;
    }
  }
}

/// What the UI knows about a generation's review.
///
/// [unknown] is deliberately distinct from [pending]: "never loaded" and
/// "loaded and awaiting review" call for different affordances, and collapsing
/// them would let an unread state present as an empty queue item.
enum OutputReviewDecision { unknown, pending, approved, rejected }
