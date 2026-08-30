import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/split_model.dart';
import '../models/transaksi_umkm.dart';
import '../settings/settings_service.dart';

/// Hasil agregasi transaksi + narasi insight (dari Gemini bila ada key,
/// atau analisis lokal bila tidak ada key / offline).
class BusinessInsights {
  final List<({String name, int qty, double revenue})> topItems;
  final String topCategory;
  final int billCount;
  final double totalRevenue;
  final double avgBill;
  final String narrative;
  final bool fromAI;

  BusinessInsights({
    required this.topItems,
    required this.topCategory,
    required this.billCount,
    required this.totalRevenue,
    required this.avgBill,
    required this.narrative,
    required this.fromAI,
  });

  /// Agregasi lokal dari seluruh transaksi; narasi dibuat dari template
  /// sehingga dashboard tetap punya insight tanpa koneksi/API key.
  factory BusinessInsights.local(List<SplitBill> splits) {
    final itemCounts = <String, int>{};
    final itemRevenue = <String, double>{};
    final categoryTotals = <String, double>{};
    double total = 0;
    for (final s in splits) {
      total += s.totalAmount;
      categoryTotals[s.categoryLabel] =
          (categoryTotals[s.categoryLabel] ?? 0) + s.totalAmount;
      for (final i in s.items) {
        itemCounts[i.name] = (itemCounts[i.name] ?? 0) + i.quantity;
        itemRevenue[i.name] = (itemRevenue[i.name] ?? 0) + i.lineTotal;
      }
    }
    final topItems = itemCounts.entries
        .map((e) => (
              name: e.key,
              qty: e.value,
              revenue: itemRevenue[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));

    String topCategory = '';
    double topCatTotal = 0;
    categoryTotals.forEach((cat, v) {
      if (v > topCatTotal) {
        topCatTotal = v;
        topCategory = cat;
      }
    });

    final n = splits.length;
    if (n == 0) {
      return BusinessInsights(
        topItems: topItems,
        topCategory: topCategory,
        billCount: 0,
        totalRevenue: 0,
        avgBill: 0,
        narrative: SettingsService.instance.isEnglish
            ? 'No transactions recorded yet. Add your first receipt to get business insights.'
            : 'Belum ada transaksi tercatat. Tambahkan struk pertama untuk mendapatkan insight bisnis.',
        fromAI: false,
      );
    }
    final en = SettingsService.instance.isEnglish;
    final first = topItems.isEmpty ? (name: '-', qty: 0, revenue: 0.0) : topItems.first;
    final second = topItems.length > 1 ? topItems[1] : null;
    final narrative = en
        ? '- Best-seller: ${first.name} (${first.qty}x, total Rp ${first.revenue.round()}).'
            '${second != null ? ' Runner-up: ${second.name} (${second.qty}x).' : ''}\n'
            '- Top category: $topCategory with Rp $topCatTotal total spending.\n'
            '- $n transactions recorded, total revenue Rp ${total.round()},'
            ' average bill Rp ${(total / n).round()}.'
        : '- Menu terlaris: ${first.name} (${first.qty}x, total Rp ${first.revenue.round()}).'
            '${second != null ? ' Runner-up: ${second.name} (${second.qty}x).' : ''}\n'
            '- Kategori terbesar: $topCategory dengan total Rp $topCatTotal.\n'
            '- $n transaksi tercatat, total pendapatan Rp ${total.round()},'
            ' rata-rata tagihan Rp ${(total / n).round()}.';

    return BusinessInsights(
      topItems: topItems,
      topCategory: topCategory,
      billCount: n,
      totalRevenue: total,
      avgBill: n > 0 ? total / n : 0,
      narrative: narrative,
      fromAI: false,
    );
  }

  BusinessInsights withNarrative(String narrative) => BusinessInsights(
        topItems: topItems,
        topCategory: topCategory,
        billCount: billCount,
        totalRevenue: totalRevenue,
        avgBill: avgBill,
        narrative: narrative,
        fromAI: true,
      );
}

/// Client Google Gemini (AI Studio free tier) untuk:
/// 1. [refineReceiptWithAI] — koreksi cerdas hasil OCR struk.
/// 2. [generateBusinessInsights] — narasi insight bisnis UMKM.
/// Tanpa API key semua method kembali null / false → UI jatuh ke mode offline.
class GeminiService {
  GeminiService._();

  static final GeminiService instance = GeminiService._();

  /// Chain model per use case (free tier AI Studio, model stable terbaru):
  /// refine OCR → Flash-Lite (cepat), insight bisnis → Flash (lebih kompleks).
  static const _refineModels = [
    'gemini-3.5-flash-lite',
    'gemini-3.6-flash',
    'gemini-flash-latest',
  ];
  static const _insightModels = [
    'gemini-3.6-flash',
    'gemini-3.5-flash-lite',
    'gemini-flash-latest',
  ];

  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';

