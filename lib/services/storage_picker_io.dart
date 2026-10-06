import 'package:flutter/services.dart';
import 'storage_picker.dart';

StoragePickerBase getPlatformStoragePicker() => StoragePickerIO();

class StoragePickerIO implements StoragePickerBase {
  static const _channel = MethodChannel('codesnap/storage_picker');

  @override
  Future<PickedMediaResult?> pickImage({bool fromCamera = false}) async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickImage', {
        'fromCamera': fromCamera,
      });
      if (res == null) return null;
      return PickedMediaResult(
        pathOrDataUrl: res['pathOrDataUrl'] as String,
        fileName: res['fileName'] as String? ?? 'image.jpg',
        fileSize: (res['fileSize'] as num?)?.toInt() ?? 0,
        mediaType: res['mediaType'] as String? ?? 'image',
        extension: res['extension'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PickedMediaResult?> pickVideo() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickVideo');
      if (res == null) return null;
      return PickedMediaResult(
        pathOrDataUrl: res['pathOrDataUrl'] as String,
        fileName: res['fileName'] as String? ?? 'video.mp4',
        fileSize: (res['fileSize'] as num?)?.toInt() ?? 0,
        mediaType: res['mediaType'] as String? ?? 'video',
        extension: res['extension'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PickedMediaResult?> pickDocument() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickDocument');
      if (res == null) return null;
      return PickedMediaResult(
        pathOrDataUrl: res['pathOrDataUrl'] as String,
        fileName: res['fileName'] as String? ?? 'document',
        fileSize: (res['fileSize'] as num?)?.toInt() ?? 0,
        mediaType: res['mediaType'] as String? ?? 'document',
        extension: res['extension'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
