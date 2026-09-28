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

int _countPages(Uint8List pdf) {
  final text = String.fromCharCodes(pdf);
  final match = RegExp(r'/Type\s*/Pages\b[^>]*?/Count\s+(\d+)', dotAll: true).firstMatch(text);
  if (match != null) {
    return int.parse(match.group(1)!);
  }
  // Fallback: match any /Count <number>
  final fallback = RegExp(r'/Count\s+(\d+)').firstMatch(text);
  return fallback != null ? int.parse(fallback.group(1)!) : 0;
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

  test('payment invoice embeds the stamp and fits on one page', () async {
    final pdf = await buildPaymentInvoicePdf(
      settings: const BusinessSettings(id: 's1', businessName: 'RATHOD ENTERPRISES'),
      receiptNumber: 'RCPT-2609-0001',
      customer: const Customer(id: 'c1', name: '8 zero', mobile: '8089455929'),
      amount: 1686,
      paymentMode: 'Cash',
      previousOutstanding: 2968,
      remainingOutstanding: 1282,
      paymentDate: DateTime(2026, 9, 18),
      remarks: 'niil',
    );
    expect(_hasJpegMarker(pdf), isTrue,
        reason: 'the invoice must carry the stamp jpeg');
    expect(_countPages(pdf), 1,
        reason: 'a standard payment invoice must fit on a single page');
  });

  test('statement embeds the stamp and does not create an unnecessary second page', () async {
    final pdf = await buildStatementPdf(
      customerName: '8 zero',
      customerMobile: '8089455929',
      customerAddress: '-',
      from: '2026-08-30',
      to: '2026-09-29',
      openingBalance: 0,
      closingBalance: 1282,
      totalDebit: 2968,
      totalCredit: 1686,
      rows: [
        {
          'date': '2026-08-31',
          'type': 'bill',
          'description': 'Bill RE-2608-0012',
          'debit': 1686.0,
          'credit': 0.0,
          'balance': 1686.0,
        },
        {
          'date': '2026-09-18',
          'type': 'payment',
          'description': 'Payment RCPT-2609-0001',
          'debit': 0.0,
          'credit': 1686.0,
          'balance': 0.0,
        },
        {
          'date': '2026-09-20',
          'type': 'bill',
          'description': 'Bill RE-2609-0006',
          'debit': 1282.0,
          'credit': 0.0,
          'balance': 1282.0,
        },
      ],
    );
    expect(_hasJpegMarker(pdf), isTrue,
        reason: 'the statement must carry the stamp jpeg');
    expect(_countPages(pdf), 1,
        reason: 'a 3-row statement must fit cleanly on a single page without generating page 2');
  });
}
