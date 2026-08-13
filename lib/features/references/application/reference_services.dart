import '../domain/reference_models.dart';

class ReferenceSetResolver {
  const ReferenceSetResolver();

  Map<ReferenceType, ReferenceModel> resolve({
    required Iterable<ReferenceModel> characterReferences,
    Iterable<ReferenceModel> modeReferences = const [],
    Iterable<ReferenceModel> sceneReferences = const [],
  }) {
    final result = <ReferenceType, ReferenceModel>{};
    for (final reference in characterReferences.where((item) => item.enabled)) {
      result[reference.type] = reference;
    }
    for (final reference in modeReferences.where((item) => item.enabled)) {
      result[reference.type] = reference;
    }
    for (final reference in sceneReferences.where((item) => item.enabled)) {
      result[reference.type] = reference;
    }
    return result;
  }
}

class ReferencePrioritySelector {
  const ReferencePrioritySelector();

  List<ReferenceModel> select({
    required Iterable<ReferenceModel> references,
    int maxItems = 4,
    ReferenceType? preferredType,
  }) {
    final sorted = references.where((item) => item.enabled).toList()
      ..sort((a, b) {
        final primary = (b.primary ? 1 : 0).compareTo(a.primary ? 1 : 0);
        if (primary != 0) return primary;
        final preferred = preferredType == null
            ? 0
            : (b.type == preferredType ? 1 : 0) -
                  (a.type == preferredType ? 1 : 0);
        if (preferred != 0) return preferred;
        return b.priority.compareTo(a.priority);
      });
    return sorted.take(maxItems).toList(growable: false);
  }
}

class ReferenceConsistencyService {
  const ReferenceConsistencyService();

  ReferenceHealth health(ReferenceModel reference, {required bool fileExists}) {
    if (!fileExists) return ReferenceHealth.broken;
    if (reference.filePath.trim().isEmpty) return ReferenceHealth.missing;
    return reference.enabled
        ? ReferenceHealth.healthy
        : ReferenceHealth.incomplete;
  }

  ConsistencyReviewStatus aggregate(
    Iterable<ConsistencyReviewStatus> statuses,
  ) {
    if (statuses.any((status) => status == ConsistencyReviewStatus.failed)) {
      return ConsistencyReviewStatus.failed;
    }
    if (statuses.any(
      (status) => status == ConsistencyReviewStatus.reviewRequired,
    )) {
      return ConsistencyReviewStatus.reviewRequired;
    }
    if (statuses.isNotEmpty &&
        statuses.every((status) => status == ConsistencyReviewStatus.passed)) {
      return ConsistencyReviewStatus.passed;
    }
    return ConsistencyReviewStatus.notReviewed;
  }
}
