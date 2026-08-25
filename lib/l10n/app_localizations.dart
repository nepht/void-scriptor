import 'package:flutter/material.dart';

/// Minimal v1.1 ARB-backed localization surface for the Welcome pilot.
class AppLocalizations {
  const AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = <Locale>[Locale('en'), Locale('id')];

  final Locale locale;

  bool get _isIndonesian => locale.languageCode == 'id';

  String get welcomeTitle => _isIndonesian
      ? 'Selamat datang di Void Scriptor'
      : 'Welcome to Void Scriptor';

  String get createProject => _isIndonesian ? 'Buat Proyek' : 'Create Project';

  String get openProject => _isIndonesian ? 'Buka Proyek' : 'Open Project';

  String get exploreDemo => _isIndonesian ? 'Jelajahi Demo' : 'Explore Demo';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
