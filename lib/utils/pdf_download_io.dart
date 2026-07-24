import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndSharePdf(Uint8List bytes, String fileName) async {
  final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$sanitizedName');
  await file.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      text: '$sanitizedName - Lesson Plan',
    ),
  );
}
