import 'package:flutter/foundation.dart';

import 'share_pdf_stub.dart'
    if (dart.library.js) 'share_pdf_web.dart' as web;

/// Shares a PDF file (e.g. invoice / bill / statement) with a WhatsApp message.
/// On web it uses the Web Share API when available (opens the native share
/// sheet so WhatsApp can receive the PDF), otherwise it opens WhatsApp with the
/// text message via a wa.me deep link.
Future<void> sharePdf(Uint8List pdfBytes, {required String filename, required String message}) async {
  if (kIsWeb) {
    return web.webSharePdf(pdfBytes, filename: filename, message: message);
  }
  throw UnsupportedError('Share is only supported on the web build.');
}

/// Builds the WhatsApp share message using the same format requested by the
/// business owner. [docLabel] is e.g. "Sale Invoice", "Payment Invoice" or
/// "Statement". [amount] is the invoice amount and [balance] the outstanding.
String buildShareMessage({
  required String businessName,
  required String docLabel,
  required double amount,
  required double balance,
}) {
  final name = businessName.trim().isEmpty ? 'NARAYAN FOODS' : businessName.trim();
  return 'Greetings from $name\n'
      'We are pleased to have you as a valuable customer. '
      'Please find the details of your transaction.\n\n'
      '$docLabel :\n'
      'Invoice Amount: ${amount.toStringAsFixed(2)}\n'
      'Balance: ${balance.toStringAsFixed(2)}\n\n'
      'Thanks for doing business with us.\n'
      'Regards,\n'
      '$name';
}
