import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fairsplit/core/utils/currency_rates.dart';

void main() {
  group('CurrencyRatesService.detectCurrency', () {
    test('null/empty text returns null', () {
      expect(CurrencyRatesService.detectCurrency(null), isNull);
      expect(CurrencyRatesService.detectCurrency('   '), isNull);
    });

    test('Rp (kasus huruf campuran) terdeteksi sebagai IDR tanpa crash', () {
      // "Rp" di-uppercase menjadi "RP" — dulu memicu null-check crash.
      expect(
        CurrencyRatesService.detectCurrency('Rp 50.000\nTotal Rp 50.000'),
        'IDR',
      );
      expect(
        CurrencyRatesService.detectCurrency('TOTAL\nRP 12.000'),
        'IDR',
      );
    });

    test('kode asing sebagai kata utuh', () {
      expect(CurrencyRatesService.detectCurrency('USD 12.50'), 'USD');
      expect(CurrencyRatesService.detectCurrency('SGD 5.00'), 'SGD');
      expect(CurrencyRatesService.detectCurrency('JPY 1,200'), 'JPY');
      expect(CurrencyRatesService.detectCurrency('EUR 9.99'), 'EUR');
    });

    test('simbol mata uang (urutan panjang dulu)', () {
      expect(CurrencyRatesService.detectCurrency('US\$ 12.50'), 'USD');
      expect(CurrencyRatesService.detectCurrency('S\$ 12.50'), 'SGD');
      expect(CurrencyRatesService.detectCurrency(r'$ 12.50'), 'USD');
      expect(CurrencyRatesService.detectCurrency('€ 9.99'), 'EUR');
      expect(CurrencyRatesService.detectCurrency('¥ 1,200'), 'JPY');
      expect(CurrencyRatesService.detectCurrency('JP¥ 1,200'), 'JPY');
    });

    test('kode di tengah kalimat tidak salah tangkap', () {
      expect(CurrencyRatesService.detectCurrency('Kopi Senja Cafe'), isNull);
    });
  });

  group('CurrencyRatesService.load & toIdr', () {
    test('kurs tersimpan dimuat dan dipakai konversi', () async {
      SharedPreferences.setMockInitialValues({
        'currency_rates_json': '{"USD": 16000.0, "JPY": 105.0}',
        'currency_rates_updated': '2026-08-17T10:00:00.000',
      });
      await CurrencyRatesService.instance.load();
      expect(CurrencyRatesService.instance.rate('USD'), 16000.0);
      expect(CurrencyRatesService.instance.rate('JPY'), 105.0);
      expect(CurrencyRatesService.instance.toIdr(10, 'USD'), 160000.0);
      expect(CurrencyRatesService.instance.toIdr(100, 'JPY'), 10500.0);
      // Mata uang tanpa kurs → 0 (tidak mengarang angka).
      expect(CurrencyRatesService.instance.toIdr(10, 'GBP'), 0);
    });

    test('IDR tampil pertama di daftar sebagai mata uang dasar', () async {
      SharedPreferences.setMockInitialValues({
        'currency_rates_json': '{"USD": 16000.0, "JPY": 111.88}',
      });
      await CurrencyRatesService.instance.load();
      // IDR (mata uang dasar) tampil pertama di daftar Pengaturan.
      expect(CurrencyRatesService.displayCurrencies.first, 'IDR');
      expect(
        CurrencyRatesService.displayCurrencies,
        ['IDR', 'USD', 'SGD', 'JPY', 'EUR'],
      );
      expect(CurrencyRatesService.instance.formatRate('USD'), '1 USD = Rp 16000');
      expect(CurrencyRatesService.instance.formatRate('JPY'), '1 JPY = Rp 111.88');
      // supportedForeign tetap hanya mata uang asing (dipakai fetch API).
      expect(CurrencyRatesService.supportedForeign.contains('IDR'), isFalse);
    });

    test('data korup tidak menggagalkan load (pakai default)', () async {
      SharedPreferences.setMockInitialValues({
        'currency_rates_json': 'not-json{{{',
      });
      await CurrencyRatesService.instance.load();
      expect(CurrencyRatesService.instance.rate('USD'),
          CurrencyRatesService.defaultRates['USD']);
    });
  });
}
