// Kontrak Focus Writing Mode (Step 109.20) — RED pertama.
//
// Acceptance kanonik sprint_109.json: distraction_free, keyboard_exit,
// autosave_visible, theme_support, screen_reader_access.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/domain/focus_writing_mode.dart';

void main() {
  group('distraction_free', () {
    test('enter menyembunyikan chrome dan hanya menyisakan kontrol inti', () {
      final mode = FocusWritingSession();
      expect(mode.isActive, isFalse);
      expect(mode.chromeVisible, isTrue);
      mode.enter();
      expect(mode.isActive, isTrue);
      expect(mode.chromeVisible, isFalse);
      expect(
        FocusWritingSession.controlLabels.keys,
        containsAll(<String>['exit', 'autosaveStatus', 'theme']),
      );
    });
  });

  group('keyboard_exit', () {
    test('keluar tercatat alasannya; sesi bisa dimasuki lagi', () {
      final mode = FocusWritingSession()..enter();
      mode.exit(viaKeyboard: true);
      expect(mode.isActive, isFalse);
      expect(mode.chromeVisible, isTrue);
      expect(mode.lastExitReason, FocusExitReason.keyboard);
      mode.enter();
      expect(mode.isActive, isTrue);
      mode.exit();
      expect(mode.lastExitReason, FocusExitReason.manual);
      expect(() => mode.exit(), throwsStateError);
    });
  });

  group('autosave_visible', () {
    test('label autosave akurat pada tiap transisi dengan jam tersuntik', () {
      var tick = DateTime(2026, 8, 26, 9);
      final mode = FocusWritingSession(
        clock: () {
          tick = tick.add(const Duration(minutes: 5));
          return tick;
        },
      )..enter();
      expect(mode.isDirty, isTrue);
      expect(mode.autosaveLabel, 'Belum tersimpan');
      mode.markSaved();
      expect(mode.isDirty, isFalse);
      expect(mode.lastSavedAt, DateTime(2026, 8, 26, 9, 10));
      expect(mode.autosaveLabel, startsWith('Tersimpan'));
      expect(mode.autosaveLabel, contains('09:10'));
      mode.edit();
      expect(mode.isDirty, isTrue);
      expect(mode.autosaveLabel, 'Belum tersimpan');
      expect(mode.lastSavedAt, DateTime(2026, 8, 26, 9, 10));
    });
  });

  group('theme_support', () {
    test('tema fokus dapat diganti kapan pun termasuk saat aktif', () {
      final mode = FocusWritingSession()..enter();
      expect(mode.theme, FocusTheme.system);
      mode.setTheme(FocusTheme.paper);
      expect(mode.theme, FocusTheme.paper);
      mode.setTheme(FocusTheme.dark);
      expect(mode.theme, FocusTheme.dark);
    });
  });

  group('screen_reader_access', () {
    test('semua kontrol inti berlabel semantik; enter/exit diumumkan', () {
      for (final label in FocusWritingSession.controlLabels.values) {
        expect(label.trim(), isNotEmpty);
      }
      final mode = FocusWritingSession()..enter();
      expect(mode.announcements.first.message, contains('fokus'));
      mode.exit(viaKeyboard: true);
      expect(mode.announcements.last.message, contains('Keluar'));
    });
  });
}
