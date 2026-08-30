import '../models/split_model.dart';

/// Data contoh untuk mode demo ("Muat Struk Contoh" di Pengaturan).
/// Semua nominal dihitung dari item dengan algoritma yang sama seperti app
/// (computeTaxAndService + computeMemberAmounts) — tidak ada angka manual,
/// sehingga demo selalu konsisten dengan perilaku asli.

final DateTime _demoNow = DateTime.now();

/// Tanggal demo relatif terhadap hari ini (bukan hardcoded tahun tertentu),
/// agar chart 6 bulan, label "Bulan Ini", dan tren selalu menampilkan data —
/// tanggal lama (mis. 2024) akan membuat grafik kosong saat demo dimuat.
DateTime _monthsAgo(int months, int day) =>
    DateTime(_demoNow.year, _demoNow.month - months, day);

/// Menyusun satu split demo: subtotal, pajak (11%), service (10%),
/// total, dan tagihan per member semuanya dihitung dari item.
SplitBill _buildSplit({
  required String id,
  required String title,
  required String category,
  required DateTime date,
  required List<Member> members,
  required List<ReceiptItem> items,
  double discount = 0,
  bool includeService = true,
  bool isCompleted = false,
}) {
  final subtotal = items.fold(0.0, (sum, i) => sum + i.lineTotal);
  final totals = computeTaxAndService(
    subtotal,
    includeService: includeService,
  );
  final withAmounts = computeMemberAmounts(
    members,
    items,
    tax: totals.tax,
    serviceCharge: totals.serviceCharge,
    discount: discount,
  );
  return SplitBill(
    id: id,
    title: title,
    category: category,
    date: date,
    subtotal: subtotal,
    tax: totals.tax,
    serviceCharge: totals.serviceCharge,
    discount: discount,
    totalAmount: totals.total - discount,
    isCompleted: isCompleted,
    members: withAmounts,
    items: items,
  );
}

Member _member(String id, String name, String color, {bool isPaid = false}) =>
    Member(
      id: id,
      name: name,
      avatarUrl: '',
      accentColorHex: color,
      isPaid: isPaid,
      amountOwed: 0,
    );

ReceiptItem _item(
  String id,
  String name,
  double price,
  int qty,
  List<String> assigned,
) => ReceiptItem(
  id: id,
  name: name,
  price: price,
  quantity: qty,
  assignedMemberIds: assigned,
);

