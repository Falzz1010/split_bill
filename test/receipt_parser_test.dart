import 'package:flutter_test/flutter_test.dart';
import 'package:fairsplit/core/utils/receipt_parser.dart';

void main() {
  group('ReceiptParser', () {
    test('thermal receipt: nama & harga baris terpisah', () {
      const raw = '''
J1. Medayu Utara 50, Surabaya
81529620220414142434
2022-04-14
14:24:34
No.0-24
Berkaa Shgp
Nasi Ayam Geprek
1X 12.000
Nasi Ayam Kremes
1 X 15.000
Nasi Goreng Spesial
1 X 20.000
Sub Total
Total
Bayar (Cash)
Kembali
Afi
sheila
Rp 12.000
Rp 15.000
Rp 20.000
47.000
47.000
47.000
Link Kritik dan Saran:
''';
      final r = ReceiptParser.parseText(raw);
      expect(r.merchantName, 'Berkaa Shgp');
      expect(r.items.length, 3);
      expect(r.items[0].name, 'Nasi Ayam Geprek');
      expect(r.items[0].quantity, 1);
      expect(r.items[0].price, 12000);
      expect(r.items[1].name, 'Nasi Ayam Kremes');
      expect(r.items[1].price, 15000);
      expect(r.items[2].name, 'Nasi Goreng Spesial');
      expect(r.items[2].price, 20000);
      expect(r.subtotal, 47000);
      expect(r.totalAmount, 47000);
    });

    test('single line items with qty and tax', () {
      const raw = '''
Kopi Senja Cafe
Kopi Susu Gula Aren 28.000
2x Roti Bakar Keju 30000
Matcha Latte Rp 34.000
Croissant Mentega 38.000
Subtotal 160.000
PPN 10% 16.000
Grand Total 176.000
''';
      final r = ReceiptParser.parseText(raw);
      expect(r.merchantName, 'Kopi Senja Cafe');
      expect(r.items.length, 4);
      expect(r.items[0].name, 'Kopi Susu Gula Aren');
      expect(r.items[0].price, 28000);
      expect(r.items[1].quantity, 2);
      expect(r.items[1].price, 30000);
      expect(r.items[2].price, 34000);
      expect(r.items[3].price, 38000);
      expect(r.subtotal, 160000);
      expect(r.tax, 16000);
      expect(r.totalAmount, 176000);
    });

    test('dots separator: Nasi Goreng.......20.000', () {
      const raw = '''
Toko Barokah
Nasi Goreng Spesial.........20.000
Es Teh Manis...........5.000
Ayam Geprek..........15.000
Total 40.000
''';
      final r = ReceiptParser.parseText(raw);
      expect(r.items.length, 3);
      expect(r.items[0].name, 'Nasi Goreng Spesial');
      expect(r.items[0].price, 20000);
      expect(r.items[1].name, 'Es Teh Manis');
      expect(r.items[1].price, 5000);
      expect(r.items[2].name, 'Ayam Geprek');
      expect(r.items[2].price, 15000);
      expect(r.subtotal, 40000);
    });

    test('qty in middle and leading', () {
      const raw = '''
RM Padang Sederhana
Nasi Rendang 1X 25.000
1X Es Teh Manis 4.000
Nasi Rendang 1X 25.000
Total 58.000
''';
      final r = ReceiptParser.parseText(raw);
      expect(r.items.length, 2);
      expect(r.items[0].name, 'Nasi Rendang');
      expect(r.items[0].quantity, 2);
      expect(r.items[0].price, 25000);
      expect(r.items[1].name, 'Es Teh Manis');
      expect(r.items[1].quantity, 1);
      expect(r.items[1].price, 4000);
      expect(r.subtotal, 54000);
      expect(r.totalAmount, 58000);
    });

    test('qty without X and Rp glued', () {
      const raw = '''
Warung Pak Kumis
Nasi Uduk 1 10.000
Kopi HitamRp5.000
Teh ManisRp 3.000
Total Rp18.000
''';
      final r = ReceiptParser.parseText(raw);
      expect(r.items.length, 3);
      expect(r.items[0].name, 'Nasi Uduk');
      expect(r.items[0].price, 10000);
      expect(r.items[1].name, 'Kopi Hitam');
      expect(r.items[1].price, 5000);
      expect(r.items[2].name, 'Teh Manis');
      expect(r.items[2].price, 3000);
      expect(r.subtotal, 18000);
    });

    test('PPN percent without amount uses next line', () {
      const raw = '''
Kafe Angkringan
Sate Ayam 15.000
Es Jeruk 5.000
Sub Total 20.000
PPN 10%
2.000
Grand Total
22.000
''';
      final r = ReceiptParser.parseText(raw);
      expect(r.items.length, 2);
      expect(r.tax, 2000);
      expect(r.totalAmount, 22000);
      expect(r.subtotal, 20000);
    });

    test('header row dan nama kasir tidak jadi item', () {
      const raw = '''
Warung Bunda
Nama Barang   Qty   Harga
Nasi Bakar 1X 12.000
Sate Usus 1X 10.000
Bayar (Cash)
22.000
Kembali
0
Kasir
Afi
sheila
Rp 12.000
Rp 10.000
22.000
''';
      final r = ReceiptParser.parseText(raw);
      expect(r.merchantName, 'Warung Bunda');
      expect(r.items.length, 2);
      expect(r.items[0].name, 'Nasi Bakar');
      expect(r.items[1].name, 'Sate Usus');
      expect(r.subtotal, 22000);
    });

    test('wholesale: qty-unit line "4.000 Kg X 12.500" dipasang ke nama', () {
      const raw = '''
GROSIR SEMBAKO DAN BERAS
JI. Rorojonggrang Raya B1 No.13 Kel. Melong - Cimahi
No. Struk: 211
Beras
4.000 Kg X 12.500
Minyak Goreng
1600 Kg X 27.500
Gula Pasir
TOKO ABANG
1600 Kg X 15.000
The Celup Isi 25
800 Box X 7.500
Mie Instan
8.000 Pcs X 3.000
Susu Kaleng
1600 Klg X 14.000
Sarden
1600 Klg X 14.000
Kardus Packing
800 Pcs X 9.000
Subtotal
Bayar
Kembali
10.01.2023-10:11:07
Rp. 50.000.000
TERI MA KAS IH
44.000.000
200.000.000
ATASKUN JUNGAN AND A
200.000.000
''';
      final r = ReceiptParser.parseText(raw);
      expect(r.merchantName, 'GROSIR SEMBAKO DAN BERAS');
      expect(r.items.length, 8);
      expect(r.items[0].name, 'Beras');
      expect(r.items[0].price, 12500);
      expect(r.items[1].name, 'Minyak Goreng');
      expect(r.items[1].price, 27500);
      expect(r.items[2].name, 'Gula Pasir');
      expect(r.items[2].price, 15000);
      expect(r.items[3].name, 'The Celup Isi 25');
      expect(r.items[3].price, 7500);
      expect(r.items[4].name, 'Mie Instan');
      expect(r.items[4].price, 3000);
      expect(r.items[5].name, 'Susu Kaleng');
      expect(r.items[5].price, 14000);
      expect(r.items[6].name, 'Sarden');
      expect(r.items[6].price, 14000);
      expect(r.items[7].name, 'Kardus Packing');
      expect(r.items[7].price, 9000);
      expect(r.subtotal, 102500);
    });

    test('pawoon two-column: nama kiri harga kanan (OCR terpisah)', () {
      const raw = '''
No. Meja :3
Kode Struk: 9873982342341
Tanggal : 2017-07-23 08:45:34
Es Teh Manis
Kasir : Ibrahim Abdullah
Martabak Original
AXA Tower Lt.7, JI. Prof.
DR. Satrio Kav. 18
Pelanggan : Bilal Fahreda
Subtotal
Pawoon Resto
Kuningan, Jakarta Selatan
12940
Martabak Telur
PPN (10%)
Total
Tunai
1500-360
Kembali
Terima kasih
Pass Wifi: 123456
pawoonpos
pawoonpos
pawoonpos
x2
x1
x1
er pawoon pos tiktok
Powered by Pawoon POS
40,000
4,000
33,000
77,000
7,700
84,700
100,000
15,300
''';
      final r = ReceiptParser.parseText(raw);
      expect(r.items.length, 3);
      expect(r.items[0].name, 'Es Teh Manis');
      expect(r.items[0].quantity, 2);
      expect(r.items[1].name, 'Martabak Original');
      expect(r.items[1].quantity, 1);
      expect(r.items[2].name, 'Martabak Telur');
      expect(r.items[2].quantity, 1);
      expect(r.items.every((it) => it.price <= 100000), isTrue);
    });

    test('mrdiy: item yang terurai muncul, harga palsu jutaan ditolak', () {
      const raw = '''
PONS MAKE UP
9057664
KACAMATA, GAYA
9O58730
ANTING-ANTNG
905/620
IKAT RAMBUT
SOST9S1
ALAT PENCARUT ALIs
sO53831
ramlal 5
MRYDEK
TOTAL
INVOICE-
1x4,500
1X 3,9o0
1X8000
1X4000
1X 10,000o
4.500
JANGAN BUANG STRUK
BELANJA MR.DIY-MU!
urusoncuanmrdiy.id
15500
8000
k000
10,000
atyfs) 5
Rp 50,000
''';
      final r = ReceiptParser.parseText(raw);
      expect(r.merchantName, 'PONS MAKE UP');
      // Layout dua-kolom MR.DIY (nama kiri, harga kanan) hanya sebagian yang
      // terurai; yang penting: tidak ada harga palsu jutaan dari teks rusak.
      expect(r.items.length, greaterThanOrEqualTo(3));
      expect(r.items.every((it) => it.price <= 1000000), isTrue);
    });

    test('simulated scan text', () {
      const raw = '''
Kopi Kenangan Senopati
1x Kopi Kenangan Mantan Large 28.000
2x Roti Coklat Klasik 30.000
1x Avocado Coffee Special 34.000
1x Toast Smoked Beef Cheese 38.000
Subtotal 130.000
PPN 10% 13.000
Service Charge 7.000
Grand Total 150.000
''';
      final r = ReceiptParser.parseText(raw);
      expect(r.merchantName, 'Kopi Kenangan Senopati');
      expect(r.items.length, 4);
      expect(r.subtotal, 130000);
      expect(r.tax, 13000);
      expect(r.serviceCharge, 7000);
      expect(r.totalAmount, 150000);
    });

    test('qty with @ separator: 2 @ 15.000 dan @20.000', () {
      const raw = '''
Warung Sebelah
Nasi Goreng 2 @ 15.000
Es Teh Manis @ 5.000
Total 35.000
''';
      final r = ReceiptParser.parseText(raw);
      expect(r.items.length, 2);
      expect(r.items[0].name, 'Nasi Goreng');
      expect(r.items[0].quantity, 2);
      expect(r.items[0].price, 15000);
      expect(r.items[1].name, 'Es Teh Manis');
      expect(r.items[1].quantity, 1);
      expect(r.items[1].price, 5000);
    });

    test('suffix rupiah lama: 20.000,-', () {
      const raw = '''
Toko Jaya
Nasi Uduk 10.000,-
Es Teh 3.000,-
Total 13.000,-
''';
      final r = ReceiptParser.parseText(raw);
      expect(r.items.length, 2);
      expect(r.items[0].name, 'Nasi Uduk');
      expect(r.items[0].price, 10000);
      expect(r.items[1].name, 'Es Teh');
      expect(r.items[1].price, 3000);
      expect(r.totalAmount, 13000);
    });

    test('thermal dua-kolom: OCR memisah blok nama & blok harga (hasil OCR asli emulator)', () {
      // Teks mentah OCR dari scan galeri struk "KOPI SENJA CAFE" di emulator:
      // ML Kit membaca nama item dan harga sebagai blok terpisah.
      const raw = '''
Nama Item
Jl. Riau No. 45, Bandung
Telp: 022 -9876543
Kopi Susu Gula Aren..
Roti Bakar Coklat. ...
Avocado Coffee.
KOPI SENJA CAFE
Subtotal.
PPN 11%.
TOTAL
Qty Harga
Toast Smoked Beef. ... 1X 38.000
Es Teh Manis Manis... 2X 5.000
Bayar (Cash)..
Kembali..
1X 28.000
2X 30.000
1X 34.000
Service Charge.. •. 8.500
170.000
18.70
197.200
200.000
2.800
Terima kasih, s ampai jumpa!
''';
      final r = ReceiptParser.parseText(raw);
      final byName = {for (final it in r.items) it.name.toLowerCase(): it};
      // Nama toko terbaca benar, bukan nama item pertama.
      expect(r.merchantName, 'KOPI SENJA CAFE');
      expect(byName['kopi susu gula aren']?.price, 28000);
      expect(byName['roti bakar coklat']?.price, 30000);
      // Qty "2X" pada blok harga ikut terbaca lewat fallback dua-kolom.
      expect(byName['roti bakar coklat']?.quantity, 2);
      expect(byName['avocado coffee']?.price, 34000);
      expect(byName['toast smoked beef']?.price, 38000);
      expect(byName['es teh manis manis']?.price, 5000);
      expect(byName['es teh manis manis']?.quantity, 2);
      // Nama toko tidak menempel sebagai item palsu (artefak subtotal).
      expect(byName.containsKey('kopi senja cafe'), isFalse);
      // Semua 5 item berhasil terurai (sebelumnya hanya 2).
      expect(r.items.length, greaterThanOrEqualTo(5));
    });

    test('empty text returns no fake placeholder items', () {
      final r = ReceiptParser.parseText('');
      expect(r.items.length, 0);
      expect(r.subtotal, 0);
    });

    test('foreign currency USD: harga desimal diparse dengan benar', () {
      const raw = '''
Starbucks Coffee
US\$ 12.50
Caramel Latte
\$ 6.25
Sub Total \$ 18.75
Tax \$ 1.50
Total \$ 20.25
''';
      final r = ReceiptParser.parseText(raw, currency: 'USD');
      expect(r.items.length, 2);
      expect(r.items[0].price, 12.5);
      expect(r.items[1].price, 6.25);
      expect(r.subtotal, 18.75);
      expect(r.totalAmount, 20.25);
    });

    test('foreign currency JPY: titik/koma adalah ribuan, bukan desimal', () {
      const raw = '''
FamilyMart
1,200
¥ 1,200
2,400
''';
      final r = ReceiptParser.parseText(raw, currency: 'JPY');
      expect(r.items.length, greaterThan(0));
      expect(r.items[0].price, 1200);
      // tanpa label total → total = subtotal item
      expect(r.totalAmount, r.subtotal);
    });
  });
}
