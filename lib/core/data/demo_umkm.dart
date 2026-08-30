import '../models/transaksi_umkm.dart';

/// Data contoh transaksi UMKM untuk mode Kasir ("Muat Data Contoh UMKM" di Pengaturan).
/// Tanggal relatif terhadap hari ini agar chart tren & forecast selalu ada data.

final DateTime _now = DateTime.now();

DateTime _daysAgo(int days, {int hour = 10, int minute = 0}) =>
    DateTime(_now.year, _now.month, _now.day - days, hour, minute);

TransaksiItem _tItem(
  String id,
  String name,
  double price,
  double cost,
  int qty,
  String category,
) =>
    TransaksiItem(
      id: id,
      name: name,
      price: price,
      costPrice: cost,
      quantity: qty,
      category: category,
    );

/// Hitung subtotal, ppn (11%), service (opsional), total dari item.
TransaksiUmkm _buildTrans({
  required String id,
  required String merchantName,
  required DateTime date,
  required List<TransaksiItem> items,
  required PaymentMethod paymentMethod,
  double amountPaid = 0,
  bool includeService = false,
  String category = '',
}) {
  final subtotal = items.fold(0.0, (sum, i) => sum + i.lineTotal);
  final ppn = (subtotal * 0.11).roundToDouble();
  final svc = includeService ? (subtotal * 0.10).roundToDouble() : 0.0;
  final total = subtotal + ppn + svc;
  return TransaksiUmkm(
    id: id,
    merchantName: merchantName,
    date: date,
    items: items,
    subtotal: subtotal,
    ppn: ppn,
    serviceCharge: svc,
    totalAmount: total,
    paymentMethod: paymentMethod,
    amountPaid: amountPaid > 0 ? amountPaid : total,
    category: category,
  );
}

