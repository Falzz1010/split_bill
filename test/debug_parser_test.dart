import 'package:flutter_test/flutter_test.dart';
import 'package:fairsplit/core/utils/receipt_parser.dart';

void main() {
  test('debug mrdiy', () {
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
    print('MERCHANT=[${r.merchantName}]');
    for (final it in r.items) {
      print('ITEM: ${it.name} qty=${it.quantity} price=${it.price}');
    }
  });
}
