import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';

Future<void> downloadHtmlFile(String content, String filename) async {
  try {
    final bytes = utf8.encode(content);
    await FileSaver.instance.saveFile(
      name: filename.replaceAll('.html', ''),
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'html',
      mimeType: MimeType.other,
      customMimeType: 'text/html',
    );
  } catch (e) {
    debugPrint("Error saving HTML to Downloads: $e");
  }
}

Future<void> savePdfFile(String htmlContent, String filename) async {
  try {
    final pdfBytes = await Printing.convertHtml(
      format: PdfPageFormat.a4,
      html: htmlContent,
    );
    await FileSaver.instance.saveFile(
      name: filename.replaceAll('.pdf', ''),
      bytes: pdfBytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  } catch (e) {
    debugPrint("Error saving PDF to Downloads: $e");
  }
}

void openPrintWindow(String content) {
  layoutPdf(content, 'aira_itinerary');
}

Future<void> shareHtmlFile(String htmlContent, String filename) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsString(htmlContent);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'My Aira Travel Itinerary HTML',
      ),
    );
  } catch (e) {
    debugPrint("Error sharing HTML: $e");
  }
}

Future<void> sharePdfFile(String htmlContent, String filename) async {
  try {
    final pdfBytes = await Printing.convertHtml(
      format: PdfPageFormat.a4,
      html: htmlContent,
    );
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(pdfBytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'My Aira Travel Itinerary PDF',
      ),
    );
  } catch (e) {
    debugPrint("Error sharing PDF: $e");
  }
}

Future<void> layoutPdf(String htmlContent, String filename) async {
  try {
    await Printing.layoutPdf(
      onLayout: (format) async => await Printing.convertHtml(
        format: format,
        html: htmlContent,
      ),
      name: filename,
    );
  } catch (e) {
    debugPrint("Error printing PDF: $e");
  }
}
