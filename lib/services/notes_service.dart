import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/book_note.dart';
import 'document_bytes_loader.dart';
import 'storage_picker.dart';
import 'supabase_service.dart';

class PreparedPdf {
  final PickedMediaResult picked;
  final Uint8List bytes;
  final int pageCount;

  const PreparedPdf({
    required this.picked,
    required this.bytes,
    required this.pageCount,
  });
}

class StarToggleResult {
  final bool isStarred;
  final int starCount;

  const StarToggleResult({
    required this.isStarred,
    required this.starCount,
  });
}

class NotesService {
  static const _table = 'note_documents';
  static const _bucket = 'notes-pdfs';
  static const _coverBucket = 'note-covers';
  static const _maxCoverBytes = 8 * 1024 * 1024;

  static SupabaseClient get _client => SupabaseService.client;

  static int previewPageCount(int totalPages) =>
      math.max(1, (totalPages * 0.20).ceil());

  static bool canAccessFullPdf({
    required bool isFree,
    required bool hasCompletedPurchase,
  }) =>
      isFree || hasCompletedPurchase;

  static Future<PreparedPdf> preparePdf(PickedMediaResult picked) async {
    if ((picked.extension ?? '').toLowerCase() != 'pdf') {
      throw const FormatException('Please select a PDF file.');
    }

    final bytes = await loadPickedDocumentBytes(picked);
    if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw const FormatException('The selected file is not a valid PDF.');
    }

