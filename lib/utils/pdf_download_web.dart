import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveAndSharePdf(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  html.Url.revokeObjectUrl(url);
  anchor.remove();
}
