import 'storage_picker_stub.dart'
    if (dart.library.html) 'storage_picker_web.dart'
    if (dart.library.io) 'storage_picker_io.dart';

class PickedMediaResult {
  final String pathOrDataUrl;
  final String fileName;
  final int fileSize;
  final String mediaType; // 'image', 'video', 'document'
  final String? extension;

  const PickedMediaResult({
    required this.pathOrDataUrl,
    required this.fileName,
    required this.fileSize,
    required this.mediaType,
    this.extension,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

abstract class StoragePickerBase {
  Future<PickedMediaResult?> pickImage({bool fromCamera = false});
  Future<PickedMediaResult?> pickVideo();
  Future<PickedMediaResult?> pickDocument();
}

StoragePickerBase getStoragePicker() => getPlatformStoragePicker();
