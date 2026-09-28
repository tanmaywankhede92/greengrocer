import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengrocer/models/business_settings.dart';
import 'package:greengrocer/models/customer.dart';
import 'package:greengrocer/widgets/bill_stamp.dart';
import 'package:greengrocer/widgets/payment_invoice_pdf.dart';
import 'package:greengrocer/widgets/statement_pdf.dart';

bool _hasJpegMarker(Uint8List pdf) {
  for (var i = 0; i + 2 < pdf.length; i++) {
    if (pdf[i] == 0xFF && pdf[i + 1] == 0xD8 && pdf[i + 2] == 0xFF) return true;
  }
  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the stamp asset really loads for the pdf generators', () async {
    // This is the guard for the silent-blank-stamp bug: if the asset 404s,
    // loadStampBytes() returns null and every document prints without a stamp.
    final bytes = await loadStampBytes();
    expect(bytes, isNotNull,
        reason: 'a null stamp means no stamp in any generated document');
    expect(bytes!.length, greaterThan(0));
  });

  test('payment invoice embeds the stamp', () async {
    final pdf = await buildPaymentInvoicePdf(
      settings: const BusinessSettings(id: 's1', businessName: 'RATHOD ENTERPRISES'),
      receiptNumber: 'R-1',
      customer: const Customer(id: 'c1', name: 'Test Customer', mobile: '9999999999'),
      amount: 500,
      paymentMode: 'Cash',
      previousOutstanding: 100,
      remainingOutstanding: 600,
      paymentDate: DateTime(2026, 1, 1),
    );
    expect(_hasJpegMarker(pdf), isTrue,
        reason: 'the invoice must carry the stamp jpeg');
  });

  test('statement embeds the stamp', () async {
    final pdf = await buildStatementPdf(
      customerName: 'Test Customer',
      customerMobile: '9999999999',
      customerAddress: 'Nagpur',
      from: '2026-01-01',
      to: '2026-01-31',
      openingBalance: 100,
      closingBalance: 250,
      totalDebit: 400,
      totalCredit: 150,
      rows: const [],
    );
    expect(_hasJpegMarker(pdf), isTrue,
        reason: 'the statement must carry the stamp jpeg');
  });
}
