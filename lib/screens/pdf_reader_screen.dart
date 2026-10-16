import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/book_note.dart';
import '../services/notes_service.dart';

class PdfReaderScreen extends StatefulWidget {
  final BookNote book;
  final bool fullDocument;
  final VoidCallback? onUnlockRequested;

  const PdfReaderScreen({
    super.key,
    required this.book,
    required this.fullDocument,
    this.onUnlockRequested,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  late final Future<Uint8List> _pdfBytes;

  @override
  void initState() {
    super.initState();
    _pdfBytes = NotesService.loadPdfBytes(
      widget.book,
      fullDocument: widget.fullDocument,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visiblePages =
        widget.fullDocument ? widget.book.pages : widget.book.previewPages;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111216),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.fullDocument
                  ? '${widget.book.pages} pages • Full PDF'
                  : '$visiblePages readable • ${widget.book.pages} pages total',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfBytes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ReaderMessage(
              icon: LucideIcons.fileWarning,
              title: 'Unable to open this PDF',
              message: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF54C5F8)),
            );
          }

          return PdfDocumentViewBuilder(
            documentRef: PdfDocumentRefData(
              snapshot.data!,
              sourceName:
                  '${widget.book.id}-${widget.fullDocument ? "full" : "preview"}.pdf',
              useProgressiveLoading: false,
            ),
            loadingBuilder: (_) => const Center(
              child: CircularProgressIndicator(color: Color(0xFF54C5F8)),
            ),
            errorBuilder: (_, error, __) => _ReaderMessage(
              icon: LucideIcons.fileWarning,
              title: 'Invalid PDF',
              message: error.toString(),
            ),
            builder: (context, document) {
              if (document == null) return const SizedBox.shrink();
              final renderedPages = document.pages.length;
              final itemCount = widget.book.pages;

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final isLockedPage =
                      !widget.fullDocument && index >= visiblePages;
                  if (isLockedPage || index >= renderedPages) {
                    return _LockedPagePlaceholder(
                      pageNumber: index + 1,
                      totalPages: widget.book.pages,
                      onUnlockRequested: widget.onUnlockRequested,
                    );
                  }

                  final page = document.pages[index];
                  final availableWidth =
                      (MediaQuery.sizeOf(context).width - 24).clamp(220, 1000);
                  final pageHeight = availableWidth * page.height / page.width;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      children: [
                        SizedBox(
                          width: availableWidth.toDouble(),
                          height: pageHeight,
                          child: PdfPageView(
                            document: document,
                            pageNumber: index + 1,
                            maximumDpi: 180,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Page ${index + 1} of ${widget.book.pages}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar:
          widget.fullDocument || widget.onUnlockRequested == null
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF111216),
                      border: Border(
                        top: BorderSide(color: Color(0x22FFFFFF)),
                      ),
                    ),
                    child: FilledButton.icon(
                      onPressed: widget.onUnlockRequested,
                      icon: const Icon(LucideIcons.creditCard, size: 18),
                      label: Text(
                        'Unlock all ${widget.book.pages} pages • ${widget.book.price}',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _LockedPagePlaceholder extends StatelessWidget {
  final int pageNumber;
  final int totalPages;
  final VoidCallback? onUnlockRequested;

  const _LockedPagePlaceholder({
    required this.pageNumber,
    required this.totalPages,
    required this.onUnlockRequested,
  });

  @override
  Widget build(BuildContext context) {
    final availableWidth =
        (MediaQuery.sizeOf(context).width - 24).clamp(220, 1000).toDouble();
    final pageHeight = availableWidth * 1.414;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: availableWidth,
              height: pageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          12,
                          (line) => Container(
                            height: line % 4 == 0 ? 18 : 9,
                            width: line % 3 == 0
                                ? availableWidth * 0.55
                                : availableWidth * 0.82,
                            margin: const EdgeInsets.only(bottom: 18),
                            color: line % 4 == 0
                                ? const Color(0xFF64748B)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(color: const Color(0x99090A0D)),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xE8151821),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0x6654C5F8)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.lockKeyhole,
                            color: Color(0xFF54C5F8),
                            size: 30,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Page $pageNumber is locked',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Complete payment to read and download the full PDF.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12.5,
                            ),
                          ),
                          if (onUnlockRequested != null) ...[
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: onUnlockRequested,
                              icon: const Icon(
                                LucideIcons.creditCard,
                                size: 16,
                              ),
                              label: const Text('Unlock full PDF'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Page $pageNumber of $totalPages',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ReaderMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ReaderMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.orangeAccent, size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
