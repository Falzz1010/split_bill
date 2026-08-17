class Member {
  final String id;
  final String name;
  final String avatarUrl;
  final String accentColorHex;
  final bool isPaid;
  final double amountOwed;

  Member({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.accentColorHex,
    required this.isPaid,
    required this.amountOwed,
  });

  Member copyWith({
    String? name,
    String? avatarUrl,
    String? accentColorHex,
    bool? isPaid,
    double? amountOwed,
  }) => Member(
    id: id,
    name: name ?? this.name,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    accentColorHex: accentColorHex ?? this.accentColorHex,
    isPaid: isPaid ?? this.isPaid,
    amountOwed: amountOwed ?? this.amountOwed,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarUrl': avatarUrl,
    'accentColorHex': accentColorHex,
    'isPaid': isPaid,
    'amountOwed': amountOwed,
  };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    id: json['id'] as String,
    name: json['name'] as String,
    avatarUrl: json['avatarUrl'] as String? ?? '',
    accentColorHex: json['accentColorHex'] as String? ?? '#FFCD00',
    isPaid: json['isPaid'] as bool? ?? false,
    amountOwed: (json['amountOwed'] as num).toDouble(),
  );
}

class ReceiptItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final List<String> assignedMemberIds;

  ReceiptItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.assignedMemberIds,
  });

  ReceiptItem copyWith({
    String? name,
    double? price,
    int? quantity,
    List<String>? assignedMemberIds,
  }) => ReceiptItem(
    id: id,
    name: name ?? this.name,
    price: price ?? this.price,
    quantity: quantity ?? this.quantity,
    assignedMemberIds: assignedMemberIds ?? this.assignedMemberIds,
  );

  /// Total baris item (harga satuan × qty).
  double get lineTotal => price * quantity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
    'assignedMemberIds': assignedMemberIds,
  };

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    quantity: json['quantity'] as int? ?? 1,
    assignedMemberIds: List<String>.from(
      json['assignedMemberIds'] as List? ?? [],
    ),
  );
}

class SplitBill {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final double subtotal;
  final double tax;
  final double serviceCharge;
  final double discount;
  final double totalAmount;
  final bool isCompleted;
  final List<Member> members;
  final List<ReceiptItem> items;

  SplitBill({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.discount,
    required this.totalAmount,
    required this.isCompleted,
    required this.members,
    required this.items,
  });

  int get paidCount => members.where((m) => m.isPaid).length;

  /// Subtotal dihitung dari item (satu sumber, tidak bergantung field tersimpan).
  double get itemsSubtotal => items.fold(0.0, (sum, i) => sum + i.lineTotal);

  /// Pencarian bebas dipakai Dashboard & Riwayat: judul, kategori, nama anggota.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        members.any((m) => m.name.toLowerCase().contains(q));
  }

  /// Kategori menyimpan prefix "N Anggota • " sebagai konvensi data yang
  /// di-parse dashboard. [categoryLabel] mengambil bagian setelah prefix.
  String get categoryLabel => categoryLabelOf(category);

  SplitBill copyWith({
    String? title,
    String? category,
    DateTime? date,
    double? subtotal,
    double? tax,
    double? serviceCharge,
    double? discount,
    double? totalAmount,
    bool? isCompleted,
    List<Member>? members,
    List<ReceiptItem>? items,
  }) => SplitBill(
    id: id,
    title: title ?? this.title,
    category: category ?? this.category,
    date: date ?? this.date,
    subtotal: subtotal ?? this.subtotal,
    tax: tax ?? this.tax,
    serviceCharge: serviceCharge ?? this.serviceCharge,
    discount: discount ?? this.discount,
    totalAmount: totalAmount ?? this.totalAmount,
    isCompleted: isCompleted ?? this.isCompleted,
    members: members ?? this.members,
    items: items ?? this.items,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'date': date.toIso8601String(),
    'subtotal': subtotal,
    'tax': tax,
    'serviceCharge': serviceCharge,
    'discount': discount,
    'totalAmount': totalAmount,
    'isCompleted': isCompleted,
    'members': members.map((m) => m.toJson()).toList(),
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory SplitBill.fromJson(Map<String, dynamic> json) => SplitBill(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    date: DateTime.parse(json['date'] as String),
    subtotal: (json['subtotal'] as num).toDouble(),
    tax: (json['tax'] as num).toDouble(),
    serviceCharge: (json['serviceCharge'] as num).toDouble(),
    discount: (json['discount'] as num).toDouble(),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    isCompleted: json['isCompleted'] as bool? ?? false,
    members: (json['members'] as List)
        .map((m) => Member.fromJson(m as Map<String, dynamic>))
        .toList(),
    items: (json['items'] as List)
        .map((i) => ReceiptItem.fromJson(i as Map<String, dynamic>))
        .toList(),
  );
}

/// Kategori menyimpan konvensi "N Anggota • <label>". Dua helper ini adalah
/// satu-satunya tempat format itu ditulis/dibaca.
String categoryLabelOf(String category) =>
    category.contains('•') ? category.split('•').last.trim() : category;

String categoryWithMemberCount(String category, int count) =>
    '$count Anggota • ${categoryLabelOf(category)}';

/// Menghitung pajak (PPN 11%) & service charge (10%) dari subtotal.
/// Satu-satunya sumber kalkulasi pajak/service agar create dialog & bill
/// editor selalu konsisten (label UI: PPN 11%, Service 10%).
({double tax, double serviceCharge, double total}) computeTaxAndService(
  double subtotal, {
  bool includeTax = true,
  bool includeService = true,
}) {
  final tax = includeTax ? subtotal * 0.11 : 0.0;
  final serviceCharge = includeService ? subtotal * 0.10 : 0.0;
  return (
    tax: tax,
    serviceCharge: serviceCharge,
    total: subtotal + tax + serviceCharge,
  );
}

/// Menghitung nominal tagihan per anggota secara proporsional:
/// pembagian item yang ditugaskan + porsi pajak/service/discount sebanding.
List<Member> computeMemberAmounts(
  List<Member> members,
  List<ReceiptItem> items, {
  double tax = 0,
  double serviceCharge = 0,
  double discount = 0,
}) {
  final memberShares = <String, double>{};
  for (final member in members) {
    memberShares[member.id] = 0;
  }

  for (final item in items) {
    var assigned = item.assignedMemberIds
        .where(memberShares.containsKey)
        .toList();
    // Item tanpa assign: dibagi rata ke semua member, supaya jumlah tagihan
    // member selalu sama dengan total tagihan (tidak ada uang yang hilang).
    if (assigned.isEmpty) assigned = memberShares.keys.toList();
    final share = item.lineTotal / assigned.length;
    for (final id in assigned) {
      memberShares[id] = (memberShares[id] ?? 0) + share;
    }
  }

  final totalShare = memberShares.values.fold(0.0, (a, b) => a + b);
  final extraTotal = (tax + serviceCharge - discount)
      .clamp(0.0, double.infinity)
      .toDouble();

  return members.map((member) {
    final base = memberShares[member.id] ?? 0;
    final extra = totalShare > 0 ? extraTotal * (base / totalShare) : 0.0;
    return member.copyWith(amountOwed: base + extra);
  }).toList();
}
