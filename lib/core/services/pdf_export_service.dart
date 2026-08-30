import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import '../../core/models/transaksi_umkm.dart';
import '../../core/state/transaksi_umkm_store.dart';
import '../../core/utils/currency_formatter.dart';

class PdfExportService {
  static Future<void> exportDailyReport({DateTime? date}) async {
    final d = date ?? DateTime.now();
    final store = TransaksiUmkmStore.instance;
    final transaksi = store.transaksi.where((t) =>
        t.date.year == d.year && t.date.month == d.month && t.date.day == d.day).toList();
    final totalRevenue = transaksi.fold(0.0, (s, t) => s + t.totalAmount);
    final totalProfit = transaksi.fold(0.0, (s, t) => s + t.items.fold(0.0, (si, i) => si + i.profit));

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoSansRegular();
    final fontBold = await PdfGoogleFonts.nunitoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Neobill — Laporan Harian',
                style: pw.TextStyle(font: fontBold, fontSize: 20)),
            pw.SizedBox(height: 4),
            pw.Text(
              '${d.day}/${d.month}/${d.year}',
              style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600),
            ),
            pw.Divider(color: PdfColors.grey300),
          ],
        ),
        build: (context) => [
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Transaksi', '${transaksi.length}', font, fontBold),
                _buildSummaryItem('Total Omzet', formatCurrency(totalRevenue), font, fontBold),
                _buildSummaryItem('Total Profit', formatCurrency(totalProfit), font, fontBold),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Transaction list
          pw.Text('Detail Transaksi', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 8),
          if (transaksi.isEmpty)
            pw.Text('Tidak ada transaksi',
                style: pw.TextStyle(font: font, color: PdfColors.grey500))
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Waktu', 'Merchant', 'Items', 'Bayar', 'Total'],
              data: transaksi.map((t) => [
                '${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}',
                t.merchantName,
                '${t.items.length}',
                paymentMethodName(t.paymentMethod),
                formatCurrency(t.totalAmount),
              ]).toList(),
            ),

          pw.SizedBox(height: 24),

          // Top items
          pw.Text('Top Items Hari Ini', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 8),
          ...store.topItems(limit: 5).map((item) => pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(item.name, style: pw.TextStyle(font: font, fontSize: 10)),
                pw.Text('${item.qty}x • ${formatCurrency(item.revenue)}',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
          )),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Laporan Neobill ${d.day}-${d.month}-${d.year}',
    );
  }

  static Future<void> exportAllTransactions({DateTimeRange? range}) async {
    final store = TransaksiUmkmStore.instance;
    List<TransaksiUmkm> transaksi;
    String title;

    if (range != null) {
      transaksi = store.transactionsInRange(range.start, range.end);
      title = 'Transaksi ${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}';
    } else {
      transaksi = store.transaksi;
      title = 'Semua Transaksi';
    }

    final totalRevenue = transaksi.fold(0.0, (s, t) => s + t.totalAmount);

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoSansRegular();
    final fontBold = await PdfGoogleFonts.nunitoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Neobill — $title',
                style: pw.TextStyle(font: fontBold, fontSize: 18)),
            pw.SizedBox(height: 4),
            pw.Text(
              '${transaksi.length} transaksi • Total: $totalRevenue',
              style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey600),
            ),
            pw.Divider(color: PdfColors.grey300),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
            cellStyle: pw.TextStyle(font: font, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Tanggal', 'Merchant', 'Items', 'Kategori', 'Bayar', 'Total'],
            data: transaksi.map((t) => [
              '${t.date.day}/${t.date.month}',
              t.merchantName,
              '${t.items.length}',
              t.category,
              paymentMethodName(t.paymentMethod),
              formatCurrency(t.totalAmount),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Neobill $title',
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 16)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
      ],
    );
  }
}
