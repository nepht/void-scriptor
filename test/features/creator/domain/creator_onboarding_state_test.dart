import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/creator_onboarding_state.dart';
import 'package:void_scriptor/features/creator/domain/creator_profile.dart';
import 'package:void_scriptor/features/creator/domain/creator_specialization.dart';

void main() {
  group('CreatorOnboardingState', () {
    test('starts at welcome step with defaults', () {
      final state = CreatorOnboardingState.initial();
      expect(state.step, CreatorOnboardingStep.welcome);
      expect(state.displayName, isEmpty);
      expect(state.specializations, isEmpty);
      expect(state.skills, isEmpty);
      expect(state.visibility, CreatorVisibility.private);
      expect(state.importExistingProjects, isFalse);
    });

    test('advances step by step', () {
      var state = CreatorOnboardingState.initial();
      state = state.copyWith(step: CreatorOnboardingStep.creatorName);
      state = state.copyWith(step: CreatorOnboardingStep.specialization);
      state = state.copyWith(step: CreatorOnboardingStep.skills);
      state = state.copyWith(step: CreatorOnboardingStep.importProjects);
      state = state.copyWith(step: CreatorOnboardingStep.visibility);
      state = state.copyWith(step: CreatorOnboardingStep.dashboard);
      expect(state.step, CreatorOnboardingStep.dashboard);
    });

    test('accumulates multiple specializations', () {
      var state = CreatorOnboardingState.initial();
      state = state.toggleSpecialization(CreatorSpecialization.writer);
      state = state.toggleSpecialization(CreatorSpecialization.animator);
      expect(state.specializations, hasLength(2));
      // toggling off removes
      state = state.toggleSpecialization(CreatorSpecialization.writer);
      expect(state.specializations, [CreatorSpecialization.animator]);
    });

    test('isComplete requires display name and dashboard step', () {
      final done = CreatorOnboardingState.initial().copyWith(
        step: CreatorOnboardingStep.dashboard,
        displayName: 'Nama Kreator',
        visibility: CreatorVisibility.public,
      );
      expect(done.isComplete, isTrue);
      expect(CreatorOnboardingState.initial().isComplete, isFalse);
    });
  });
}