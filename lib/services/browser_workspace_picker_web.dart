// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'browser_workspace_selection.dart';

const _maxFiles = 400;
const _maxFileBytes = 5 * 1024 * 1024;
const _maxTotalBytes = 32 * 1024 * 1024;

Future<BrowserWorkspaceSelection?> pickBrowserWorkspace({
  required bool folder,
}) async {
  final input = html.FileUploadInputElement()
    ..multiple = folder
    ..style.display = 'none';
  if (folder) {
    input.setAttribute('webkitdirectory', '');
    input.setAttribute('directory', '');
  }

  html.document.body?.append(input);
  final completer = Completer<List<html.File>?>();
  late StreamSubscription<html.Event> changeSubscription;
  StreamSubscription<html.Event>? focusSubscription;

  changeSubscription = input.onChange.listen((_) {
    if (!completer.isCompleted) {
      completer.complete(input.files?.toList() ?? const <html.File>[]);
    }
  });
  focusSubscription = html.window.onFocus.listen((_) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!completer.isCompleted) {
      completer.complete(input.files?.toList() ?? const <html.File>[]);
    }
  });

  input.click();
  final selected = await completer.future;
  await changeSubscription.cancel();
  await focusSubscription.cancel();
  input.remove();
  if (selected == null || selected.isEmpty) return null;

  final files = <String, String>{};
  var skipped = 0;
  var totalBytes = 0;
  final firstRelative = selected.first.relativePath?.replaceAll('\\', '/');
  final rootName =
      folder && firstRelative != null && firstRelative.contains('/')
          ? firstRelative.split('/').first
          : selected.first.name.replaceFirst(RegExp(r'\.[^.]+$'), '');

  for (final file in selected.take(_maxFiles)) {
    if (file.size > _maxFileBytes || totalBytes + file.size > _maxTotalBytes) {
      skipped++;
      continue;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    final result = reader.result;
    final bytes = switch (result) {
      ByteBuffer value => Uint8List.view(value),
      Uint8List value => value,
      _ => null,
    };
    if (bytes == null || bytes.contains(0)) {
      skipped++;
      continue;
    }
    try {
      final content = utf8.decode(bytes, allowMalformed: false);
      var path = (file.relativePath?.isNotEmpty == true
              ? file.relativePath!
              : file.name)
          .replaceAll('\\', '/');
      if (folder && path.startsWith('$rootName/')) {
        path = path.substring(rootName.length + 1);
      }
      if (path.isEmpty || path.split('/').any((part) => part == '..')) {
        skipped++;
        continue;
      }
      files[path] = content;
      totalBytes += bytes.length;
    } on FormatException {
      skipped++;
    }
  }
  skipped += selected.length > _maxFiles ? selected.length - _maxFiles : 0;
  if (files.isEmpty) return null;
  return BrowserWorkspaceSelection(
    projectName: rootName.isEmpty ? 'Imported_Project' : rootName,
    files: files,
    skippedFiles: skipped,
    totalBytes: totalBytes,
  );
}
