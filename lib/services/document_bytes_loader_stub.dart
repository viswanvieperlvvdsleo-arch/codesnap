import 'dart:convert';
import 'dart:typed_data';

Future<Uint8List> loadDocumentBytes(String source) async {
  final comma = source.indexOf(',');
  if (!source.startsWith('data:') || comma < 0) {
    throw UnsupportedError(
        'Document files are not supported on this platform.');
  }
  return base64Decode(source.substring(comma + 1));
}
