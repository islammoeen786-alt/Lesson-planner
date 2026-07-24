import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndSharePdf(Uint8List bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      text: '$fileName - Lesson Plan',
    ),
  );
}
