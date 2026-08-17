import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/creator_metrics.dart';
import '../domain/creator_profile.dart';
import '../domain/creator_workspace_section.dart';

/// Sprint 43 — Creator Studio state.
///
/// Menggabungkan state creator (metrics, profile, active workspace
/// section) menjadi satu Notifier agar screen-screen Creator Studio
/// dapat berbagi state melalui Riverpod.
class CreatorStudioState {
  const CreatorStudioState({
    this.metrics = const CreatorMetrics(
      activeProjects: 0,
      publishedWorks: 0,
      portfolioViews: 0,
      aiUsage: 0,
      storageBytes: 0,
    ),
    this.profile,
    this.activeSection = CreatorWorkspaceSection.myProjects,
  });

  final CreatorMetrics metrics;
  final CreatorProfile? profile;
  final CreatorWorkspaceSection activeSection;

  CreatorStudioState copyWith({
    CreatorMetrics? metrics,
    CreatorProfile? profile,
    CreatorWorkspaceSection? activeSection,
  }) {
    return CreatorStudioState(
      metrics: metrics ?? this.metrics,
      profile: profile ?? this.profile,
      activeSection: activeSection ?? this.activeSection,
    );
  }
}

class CreatorStudioController extends Notifier<CreatorStudioState> {
  @override
  CreatorStudioState build() => const CreatorStudioState();

  void setSection(CreatorWorkspaceSection section) {
    state = state.copyWith(activeSection: section);
  }

  void updateMetrics(CreatorMetrics metrics) {
    state = state.copyWith(metrics: metrics);
  }

  void updateProfile(CreatorProfile profile) {
    state = state.copyWith(profile: profile);
  }
}

final creatorStudioProvider =
    NotifierProvider<CreatorStudioController, CreatorStudioState>(
      CreatorStudioController.new,
    );
