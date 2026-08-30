import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { personal, umkm }

class SettingsService extends ChangeNotifier {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const _kCurrency = 'settings_currency';
  static const _kDarkMode = 'settings_dark_mode';
  static const _kLanguage = 'settings_language';
  static const _kSeenTutorialVersion = 'settings_seen_tutorial_version';
  static const _kGeminiApiKey = 'settings_gemini_api_key';
  static const _kUseAiEnhancement = 'settings_use_ai_enhancement';
  static const _kScanMode = 'settings_scan_mode';
  static const _kSeenScanTutorial = 'settings_seen_scan_tutorial';
  static const _kAppMode = 'settings_app_mode';
  static const _kSeenOnboarding = 'settings_seen_onboarding';

  /// Versi konten tutorial. Naikkan setiap kali isi tutorial berubah, supaya
  /// pengguna (termasuk yang sudah pernah lihat) melihat tutorial versi baru.
  static const kTutorialVersion = '2';

  /// Versi tutorial mode scan (ditampilkan di layar Scanner, flag terpisah
  /// dari tutorial navigasi supaya tidak saling menimpa).
  static const kScanTutorialVersion = '1';

  static const supportedCurrencies = ['IDR', 'USD', 'SGD'];
  static const supportedLanguages = [
    {'code': 'id', 'name': 'Indonesia'},
    {'code': 'en', 'name': 'English'},
  ];

  String _currency = 'IDR';
  bool _darkMode = false;
  String _language = 'id';
  String _seenTutorialVersion = '';
  String _geminiApiKey = '';
  bool _useAiEnhancement = true;
  String _scanMode = 'auto';
  String _seenScanTutorialVersion = '';
  AppMode _appMode = AppMode.personal;
  bool _seenOnboarding = false;

  String get currency => _currency;
  bool get darkMode => _darkMode;
  String get language => _language;
  bool get isEnglish => _language == 'en';
  String get geminiApiKey => _geminiApiKey;
  bool get useAiEnhancement => _useAiEnhancement;
  AppMode get appMode => _appMode;

  /// Mode scan: 'auto' (OCR dulu, AI fallback — hemat token), 'ocr' (ML Kit
  /// saja, offline), 'ai' (Gemini vision saja).
  String get scanMode => _scanMode;

  /// Tutorial perlu ditampilkan bila versi tutorial yang pernah dilihat
  /// berbeda dari versi saat ini (fresh install / versi baru / data lama).
  bool get tutorialNeeded => _seenTutorialVersion != kTutorialVersion;

  bool get scanTutorialNeeded => _seenScanTutorialVersion != kScanTutorialVersion;

  bool get onboardingNeeded => !_seenOnboarding;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currency = prefs.getString(_kCurrency) ?? 'IDR';
      _darkMode = prefs.getBool(_kDarkMode) ?? false;
      _language = prefs.getString(_kLanguage) ?? 'id';
      _seenTutorialVersion = prefs.getString(_kSeenTutorialVersion) ?? '';
      _seenScanTutorialVersion = prefs.getString(_kSeenScanTutorial) ?? '';
      _geminiApiKey = prefs.getString(_kGeminiApiKey) ?? '';
      _useAiEnhancement = prefs.getBool(_kUseAiEnhancement) ?? true;
      _scanMode = prefs.getString(_kScanMode) ?? 'auto';
      _appMode = AppMode.values[prefs.getInt(_kAppMode) ?? 0];
      _seenOnboarding = prefs.getBool(_kSeenOnboarding) ?? false;
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

  Future<void> setGeminiApiKey(String value) async {
    _geminiApiKey = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kGeminiApiKey, value);
    } catch (_) {}
  }

  Future<void> setUseAiEnhancement(bool value) async {
    _useAiEnhancement = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kUseAiEnhancement, value);
    } catch (_) {}
  }

  Future<void> setScanMode(String value) async {
    _scanMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kScanMode, value);
    } catch (_) {}
  }

  Future<void> setAppMode(AppMode mode) async {
    _appMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kAppMode, mode.index);
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

  Future<void> markScanTutorialSeen() async {
    _seenScanTutorialVersion = kScanTutorialVersion;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSeenScanTutorial, kScanTutorialVersion);
    } catch (_) {}
  }

  Future<void> markOnboardingSeen() async {
    _seenOnboarding = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSeenOnboarding, true);
    } catch (_) {}
  }
}