    await pdfrxFlutterInitialize();
    final document = await PdfDocument.openData(
      bytes,
      sourceName: picked.fileName,
      useProgressiveLoading: false,
    );
    try {
      final pages = document.pages.length;
      if (pages < 1) {
        throw const FormatException('The PDF does not contain any pages.');
      }
      return PreparedPdf(picked: picked, bytes: bytes, pageCount: pages);
    } finally {
      await document.dispose();
    }
  }

  static Future<Uint8List> _createPreviewPdf(
    Uint8List bytes,
    int pageCount,
    String fileName,
  ) async {
    final source = await PdfDocument.openData(
      bytes,
      sourceName: fileName,
      useProgressiveLoading: false,
    );
    final preview =
        await PdfDocument.createNew(sourceName: 'preview-$fileName');
    try {
      preview.pages = source.pages.take(pageCount).toList();
      return await preview.encodePdf();
    } finally {
      await preview.dispose();
      await source.dispose();
    }
  }

  static Future<BookNote> uploadDocument({
    required PreparedPdf pdf,
    PickedMediaResult? cover,
    required String title,
    required String author,
    required String category,
    required bool isPaid,
    required double price,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before uploading a PDF.');
    }

    final safeName = pdf.picked.fileName
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final basePath = '${user.id}/$stamp';
    final fullPath = '${basePath}_$safeName';
    final previewPath = isPaid ? '${basePath}_preview.pdf' : null;
    final uploadedPaths = <String>[];
    String? coverPath;

    try {
      await _client.storage.from(_bucket).uploadBinary(
            fullPath,
            pdf.bytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: false,
            ),
          );
      uploadedPaths.add(fullPath);

      if (previewPath != null) {
        final previewBytes = await _createPreviewPdf(
          pdf.bytes,
          previewPageCount(pdf.pageCount),
          pdf.picked.fileName,
        );
        await _client.storage.from(_bucket).uploadBinary(
              previewPath,
              previewBytes,
              fileOptions: const FileOptions(
                contentType: 'application/pdf',
                upsert: false,
              ),
            );
        uploadedPaths.add(previewPath);
      }

      if (cover != null) {
        final extension = _validatedCoverExtension(cover);
        final coverBytes = await loadPickedDocumentBytes(cover);
        if (coverBytes.isEmpty || coverBytes.length > _maxCoverBytes) {
          throw const FormatException(
            'Cover image must be smaller than 8 MB.',
          );
        }
        coverPath = '${user.id}/${stamp}_cover.$extension';
        await _client.storage.from(_coverBucket).uploadBinary(
              coverPath,
              coverBytes,
              fileOptions: FileOptions(
                contentType: _coverContentType(extension),
                upsert: false,
              ),
            );
      }

      final row = await _client
          .from(_table)
          .insert({
            'owner_id': user.id,
            'title': title,
            'author': author.isEmpty ? 'Unknown' : author,
            'category': category,
            'page_count': pdf.pageCount,
            'is_paid': isPaid,
            'price': isPaid ? price : 0,
            'storage_path': fullPath,
            'preview_storage_path': previewPath,
            'file_name': pdf.picked.fileName,
            'file_size_bytes': pdf.bytes.length,
            'cover_storage_path': coverPath,
          })
          .select()
          .single();
      return _bookFromRow(row);
    } catch (_) {
      if (uploadedPaths.isNotEmpty) {
        try {
          await _client.storage.from(_bucket).remove(uploadedPaths);
        } catch (_) {}
      }
      if (coverPath != null) {
        try {
          await _client.storage.from(_coverBucket).remove([coverPath]);
        } catch (_) {}
      }
      rethrow;
    }
  }

  static String _validatedCoverExtension(PickedMediaResult cover) {
    final extension =
        (cover.extension ?? '').toLowerCase().replaceFirst('jpeg', 'jpg');
    if (!const {'jpg', 'png', 'webp'}.contains(extension)) {
      throw const FormatException('Cover must be a JPG, PNG, or WebP image.');
    }
    return extension;
  }

  static String _coverContentType(String extension) => switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  static Future<List<BookNote>> fetchDocuments() async {
    final rows = await _client
        .from(_table)
        .select('*, note_document_stars(user_id)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows).map(_bookFromRow).toList();
  }

  static Future<StarToggleResult> toggleStar(BookNote book) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to star this PDF.');
    }

    if (book.isStarred) {
      await _client
          .from('note_document_stars')
          .delete()
          .eq('document_id', book.id)
          .eq('user_id', user.id);
    } else {
      await _client.from('note_document_stars').insert({
        'document_id': book.id,
        'user_id': user.id,
      });
    }

    final row = await _client
        .from(_table)
        .select('star_count')
        .eq('id', book.id)
        .single();
    return StarToggleResult(
      isStarred: !book.isStarred,
      starCount: (row['star_count'] as num?)?.toInt() ?? 0,
    );
  }

  static Future<Uint8List> loadPdfBytes(
    BookNote book, {
    required bool fullDocument,
  }) async {
    final path = fullDocument
        ? book.storagePath
        : (book.previewStoragePath ?? book.storagePath);
    if (path != null && path.isNotEmpty) {
      return _client.storage.from(_bucket).download(path);
    }

    final source = book.pdfUrl;
    if (source == null || source.isEmpty) {
      throw StateError('No PDF file is attached to this document.');
    }
    return loadDocumentSourceBytes(source);
  }

  static Future<void> deleteDocument(BookNote book) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before deleting a PDF.');
    }
    if (book.ownerId != user.id) {
      throw StateError('Only the PDF owner can delete this document.');
    }

    final storagePaths = <String>[];
    if (book.storagePath != null && book.storagePath!.isNotEmpty) {
      storagePaths.add(book.storagePath!);
    }
    if (book.previewStoragePath != null &&
        book.previewStoragePath!.isNotEmpty &&
        !storagePaths.contains(book.previewStoragePath)) {
      storagePaths.add(book.previewStoragePath!);
    }

    if (storagePaths.isNotEmpty) {
      await _client.storage.from(_bucket).remove(storagePaths);
    }
    if (book.coverStoragePath != null && book.coverStoragePath!.isNotEmpty) {
      await _client.storage.from(_coverBucket).remove([book.coverStoragePath!]);
    }

    final deletedRows = await _client
        .from(_table)
        .delete()
        .eq('id', book.id)
        .eq('owner_id', user.id)
        .select('id');
    if (List<Map<String, dynamic>>.from(deletedRows).isEmpty) {
      throw StateError('The PDF was not deleted. Refresh and try again.');
    }
  }

  static Future<void> updateDocumentAccess(
    BookNote book, {
    required bool isPaid,
    double price = 0,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before changing PDF access.');
    }
    if (book.ownerId != user.id) {
      throw StateError('Only the PDF owner can change its access.');
    }
    if (isPaid && price <= 0) {
      throw const FormatException('Enter a valid price for this paid PDF.');
    }

    String? newPreviewPath;
    if (isPaid &&
        (book.previewStoragePath == null || book.previewStoragePath!.isEmpty)) {
      final fullBytes = await loadPdfBytes(book, fullDocument: true);
      final fileName = book.fileName ?? '${book.title}.pdf';
      final previewBytes = await _createPreviewPdf(
        fullBytes,
        previewPageCount(book.pages),
        fileName,
      );
      newPreviewPath =
          '${user.id}/${DateTime.now().microsecondsSinceEpoch}_preview.pdf';
      await _client.storage.from(_bucket).uploadBinary(
            newPreviewPath,
            previewBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: false,
            ),
          );
    }

    final existingPreviewPath = book.previewStoragePath;
    final previewPath = isPaid
        ? (existingPreviewPath != null && existingPreviewPath.isNotEmpty
            ? existingPreviewPath
            : newPreviewPath)
        : null;
    try {
      final updatedRows = await _client
          .from(_table)
          .update({
            'is_paid': isPaid,
            'price': isPaid ? price : 0,
            'preview_storage_path': previewPath,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', book.id)
          .eq('owner_id', user.id)
          .select('id');
      if (List<Map<String, dynamic>>.from(updatedRows).isEmpty) {
        throw StateError('Access was not changed. Refresh and try again.');
      }
    } catch (_) {
      if (newPreviewPath != null) {
        try {
          await _client.storage.from(_bucket).remove([newPreviewPath]);
        } catch (_) {}
      }
      rethrow;
    }

    if (!isPaid &&
        book.previewStoragePath != null &&
        book.previewStoragePath!.isNotEmpty) {
      try {
        await _client.storage.from(_bucket).remove([book.previewStoragePath!]);
      } catch (_) {
        // The document is already free; a stale preview is harmless and private.
      }
    }
  }

  static Future<String> downloadPdf(BookNote book) async {
    final bytes = await loadPdfBytes(book, fullDocument: true);
    final baseName = (book.fileName ?? book.title)
        .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return FileSaver.instance.saveFile(
      name: baseName,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static BookNote _bookFromRow(Map<String, dynamic> row) {
    final isPaid = row['is_paid'] == true;
    final pageCount = (row['page_count'] as num).toInt();
    final rawPrice = row['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;
    final title = row['title']?.toString() ?? 'Untitled PDF';
    final coverStoragePath = row['cover_storage_path']?.toString();
    final coverImageUrl = coverStoragePath == null || coverStoragePath.isEmpty
        ? null
        : _client.storage.from(_coverBucket).getPublicUrl(coverStoragePath);
    final ownStars = row['note_document_stars'];
    return BookNote(
      id: row['id'].toString(),
      title: title,
      subtitle: 'PDF document • $pageCount pages',
      author: row['author']?.toString() ?? 'Unknown',
      category: row['category']?.toString() ?? 'Document',
      rating: 0,
      reviewCount: 0,
      starCount: (row['star_count'] as num?)?.toInt() ?? 0,
      isStarred: ownStars is List && ownStars.isNotEmpty,
      pages: pageCount,
      price: isPaid ? '₹${price.toStringAsFixed(0)}' : 'Free',
      isFree: !isPaid,
      badge: 'PDF',
      primaryColor: const Color(0xFF0F172A),
      secondaryColor: const Color(0xFF2563EB),
      categoryIcon: LucideIcons.fileText,
      coverCodeSnippet: '',
      description: isPaid
          ? '${previewPageCount(pageCount)} of $pageCount pages available in the free preview.'
          : 'All $pageCount PDF pages are available to read and download.',
      keyTakeaways: [
        '$pageCount real PDF pages',
        isPaid ? '20% preview before purchase' : 'Free full-document access',
        'Stored securely in Supabase',
      ],
      fullReviewSummary: 'Uploaded PDF document.',
      reviews: const [],
      chapters: const [],
      readTime: '${math.max(1, (pageCount * 1.5).round())} mins',
      difficulty: 'Reference',
      isFeatured: true,
      coverImageUrl: coverImageUrl,
      coverStoragePath: coverStoragePath,
      ownerId: row['owner_id']?.toString(),
      storagePath: row['storage_path']?.toString(),
      previewStoragePath: row['preview_storage_path']?.toString(),
      fileName: row['file_name']?.toString(),
      fileSizeBytes: (row['file_size_bytes'] as num?)?.toInt(),
    );
  }
}
