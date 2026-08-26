// Kontrak Character Interview Workspace (Step 109.15) — RED pertama.
//
// Acceptance kanonik sprint_109.json:
// question_sets, first_person_answers, session_history, manual_edit,
// source_provenance.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/domain/character_interview.dart';

final DateTime t0 = DateTime.utc(2026, 8, 26, 9);

DateTime Function() makeClock(DateTime start) {
  var n = 0;
  return () => start.add(Duration(minutes: n++));
}

const questionSet = InterviewQuestionSet(
  id: 'qs-inti',
  title: 'Wawancara Inti Karakter',
  questions: <InterviewQuestion>[
    InterviewQuestion(id: 'q-asal', prompt: 'Dari mana kamu berasal?'),
    InterviewQuestion(id: 'q-takut', prompt: 'Apa ketakutan terbesarmu?'),
    InterviewQuestion(id: 'q-senjata', prompt: 'Senjata apa yang kamu bawa?'),
  ],
);

void main() {
  group('question_sets', () {
    test('set sah lolos validateSchema tanpa masalah', () {
      expect(questionSet.validateSchema(), isEmpty);
    });

    test(
      'masalah dilaporkan deterministik: judul, prompt kosong, id ganda',
      () {
        const broken = InterviewQuestionSet(
          id: '',
          title: '   ',
          questions: <InterviewQuestion>[
            InterviewQuestion(id: '', prompt: ''),
            InterviewQuestion(id: 'q-a', prompt: 'ok'),
            InterviewQuestion(id: 'q-a', prompt: 'duplikat'),
          ],
        );
        expect(broken.validateSchema(), <String>[
          'title must not be blank',
          'question[0].id must not be blank',
          'question[0].prompt must not be blank',
          'duplicate question id: q-a',
        ]);
      },
    );
  });

  group('first_person_answers', () {
    test('jawaban orang-pertama terekam verbatim dengan jam tersuntik', () {
      final session = CharacterInterviewSession.start(
        characterId: 'c-marek',
        questionSet: questionSet,
        openedAt: t0,
        clock: makeClock(t0),
      );
      final entry = session.answer('q-asal', text: 'Aku dari Pelabuhan Abu.');
      expect(entry.answer, 'Aku dari Pelabuhan Abu.');
      expect(entry.questionPrompt, 'Dari mana kamu berasal?');
      expect(entry.answeredAt, t0);
      expect(session.entries.single.questionId, 'q-asal');
      expect(entry.isEdited, isFalse);
    });

    test('pertanyaan tak dikenal, duplikat, dan jawaban kosong ditolak', () {
      final session = CharacterInterviewSession.start(
        characterId: 'c-marek',
        questionSet: questionSet,
        openedAt: t0,
        clock: makeClock(t0),
      );
      expect(
        () => session.answer('q-tidak-ada', text: 'x'),
        throwsArgumentError,
      );
      session.answer('q-asal', text: 'sudah');
      expect(() => session.answer('q-asal', text: 'lagi'), throwsStateError);
      expect(() => session.answer('q-takut', text: '   '), throwsArgumentError);
      expect(session.entries.length, 1);
    });
  });

  group('manual_edit', () {
    test('edit memperbarui jawaban dan merawat riwayat revisi', () {
      final session = CharacterInterviewSession.start(
        characterId: 'c-marek',
        questionSet: questionSet,
        openedAt: t0,
        clock: makeClock(t0),
      );
      session.answer('q-takut', text: 'Kehilangan kapalku.');
      final edited = session.editAnswer(
        'q-takut',
        newText: 'Kehilangan kruku.',
      );
      expect(edited.answer, 'Kehilangan kruku.');
      expect(edited.isEdited, isTrue);
      expect(edited.editedAt, t0.add(const Duration(minutes: 1)));
      expect(edited.revisions, <String>['Kehilangan kapalku.']);
      expect(session.entries.single.revisions.length, 1);
    });

    test('edit pada pertanyaan belum terjawab atau teks kosong ditolak', () {
      final session = CharacterInterviewSession.start(
        characterId: 'c-marek',
        questionSet: questionSet,
        openedAt: t0,
        clock: makeClock(t0),
      );
      expect(
        () => session.editAnswer('q-asal', newText: 'x'),
        throwsStateError,
      );
      session.answer('q-asal', text: 'asli');
      expect(
        () => session.editAnswer('q-asal', newText: ' '),
        throwsArgumentError,
      );
      expect(session.entries.single.answer, 'asli');
    });
  });

  group('session_history', () {
    test('sesi per karakter terurut kronologis; karakter lain tersaring', () {
      final log = CharacterInterviewLog();
      final later = CharacterInterviewSession.start(
        characterId: 'c-marek',
        questionSet: questionSet,
        openedAt: t0.add(const Duration(hours: 2)),
        clock: makeClock(t0.add(const Duration(hours: 2))),
      );
      final earlier = CharacterInterviewSession.start(
        characterId: 'c-marek',
        questionSet: questionSet,
        openedAt: t0,
        clock: makeClock(t0),
      );
      final other = CharacterInterviewSession.start(
        characterId: 'c-kai',
        questionSet: questionSet,
        openedAt: t0.add(const Duration(hours: 1)),
        clock: makeClock(t0.add(const Duration(hours: 1))),
      );
      log
        ..add(later)
        ..add(other)
        ..add(earlier);
      expect(log.sessionsFor('c-marek').map((s) => s.id), <String>[
        earlier.id,
        later.id,
      ]);
      expect(log.sessionsFor('c-kai').single.id, other.id);
      expect(log.all.length, 3);
    });

    test('id sesi deterministik dari karakter+waktu mulai', () {
      final a = CharacterInterviewSession.start(
        characterId: 'c-marek',
        questionSet: questionSet,
        openedAt: t0,
        clock: makeClock(t0),
      );
      final b = CharacterInterviewSession.start(
        characterId: 'c-marek',
        questionSet: questionSet,
        openedAt: t0,
        clock: makeClock(t0),
      );
      expect(a.id, b.id);
      expect(a.id, contains('c-marek'));
    });
  });

  group('source_provenance_dan_persistensi', () {
    test('provenance membawa sesi, pertanyaan, waktu tangkap & revisi', () {
      final session = CharacterInterviewSession.start(
        characterId: 'c-marek',
        questionSet: questionSet,
        openedAt: t0,
        clock: makeClock(t0),
      );
      session.answer('q-senjata', text: 'Parang pusaka.');
      session.editAnswer('q-senjata', newText: 'Parang pusaka keluarga.');
      final p = session.provenanceFor('q-senjata');
      expect(p.sessionId, session.id);
      expect(p.characterId, 'c-marek');
      expect(p.questionId, 'q-senjata');
      expect(p.capturedAt, t0);
      expect(p.editedAt, t0.add(const Duration(minutes: 1)));
      expect(p.revisionCount, 1);
      expect(
        session.provenanceFor('q-tidak-ada').toString(),
        isNot(contains('q-senjata')),
      );
    });

    test('roundtrip JSON sesi & log identik antar-rebuild', () {
      CharacterInterviewLog build() {
        final log = CharacterInterviewLog();
        final session = CharacterInterviewSession.start(
          characterId: 'c-marek',
          questionSet: questionSet,
          clock: makeClock(t0),
        );
        session
          ..answer('q-asal', text: 'Pelabuhan Abu.')
          ..answer('q-takut', text: 'Lautan kosong.')
          ..editAnswer('q-takut', newText: 'Kehilangan kru.');
        log.add(session);
        return log;
      }

      final a = build();
      final restored = CharacterInterviewLog.fromJson(a.toJson());
      expect(restored.toJson(), a.toJson());
      final session = restored.sessionsFor('c-marek').single;
      expect(session.entryFor('q-takut')!.answer, 'Kehilangan kru.');
      expect(session.entryFor('q-takut')!.revisions, <String>[
        'Lautan kosong.',
      ]);
    });
  });
}