  String? get _apiKey {
    final key = SettingsService.instance.geminiApiKey.trim();
    return key.isEmpty ? null : key;
  }

  /// Minta Gemini memperbaiki salah baca OCR pada [rawOcrText] menjadi daftar
  /// item presisi (nama menu Indonesia + harga satuan). Harga dalam mata uang
  /// asal struk ([currency]). Mengembalikan null bila tidak ada API key,
  /// jaringan gagal, atau respons tidak bisa diparse.
  Future<({String merchantName, List<ReceiptItem> items})?>
      refineReceiptWithAI(String rawOcrText, {String currency = 'IDR'}) async {
    final key = _apiKey;
    if (key == null) return null;
    final prompt = '''
Kamu adalah korektor OCR struk restoran/kafe Indonesia. Perbaiki salah baca OCR pada teks struk mentah berikut (mata uang: $currency, angka tanpa simbol).
1. Perbaiki nama menu yang salah terbaca (mis. "Nasi Goreng Special").
2. Buang baris yang bukan item (subtotal, PPN, service, total, alamat, kasir, metode bayar, dll).
3. Keluarkan hanya JSON valid dengan skema: {"merchant_name": string, "items": [{"name": string, "price": number, "qty": number}]}
4. price adalah harga SATUAN dalam $currency. Jangan menambahkan PPN/service/total.
Teks struk mentah:
---
$rawOcrText''';
    try {
      final text = await _generate(key, prompt, json: true, models: _refineModels);
      return parseRefineJson(text);
    } catch (_) {
      return null;
    }
  }

  /// Agregasi dihitung lokal (top menu, kategori, total), lalu Gemini menulis
  /// narasi insight & rekomendasi UMKM. Null bila tidak ada key atau gagal —
  /// pemanggil cukup memakai [BusinessInsights.local].
  Future<BusinessInsights?> generateBusinessInsights(
    List<SplitBill> splits,
  ) async {
    final key = _apiKey;
    if (key == null || splits.isEmpty) return null;
    final local = BusinessInsights.local(splits);
    final lang = SettingsService.instance.isEnglish ? 'English' : 'Indonesian';
    final summary = jsonEncode({
      'total_transactions': local.billCount,
      'total_revenue_idr': local.totalRevenue.round(),
      'avg_bill_idr': local.avgBill.round(),
      'top_items': local.topItems
          .take(5)
          .map((t) => {
                'name': t.name,
                'qty': t.qty,
                'revenue_idr': t.revenue.round(),
              })
          .toList(),
      'top_category': local.topCategory,
    });
    final prompt = '''
Kamu adalah asisten bisnis untuk pemilik UMKM F&B di Indonesia. Dari ringkasan transaksi berikut (JSON), berikan:
1. 3-4 poin insight singkat: tren menu terlaris, pola kategori, dan saran aksi nyata.
2. 1 ide promo/strategi yang bisa langsung dijalankan oleh warung/kafe kecil.
Jawab dalam bahasa $lang, tiap poin diawali "-". Jangan menyebut "data simulasi" atau "demo".
Ringkasan:
$summary''';
    try {
      final text = await _generate(key, prompt, models: _insightModels);
      return local.withNarrative(text.trim());
    } catch (_) {
      return null;
    }
  }

  /// Generate business insights for UMKM mode from TransaksiUmkm list.
  Future<BusinessInsights?> generateUmkmInsights(
    List<TransaksiUmkm> transaksi,
  ) async {
    final key = _apiKey;
    if (key == null || transaksi.isEmpty) return null;

    // Build local aggregation
    final itemCounts = <String, int>{};
    final itemRevenue = <String, double>{};
    final categoryTotals = <String, double>{};
    double total = 0;
    for (final t in transaksi) {
      total += t.totalAmount;
      final cat = t.category.isNotEmpty ? t.category : 'Lainnya';
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.totalAmount;
      for (final i in t.items) {
        itemCounts[i.name] = (itemCounts[i.name] ?? 0) + i.quantity;
        itemRevenue[i.name] = (itemRevenue[i.name] ?? 0) + i.lineTotal;
      }
    }
    final topItems = itemCounts.entries
        .map((e) => (name: e.key, qty: e.value, revenue: itemRevenue[e.key] ?? 0))
        .toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));

    String topCategory = '';
    double topCatTotal = 0;
    categoryTotals.forEach((cat, v) {
      if (v > topCatTotal) {
        topCatTotal = v;
        topCategory = cat;
      }
    });

    final local = BusinessInsights(
      topItems: topItems,
      topCategory: topCategory,
      billCount: transaksi.length,
      totalRevenue: total,
      avgBill: transaksi.isNotEmpty ? total / transaksi.length : 0,
      narrative: '',
      fromAI: false,
    );

