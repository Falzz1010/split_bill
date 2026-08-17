import '../models/split_model.dart';

class ParsedReceiptResult {
  final String merchantName;
  final double subtotal;
  final double tax;
  final double serviceCharge;
  final double totalAmount;
  final List<ReceiptItem> items;

  ParsedReceiptResult({
    required this.merchantName,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.totalAmount,
    required this.items,
  });
}

class ReceiptParser {
  static final RegExp _junkRegex =
      RegExp(r'^(no\.?|link|www\.|http|teri\w*\s*kas|atas\s*kun|jangan buang|mrdiy|\w+\.id$)', caseSensitive: false);
  static final RegExp _dateRegex = RegExp(r'^\d{1,4}[-/]\d{1,2}[-/]\d{1,4}$');
  static final RegExp _dateTimeRegex = RegExp(r'^\d{1,2}[\./]\d{1,2}[\./]\d{2,4}');
  static final RegExp _timeRegex = RegExp(r'^\d{1,2}:\d{2}');
  static final RegExp _digitsOnlyRegex = RegExp(r'^\d{8,}$');

  /// Normalisasi OCR: rontek titik ("Nasi....20.000"), spasi "1 X 20.000",
  /// "Rp 20.000", dan huruf O yang terbaca sebagai 0 ("15.O00") →
  /// bentuk baku agar mudah diparse.
  static String _normalizeLine(String raw) {
    var l = raw.trim();
    l = l.replaceAll(RegExp(r'(?<=[\d\.,])[Oo](?=[\d\.,])'), '0');
    l = l.replaceAll(RegExp(r'[\s\.\-=]{2,}'), ' ');
    l = l.replaceAll(RegExp(r'\s+[xX×]\s*'), 'X');
    l = l.replaceAll(RegExp(r'(?<![A-Za-z])[xX×]'), 'X');
    l = l.replaceAllMapped(RegExp(r'(\d)X\s+(\d)'), (m) => '${m[1]}X${m[2]}');
    // Format qty dengan '@': "2 @ 15.000" → "2X15.000"; "@15.000" → "15.000"
    l = l.replaceAllMapped(RegExp(r'(\d)\s*@\s*(\d)'), (m) => '${m[1]}X${m[2]}');
    l = l.replaceAll(RegExp(r'\s*@\s*'), ' ');
    // Sufiks rupiah lama: "20.000,-" → "20.000"
    l = l.replaceAll(RegExp(r',-'), '');
    l = l.replaceAll(RegExp(r'Rp\.?\s*', caseSensitive: false), 'Rp');
    l = l.replaceAll(RegExp(r'\s+'), ' ').trim();
    return l;
  }

  static final RegExp _amountOnlyRegex = RegExp(r'^(?:(\d+)X)?(?:Rp)?([\d\.,]{3,})$');
  static final RegExp _nameAmountRegex =
      RegExp(r'^(?:(\d+)X)?(.+?)(?:(?:(\d+)X)|(\d+)\s+)?(?:Rp)?([\d\.,]{3,})$');
  /// Nama berupa kuantitas + satuan, mis. "4.000 KgX", "800 BoxX" → baris harga
  /// yang harus dipasangkan ke nama item di baris sebelumnya.
  static final RegExp _unitQtyNameRegex = RegExp(r'^(\d[\d\.,]*\s*)?[A-Za-z]{2,5}X?$');

