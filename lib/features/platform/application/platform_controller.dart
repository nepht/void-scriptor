import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlatformState {
  final String? activeFlow;
  final bool isTourStarted;
  final bool isDownloading;

  const PlatformState({
    this.activeFlow,
    this.isTourStarted = false,
    this.isDownloading = false,
  });

  PlatformState copyWith({
    String? Function()? activeFlow,
    bool? isTourStarted,
    bool? isDownloading,
  }) {
    return PlatformState(
      activeFlow: activeFlow != null ? activeFlow() : this.activeFlow,
      isTourStarted: isTourStarted ?? this.isTourStarted,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }
}

class PlatformController extends Notifier<PlatformState> {
  @override
  PlatformState build() => const PlatformState();

  void startTour() {
    state = state.copyWith(activeFlow: () => 'tour', isTourStarted: true);
  }

  void startDownload() {
    state = state.copyWith(activeFlow: () => 'download', isDownloading: true);
  }

  void completeDownload() {
    state = state.copyWith(isDownloading: false);
  }
}

final platformProvider = NotifierProvider<PlatformController, PlatformState>(
  PlatformController.new,
);
