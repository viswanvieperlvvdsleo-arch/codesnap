import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> loadDocumentBytes(String source) async {
  if (source.startsWith('data:')) {
    final comma = source.indexOf(',');
    if (comma < 0) throw const FormatException('Invalid document data.');
    return base64Decode(source.substring(comma + 1));
  }
  return File(source).readAsBytes();
}
