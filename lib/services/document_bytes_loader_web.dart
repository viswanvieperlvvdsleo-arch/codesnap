import 'dart:convert';
import 'dart:typed_data';

Future<Uint8List> loadDocumentBytes(String source) async {
  final comma = source.indexOf(',');
  if (!source.startsWith('data:') || comma < 0) {
    throw const FormatException('The selected browser file is not readable.');
  }
  return base64Decode(source.substring(comma + 1));
}
