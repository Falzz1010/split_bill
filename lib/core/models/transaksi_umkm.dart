class TransaksiItem {
  final String id;
  final String name;
  final double price;
  final double costPrice; // modal per item
  final int quantity;
  final String category;

  TransaksiItem({
    required this.id,
    required this.name,
    required this.price,
    this.costPrice = 0,
    required this.quantity,
    this.category = '',
  });

  double get lineTotal => price * quantity;
  double get lineCost => costPrice * quantity;
  double get profit => (price - costPrice) * quantity;
  double get margin => price > 0 ? ((price - costPrice) / price * 100) : 0;

  TransaksiItem copyWith({
    String? name,
    double? price,
    double? costPrice,
    int? quantity,
    String? category,
  }) => TransaksiItem(
    id: id,
    name: name ?? this.name,
    price: price ?? this.price,
    costPrice: costPrice ?? this.costPrice,
    quantity: quantity ?? this.quantity,
    category: category ?? this.category,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'costPrice': costPrice,
    'quantity': quantity,
    'category': category,
  };

  factory TransaksiItem.fromJson(Map<String, dynamic> json) => TransaksiItem(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
    quantity: (json['quantity'] as int?) ?? 1,
    category: json['category']?.toString() ?? '',
  );
}

enum PaymentMethod { cash, qris, debit, credit }

String paymentMethodName(PaymentMethod m) {
  switch (m) {
    case PaymentMethod.cash:
      return 'Tunai';
    case PaymentMethod.qris:
      return 'QRIS';
    case PaymentMethod.debit:
      return 'Kartu Debit';
    case PaymentMethod.credit:
      return 'Kartu Kredit';
  }
}

class TransaksiUmkm {
  final String id;
  final String merchantName;
  final DateTime date;
  final List<TransaksiItem> items;
  final double subtotal;
  final double ppn;
  final double serviceCharge;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final String category;

  TransaksiUmkm({
    required this.id,
    required this.merchantName,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.ppn,
    required this.serviceCharge,
    required this.totalAmount,
    required this.paymentMethod,
    required this.amountPaid,
    this.category = '',
  });

  double get change => amountPaid - totalAmount;

  TransaksiUmkm copyWith({
    String? merchantName,
    DateTime? date,
    List<TransaksiItem>? items,
    double? subtotal,
    double? ppn,
    double? serviceCharge,
    double? totalAmount,
    PaymentMethod? paymentMethod,
    double? amountPaid,
    String? category,
  }) => TransaksiUmkm(
    id: id,
    merchantName: merchantName ?? this.merchantName,
    date: date ?? this.date,
    items: items ?? this.items,
    subtotal: subtotal ?? this.subtotal,
    ppn: ppn ?? this.ppn,
    serviceCharge: serviceCharge ?? this.serviceCharge,
    totalAmount: totalAmount ?? this.totalAmount,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    amountPaid: amountPaid ?? this.amountPaid,
    category: category ?? this.category,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'merchantName': merchantName,
    'date': date.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'ppn': ppn,
    'serviceCharge': serviceCharge,
    'totalAmount': totalAmount,
    'paymentMethod': paymentMethod.index,
    'amountPaid': amountPaid,
    'category': category,
  };

  factory TransaksiUmkm.fromJson(Map<String, dynamic> json) {
    DateTime date;
    try {
      date = DateTime.parse(json['date']?.toString() ?? '');
    } catch (_) {
      date = DateTime.now();
    }
    final payIdx = json['paymentMethod'] as int? ?? 0;
    return TransaksiUmkm(
      id: json['id']?.toString() ?? '',
      merchantName: json['merchantName']?.toString() ?? '',
      date: date,
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => TransaksiItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      ppn: (json['ppn'] as num?)?.toDouble() ?? 0.0,
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.values[payIdx.clamp(0, PaymentMethod.values.length - 1)],
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString() ?? '',
    );
  }
}
