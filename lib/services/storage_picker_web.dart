// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'storage_picker.dart';

StoragePickerBase getPlatformStoragePicker() => StoragePickerWeb();

class StoragePickerWeb implements StoragePickerBase {
  @override
  Future<PickedMediaResult?> pickImage({bool fromCamera = false}) async {
    final completer = Completer<PickedMediaResult?>();
    final input = html.FileUploadInputElement()..accept = 'image/*';
    if (fromCamera) {
      input.setAttribute('capture', 'camera');
    }
    input.style.display = 'none';
    html.document.body?.append(input);

    Timer? cancelTimer;
    void cleanup() {
      cancelTimer?.cancel();
      try {
        input.remove();
      } catch (_) {}
    }

    input.onChange.listen((e) {
      cleanup();
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((e) {
        final result = reader.result as String;
        final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
        if (!completer.isCompleted) {
          completer.complete(PickedMediaResult(
            pathOrDataUrl: result,
            fileName: file.name,
            fileSize: file.size,
            mediaType: 'image',
            extension: ext,
          ));
        }
      });
    });

    input.click();

    // Fallback if user cancels file chooser
    cancelTimer = Timer(const Duration(seconds: 45), () {
      cleanup();
      if (!completer.isCompleted) completer.complete(null);
    });

    return completer.future;
  }

  @override
  Future<PickedMediaResult?> pickVideo() async {
    final completer = Completer<PickedMediaResult?>();
    final input = html.FileUploadInputElement()..accept = 'video/*';
    input.style.display = 'none';
    html.document.body?.append(input);

    Timer? cancelTimer;
    void cleanup() {
      cancelTimer?.cancel();
      try {
        input.remove();
      } catch (_) {}
    }

    input.onChange.listen((e) {
      cleanup();
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((e) {
        final result = reader.result as String;
        final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'mp4';
        if (!completer.isCompleted) {
          completer.complete(PickedMediaResult(
            pathOrDataUrl: result,
            fileName: file.name,
            fileSize: file.size,
            mediaType: 'video',
            extension: ext,
          ));
        }
      });
    });

    input.click();

    cancelTimer = Timer(const Duration(seconds: 45), () {
      cleanup();
      if (!completer.isCompleted) completer.complete(null);
    });

    return completer.future;
  }

  @override
  Future<PickedMediaResult?> pickDocument() async {
    final completer = Completer<PickedMediaResult?>();
    final input = html.FileUploadInputElement()
      ..accept = '.pdf,.doc,.docx,.txt,.json,.dart,.csv,.zip,.png,.jpg,.jpeg';
    input.style.display = 'none';
    html.document.body?.append(input);

    Timer? cancelTimer;
    void cleanup() {
      cancelTimer?.cancel();
      try {
        input.remove();
      } catch (_) {}
    }

    input.onChange.listen((e) {
      cleanup();
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((e) {
        final result = reader.result as String;
        final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'pdf';
        if (!completer.isCompleted) {
          completer.complete(PickedMediaResult(
            pathOrDataUrl: result,
            fileName: file.name,
            fileSize: file.size,
            mediaType: 'document',
            extension: ext,
          ));
        }
      });
    });

    input.click();

    cancelTimer = Timer(const Duration(seconds: 45), () {
      cleanup();
      if (!completer.isCompleted) completer.complete(null);
    });

    return completer.future;
  }
}
