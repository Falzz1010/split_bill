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
];