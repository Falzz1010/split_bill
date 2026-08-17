import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const _kCurrency = 'settings_currency';
  static const _kDarkMode = 'settings_dark_mode';
  static const _kLanguage = 'settings_language';
  static const _kSeenTutorialVersion = 'settings_seen_tutorial_version';

  /// Versi konten tutorial. Naikkan setiap kali isi tutorial berubah, supaya
  /// pengguna (termasuk yang sudah pernah lihat) melihat tutorial versi baru.
  static const kTutorialVersion = '1';

  static const supportedCurrencies = ['IDR', 'USD', 'SGD'];
  static const supportedLanguages = [
    {'code': 'id', 'name': 'Indonesia'},
    {'code': 'en', 'name': 'English'},
  ];

  String _currency = 'IDR';
  bool _darkMode = false;
  String _language = 'id';
  String _seenTutorialVersion = '';

  String get currency => _currency;
  bool get darkMode => _darkMode;
  String get language => _language;
  bool get isEnglish => _language == 'en';

  /// Tutorial perlu ditampilkan bila versi tutorial yang pernah dilihat
  /// berbeda dari versi saat ini (fresh install / versi baru / data lama).
  bool get tutorialNeeded => _seenTutorialVersion != kTutorialVersion;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currency = prefs.getString(_kCurrency) ?? 'IDR';
      _darkMode = prefs.getBool(_kDarkMode) ?? false;
      _language = prefs.getString(_kLanguage) ?? 'id';
      _seenTutorialVersion = prefs.getString(_kSeenTutorialVersion) ?? '';
    } catch (_) {
      // plugin unavailable (misal hot restart web) — pakai default
    }
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCurrency, value);
    } catch (_) {}
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDarkMode, value);
    } catch (_) {}
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguage, value);
    } catch (_) {}
  }

  /// Tandai tutorial versi saat ini sudah dilihat (tidak ditampilkan lagi
  /// sampai versi tutorial naik).
  Future<void> markTutorialSeen() async {
    _seenTutorialVersion = kTutorialVersion;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSeenTutorialVersion, kTutorialVersion);
    } catch (_) {}
  }
}