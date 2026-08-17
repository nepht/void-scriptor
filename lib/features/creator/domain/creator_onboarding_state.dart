import 'creator_profile.dart';
import 'creator_specialization.dart';

/// Sprint 43 — Step 43.3 Creator Onboarding.
///
/// Activation flow when Creator Mode is first enabled:
/// welcome → creator name → specialization → skills → import projects →
/// visibility → dashboard.
enum CreatorOnboardingStep {
  welcome,
  creatorName,
  specialization,
  skills,
  importProjects,
  visibility,
  dashboard,
}

/// Serializable multi-step onboarding state. Purely a value object; the
/// controller/service owns progression and persistence.
class CreatorOnboardingState {
  const CreatorOnboardingState({
    required this.step,
    required this.displayName,
    required this.specializations,
    required this.skills,
    required this.importExistingProjects,
    required this.visibility,
  });

  factory CreatorOnboardingState.initial() => const CreatorOnboardingState(
    step: CreatorOnboardingStep.welcome,
    displayName: '',
    specializations: [],
    skills: [],
    importExistingProjects: false,
    visibility: CreatorVisibility.private,
  );

  final CreatorOnboardingStep step;
  final String displayName;
  final List<CreatorSpecialization> specializations;
  final List<String> skills;
  final bool importExistingProjects;
  final CreatorVisibility visibility;

  bool get isComplete =>
      step == CreatorOnboardingStep.dashboard && displayName.trim().isNotEmpty;

  CreatorOnboardingState copyWith({
    CreatorOnboardingStep? step,
    String? displayName,
    List<CreatorSpecialization>? specializations,
    List<String>? skills,
    bool? importExistingProjects,
    CreatorVisibility? visibility,
  }) {
    return CreatorOnboardingState(
      step: step ?? this.step,
      displayName: displayName ?? this.displayName,
      specializations: specializations ?? this.specializations,
      skills: skills ?? this.skills,
      importExistingProjects:
          importExistingProjects ?? this.importExistingProjects,
      visibility: visibility ?? this.visibility,
    );
  }

  /// Toggles a specialization in/out of the selection list.
  CreatorOnboardingState toggleSpecialization(CreatorSpecialization spec) {
    final specs = List<CreatorSpecialization>.of(specializations);
    if (specs.contains(spec)) {
      specs.remove(spec);
    } else {
      specs.add(spec);
    }
    return copyWith(specializations: specs);
  }
}