final List<TransaksiUmkm> mockUmkmTransactions = [
  // ---- Hari ini (2 transaksi) ----
  _buildTrans(
    id: 'u1',
    merchantName: 'Kedai Kopi Nusantara',
    date: _daysAgo(0, hour: 8, minute: 15),
    category: 'Minuman',
    paymentMethod: PaymentMethod.qris,
    items: [
      _tItem('ut1', 'Kopi Susu Signature', 28000, 8500, 3, 'Minuman'),
      _tItem('ut2', 'Croissant Coklat', 22000, 7000, 2, 'Snack'),
      _tItem('ut3', 'Air Mineral', 5000, 1500, 1, 'Minuman'),
    ],
  ),
  _buildTrans(
    id: 'u2',
    merchantName: 'Kedai Kopi Nusantara',
    date: _daysAgo(0, hour: 12, minute: 30),
    category: 'Makanan',
    paymentMethod: PaymentMethod.cash,
    items: [
      _tItem('ut4', 'Nasi Goreng Spesial', 35000, 12000, 2, 'Makanan'),
      _tItem('ut5', 'Mie Ayam Bakso', 30000, 10000, 1, 'Makanan'),
      _tItem('ut6', 'Es Teh Manis', 8000, 2000, 3, 'Minuman'),
      _tItem('ut7', 'Kerupuk', 3000, 1000, 2, 'Snack'),
    ],
  ),

  // ---- 1 hari lalu ----
  _buildTrans(
    id: 'u3',
    merchantName: 'Kedai Kopi Nusantara',
    date: _daysAgo(1, hour: 9, minute: 0),
    category: 'Minuman',
    paymentMethod: PaymentMethod.debit,
    items: [
      _tItem('ut8', 'Cappuccino', 32000, 10000, 2, 'Minuman'),
      _tItem('ut9', 'Matcha Latte', 35000, 11000, 1, 'Minuman'),
      _tItem('ut10', 'Banana Bread', 20000, 6500, 2, 'Snack'),
    ],
  ),
  _buildTrans(
    id: 'u4',
    merchantName: 'Kedai Kopi Nusantara',
    date: _daysAgo(1, hour: 14, minute: 45),
    category: 'Makanan',
    paymentMethod: PaymentMethod.qris,
    items: [
      _tItem('ut11', 'Paket Nasi Padang', 28000, 10000, 4, 'Makanan'),
      _tItem('ut12', 'Es Jeruk Segar', 12000, 3500, 4, 'Minuman'),
    ],
  ),

  // ---- 2 hari lalu ----
  _buildTrans(
    id: 'u5',
    merchantName: 'Kedai Kopi Nusantara',
    date: _daysAgo(2, hour: 10, minute: 20),
    category: 'Minuman',
    paymentMethod: PaymentMethod.cash,
    items: [
      _tItem('ut13', 'Americano', 25000, 7500, 3, 'Minuman'),
      _tItem('ut14', 'Cheesecake', 35000, 12000, 1, 'Snack'),
      _tItem('ut15', 'Tiramisu', 38000, 13000, 1, 'Snack'),
    ],
  ),
  _buildTrans(
    id: 'u6',
    merchantName: 'Kedai Kopi Nusantara',
    date: _daysAgo(2, hour: 16, minute: 0),
    category: 'Makanan',
    paymentMethod: PaymentMethod.qris,
    items: [
      _tItem('ut16', 'Chicken Katsu', 42000, 15000, 2, 'Makanan'),
      _tItem('ut17', 'French Fries', 25000, 8000, 1, 'Snack'),
      _tItem('ut18', 'Lemon Tea', 15000, 4000, 2, 'Minuman'),
    ],
  ),

  // ---- 3 hari lalu ----
  _buildTrans(
    id: 'u7',
    merchantName: 'Kedai Kopi Nusantara',
    date: _daysAgo(3, hour: 8, minute: 30),
    category: 'Minuman',
    paymentMethod: PaymentMethod.credit,
    includeService: true,
    items: [
      _tItem('ut19', 'Flat White', 35000, 11000, 4, 'Minuman'),
      _tItem('ut20', 'Avocado Toast', 45000, 15000, 2, 'Makanan'),
      _tItem('ut21', 'Granola Bowl', 38000, 12000, 1, 'Makanan'),
    ],
  ),

  // ---- 5 hari lalu ----
  _buildTrans(
    id: 'u8',
    merchantName: 'Kedai Kopi Nusantara',
    date: _daysAgo(5, hour: 11, minute: 15),
    category: 'Makanan',
    paymentMethod: PaymentMethod.qris,
    items: [
      _tItem('ut22', 'Mie Goreng Seafood', 40000, 14000, 3, 'Makanan'),
      _tItem('ut23', 'Sate Ayam 10 Tusuk', 35000, 12000, 2, 'Makanan'),
      _tItem('ut24', 'Es Campur', 18000, 5500, 3, 'Minuman'),
    ],
  ),

  // ---- 7 hari lalu ----
  _buildTrans(
    id: 'u9',
    merchantName: 'Kedai Kopi Nusantara',
    date: _daysAgo(7, hour: 9, minute: 0),
    category: 'Minuman',
    paymentMethod: PaymentMethod.cash,
    items: [
      _tItem('ut25', 'Kopi Tubruk', 15000, 4500, 5, 'Minuman'),
      _tItem('ut26', 'Tempe Mendoan', 12000, 4000, 3, 'Snack'),
      _tItem('ut27', 'Gorengan Campur', 10000, 3500, 2, 'Snack'),
    ],
  ),
  _buildTrans(
    id: 'u10',
    merchantName: 'Kedai Kopi Nusantara',
    date: _daysAgo(7, hour: 15, minute: 30),
    category: 'Minuman',
    paymentMethod: PaymentMethod.qris,
    items: [
      _tItem('ut28', 'Hazelnut Latte', 35000, 11000, 2, 'Minuman'),
      _tItem('ut29', 'Red Velvet Latte', 35000, 11000, 1, 'Minuman'),
      _tItem('ut30', 'Cinnamon Roll', 25000, 8000, 2, 'Snack'),
    ],
  ),

  // ---- 10 hari lalu ----
  _buildTrans(
    id: 'u11',
    merchantName: 'Kedai Kopi Nusantara',
    date: _daysAgo(10, hour: 10, minute: 0),
    category: 'Makanan',
    paymentMethod: PaymentMethod.debit,
    items: [
      _tItem('ut31', 'Nasi Goreng Kampung', 32000, 11000, 3, 'Makanan'),
      _tItem('ut32', 'Ayam Penyet', 38000, 13000, 2, 'Makanan'),
      _tItem('ut33', 'Es Kelapa Muda', 15000, 5000, 3, 'Minuman'),
    ],
  ),

  // ---- 12 hari lalu ----
  _buildTrans(
    id: 'u12',
    merchantName: 'Kedai Kopi Nusantara',
    date: _daysAgo(12, hour: 13, minute: 0),
    category: 'Minuman',
    paymentMethod: PaymentMethod.qris,
    items: [
      _tItem('ut34', 'Cold Brew', 30000, 9000, 4, 'Minuman'),
      _tItem('ut35', 'Brownies Coklat', 22000, 7000, 3, 'Snack'),
      _tItem('ut36', 'Muffin Blueberry', 20000, 6500, 2, 'Snack'),
    ],
  ),
];
