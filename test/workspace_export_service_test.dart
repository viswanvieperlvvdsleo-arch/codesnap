import 'dart:convert';
import 'dart:typed_data';

import 'package:codesnap/services/workspace_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates a ZIP containing all edited source entries', () {
    final archive = WorkspaceExportService.createSourceArchive({
      'lib/main.dart': 'void main() {}',
      'README.md': '# Example',
    });
    final data = ByteData.sublistView(archive);
    final text = utf8.decode(archive, allowMalformed: true);
    final endOffset = archive.length - 22;

    expect(data.getUint32(0, Endian.little), 0x04034b50);
    expect(data.getUint32(endOffset, Endian.little), 0x06054b50);
    expect(data.getUint16(endOffset + 10, Endian.little), 2);
    expect(text, contains('lib/main.dart'));
    expect(text, contains('void main() {}'));
    expect(text, contains('README.md'));
  });
}
