// Kontrak Word Targets & Session Progress (Step 109.21) — RED pertama.
//
// Acceptance kanonik sprint_109.json: target_levels, live_progress,
// session_reset, history, timezone_safe.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/domain/word_targets.dart';

void main() {
  group('target_levels', () {
    test('empat tingkat target dapat ditetapkan terpisah', () {
      final tracker = WordTargetTracker()
        ..setTarget(level: WordTargetLevel.session, scopeKey: 's1', words: 500)
        ..setTarget(level: WordTargetLevel.scene, scopeKey: 'sc-9', words: 1200)
        ..setTarget(
          level: WordTargetLevel.chapter,
          scopeKey: 'ch-2',
          words: 6000,
        )
        ..setTarget(
          level: WordTargetLevel.project,
          scopeKey: 'p-main',
          words: 80000,
        );
      expect(
        tracker
            .progressFor(level: WordTargetLevel.project, scopeKey: 'p-main')
            .target,
        80000,
      );
      expect(
        () => tracker.setTarget(
          level: WordTargetLevel.session,
          scopeKey: '  ',
          words: 100,
        ),
        throwsArgumentError,
      );
      expect(
        () => tracker.setTarget(
          level: WordTargetLevel.session,
          scopeKey: 's2',
          words: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('live_progress', () {
    test('kemajuan hidup akurat saat menulis bertahap', () {
      final tracker = WordTargetTracker()
        ..setTarget(
          level: WordTargetLevel.session,
          scopeKey: 's1',
          words: 1000,
        );
      tracker.recordWords(
        level: WordTargetLevel.session,
        scopeKey: 's1',
        count: 250,
      );
      var p = tracker.progressFor(
        level: WordTargetLevel.session,
        scopeKey: 's1',
      );
      expect(p.written, 250);
      expect(p.remaining, 750);
      expect(p.fraction, closeTo(0.25, 0.0001));
      tracker.recordWords(
        level: WordTargetLevel.session,
        scopeKey: 's1',
        count: 150,
      );
      p = tracker.progressFor(level: WordTargetLevel.session, scopeKey: 's1');
      expect(p.written, 400);
      expect(p.remaining, 600);
      expect(
        () => tracker.recordWords(
          level: WordTargetLevel.session,
          scopeKey: 's1',
          count: -5,
        ),
        throwsArgumentError,
      );
    });
  });

  group('session_reset', () {
    test('reset sesian menyisakan progres adegan/bab/project utuh', () {
      final tracker = WordTargetTracker()
        ..setTarget(level: WordTargetLevel.session, scopeKey: 's1', words: 500)
        ..setTarget(
          level: WordTargetLevel.scene,
          scopeKey: 'sc-9',
          words: 1200,
        );
      tracker.recordWords(
        level: WordTargetLevel.session,
        scopeKey: 's1',
        count: 300,
      );
      tracker.recordWords(
        level: WordTargetLevel.scene,
        scopeKey: 'sc-9',
        count: 700,
      );
      tracker.resetSession();
      expect(
        tracker
            .progressFor(level: WordTargetLevel.session, scopeKey: 's1')
            .written,
        0,
      );
      expect(
        tracker
            .progressFor(level: WordTargetLevel.scene, scopeKey: 'sc-9')
            .written,
        700,
      );
    });
  });

  group('history', () {
    test('setiap mutasi tercatat kronologis dengan jam tersuntik', () {
      var tick = DateTime(2026, 8, 26, 10);
      final tracker = WordTargetTracker(
        clock: () {
          tick = tick.add(const Duration(minutes: 10));
          return tick;
        },
      )..setTarget(level: WordTargetLevel.session, scopeKey: 's1', words: 500);
      tracker.recordWords(
        level: WordTargetLevel.session,
        scopeKey: 's1',
        count: 120,
      );
      tracker.resetSession();
      expect(tracker.history.length, 3);
      expect(tracker.history[1].summary, startsWith('write:'));
      expect(tracker.history[2].summary, startsWith('reset:'));
      expect(tracker.history[0].at.isBefore(tracker.history[1].at), isTrue);
    });
  });

  group('timezone_safe', () {
    test(
      'kunci hari lokal diturunkan dari offset eksplisit, bukan jam host',
      () {
        final instant = DateTime.utc(2026, 8, 26, 18, 30);
        final jakarta = WordTargetDayStamp.fromUtcInstant(
          instant,
          offsetMinutes: 420,
        );
        final reykjavik = WordTargetDayStamp.fromUtcInstant(
          instant,
          offsetMinutes: 0,
        );
        expect(jakarta.dayKey, '2026-08-27');
        expect(reykjavik.dayKey, '2026-08-26');
        expect(
          WordTargetDayStamp.fromUtcInstant(
            DateTime.utc(2026, 1, 1, 0, 30),
            offsetMinutes: -60,
          ).dayKey,
          '2025-12-31',
        );
      },
    );
  });
}