  static double _parseAmount(String s) => double.tryParse(s.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  /// Nilai OCR palsu (jutaan rupiah dari teks rusak) tidak pernah jadi harga item.
  static const double _maxItemPrice = 1000000;

  /// Baris yang jelas bukan nama item: kasir, pelanggan, alamat, label aplikasi POS.
  static final List<RegExp> _nonItemPatterns = [
    RegExp(r'kasir', caseSensitive: false),
    RegExp(r'pelanggan', caseSensitive: false),
    RegExp(r'meja', caseSensitive: false),
    RegExp(r'struk', caseSensitive: false),
    RegExp(r'tanggal', caseSensitive: false),
    RegExp(r'wifi', caseSensitive: false),
    RegExp(r'pawoon', caseSensitive: false),
    RegExp(r'powered', caseSensitive: false),
    RegExp(r'invoice', caseSensitive: false),
    RegExp(r'\b(jl|ji|jalan)\.?\b', caseSensitive: false),
    RegExp(r'\bkav\.?\b', caseSensitive: false),
    RegExp(r'jakarta|surabaya|bandung|yogyakarta|semarang|malang|depok|bekasi|tangerang|bogor|cimahi|\bbali\b',
        caseSensitive: false),
    RegExp(r'mrdiy|mr\.?diy', caseSensitive: false),
  ];

  static bool _looksLikeNonItem(String line) => _nonItemPatterns.any((r) => r.hasMatch(line));

  /// Pola alamat untuk membuang nominal yang menempel setelah baris alamat
  /// pada zip dua-kolom (harga palsu hasil OCR alamat).
  static final RegExp _addressPattern = RegExp(
      r'\b(jl|ji|jalan)\.?\b|\bkav\.?\b|jakarta|surabaya|bandung|yogyakarta|semarang|malang|depok|bekasi|tangerang|bogor|cimahi|\bbali\b',
      caseSensitive: false);

  static bool _isJunkLine(String line) =>
      _junkRegex.hasMatch(line) ||
      _dateRegex.hasMatch(line) ||
      _dateTimeRegex.hasMatch(line) ||
      _timeRegex.hasMatch(line) ||
      _digitsOnlyRegex.hasMatch(line);

  static bool _hasDigits(String s) => s.contains(RegExp(r'\d'));

  static int _letterCount(String s) => s.replaceAll(RegExp(r'[^A-Za-z]'), '').length;

  static String _cleanName(String s) => s.replaceAll(RegExp(r'[\s\.\-]+$'), '').trim();

  static bool _isLabelLine(String lower) {
    if (lower.contains('sub total') || lower.contains('subtotal')) return true;
    if (lower.contains('ppn') || lower.contains('pajak') || lower.contains('tax')) return true;
    if (lower.contains('service')) return true;
    if (lower.contains('total') || lower.contains('jumlah')) return true;
    if (lower.contains('bayar') || lower.contains('kembali') || lower.contains('tunai') ||
        lower.contains('cash') || lower.contains('debit') || lower.contains('kartu') ||
        lower.contains('qris') || lower.contains('gopay') || lower.contains('ovo') ||
        lower.contains('dana') || lower.contains('transfer')) {
      return true;
    }
    return false;
  }

  static bool _isHeaderLine(String lower) {
    if (lower == 'qty' || lower == 'harga' || lower == 'jumlah' || lower == 'item' || lower == 'menu' || lower == 'kasir') {
      return true;
    }
    if (lower.contains('nama barang') || lower.contains('nama item')) return true;
    if (lower.contains('qty') && lower.contains('harga')) return true;
    return false;
  }

  /// Memproses teks mentah hasil scan OCR struk dan mengurai item, harga, pajak, & total secara otomatis.
  /// Mendukung layout umum struk Indonesia:
  /// - Satu baris:  "Kopi Susu 28.000" / "2x Roti Bakar 30000" / "Ayam Bakar Rp 35.000"
  /// - Thermal:      "Nasi Ayam Geprek" + baris berikut "1X 12.000"
  /// - Rontek titik: "Nasi Goreng.......20.000"
  /// - Qty di tengah: "Nasi Goreng 1X 20.000"
  /// Bila hasil sangat sedikit, coba pasang nama item dengan blok harga
  /// dua-kolom (struk resto/retail: nama kiri, harga kanan — OCR membaca kolom
  /// harga terpisah/terbalik, mis. Pawoon POS). Mengembalikan null bila pola
  /// tidak cocok.
  /// Fallback dua-kolom. Mengembalikan (nama, qty baris terpisah, harga,
  /// qty yang menempel pada baris harga) — qty "2X30.000" ikut tercatat agar
  /// kuantitas item tidak hilang saat nama & harga terbaca terpisah oleh OCR.
  static (List<String>, List<int>, List<double>, List<int>)? _zipColumnFallback(
    List<String> lines,
    Set<int> consumed,
  ) {
    var names = <String>[];
    final amounts = <double>[];
    final qtyLines = <int>[]; // baris "x2" / "x1" yang berdiri sendiri (Pawoon)
    final amountQtys = <int>[]; // qty dari prefiks "2X" pada baris harga
    var qtyPrefixedAmounts = 0; // jumlah baris harga berprefiks qty ("2X30.000")
    for (var i = 0; i < lines.length; i++) {
      if (consumed.contains(i)) continue;
      final l = lines[i];
      final lower = l.toLowerCase();
      if (_isJunkLine(l)) continue;
      if (_isLabelLine(lower)) continue;
      final am = _amountOnlyRegex.firstMatch(l);
      if (am != null) {
        final price = _parseAmount(am.group(2)!);
        final qty = int.tryParse(am.group(1) ?? '') ?? 1;
        if (am.group(1) != null) qtyPrefixedAmounts++;
        final prevIsAddress = i > 0 && _addressPattern.hasMatch(lines[i - 1]);
        if (!prevIsAddress && price >= 100 && price <= _maxItemPrice) {
          amounts.add(price);
          amountQtys.add(qty);
        }
        continue;
      }
      final qm = RegExp(r'^x(\d+)$', caseSensitive: false).firstMatch(l);
      if (qm != null) {
        qtyLines.add(int.parse(qm.group(1)!));
        continue;
      }
      // Nama yang mengikuti label "Kasir" tanpa nilai (nama kasir ada di
      // baris berikutnya) adalah nama kasir, bukan item.
      if (_usableNameLine(l) && !_isKasirNameLine(i, lines)) names.add(_cleanName(l));
    }
    // Jumlah item sebenarnya terlihat dari sinyal qty: baris "x2" terpisah
    // (Pawoon) atau baris harga berprefiks "2X". Nama berlebih — biasanya
    // nama toko yang ikut terbaca dalam blok nama — dibuang dari belakang
    // agar tidak terpasang ke nilai subtotal/total.
    final qtySignals = qtyLines.length > qtyPrefixedAmounts ? qtyLines.length : qtyPrefixedAmounts;
    if (qtySignals >= 2 && names.length > qtySignals) {
      names = names.sublist(0, qtySignals);
    }
    if (names.length >= 2 && amounts.length >= names.length) {
      return (names, qtyLines, amounts, amountQtys);
    }
    return null;
  }

  static ParsedReceiptResult parseText(String rawText) {
    final lines = rawText
        .split('\n')
        .map(_normalizeLine)
        .where((l) => l.isNotEmpty)
        .toList();
    final consumed = <int>{};

    // --- Pindai label & item ---
    final List<ReceiptItem> extractedItems = [];
    final indexByName = <String, int>{};
    double subtotal = 0;
    double tax = 0;
    double serviceCharge = 0;
    double totalAmount = 0;
    int itemCounter = 1;

    void addItem(String name, int qty, double price) {
      if (price <= 0 || qty <= 0) return;
      final clean = _cleanName(name);
      if (_letterCount(clean) < 3) return;
      final key = clean.toLowerCase();
      final existing = indexByName[key];
      if (existing != null) {
        final old = extractedItems[existing];
        extractedItems[existing] = ReceiptItem(
          id: old.id,
          name: old.name,
          price: old.price,
          quantity: old.quantity + qty,
          assignedMemberIds: old.assignedMemberIds,
        );
      } else {
        extractedItems.add(
          ReceiptItem(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}_$itemCounter',
            name: clean,
            price: price,
            quantity: qty,
            assignedMemberIds: [],
          ),
        );
        indexByName[key] = extractedItems.length - 1;
        itemCounter++;
      }
      subtotal += price * qty;
    }

    for (var i = 0; i < lines.length; i++) {
      if (consumed.contains(i)) continue;
      final line = lines[i];
      final lower = line.toLowerCase();

      if (_isJunkLine(line)) continue;
      if (_isHeaderLine(lower)) continue;

      // Label nilai: PPN / Service Charge / Sub Total / Total
      if (lower.contains('ppn') || lower.contains('pajak') || lower.contains('tax')) {
        final v = _extractAmountWithPeek(i, lines, consumed);
        if (v > 0) tax = v;
        continue;
      }
      if (lower.contains('service')) {
        final v = _extractAmountWithPeek(i, lines, consumed);
        if (v > 0) serviceCharge = v;
        continue;
      }
      if (lower.contains('sub total') || lower.contains('subtotal')) {
        final v = _extractAmountWithPeek(i, lines, consumed);
        if (v > 0) subtotal = v;
        continue;
      }
      if (lower.contains('total') || lower.contains('jumlah')) {
        final v = _extractAmountWithPeek(i, lines, consumed);
        if (v > 0) totalAmount = v;
        continue;
      }
      if (_isLabelLine(lower)) continue;

      // Baris harga saja → pasangkan dengan nama item pada baris sebelumnya
      final amountMatch = _amountOnlyRegex.firstMatch(line);
      if (amountMatch != null) {
        final qty = int.tryParse(amountMatch.group(1) ?? '') ?? 1;
        final price = _parseAmount(amountMatch.group(2)!);
        if (price <= _maxItemPrice) {
          _pairPriceLine(lines, i, qty, price, consumed, addItem);
        }
        continue;
      }

      // Baris berisi nama + harga (qty boleh di awal / tengah / akhir)
      final nameMatch = _nameAmountRegex.firstMatch(line);
      if (nameMatch != null) {
        final leadQty = int.tryParse(nameMatch.group(1) ?? '') ?? 1;
        final name = _cleanName(nameMatch.group(2) ?? '');
        final trailQty = int.tryParse(nameMatch.group(3) ?? nameMatch.group(4) ?? '') ?? 1;
        final price = _parseAmount(nameMatch.group(5) ?? '0');
        final isUnitQtyName = _unitQtyNameRegex.hasMatch(name);
        if (_letterCount(name) >= 3 &&
            !isUnitQtyName &&
            !_looksLikeNonItem(name) &&
            price >= 100 &&
            price <= _maxItemPrice) {
          addItem(name, leadQty * trailQty, price);
          continue;
        }
        // "4.000 KgX12.500" / "800 BoxX7.500" → baris kuantitas-satuan-harga,
        // pasangkan ke nama item pada baris sebelumnya.
        if (price > 0 && price <= _maxItemPrice) {
          _pairPriceLine(lines, i, 1, price, consumed, addItem);
          continue;
        }
      }
    }

    // Struk thermal dua-kolom sering terbaca OCR sebagai blok nama terpisah
    // dari blok harga. Bila hasil normal minim (≤ 2 item), coba pasangkan
    // nama yang belum terpakai dengan blok harga — dan GABUNG, jangan replace,
    // agar item yang sudah benar tetap dipertahankan.
    if (extractedItems.length <= 2) {
      final zipped = _zipColumnFallback(lines, consumed);
      if (zipped != null) {
        final (names0, qtyLines, amounts, amountQtys) = zipped;
        final names = names0;
        // Utamakan qty baris terpisah ("x2") bila sejajar dengan nama;
        // kalau tidak, pakai qty yang menempel pada baris harga ("2X30.000").
        List<int> qtys;
        if (qtyLines.length == names.length) {
          qtys = qtyLines;
        } else if (amountQtys.any((q) => q > 1)) {
          qtys = amountQtys.take(names.length).toList();
        } else {
          qtys = List.filled(names.length, 1);
        }
        final existingNames = extractedItems.map((e) => e.name.toLowerCase()).toSet();
        for (var k = 0; k < names.length; k++) {
          if (!existingNames.contains(names[k].toLowerCase())) {
            addItem(names[k], qtys[k], amounts[k]);
          }
        }
      }
    }

    // --- Nama merchant: baris pertama yang bukan sampah/label/nama item ---
    // Dijalankan SETELAH item terurai agar baris yang ternyata nama item
    // (struk dua-kolom: OCR sering membaca blok nama item sebelum nama toko)
    // tidak salah dipilih sebagai nama toko.
    String merchantName = 'Struk Belanja Baru';
    final itemNames = extractedItems.map((e) => e.name.toLowerCase()).toSet();
    int? firstCandidate;
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      final lower = l.toLowerCase();
      if (_isJunkLine(l) || _hasDigits(l) && _letterCount(l) == 0) continue;
      if (_amountOnlyRegex.firstMatch(l) != null) continue;
      if (_nameAmountRegex.firstMatch(l) != null) continue;
      if (_isLabelLine(lower) || _isHeaderLine(lower)) continue;
      if (_looksLikeNonItem(l)) continue;
      if (itemNames.contains(_cleanName(l).toLowerCase())) continue;
      firstCandidate = i;
      break;
    }
    if (firstCandidate != null) {
      merchantName = _cleanName(lines[firstCandidate]);
      // Jika kandidat berisi angka (mis. alamat), cari nama toko tanpa angka di baris berikutnya.
      if (_hasDigits(lines[firstCandidate])) {
        for (var j = firstCandidate + 1; j < lines.length && j <= firstCandidate + 8; j++) {
          final l = lines[j];
          final lower = l.toLowerCase();
          if (_isJunkLine(l) || _amountOnlyRegex.firstMatch(l) != null) continue;
          if (_isLabelLine(lower) || _isHeaderLine(lower)) continue;
          if (_looksLikeNonItem(l)) continue;
          if (itemNames.contains(_cleanName(l).toLowerCase())) continue;
          if (!_hasDigits(l) && _letterCount(l) >= 3) {
            merchantName = _cleanName(l);
            break;
          }
        }
      }
    }

