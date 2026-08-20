import 'package:flutter_test/flutter_test.dart';
import 'package:fairsplit/core/utils/category_guesser.dart';

void main() {
  group('guessCategory', () {
    test('menebak kategori dari nama toko umum', () {
      expect(guessCategory('Kopi Kenangan Cabang Jl. Sudirman'), 'Makanan & Minuman');
      expect(guessCategory('Warung Nasi Bu Sari'), 'Makanan & Minuman');
      expect(guessCategory('Pertamina SPBU 34.123'), 'Transportasi');
      expect(guessCategory('Shell Jl. Ahmad Yani'), 'Transportasi');
      expect(guessCategory('Telkomsel Pulsa'), 'Pulsa & Listrik');
      expect(guessCategory('PLN Token Listrik'), 'Pulsa & Listrik');
      expect(guessCategory('Alfamart Sudirman 2'), 'Belanja');
      expect(guessCategory('Indomaret Kemang'), 'Belanja');
      expect(guessCategory('Apotek Kimia Farma'), 'Kesehatan');
      expect(guessCategory('XXI Grand Indonesia'), 'Hiburan');
      expect(guessCategory('Tokopedia Order #123'), 'Belanja Online');
      expect(guessCategory('Gramedia Gramedia'), 'Pendidikan');
    });

    test('judul tidak dikenal / kosong → null (user mengisi manual)', () {
      expect(guessCategory(null), isNull);
      expect(guessCategory(''), isNull);
      expect(guessCategory('Acme Corp Cargo Services'), isNull);
    });

    test('tidak sensitif huruf besar/kecil', () {
      expect(guessCategory('KOPI KENANGAN'), 'Makanan & Minuman');
      expect(guessCategory('alfamart'), 'Belanja');
    });
  });
}