    final lang = SettingsService.instance.isEnglish ? 'English' : 'Indonesian';
    final summary = jsonEncode({
      'total_transactions': transaksi.length,
      'total_revenue_idr': total.round(),
      'avg_bill_idr': transaksi.isNotEmpty ? (total / transaksi.length).round() : 0,
      'top_items': topItems
          .take(5)
          .map((t) => {
                'name': t.name,
                'qty': t.qty,
                'revenue_idr': t.revenue.round(),
              })
          .toList(),
      'top_category': topCategory,
      'categories': categoryTotals.entries
          .map((e) => {'name': e.key, 'revenue_idr': e.value.round()})
          .toList(),
    });
    final prompt = '''
Kamu adalah asisten bisnis untuk pemilik UMKM F&B di Indonesia. Dari ringkasan transaksi kasir berikut (JSON), berikan:
1. 3-4 poin insight singkat: tren menu terlaris, pola kategori, dan saran aksi nyata.
2. 1 ide promo/strategi yang bisa langsung dijalankan oleh warung/kafe kecil.
Jawab dalam bahasa $lang, tiap poin diawali "-". Jangan menyebut "data simulasi" atau "demo".
Ringkasan:
$summary''';
    try {
      final text = await _generate(key, prompt, models: _insightModels);
      return local.withNarrative(text.trim());
    } catch (_) {
      return null;
    }
  }

  /// Analisis profitabilitas menu: AI analisis margin, saran harga, item review.
  Future<String?> analyzeMenuProfitability(List<TransaksiUmkm> transaksi) async {
    final key = _apiKey;
    if (key == null || transaksi.isEmpty) return null;

    final items = <String, ({int qty, double revenue, double cost})>{};
    for (final t in transaksi) {
      for (final i in t.items) {
        final existing = items[i.name];
        items[i.name] = (
          qty: (existing?.qty ?? 0) + i.quantity,
          revenue: (existing?.revenue ?? 0) + i.lineTotal,
          cost: (existing?.cost ?? 0) + i.lineCost,
        );
      }
    }
    final menuList = items.entries.map((e) {
      final profit = e.value.revenue - e.value.cost;
      final margin = e.value.revenue > 0 ? (profit / e.value.revenue * 100) : 0;
      return {
        'name': e.key,
        'qty_sold': e.value.qty,
        'revenue_idr': e.value.revenue.round(),
        'cost_idr': e.value.cost.round(),
        'profit_idr': profit.round(),
        'margin_pct': margin.round(),
      };
    }).toList()
      ..sort((a, b) => (b['profit_idr'] as int).compareTo(a['profit_idr'] as int));

    final lang = SettingsService.instance.isEnglish ? 'English' : 'Indonesian';
    final summary = jsonEncode({'menu': menuList.take(10).toList()});
    final prompt = '''
Kamu adalah konsultan bisnis F&B untuk UMKM Indonesia. Dari data profitabilitas menu berikut (JSON), berikan:
1. Top 3 menu dengan margin tertinggi (profitable).
2. Menu yang margin-nya rendah (< 30%) — saran: naikkan harga, kurangi porsi, atau hapus.
3. Item yang laku banyak tapi margin tipis — saran strategi bundling.
4. 1 rekomendasi harga jual baru untuk item dengan margin terendah.
Jawab dalam bahasa $lang, konkret dan bisa langsung dijalankan. Jangan menyebut "data simulasi".
Data:
$summary''';
    try {
      return await _generate(key, prompt, models: _insightModels);
    } catch (_) {
      return null;
    }
  }

  /// Prediksi penjualan: AI forecast omzet & item populer minggu depan.
  Future<String?> forecastSales(List<TransaksiUmkm> transaksi) async {
    final key = _apiKey;
    if (key == null || transaksi.isEmpty) return null;

    // Build daily data for last 14 days
    final now = DateTime.now();
    final dailyData = <Map<String, dynamic>>[];
    for (var i = 13; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day - i);
      final dayTrans = transaksi.where((t) =>
          t.date.year == d.year && t.date.month == d.month && t.date.day == d.day);
      final total = dayTrans.fold(0.0, (sum, t) => sum + t.totalAmount);
      final count = dayTrans.length;
      final dayName = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'][d.weekday % 7];
      dailyData.add({
        'date': '${d.day}/${d.month}',
        'day': dayName,
        'revenue_idr': total.round(),
        'transactions': count,
      });
    }

    // Item velocity
    final itemVelocity = <String, int>{};
    for (final t in transaksi) {
      if (t.date.isAfter(now.subtract(const Duration(days: 7)))) {
        for (final i in t.items) {
          itemVelocity[i.name] = (itemVelocity[i.name] ?? 0) + i.quantity;
        }
      }
    }
    final topItems = itemVelocity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final lang = SettingsService.instance.isEnglish ? 'English' : 'Indonesian';
    final summary = jsonEncode({
      'last_14_days': dailyData,
      'top_items_this_week': topItems.take(5).map((e) => {'name': e.key, 'qty': e.value}).toList(),
      'today_day': ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'][now.weekday % 7],
    });
    final prompt = '''
Kamu adalah analis bisnis F&B untuk UMKM Indonesia. Dari data penjualan 14 hari terakhir (JSON), berikan:
1. Prediksi omzet 3 hari ke depan (besok, lusa, dan 2 hari lagi).
2. Hari yang biasanya ramai vs sepi minggu ini.
3. Item yang velocity-nya naik/turun.
4. Saran stok untuk 3 hari ke depan.
Jawab dalam bahasa $lang, praktis dan spesifik angka. Jangan menyebut "data simulasi".
Data:
$summary''';
    try {
      return await _generate(key, prompt, models: _insightModels);
    } catch (_) {
      return null;
    }
  }

  /// Briefing pagi: AI ringkas kondisi bisnis + rekomendasi hari ini.
  Future<String?> generateMorningBriefing(List<TransaksiUmkm> transaksi) async {
    final key = _apiKey;
    if (key == null || transaksi.isEmpty) return null;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayTrans = transaksi.where((t) =>
        t.date.year == yesterday.year &&
        t.date.month == yesterday.month &&
        t.date.day == yesterday.day);
    final yesterdayRevenue = yesterdayTrans.fold(0.0, (sum, t) => sum + t.totalAmount);
    final yesterdayCount = yesterdayTrans.length;

    // Last 7 days average
    double avgRevenue = 0;
    int avgCount = 0;
    for (var i = 1; i <= 7; i++) {
      final d = now.subtract(Duration(days: i));
      final dTrans = transaksi.where((t) =>
          t.date.year == d.year && t.date.month == d.month && t.date.day == d.day);
      avgRevenue += dTrans.fold(0.0, (sum, t) => sum + t.totalAmount);
      avgCount += dTrans.length;
    }
    avgRevenue /= 7;
    avgCount = (avgCount / 7).round();

    // Best seller last 7 days
    final itemQty = <String, int>{};
    for (final t in transaksi) {
      if (t.date.isAfter(now.subtract(const Duration(days: 7)))) {
        for (final i in t.items) {
          itemQty[i.name] = (itemQty[i.name] ?? 0) + i.quantity;
        }
      }
    }
    final bestSeller = itemQty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Peak hour
    final hours = List.filled(24, 0);
    for (final t in transaksi) {
      if (t.date.isAfter(now.subtract(const Duration(days: 7)))) {
        hours[t.date.hour]++;
      }
    }
    final peakHour = hours.indexOf(hours.reduce((a, b) => a > b ? a : b));

    final lang = SettingsService.instance.isEnglish ? 'English' : 'Indonesian';
    final dayName = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'][now.weekday % 7];
    final summary = jsonEncode({
      'today': dayName,
      'yesterday_revenue_idr': yesterdayRevenue.round(),
      'yesterday_transactions': yesterdayCount,
      'avg_7day_revenue_idr': avgRevenue.round(),
      'avg_7day_transactions': avgCount,
      'best_seller_7days': bestSeller.take(3).map((e) => {'name': e.key, 'qty': e.value}).toList(),
      'peak_hour': peakHour,
    });
    final prompt = '''
Kamu adalah asisten bisnis untuk pemilik warung/kafe di Indonesia. Buat briefing pagi yang singkat dan memotivasi:
1. Ringkasan kondisi: "Kemarin: [omzet], [jumlah transaksi]. Rata-rata 7 hari: [omzet]."
2. Best seller & tren: menu apa yang lagi naik.
3. Prediksi hari ini: jam ramai, stok yang perlu disiapkan.
4. 1 aksi hari ini yang bisa langsung dilakukan.
Gunakan emoji ✅ untuk poin yang bagus, ⚠️ untuk yang perlu perhatian. Jawab dalam bahasa $lang, max 6 baris. Jangan menyebut "data simulasi" atau "briefing otomatis".
Data:
$summary''';
    try {
      return await _generate(key, prompt, models: _insightModels);
    } catch (_) {
      return null;
    }
  }

  /// Health score bisnis: AI hitung skor 1-100 + rekomendasi perbaikan.
  Future<({int score, String analysis})?> calculateHealthScore(List<TransaksiUmkm> transaksi) async {
    final key = _apiKey;
    if (key == null || transaksi.isEmpty) return null;

    final now = DateTime.now();
    final thisMonth = transaksi.where((t) =>
        t.date.year == now.year && t.date.month == now.month);
    final lastMonth = transaksi.where((t) {
      final d = DateTime(now.year, now.month - 1, 1);
      return t.date.year == d.year && t.date.month == d.month;
    });

    final thisMonthRevenue = thisMonth.fold(0.0, (sum, t) => sum + t.totalAmount);
    final lastMonthRevenue = lastMonth.fold(0.0, (sum, t) => sum + t.totalAmount);
    final thisMonthCount = thisMonth.length;
    final lastMonthCount = lastMonth.length;

    // Unique items this month
    final uniqueItems = <String>{};
    for (final t in thisMonth) {
      for (final i in t.items) {
        uniqueItems.add(i.name);
      }
    }

    // Consistency: days with transactions this month
    final daysWithTrans = <int>{};
    for (final t in thisMonth) {
      daysWithTrans.add(t.date.day);
    }

    // Category diversity
    final cats = <String>{};
    for (final t in thisMonth) {
      if (t.category.isNotEmpty) cats.add(t.category);
    }

    final lang = SettingsService.instance.isEnglish ? 'English' : 'Indonesian';
    final summary = jsonEncode({
      'this_month_revenue_idr': thisMonthRevenue.round(),
      'last_month_revenue_idr': lastMonthRevenue.round(),
      'revenue_growth_pct': lastMonthRevenue > 0
          ? ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue * 100).round()
          : 0,
      'this_month_transactions': thisMonthCount,
      'last_month_transactions': lastMonthCount,
      'unique_items': uniqueItems.length,
      'active_days': daysWithTrans.length,
      'days_in_month': DateTime(now.year, now.month + 1, 0).day,
      'categories': cats.length,
      'avg_order_value': thisMonthCount > 0 ? (thisMonthRevenue / thisMonthCount).round() : 0,
    });
    final prompt = '''
Kamu adalah konsultan bisnis UMKM F&B di Indonesia. Hitung skor kesehatan bisnis dari data berikut (JSON):
Skor 1-100 berdasarkan:
- Pertumbuhan omzet (30%): dibanding bulan lalu
- Konsistensi transaksi (25%): berapa hari aktif dalam sebulan
- Rata-rata order value (20%): estimasi dari total/transaksi
- Keanekaragaman menu (15%): jumlah item unik
- Keanekaragaman kategori (10%): jumlah kategori

Balas HANYA JSON: {"score": <angka 1-100>, "analysis": "<analisis 3-4 kalimat dalam bahasa $lang, termasuk 2 saran perbaikan>"}. Jangan menyebut "data simulasi".
Data:
$summary''';
    try {
      final text = await _generate(key, prompt, json: true, models: _insightModels);
      final data = jsonDecode(text) as Map<String, dynamic>;
      return (
        score: (data['score'] as num?)?.toInt().clamp(0, 100) ?? 0,
        analysis: data['analysis']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> analyzeSmartPricing(List<TransaksiUmkm> transaksi) async {
    final key = _apiKey;
    if (key == null || transaksi.isEmpty) return null;
    final items = <String, ({double cost, double price, int qty})>{};
    for (final t in transaksi) {
      for (final i in t.items) {
        if (i.costPrice <= 0) continue;
        final existing = items[i.name];
        items[i.name] = (
          cost: (existing?.cost ?? 0) + (i.costPrice * i.quantity),
          price: (existing?.price ?? 0) + i.lineTotal,
          qty: (existing?.qty ?? 0) + i.quantity,
        );
      }
    }
    if (items.isEmpty) return null;
    final menuList = items.entries.map((e) {
      final avgCost = e.value.qty > 0 ? e.value.cost / e.value.qty : 0;
      final avgPrice = e.value.qty > 0 ? e.value.price / e.value.qty : 0;
      final margin = avgPrice > 0 ? ((avgPrice - avgCost) / avgPrice * 100) : 0;
      return {
        'name': e.key,
        'avg_cost_idr': avgCost.round(),
        'current_price_idr': avgPrice.round(),
        'margin_pct': margin.round(),
        'qty_sold': e.value.qty,
      };
    }).toList()
      ..sort((a, b) => (a['margin_pct'] as int).compareTo(b['margin_pct'] as int));
    final lang = SettingsService.instance.isEnglish ? 'English' : 'Indonesian';
    final summary = jsonEncode({'menu': menuList.take(10).toList()});
    final prompt = 'Kamu adalah konsultan harga UMKM F&B Indonesia. Dari data harga modal vs harga jual berikut:\n1. Saran harga jual baru untuk setiap item (target margin 40-60%).\n2. Item yang sudah margin-nya baik pertahankan.\n3. Item margin rendah: naik harga berapa, atau strategi bundling.\n4. Format per item: nama, harga sekarang, harga saran, alasan.\nBahasa $lang, praktis langsung pakai angka. Jangan sebut "data simulasi".\nData:\n$summary';
    try {
      return await _generate(key, prompt, models: _insightModels);
    } catch (_) {
      return null;
    }
  }

  Future<String?> optimizeCosts(List<TransaksiUmkm> transaksi) async {
    final key = _apiKey;
    if (key == null || transaksi.isEmpty) return null;
    final now = DateTime.now();
    final last7 = transaksi.where((t) =>
        t.date.isAfter(now.subtract(const Duration(days: 7))));
    final totalRevenue = last7.fold(0.0, (sum, t) => sum + t.totalAmount);
    double totalCost = 0;
    for (final t in last7) {
      for (final i in t.items) {
        totalCost += i.lineCost;
      }
    }
    final itemFreq = <String, int>{};
    for (final t in last7) {
      for (final i in t.items) {
        itemFreq[i.name] = (itemFreq[i.name] ?? 0) + i.quantity;
      }
    }
    final sortedFreq = itemFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final payMethods = <String, int>{};
    for (final t in last7) {
      payMethods[t.paymentMethod.name] = (payMethods[t.paymentMethod.name] ?? 0) + 1;
    }
    final lang = SettingsService.instance.isEnglish ? 'English' : 'Indonesian';
    final summary = jsonEncode({
      'last_7days_revenue': totalRevenue.round(),
      'last_7days_cost': totalCost.round(),
      'cost_ratio_pct': totalRevenue > 0 ? (totalCost / totalRevenue * 100).round() : 0,
      'top_items': sortedFreq.take(5).map((e) => {'name': e.key, 'qty': e.value}).toList(),
      'payment_methods': payMethods,
    });
    final prompt = 'Kamu adalah konsultan efisiensi bisnis UMKM Indonesia. Dari data berikut:\n1. Analisis rasio biaya vs pendapatan.\n2. 3 tips kurangi waste/bahan mubazir berdasarkan item terlaris.\n3. Optimasi metode bayar (cash vs QRIS vs debit).\n4. 1 ide efisiensi operasional yang bisa langsung dilakukan.\nBahasa $lang, praktis dan spesifik. Jangan sebut "data simulasi".\nData:\n$summary';
    try {
      return await _generate(key, prompt, models: _insightModels);
    } catch (_) {
      return null;
    }
  }

  Future<String?> analyzeCompetitors(List<TransaksiUmkm> transaksi) async {
    final key = _apiKey;
    if (key == null || transaksi.isEmpty) return null;
    final items = <String, double>{};
    for (final t in transaksi) {
      for (final i in t.items) {
        items[i.name] = i.price;
      }
    }
    final menuList = items.entries.map((e) => {
      'name': e.key,
      'price_idr': e.value.round(),
    }).toList()
      ..sort((a, b) => (a['price_idr'] as int).compareTo(b['price_idr'] as int));
    final lang = SettingsService.instance.isEnglish ? 'English' : 'Indonesian';
    final summary = jsonEncode({'menu': menuList.take(10).toList()});
    final prompt = 'Kamu adalah analis pasar UMKM F&B Indonesia. Dari data harga menu berikut:\n1. Estimasi harga pasar umum untuk makanan/minuman serupa di Indonesia.\n2. Item yang harga-nya terlalu rendah dari pasar -> bisa naik harga.\n3. Item yang harga-nya terlalu tinggi -> pertimbangkan diskon atau porsi lebih besar.\n4. Rekomendasi positioning: murah meriah, sedang, atau premium.\nBahasa $lang, berikan angka perbandingan realistis. Jangan sebut "data simulasi".\nData:\n$summary';
    try {
      return await _generate(key, prompt, models: _insightModels);
    } catch (_) {
      return null;
    }
  }

  Future<String?> analyzeMarketTrends(List<TransaksiUmkm> transaksi) async {
    final key = _apiKey;
    if (key == null || transaksi.isEmpty) return null;
    final now = DateTime.now();
    final itemQty = <String, int>{};
    final dailyRevenue = <String, double>{};
    final hourlyCount = List.filled(24, 0);
    for (final t in transaksi) {
      if (t.date.isAfter(now.subtract(const Duration(days: 14)))) {
        final dayKey = '${t.date.day}/${t.date.month}';
        dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + t.totalAmount;
        hourlyCount[t.date.hour]++;
        for (final i in t.items) {
          itemQty[i.name] = (itemQty[i.name] ?? 0) + i.quantity;
        }
      }
    }
    final topItems = itemQty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peakHour = hourlyCount.indexOf(hourlyCount.reduce((a, b) => a > b ? a : b));
    final avgDailyRevenue = dailyRevenue.values.isNotEmpty
        ? dailyRevenue.values.reduce((a, b) => a + b) / dailyRevenue.length
        : 0;
    final lang = SettingsService.instance.isEnglish ? 'English' : 'Indonesian';
    final summary = jsonEncode({
      'top_items_14days': topItems.take(5).map((e) => {'name': e.key, 'qty': e.value}).toList(),
      'peak_hour': peakHour,
      'avg_daily_revenue': avgDailyRevenue.round(),
      'days_active': dailyRevenue.length,
    });
    final prompt = 'Kamu adalah analis tren pasar UMKM F&B Indonesia. Dari data penjualan 2 tren minggu terakhir:\n1. Item yang tren-nya naik vs turun.\n2. Jam ramai dan strategi manfaatkan jam sepi.\n3. Tren konsumen lokal: apa yang biasanya dicari di warung/kafe sejenis.\n4. 1 ide promosi yang relevan dengan tren saat ini.\nBahasa $lang, praktis. Jangan sebut "data simulasi".\nData:\n$summary';
    try {
      return await _generate(key, prompt, models: _insightModels);
    } catch (_) {
      return null;
    }
  }

  Future<String?> suggestGrowthTips(List<TransaksiUmkm> transaksi) async {
    final key = _apiKey;
    if (key == null || transaksi.isEmpty) return null;
    final now = DateTime.now();
    final thisMonth = transaksi.where((t) =>
        t.date.year == now.year && t.date.month == now.month);
    final lastMonth = transaksi.where((t) {
      final d = DateTime(now.year, now.month - 1, 1);
      return t.date.year == d.year && t.date.month == d.month;
    });
    final thisMonthRevenue = thisMonth.fold(0.0, (sum, t) => sum + t.totalAmount);
    final lastMonthRevenue = lastMonth.fold(0.0, (sum, t) => sum + t.totalAmount);
    final uniqueItems = <String>{};
    final uniqueCats = <String>{};
    for (final t in thisMonth) {
      for (final i in t.items) uniqueItems.add(i.name);
      if (t.category.isNotEmpty) uniqueCats.add(t.category);
    }
    final lang = SettingsService.instance.isEnglish ? 'English' : 'Indonesian';
    final summary = jsonEncode({
      'this_month_revenue': thisMonthRevenue.round(),
      'last_month_revenue': lastMonthRevenue.round(),
      'growth_pct': lastMonthRevenue > 0
          ? ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue * 100).round()
          : 0,
      'total_items': uniqueItems.length,
      'total_categories': uniqueCats.length,
      'total_transactions': thisMonth.length,
    });
    final prompt = 'Kamu adalah konsultan pertumbuhan UMKM F&B Indonesia. Dari data bisnis berikut:\n1. Analisis pertumbuhan: apakah bisnis naik atau turun.\n5. 3 tips berkembang: expand menu, digital marketing, join marketplace.\n6. Strategi media sosial: platform, konten, jadwal posting.\n7. Saran diversifikasi: menu baru, layanan baru, kerjasama.\nBahasa $lang, inspiratif tapi realistis untuk warung/kafe kecil. Jangan sebut "data simulasi".\nData:\n$summary';
    try {
      return await _generate(key, prompt, models: _insightModels);
    } catch (_) {
      return null;
    }
  }

  Future<String?> recommendSuppliers(List<TransaksiUmkm> transaksi) async {
    final key = _apiKey;
    if (key == null || transaksi.isEmpty) return null;
    final itemCost = <String, ({double totalCost, int qty})>{};
    for (final t in transaksi) {
      for (final i in t.items) {
        if (i.costPrice <= 0) continue;
        final existing = itemCost[i.name];
        itemCost[i.name] = (
          totalCost: (existing?.totalCost ?? 0) + i.lineCost,
          qty: (existing?.qty ?? 0) + i.quantity,
        );
      }
    }
    final topCostItems = itemCost.entries.toList()
      ..sort((a, b) => b.value.totalCost.compareTo(a.value.totalCost));
    final lang = SettingsService.instance.isEnglish ? 'English' : 'Indonesian';
    final summary = jsonEncode({
      'highest_cost_items': topCostItems.take(5).map((e) => {
        'name': e.key,
        'avg_cost_idr': e.value.qty > 0 ? (e.value.totalCost / e.value.qty).round() : 0,
        'total_qty': e.value.qty,
      }).toList(),
    });
    final prompt = 'Kamu adalah procurement specialist UMKM F&B Indonesia. Dari data bahan baku berikut:\n1. Rekomendasi jenis supplier untuk setiap bahan: grosir, agen, langsung dari petani/nelayan.\n2. Tips negosiasi harga dengan supplier.\n3. Strategi beli bahan: borongan vs harian, musiman vs tetap.\n4. Platform online untuk cari supplier murah (Tokopedia, Shopee, B2B).\nBahasa $lang, praktis untuk warung/kafe kecil. Jangan sebut "data simulasi".\nData:\n$summary';
    try {
      return await _generate(key, prompt, models: _insightModels);
    } catch (_) {
      return null;
    }
  }

  /// OCR fallback via Gemini vision: kirim gambar struk, Gemini mengembalikan
  /// teks mentah (bukan JSON) agar alur parser lokal tetap sama seperti ML Kit.
  /// Dipakai saat ML Kit gagal (mis. perangkat tanpa Play Services model).
  /// Null bila tidak ada key / gagal.
  Future<String?> extractTextFromImage(Uint8List imageBytes,
      {String mimeType = 'image/jpeg'}) async {
    final key = _apiKey;
    if (key == null) return null;
    final prompt = '''
Transkripsi SEMUA teks pada gambar struk belanja/kasir ini secara verbatim, termasuk nama toko, alamat, nama item, harga, qty, pajak, dan total.
Jangan tambahkan komentar, jangan ubah format, jangan keluarkan JSON — hanya teks mentah persis seperti di struk, baris per baris.''';
    try {
      final uri = Uri.parse(
          '$_endpoint/${_refineModels.first}:generateContent?key=${Uri.encodeComponent(key)}');
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                    {
                      'inline_data': {
                        'mime_type': mimeType,
                        'data': base64Encode(imageBytes),
                      },
                    },
                  ],
                },
              ],
              'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 4096},
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>? ?? [];
      if (candidates.isEmpty) return null;
      final parts =
          (candidates.first as Map<String, dynamic>)['content']
              ?['parts'] as List<dynamic>? ??
          [];
      final text = parts.isEmpty ? null : parts.first['text'] as String?;
      if (text == null || text.trim().isEmpty) return null;
      return text.trim();
    } catch (_) {
      return null;
    }
  }

  /// Tes koneksi: kirim prompt minimal, true bila Gemini merespons JSON valid.
  Future<bool> testConnection() async {
    final key = _apiKey;
    if (key == null) return false;
    try {
      await _generate(key, 'Balas dengan JSON: {"ok": true}',
          json: true, models: _refineModels);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Coba model terbaru dulu, fallback ke model lain bila 4xx/5xx.
  Future<String> _generate(String key, String prompt,
      {bool json = false, List<String> models = _refineModels}) async {
    Object? lastError;
    for (final model in models) {
      try {
        final uri = Uri.parse(
            '$_endpoint/$model:generateContent?key=${Uri.encodeComponent(key)}');
        final resp = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {'parts': [{'text': prompt}]},
                ],
                'generationConfig': {
                  if (json) 'responseMimeType': 'application/json',
                  'temperature': 0.2,
                  'maxOutputTokens': 2048,
                },
              }),
            )
            .timeout(const Duration(seconds: 30));
        if (resp.statusCode != 200) {
          lastError = Exception('HTTP ${resp.statusCode}');
          continue;
        }
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>? ?? [];
        if (candidates.isEmpty) {
          lastError = Exception('empty candidates');
          continue;
        }
        final parts =
            (candidates.first as Map<String, dynamic>)['content']
                ?['parts'] as List<dynamic>? ??
            [];
        final text = parts.isEmpty ? null : parts.first['text'] as String?;
        if (text == null || text.trim().isEmpty) {
          lastError = Exception('empty response');
          continue;
        }
        return text;
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('gemini request failed: $lastError');
  }

  /// Parse JSON respons Gemini (boleh dibungkus fence ```json). Public agar
  /// bisa diuji tanpa jaringan.
  static ({String merchantName, List<ReceiptItem> items})? parseRefineJson(
    String raw,
  ) {
    try {
      final data = jsonDecode(_stripFences(raw)) as Map<String, dynamic>;
      final itemsJson = data['items'] as List<dynamic>? ?? [];
      final items = <ReceiptItem>[];
      var i = 0;
      for (final j in itemsJson) {
        final m = j as Map<String, dynamic>;
        final name = (m['name']?.toString() ?? '').trim();
        final price = (m['price'] as num?)?.toDouble() ?? 0;
        final qty = (m['qty'] as num?)?.toInt() ?? 1;
        if (name.isEmpty || price <= 0 || qty <= 0) continue;
        items.add(ReceiptItem(
          id: 'item_ai_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: name,
          price: price,
          quantity: qty,
          assignedMemberIds: [],
        ));
        i++;
      }
      return (
        merchantName: data['merchant_name']?.toString().trim() ?? '',
        items: items,
      );
    } catch (_) {
      return null;
    }
  }

  static String _stripFences(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
      t = t.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return t;
  }
}