    // Tanpa item palsu: hasil kosong ditampilkan polos agar pengguna bisa
    // mengoreksi lewat preview OCR / input manual, bukan placeholder.

    if (totalAmount <= 0) {
      totalAmount = subtotal + tax + serviceCharge;
    }

    return ParsedReceiptResult(
      merchantName: merchantName,
      subtotal: subtotal,
      tax: tax,
      serviceCharge: serviceCharge,
      totalAmount: totalAmount,
      items: extractedItems,
    );
  }

  /// Ambil nominal dari baris label; jika tidak ada (mis. "PPN 10%" atau
  /// "Sub Total" tanpa angka), coba baris berikutnya.
  static double _extractAmountWithPeek(int i, List<String> lines, Set<int> consumed) {
    var amt = _extractAmount(lines[i]);
    if (amt == 0 && i + 1 < lines.length) {
      final next = _amountOnlyRegex.firstMatch(lines[i + 1]);
      if (next != null && next.group(1) == null) {
        amt = _parseAmount(next.group(2)!);
        consumed.add(i + 1);
      }
    }
    return amt;
  }

  static double _extractAmount(String line) {
    final t = line.trim();
    if (t.endsWith('%')) return 0;
    final amountRegex = RegExp(r'(\d[\d\.,]*)\s*$');
    final match = amountRegex.firstMatch(line);
    if (match == null) return 0;
    return _parseAmount(match.group(1)!);
  }

  /// Baris dapat menjadi nama item pada pasangan dua baris bila bukan label,
  /// bukan angka/harga, dan bukan baris qty-satuan-harga.
  static bool _usableNameLine(String line) {
    final lower = line.toLowerCase();
    if (_isJunkLine(line)) return false;
    if (_looksLikeNonItem(line)) return false;
    if (_isLabelLine(lower) || _isHeaderLine(lower)) return false;
    if (_amountOnlyRegex.firstMatch(line) != null) return false;
    if (_nameAmountRegex.firstMatch(line) != null) return false;
    return _letterCount(line) >= 3 && line.length >= 4;
  }

  /// Memasangkan baris harga ke nama item di atasnya. Jika nama terdekat
  /// pendek (<= 2 kata) dan baris dua tingkat di atas masih nama yang layak,
  /// utamakan baris lebih jauh — mencegah "TOKO ABANG" mencuri harga
  /// "Gula Pasir" pada struk grosir.
  static void _pairPriceLine(
    List<String> lines,
    int priceIndex,
    int qty,
    double price,
    Set<int> consumed,
    void Function(String name, int qty, double price) addItem,
  ) {
    bool usable(int idx) =>
        idx >= 0 &&
        !consumed.contains(idx) &&
        _usableNameLine(lines[idx]) &&
        !_hasPaymentLabelNearby(idx, lines);

    final prev = priceIndex - 1;
    final far = priceIndex - 2;
    if (usable(prev)) {
      final prevShort = lines[prev].split(' ').length <= 2;
      if (!prevShort || !usable(far)) {
        consumed.add(prev);
        addItem(lines[prev], qty, price);
        return;
      }
      consumed.add(far);
      addItem(lines[far], qty, price);
      return;
    }
    if (usable(far)) {
      consumed.add(far);
      addItem(lines[far], qty, price);
    }
  }

  static bool _isPaymentLabel(String lower) =>
      lower.contains('bayar') || lower.contains('kembali') || lower.contains('tunai') ||
      lower.contains('cash') || lower.contains('debit') || lower.contains('kartu') ||
      lower.contains('qris') || lower.contains('gopay') || lower.contains('ovo') ||
      lower.contains('dana') || lower.contains('transfer') || lower.contains('kasir');

  /// Menolak pasangan bila ada label pembayaran/kasir di dekat nama item —
  /// nama yang mengikuti blok "Bayar/Kembali" biasanya nama kasir.
  static bool _hasPaymentLabelNearby(int nameIndex, List<String> lines) {
    for (var j = nameIndex - 1; j >= 0 && j >= nameIndex - 6; j--) {
      if (_isPaymentLabel(lines[j].toLowerCase())) return true;
    }
    return false;
  }

  /// True bila baris [nameIndex] mengikuti label "Kasir" yang TIDAK memuat
  /// nama di baris yang sama (mis. "Kasir" polos → nama kasir di baris
  /// berikutnya). Label "Kasir : Budi" tidak dianggap — item berikutnya
  /// (layout Pawoon) tetap valid.
  static bool _isKasirNameLine(int nameIndex, List<String> lines) {
    for (var j = nameIndex - 1; j >= 0 && j >= nameIndex - 6; j--) {
      final t = lines[j].trim().toLowerCase();
      if (t == 'kasir' || t == 'kasir:' || t == 'kasir :' || t == 'kasir  :') return true;
    }
    return false;
  }
}
