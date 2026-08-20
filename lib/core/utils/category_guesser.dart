/// Tebak kategori struk dari nama toko/judul (rule-based, tanpa AI).
/// Mengembalikan null bila tidak ada pola yang cocok (biarkan user mengisi).
String? guessCategory(String? title) {
  final t = (title ?? '').toLowerCase();
  if (t.isEmpty) return null;

  const rules = <String, List<String>>{
    'Makanan & Minuman': [
      'kopi', 'cafe', 'coffee', 'resto', 'restoran', 'warung', 'makan', 'nasi',
      'ayam', 'mie', 'mi ', 'bakso', 'soto', 'pizza', 'kebab', 'sushi',
      'burger', 'teh', 'jus', 'kue', 'roti', 'bakery', 'snack', 'street',
      'geprek', 'ketan', 'martabak', 'es ', 'milk', 'boba', 'dapur',
    ],
    'Transportasi': [
      'bensin', 'pertamina', 'shell', 'spbu', 'parkir', 'tol', 'grab',
      'gojek', 'go-jek', 'taksi', 'taxi', 'kereta', 'bus', 'bbm', 'gofood',
      'grabfood', 'ojek', 'terminal', 'stasiun', 'pesawat', 'airline',
    ],
    'Pulsa & Listrik': [
      'pulsa', 'telkomsel', 'indosat', 'axis', 'three', 'tri', 'xl ', 'data',
      'token', 'listrik', 'pln', 'wifi', 'indihome',
    ],
    'Belanja': [
      'alfamart', 'indomaret', 'minimarket', 'supermarket', 'market',
      'mart', 'mall', 'store', 'shop', 'fashion', 'pakaian', 'sepatu',
      'grosir', 'swalayan', 'convenience',
    ],
    'Kesehatan': [
      'apotek', 'klinik', 'dokter', 'obat', 'farmasi', 'rumah sakit',
      'laboratorium', 'klinik', 'farma', 'kimia',
    ],
    'Hiburan': [
      'bioskop', 'cinema', 'cinepolis', 'xxi', 'game', 'steam', 'netflix',
      'spotify', 'youtube', 'konser', 'bowling', 'karaoke',
    ],
    'Belanja Online': [
      'tokopedia', 'shopee', 'lazada', 'bukalapak', 'tiktok shop',
      'blibli', 'j&t', 'jnt', 'sicepat', 'ninja express',
    ],
    'Pendidikan': [
      'buku', 'gramedia', 'sekolah', 'kuliah', 'kursus', 'stationery',
      'alat tulis', 'atk', 'perpustakaan',
    ],
  };

  for (final entry in rules.entries) {
    for (final kw in entry.value) {
      if (t.contains(kw)) return entry.key;
    }
  }
  return null;
}