import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../config/theme.dart';

class StatementPdfPreviewDialog extends StatelessWidget {
  final Uint8List pdfBytes;
  final String title;

  const StatementPdfPreviewDialog({
    super.key,
    required this.pdfBytes,
    this.title = 'Statement Preview',
  });

  static Future<void> show(
    BuildContext context, {
    required Uint8List pdfBytes,
    String title = 'Statement Preview',
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => Scaffold(
            appBar: AppBar(
              title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textPrimary,
              elevation: 1,
            ),
            body: PdfPreview(
              build: (format) => pdfBytes,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              allowPrinting: true,
              allowSharing: true,
              initialPageFormat: PdfPageFormat.a4,
              pdfFileName: '$title.pdf',
              previewPageMargin: const EdgeInsets.all(8),
            ),
          ),
        ),
      );
    }

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatementPdfPreviewDialog(pdfBytes: pdfBytes, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 900),
        child: Scaffold(
          appBar: AppBar(
            title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textPrimary,
            elevation: 1,
          ),
          body: PdfPreview(
            build: (format) => pdfBytes,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
            initialPageFormat: PdfPageFormat.a4,
            pdfFileName: '$title.pdf',
            previewPageMargin: const EdgeInsets.all(12),
          ),
        ),
      ),
    );
  }
}
