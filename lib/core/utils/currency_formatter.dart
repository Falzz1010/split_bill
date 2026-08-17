import 'package:intl/intl.dart';
import '../settings/settings_service.dart';

String formatCurrency(double amount, {int decimalDigits = 0}) {
  final code = SettingsService.instance.currency;
  switch (code) {
    case 'USD':
      return NumberFormat.currency(locale: 'en_US', symbol: r'$ ', decimalDigits: decimalDigits).format(amount);
    case 'SGD':
      return NumberFormat.currency(locale: 'en_SG', symbol: r'S$ ', decimalDigits: decimalDigits).format(amount);
    default:
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: decimalDigits).format(amount);
  }
}

/// Ambil angka dari input harga bebas ('Rp 25.000', '25,000 ', '$ 12.50' → 25000/12.5).
/// Satu-satunya tempat parsing harga agar semua form konsisten.
double parsePrice(String? text) {
  final raw = (text ?? '').replaceAll(RegExp(r'[^\d.,]'), '');
  if (raw.isEmpty) return 0;
  final dot = raw.lastIndexOf('.');
  final comma = raw.lastIndexOf(',');
  // Dua separator: yang terakhir adalah desimal ('12.500,50' → 12500.5).
  if (dot != -1 && comma != -1) {
    final decimal = dot > comma ? '.' : ',';
    final parts = raw.split(decimal);
    return double.tryParse('${parts[0].replaceAll(RegExp(r'[.,]'), '')}.${parts[1]}') ?? 0;
  }
  // Satu separator: 3 digit di belakangnya = ribuan ('12.500' → 12500),
  // selain itu desimal ('12.50' → 12.5).
  final sep = dot != -1 ? dot : comma;
  if (sep != -1 && raw.length - sep - 1 == 3) {
    return double.tryParse(raw.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
  }
  if (sep != -1) {
    final parts = raw.split(RegExp(r'[.,]'));
    return double.tryParse('${parts[0]}.${parts[1]}') ?? 0;
  }
  return double.tryParse(raw) ?? 0;
}

String formatCompactCurrency(double amount) {
  final code = SettingsService.instance.currency;
  final symbol = code == 'IDR' ? 'Rp ' : (code == 'USD' ? r'$' : r'S$');
  final abs = amount.abs();
  if (abs >= 1000000000) return '$symbol ${(amount / 1000000000).toStringAsFixed(1)}B';
  if (abs >= 1000000) {
    if (code == 'IDR') return '$symbol ${(amount / 1000000).toStringAsFixed(1)}jt';
    return '$symbol ${(amount / 1000000).toStringAsFixed(1)}M';
  }
  if (abs >= 1000) return '$symbol ${(amount / 1000).toStringAsFixed(0)}k';
  return '$symbol ${amount.toStringAsFixed(0)}';
}