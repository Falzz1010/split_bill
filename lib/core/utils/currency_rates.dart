import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Kurs mata uang asing → IDR. Default adalah nilai pasar perkiraan agar
/// fitur tetap berguna tanpa internet; bisa diperbarui lewat API gratis
/// (open.er-api.com, tanpa API key).
class CurrencyRatesService extends ChangeNotifier {
  CurrencyRatesService._();

  static final CurrencyRatesService instance = CurrencyRatesService._();

  static const _kRates = 'currency_rates_json';
  static const _kUpdated = 'currency_rates_updated';

  /// Kurs default (perkiraan pasar, 1 unit asing = ... IDR).
  static const Map<String, double> defaultRates = {
    'IDR': 1,
    'USD': 16000,
    'SGD': 12000,
    'JPY': 105,
    'EUR': 17500,
  };

  static const supportedForeign = ['USD', 'SGD', 'JPY', 'EUR'];

  /// Daftar kurs yang ditampilkan di Pengaturan: IDR (mata uang dasar) dulu,
  /// lalu mata uang asing. [supportedForeign] tetap dipakai untuk fetch API.
  static List<String> get displayCurrencies => ['IDR', ...supportedForeign];

  Map<String, double> _rates = Map.of(defaultRates);
  DateTime? _lastUpdated;

  double rate(String code) => _rates[code] ?? 1;

  bool get hasLiveRates => _lastUpdated != null;

  DateTime? get lastUpdated => _lastUpdated;

  /// Deteksi mata uang dari teks OCR struk. Prioritas: kode eksplisit
  /// (Rp/IDR/USD/SGD/JPY/EUR), lalu simbol ($, S$, €, ¥). Null = tidak terdeteksi.
  static String? detectCurrency(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final t = text.toUpperCase();
    // Kode huruf utuh (bukan bagian kata lain). 'RP' hasil uppercase dari 'Rp'.
    final word = RegExp(r'\b(USD|SGD|JPY|EUR|IDR|RP)\b');
    final m = word.firstMatch(t);
    if (m != null) {
      final code = m.group(1)!;
      if (code == 'RP' || code == 'IDR') return 'IDR';
      return code;
    }
    // Simbol: periksa bentuk panjang dulu (US\$ sebelum S\$ sebelum \$,
    // JP¥ sebelum ¥) karena yang pendek adalah substring yang panjang.
    if (t.contains('US\$')) return 'USD';
    if (t.contains('S\$')) return 'SGD';
    if (t.contains(r'$')) return 'USD';
    if (t.contains('JP¥') || t.contains('¥')) return 'JPY';
    if (t.contains('€')) return 'EUR';
    return null;
  }

  /// Muat kurs tersimpan dari SharedPreferences.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kRates);
      if (raw != null) {
        final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
        _rates = Map.of(defaultRates)..addAll(map.cast<String, double>());
      }
      final updated = prefs.getString(_kUpdated);
      if (updated != null) _lastUpdated = DateTime.tryParse(updated);
    } catch (_) {}
  }

  /// Ambil kurs terbaru dari open.er-api.com (gratis, tanpa key).
  /// Gagal (offline/down) → kurs lama tetap dipakai, kembalikan false.
  Future<bool> refreshRates() async {
    try {
      final res = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/IDR'))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return false;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final rates = (json['rates'] as Map).cast<String, dynamic>();
      final next = Map<String, double>.of(_rates);
      for (final code in supportedForeign) {
        final v = (rates[code] as num?)?.toDouble();
        // Endpoint memakai base IDR: rates = "1 IDR = ... asing".
        // Kurs yang kita simpan adalah "1 unit asing = ... IDR" → dibalik.
        if (v != null && v > 0) next[code] = 1 / v;
      }
      _rates = next;
      _lastUpdated = DateTime.now();
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kRates, jsonEncode(_rates));
        await prefs.setString(_kUpdated, _lastUpdated!.toIso8601String());
      } catch (_) {}
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Auto-refresh saat app dibuka: hanya jika belum pernah di-update hari ini
  /// (hemat kuota API, kurs "hari itu" cukup sekali). Gagal → kurs lama dipakai.
  Future<void> refreshIfStale() async {
    final last = _lastUpdated;
    if (last != null &&
        last.year == DateTime.now().year &&
        last.month == DateTime.now().month &&
        last.day == DateTime.now().day) {
      return;
    }
    await refreshRates();
  }

  /// Konversi nilai dari [code] ke IDR. Kode asing tanpa kurs → 0.
  double toIdr(double amount, String code) {
    final r = _rates[code];
    if (r == null || r <= 0) return 0;
    return amount * r;
  }

  /// Format kurs 1 unit mata uang = Rp X untuk ditampilkan ("1 USD = Rp 17857",
  /// "1 JPY = Rp 111.88"). Kurs besar dibulatkan ke integer; kurs kecil
  /// pakai 2 desimal agar tetap informatif. IDR tidak dipakai di sini
  /// (ditampilkan sebagai mata uang dasar di Pengaturan).
  String formatRate(String code) {
    final r = _rates[code] ?? 0;
    return '1 $code = Rp ${r.toStringAsFixed(r >= 1000 ? 0 : 2)}';
  }
}