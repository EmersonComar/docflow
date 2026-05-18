import 'package:flutter/material.dart';
import '../../data/datasources/local_database.dart';


class LocaleProvider extends ChangeNotifier {
  final LocalDatabase _database;

  Locale? _locale;

  LocaleProvider(this._database) {
    _loadSavedLocale();
  }

  Locale? get locale => _locale;

  Future<void> _loadSavedLocale() async {
    try {
      await _database.initialize();
      final saved = await _database.getPreference('locale');
      if (saved != null && saved.isNotEmpty) {
        _locale = Locale(saved);
        notifyListeners();
      }
    } catch (_) {
    }
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    try {
      await _database.initialize();
      final value = locale == null ? '' : locale.languageCode;
      await _database.savePreference('locale', value);
    } catch (_) {
    }
  }

  Future<void> clearLocale() async => await setLocale(null);
}
