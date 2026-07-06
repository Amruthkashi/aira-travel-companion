// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

Future<void> downloadHtmlFile(String content, String filename) async {
  js.context.callMethod('eval', [
    '''
    (function(content, filename) {
      const blob = new Blob([content], { type: 'text/html' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    })(${js.context['JSON'].callMethod('stringify', [content])}, '$filename');
    '''
  ]);
}

void openPrintWindow(String content) {
  js.context.callMethod('eval', [
    '''
    (function(content) {
      const win = window.open('', '_blank');
      if (win) {
        win.document.write(content);
        win.document.close();
      } else {
        alert('Please allow popups to open print version.');
      }
    })(${js.context['JSON'].callMethod('stringify', [content])});
    '''
  ]);
}

Future<void> shareHtmlFile(String htmlContent, String filename) async {
  // No-op on Web
}

Future<void> sharePdfFile(String htmlContent, String filename) async {
  // No-op on Web
}

Future<void> layoutPdf(String htmlContent, String filename) async {
  // No-op on Web
}

Future<void> savePdfFile(String htmlContent, String filename) async {
  // No-op on Web
}
