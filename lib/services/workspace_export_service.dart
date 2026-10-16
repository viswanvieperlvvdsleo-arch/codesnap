import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

class WorkspaceExportService {
  WorkspaceExportService._();

  static Future<String> downloadEditedWorkspace({
    required String projectName,
    required Map<String, String> files,
  }) async {
    if (files.isEmpty) {
      throw StateError('There are no text files to download.');
    }
    final safeName = _safeName(projectName);
    final bytes = createSourceArchive(files);
    return FileSaver.instance.saveFile(
      name: safeName,
      bytes: bytes,
      fileExtension: 'zip',
      mimeType: MimeType.zip,
    );
  }

  static Future<String?> downloadOriginalGitHubArchive({
    required String owner,
    required String repository,
    required String branch,
  }) {
    final encodedBranch = branch.split('/').map(Uri.encodeComponent).join('/');
    final archiveUrl =
        'https://github.com/$owner/$repository/archive/refs/heads/$encodedBranch.zip';
    return FileSaver.instance.downloadLink(
      link: LinkDetails(link: archiveUrl),
      name: '${_safeName(repository)}-${_safeName(branch)}.zip',
    );
  }

  static String _safeName(String value) {
    final safe = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return safe.isEmpty ? 'workspace' : safe;
  }

  static Uint8List createSourceArchive(Map<String, String> files) {
    return _createStoredZip(files);
  }

  static Uint8List _createStoredZip(Map<String, String> files) {
    final output = BytesBuilder(copy: false);
    final centralDirectory = BytesBuilder(copy: false);
    final now = DateTime.now();
    final dosTime = (now.hour << 11) | (now.minute << 5) | (now.second ~/ 2);
    final dosDate =
        ((now.year - 1980).clamp(0, 127) << 9) | (now.month << 5) | now.day;
    var offset = 0;
    var entryCount = 0;

    final sortedEntries = files.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in sortedEntries) {
      final normalizedName =
          entry.key.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
      if (normalizedName.isEmpty ||
          normalizedName.split('/').any((part) => part == '..')) {
        continue;
      }
      final name = Uint8List.fromList(utf8.encode(normalizedName));
      final data = Uint8List.fromList(utf8.encode(entry.value));
      final crc = _crc32(data);
      final localOffset = offset;

      _u32(output, 0x04034b50);
      _u16(output, 20);
      _u16(output, 0x0800);
      _u16(output, 0);
      _u16(output, dosTime);
      _u16(output, dosDate);
      _u32(output, crc);
      _u32(output, data.length);
      _u32(output, data.length);
      _u16(output, name.length);
      _u16(output, 0);
      output.add(name);
      output.add(data);
      offset += 30 + name.length + data.length;

      _u32(centralDirectory, 0x02014b50);
      _u16(centralDirectory, 20);
      _u16(centralDirectory, 20);
      _u16(centralDirectory, 0x0800);
      _u16(centralDirectory, 0);
      _u16(centralDirectory, dosTime);
      _u16(centralDirectory, dosDate);
      _u32(centralDirectory, crc);
      _u32(centralDirectory, data.length);
      _u32(centralDirectory, data.length);
      _u16(centralDirectory, name.length);
      _u16(centralDirectory, 0);
      _u16(centralDirectory, 0);
      _u16(centralDirectory, 0);
      _u16(centralDirectory, 0);
      _u32(centralDirectory, 0);
      _u32(centralDirectory, localOffset);
      centralDirectory.add(name);
      entryCount++;
    }

    final centralBytes = centralDirectory.takeBytes();
    output.add(centralBytes);
    _u32(output, 0x06054b50);
    _u16(output, 0);
    _u16(output, 0);
    _u16(output, entryCount);
    _u16(output, entryCount);
    _u32(output, centralBytes.length);
    _u32(output, offset);
    _u16(output, 0);
    return output.takeBytes();
  }

  static void _u16(BytesBuilder builder, int value) {
    final data = ByteData(2)..setUint16(0, value, Endian.little);
    builder.add(data.buffer.asUint8List());
  }

  static void _u32(BytesBuilder builder, int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    builder.add(data.buffer.asUint8List());
  }

  static int _crc32(Uint8List bytes) {
    var crc = 0xffffffff;
    for (final byte in bytes) {
      crc = _crcTable[(crc ^ byte) & 0xff] ^ (crc >>> 8);
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }

  static final List<int> _crcTable = List<int>.generate(256, (index) {
    var value = index;
    for (var bit = 0; bit < 8; bit++) {
      value = (value & 1) == 1 ? 0xedb88320 ^ (value >>> 1) : value >>> 1;
    }
    return value;
  });
}
