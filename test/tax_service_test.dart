import 'package:flutter_test/flutter_test.dart';
import 'package:fairsplit/core/models/split_model.dart';
import 'package:fairsplit/core/utils/currency_formatter.dart';

Member _m(String id) => Member(
  id: id,
  name: id,
  avatarUrl: '',
  accentColorHex: '#FFCD00',
  isPaid: false,
  amountOwed: 0,
);

void main() {
  group('computeTaxAndService', () {
    test('PPN 11% + Service 10% dihitung dari subtotal', () {
      final t = computeTaxAndService(50000);
      expect(t.tax, 5500); // 11%
      expect(t.serviceCharge, 5000); // 10% (bukan 5%)
      expect(t.total, 60500); // subtotal + tax + service
    });

    test('nilai nol saat subtotal nol', () {
      final t = computeTaxAndService(0);
      expect(t.tax, 0);
      expect(t.serviceCharge, 0);
      expect(t.total, 0);
    });

    test('includeTax=false mematikan PPN saja', () {
      final t = computeTaxAndService(100000, includeTax: false);
      expect(t.tax, 0);
      expect(t.serviceCharge, 10000);
      expect(t.total, 110000);
    });

    test('includeService=false mematikan service saja', () {
      final t = computeTaxAndService(100000, includeService: false);
      expect(t.tax, 11000);
      expect(t.serviceCharge, 0);
      expect(t.total, 111000);
    });
  });

  group('computeMemberAmounts', () {
    test('item tanpa assign dibagi rata ke semua member (uang tidak hilang)', () {
      final members = [_m('a'), _m('b'), _m('c')];
      final items = [
        ReceiptItem(
          id: 'i1',
          name: 'Kopi',
          price: 60000,
          quantity: 1,
          assignedMemberIds: [],
        ),
      ];
      final result = computeMemberAmounts(members, items);
      final total = result.fold(0.0, (s, m) => s + m.amountOwed);
      expect(result[0].amountOwed, 20000);
      expect(result[1].amountOwed, 20000);
      expect(result[2].amountOwed, 20000);
      expect(total, 60000);
    });

    test('item yang di-assign dibagi ke anggota tsb saja', () {
      final members = [_m('a'), _m('b')];
      final items = [
        ReceiptItem(
          id: 'i1',
          name: 'Nasi',
          price: 10000,
          quantity: 1,
          assignedMemberIds: ['a'],
        ),
      ];
      final result = computeMemberAmounts(members, items);
      expect(result[0].amountOwed, 10000);
      expect(result[1].amountOwed, 0);
    });

    test('pembulatan: jumlah tagihan member selalu persis total (rupiah utuh)', () {
      final members = [_m('a'), _m('b'), _m('c')];
      final items = [
        ReceiptItem(
          id: 'i1',
          name: 'Kopi',
          price: 25000,
          quantity: 1,
          assignedMemberIds: [],
        ),
      ];
      final result = computeMemberAmounts(members, items);
      final total = result.fold(0.0, (s, m) => s + m.amountOwed);
      expect(total, 25000);
      for (final m in result) {
        expect(m.amountOwed, m.amountOwed.roundToDouble());
      }
    });

    test('pembulatan dengan pajak: tetap utuh & jumlahnya persis total', () {
      final members = [_m('a'), _m('b')];
      final items = [
        ReceiptItem(
          id: 'i1',
          name: 'Nasi',
          price: 33333,
          quantity: 1,
          assignedMemberIds: ['a'],
        ),
      ];
      final result = computeMemberAmounts(
        members,
        items,
        tax: 3666.63,
        serviceCharge: 3333.3,
      );
      final total = result.fold(0.0, (s, m) => s + m.amountOwed);
      expect(total, (33333 + 3666.63 + 3333.3).roundToDouble());
    });
  });

  group('parsePrice', () {
    test('ribuan & desimal dibedakan dengan benar', () {
      expect(parsePrice('Rp 25.000'), 25000); // ribuan IDR
      expect(parsePrice('25,000'), 25000); // ribuan US
      expect(parsePrice(r'$ 12.50'), 12.5); // desimal US
      expect(parsePrice('25,50'), 25.5); // desimal IDR
      expect(parsePrice('12.500,50'), 12500.5); // dua separator
      expect(parsePrice('0.99'), 0.99);
      expect(parsePrice(''), 0);
    });
  });
}