final List<SplitBill> mockSplitBills = [
  _buildSplit(
    id: '1',
    title: 'Kopi Kenangan Senopati',
    category: '4 Anggota • F&B Resto',
    date: _monthsAgo(0, 12),
    members: [
      _member('m1', 'Marko (Saya)', '#FFCD00', isPaid: true),
      _member('m2', 'Budi (BCA)', '#62FAE3', isPaid: true),
      _member('m3', 'Siti (Mandiri)', '#FF7A59', isPaid: true),
      _member('m4', 'Luna (GoPay)', '#A5B4FC'),
    ],
    items: [
      _item('i1', 'Kopi Kenangan Mantan Large', 28000, 2, ['m1', 'm2']),
      _item('i2', 'Roti Coklat Klasik', 15000, 3, ['m3', 'm4']),
      _item('i3', 'Avocado Coffee Special', 34000, 1, ['m1']),
      _item('i4', 'Toast Smoked Beef Cheese', 38000, 1, ['m2', 'm3']),
    ],
  ),
  _buildSplit(
    id: '2',
    title: 'Makan Malam Sate Khas Senayan',
    category: '3 Anggota • Restoran',
    date: _monthsAgo(2, 10),
    discount: 15000,
    isCompleted: true,
    members: [
      _member('m1', 'Marko', '#FFCD00', isPaid: true),
      _member('m5', 'Dini', '#FF7A59', isPaid: true),
      _member('m6', 'Rian', '#62FAE3', isPaid: true),
    ],
    items: [
      _item('i5', 'Sate Ayam Ponorogo 10 Pcs', 68000, 2, ['m1', 'm5', 'm6']),
      _item('i6', 'Nasi Goreng Kambing', 55000, 1, ['m1']),
      _item('i7', 'Es Teh Manis', 12000, 3, ['m1', 'm5', 'm6']),
    ],
  ),
  _buildSplit(
    id: '3',
    title: 'Supermarket Ranch Market',
    category: '2 Anggota • Belanja Bulanan',
    date: _monthsAgo(4, 8),
    discount: 10000,
    includeService: false,
    members: [
      _member('m1', 'Marko', '#FFCD00', isPaid: true),
      _member('m7', 'Sarah', '#A5B4FC'),
    ],
    items: [
      _item('i8', 'Susu UHT Full Cream 1L', 24000, 2, ['m1', 'm7']),
      _item('i9', 'Buah Apel Fuji 1kg', 48000, 1, ['m1', 'm7']),
    ],
  ),
  _buildSplit(
    id: '4',
    title: 'Warung Makan Padang Sederhana',
    category: '3 Anggota • Warung',
    date: _monthsAgo(0, 5),
    includeService: false,
    members: [
      _member('m1', 'Marko (Saya)', '#FFCD00', isPaid: true),
      _member('m8', 'Rina (DANA)', '#FF7A59'),
      _member('m9', 'Andi (OVO)', '#62FAE3'),
    ],
    items: [
      _item('i10', 'Nasi Padang Ayam Gulai', 25000, 2, ['m1', 'm8']),
      _item('i11', 'Nasi Rendang Spesial', 35000, 1, ['m1']),
      _item('i12', 'Sayur Nangka', 8000, 3, ['m1', 'm8', 'm9']),
      _item('i13', 'Es Teh Manis', 5000, 3, ['m1', 'm8', 'm9']),
      _item('i14', 'Kerupuk Jengkol', 7000, 2, ['m8', 'm9']),
    ],
  ),
  _buildSplit(
    id: '5',
    title: 'Food Court Plaza Senayan',
    category: '5 Anggota • Food Court',
    date: _monthsAgo(1, 18),
    discount: 25000,
    isCompleted: true,
    members: [
      _member('m1', 'Marko', '#FFCD00', isPaid: true),
      _member('m10', 'Lestari', '#A5B4FC', isPaid: true),
      _member('m11', 'Fajar', '#62FAE3', isPaid: true),
      _member('m12', 'Nina', '#FF7A59', isPaid: true),
      _member('m13', 'Tommy', '#2DD4BF', isPaid: true),
    ],
    items: [
      _item('i15', 'Chicken Teriyaki Donburi', 45000, 2, ['m1', 'm10']),
      _item('i16', 'Beef Burger XL', 55000, 1, ['m11']),
      _item('i17', 'Paket Nasi Goreng Seafood', 42000, 2, ['m12', 'm13']),
      _item('i18', 'Iced Lemon Tea', 18000, 5, ['m1', 'm10', 'm11', 'm12', 'm13']),
      _item('i19', 'Kentang Goreng Reuse', 28000, 2, ['m10', 'm13']),
    ],
  ),
  _buildSplit(
    id: '6',
    title: 'Kedai Kopi Sabana',
    category: '2 Anggota • Kedai Kopi',
    date: _monthsAgo(3, 22),
    members: [
      _member('m1', 'Marko (Saya)', '#FFCD00', isPaid: true),
      _member('m14', 'Putri (Jago)', '#A5B4FC'),
    ],
    items: [
      _item('i20', 'Kopi Susu Hazelnut', 32000, 2, ['m1', 'm14']),
      _item('i21', 'Matcha Latte', 35000, 1, ['m14']),
      _item('i22', 'Croissant Butter', 28000, 1, ['m1']),
      _item('i23', 'Tiramisu Slice', 38000, 1, ['m1', 'm14']),
      _item('i24', 'Mineral Water', 8000, 2, ['m1', 'm14']),
      _item('i25', 'Cheesecake Slice', 42000, 1, ['m1']),
      _item('i26', 'Roti Garlic Cheese', 25000, 1, ['m14']),
    ],
  ),
  _buildSplit(
    id: '7',
    title: 'Restoran Sushi Tei',
    category: '4 Anggota • Restoran',
    date: _monthsAgo(1, 3),
    isCompleted: true,
    members: [
      _member('m1', 'Marko', '#FFCD00', isPaid: true),
      _member('m15', 'Dian (Mandiri)', '#FF7A59', isPaid: true),
      _member('m16', 'Yoga (BCA)', '#62FAE3', isPaid: true),
      _member('m17', 'Maya (BNI)', '#A5B4FC', isPaid: true),
    ],
    items: [
      _item('i27', 'Salmon Sashimi Premium', 125000, 1, ['m1', 'm15']),
      _item('i28', 'Chicken Katsu Curry', 68000, 2, ['m16', 'm17']),
      _item('i29', 'Dragon Roll Maki', 88000, 1, ['m1', 'm15', 'm16']),
      _item('i30', 'Miso Soup', 22000, 4, ['m1', 'm15', 'm16', 'm17']),
      _item('i31', 'Green Tea Ice Cream', 28000, 2, ['m15', 'm17']),
      _item('i32', 'Iced Ocha', 15000, 4, ['m1', 'm15', 'm16', 'm17']),
    ],
  ),
  _buildSplit(
    id: '8',
    title: 'Baker Street Bakery',
    category: '2 Anggota • Bakery',
    date: _monthsAgo(2, 14),
    members: [
      _member('m1', 'Marko (Saya)', '#FFCD00'),
      _member('m7', 'Sarah (BCA)', '#A5B4FC', isPaid: true),
    ],
    items: [
      _item('i33', 'Sourdough Bread', 45000, 1, ['m1', 'm7']),
      _item('i34', 'Cinnamon Roll', 28000, 2, ['m1']),
      _item('i35', 'Almond Croissant', 32000, 1, ['m7']),
      _item('i36', 'Banana Bread Slice', 22000, 2, ['m1', 'm7']),
      _item('i37', 'Cappuccino', 35000, 1, ['m1']),
      _item('i38', 'Flat White', 38000, 1, ['m7']),
    ],
  ),
  _buildSplit(
    id: '9',
    title: 'Mie Ayam Gondangdia',
    category: '3 Anggota • Warung Mie',
    date: _monthsAgo(5, 1),
    includeService: false,
    isCompleted: true,
    members: [
      _member('m1', 'Marko', '#FFCD00', isPaid: true),
      _member('m8', 'Rina', '#FF7A59', isPaid: true),
      _member('m18', 'Gilbert', '#2DD4BF', isPaid: true),
    ],
    items: [
      _item('i39', 'Mie Ayam Komplit', 28000, 3, ['m1', 'm8', 'm18']),
      _item('i40', 'Pangsit Goreng', 12000, 3, ['m1', 'm8', 'm18']),
      _item('i41', 'Es Jeruk Segar', 10000, 3, ['m1', 'm8', 'm18']),
      _item('i42', 'Tahu Gejrot', 8000, 2, ['m1', 'm18']),
    ],
  ),
  _buildSplit(
    id: '10',
    title: 'Solaria Mall Kelapa Gading',
    category: '4 Anggota • Restoran',
    date: _monthsAgo(0, 20),
    members: [
      _member('m1', 'Marko (Saya)', '#FFCD00', isPaid: true),
      _member('m10', 'Lestari (GoPay)', '#A5B4FC'),
      _member('m11', 'Fajar (DANA)', '#62FAE3'),
      _member('m12', 'Nina (OVO)', '#FF7A59'),
    ],
    items: [
      _item('i43', 'Nasi Goreng Spesial', 38000, 2, ['m1', 'm10']),
      _item('i44', 'Ayam Bakar Madu', 45000, 1, ['m11']),
      _item('i45', 'Capcay Seafood', 42000, 1, ['m12']),
      _item('i46', 'Es Campur', 18000, 4, ['m1', 'm10', 'm11', 'm12']),
      _item('i47', 'Kerupuk', 5000, 2, ['m1', 'm12']),
    ],
  ),
];