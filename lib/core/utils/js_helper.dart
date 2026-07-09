import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';

Future<String?> downloadHtmlFile(String content, String filename) async {
  final bytes = utf8.encode(content);
  return await FileSaver.instance.saveFile(
    name: filename.replaceAll('.html', ''),
    bytes: Uint8List.fromList(bytes),
    fileExtension: 'html',
    mimeType: MimeType.other,
    customMimeType: 'text/html',
  );
}

Future<String?> savePdfFile(String htmlContent, String filename) async {
  final pdfBytes = await Printing.convertHtml(
    format: PdfPageFormat.a4,
    html: htmlContent,
  );
  return await FileSaver.instance.saveFile(
    name: filename.replaceAll('.pdf', ''),
    bytes: pdfBytes,
    fileExtension: 'pdf',
    mimeType: MimeType.pdf,
  );
}

void openPrintWindow(String content) {
  layoutPdf(content, 'tria_itinerary');
}

Future<void> shareHtmlFile(String htmlContent, String filename) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsString(htmlContent);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'My Tria Travel Itinerary HTML',
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
        text: 'My Tria Travel Itinerary PDF',
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
