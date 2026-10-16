import 'dart:typed_data';

import 'document_bytes_loader_stub.dart'
    if (dart.library.html) 'document_bytes_loader_web.dart'
    if (dart.library.io) 'document_bytes_loader_io.dart';
import 'storage_picker.dart';

Future<Uint8List> loadPickedDocumentBytes(PickedMediaResult picked) =>
    loadDocumentBytes(picked.pathOrDataUrl);

Future<Uint8List> loadDocumentSourceBytes(String source) =>
    loadDocumentBytes(source);
