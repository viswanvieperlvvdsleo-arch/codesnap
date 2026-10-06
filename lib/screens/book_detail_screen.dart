import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/book_note.dart';
import '../utils/app_animations.dart';
import '../widgets/spring_button.dart';
import '../services/payment_service.dart';
import '../widgets/morphing_capsule.dart';
import '../widgets/expandable_text.dart';
import '../services/browser_launcher.dart';

class BookDetailScreen extends StatefulWidget {
  final BookNote book;
  final String? heroTag;
  final VoidCallback? onBookmarkToggle;

  const BookDetailScreen({
    super.key,
    required this.book,
    this.heroTag,
    this.onBookmarkToggle,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  late BookNote _book;
  late TabController _tabController;
  int _selectedTab = 0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleBookmark() {
    setState(() {
      _book.isBookmarked = !_book.isBookmarked;
    });
    widget.onBookmarkToggle?.call();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xEB18181B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        content: Row(
          children: [
            Icon(
              _book.isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmarkMinus,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              _book.isBookmarked ? 'Added to Saved Books' : 'Removed from Saved Books',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool get _isUnlocked => _book.isFree || PaymentService.instance.isItemUnlocked(_book.id);

  void _triggerReadNow() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildReadingReaderSheet(ctx),
    );
  }

  void _triggerDownload() async {
    if (!_isUnlocked) {
      _showPaymentModal(context, forDownload: true);
      return;
    }
    setState(() => _isDownloading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isDownloading = false);
      MorphingCapsule.show(
        context,
        icon: LucideIcons.checkCheck,
        label: '${_book.title} downloaded to internal storage!',
        color: const Color(0xFF10B981),
      );
    }
  }

  void _showPaymentModal(BuildContext context, {bool forDownload = false}) {
    String selectedMethod = 'Apple Pay';
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0E17).withOpacity(0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(LucideIcons.creditCard, color: Color(0xFF54C5F8), size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Unlock Full Document',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalCtx),
                        icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    forDownload
                        ? 'Payment Required: Unlock all ${_book.pages} pages to enable offline download.'
                        : 'Unlock 100% of ${_book.pages} pages (currently previewing first 5% only).',
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF54C5F8).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_book.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('${_book.pages} Pages PDF • Lifetime Access', style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 11.5)),
                            ],
                          ),
                        ),
                        Text(
                          _book.price,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text('Select Payment Method', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...['Apple Pay', 'Google Pay', 'Credit Card (•••• 4242)', 'UPI / Instant Pay'].map((method) {
                    final isSel = selectedMethod == method;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedMethod = method),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF54C5F8).withOpacity(0.15) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSel ? const Color(0xFF54C5F8) : Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(method, style: TextStyle(color: isSel ? Colors.white : Colors.white70, fontSize: 13.5, fontWeight: isSel ? FontWeight.bold : FontWeight.w500)),
                            Icon(isSel ? LucideIcons.checkCircle2 : LucideIcons.circle, color: isSel ? const Color(0xFF54C5F8) : Colors.white30, size: 18),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  SpringButton(
                    onTap: isProcessing
                        ? () {}
                        : () async {
                            setModalState(() => isProcessing = true);
                            await PaymentService.instance.processPayment(
                              itemId: _book.id,
                              itemTitle: _book.title,
                              amount: double.tryParse(_book.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 4.99,
                              method: selectedMethod,
                            );
                            if (mounted) {
                              setState(() {});
                              Navigator.pop(modalCtx);
                              MorphingCapsule.show(
                                context,
                                icon: LucideIcons.checkCheck,
                                label: 'Unlocked! Full document ready',
                                color: const Color(0xFF10B981),
                              );
                              if (forDownload) {
                                _triggerDownload();
                              }
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF54C5F8), Color(0xFF2563EB)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF54C5F8).withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: isProcessing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              'Pay ${_book.price} & Unlock Full Document',
                              style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBooks = BookNoteData.getAllBooks();
    final suggestions = allBooks.where((b) => b.id != _book.id).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          // Background ambient frosted glass lights (strictly glass white / deep obsidian)
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 220,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            top: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Flexible Glass App Bar
                _buildSliverAppBar(),

                // Book Details & Highlights
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildBookMetaSection(),
                        const SizedBox(height: 20),
                        _buildQuickMetricsBar(),
                        const SizedBox(height: 22),
                        _buildActionButtonsBar(),
                        const SizedBox(height: 28),
                        _buildSegmentedTabHeader(),
                        const SizedBox(height: 20),
                        _buildTabContent(),
                        const SizedBox(height: 36),
                        _buildDownSuggestionsSection(suggestions),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Flexible Glass App Bar ──────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xCC09090B),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SpringButton(
          onTap: () => Navigator.of(context).pop(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: SpringButton(
            onTap: _toggleBookmark,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _book.isBookmarked
                        ? const Color(0x4DFFFFFF)
                        : const Color(0x26FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _book.isBookmarked
                          ? Colors.white
                          : const Color(0x33FFFFFF),
                    ),
                  ),
                  child: Icon(
                    _book.isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, right: 16),
          child: SpringButton(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Book link copied to clipboard!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: const Icon(LucideIcons.share2, color: Colors.white, size: 19),
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Liquid Glass Hero Book Cover
            Positioned(
              bottom: 24,
              child: Hero(
                tag: widget.heroTag ?? 'book-cover-${_book.id}',
                child: Container(
                  width: 175,
                  height: 235,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: _book.coverImageUrl != null
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _book.primaryColor,
                              _book.secondaryColor,
                              const Color(0xFF121216),
                            ],
                          ),
                    image: _book.coverImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_book.coverImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.55),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.08),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x33FFFFFF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0x26FFFFFF)),
                            ),
                            child: Text(
                              _book.category.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Icon(_book.categoryIcon, color: Colors.white70, size: 16),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        _book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_book.coverImageUrl == null && _book.coverCodeSnippet.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            _book.coverCodeSnippet,
                            style: GoogleFonts.firaCode(
                              color: Colors.white70,
                              fontSize: 8.5,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Book Meta (Title, Author, Rating) ───────────────────────────────────────
  Widget _buildBookMetaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge + Category Row
        Row(
          children: [
            if (_book.badge != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x40FFFFFF)),
                    ),
                    child: Text(
                      _book.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x26FFFFFF)),
              ),
              child: Text(
                _book.category,
                style: const TextStyle(
                  color: Color(0xDEFFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            // Rating pill in liquid glass
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.star, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    _book.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${_book.reviewCount})',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Title
        Text(
          _book.title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        if (_book.subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _book.subtitle,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        const SizedBox(height: 10),

        // Author
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x26FFFFFF),
                border: Border.all(color: const Color(0x40FFFFFF)),
              ),
              alignment: Alignment.center,
              child: Text(
                _book.author.isNotEmpty ? _book.author[0] : 'A',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _book.author,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.badgeCheck, color: Colors.white70, size: 15),
          ],
        ),
      ],
    );
  }

  // ── Quick Metrics Bar ───────────────────────────────────────────────────────
  Widget _buildQuickMetricsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(LucideIcons.bookOpen, '${_book.pages}', 'Pages'),
          _buildDivider(),
          _buildMetricItem(LucideIcons.clock, _book.readTime, 'Read Time'),
          _buildDivider(),
          _buildMetricItem(LucideIcons.gauge, _book.difficulty, 'Level'),
          _buildDivider(),
          _buildMetricItem(
            LucideIcons.indianRupee,
            _book.price,
            _book.isFree ? 'Free Forever' : 'Price',
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label, {bool highlight = false}) {
    return Column(
      children: [
        Icon(
          icon,
          size: 17,
          color: Colors.white,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0x80FFFFFF),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0x1FFFFFFF),
    );
  }

  // ── Action Buttons ─────────────────────────────────────────────────────────
  Widget _buildActionButtonsBar() {
    return Row(
      children: [
        // Read Now Button in Liquid Glass
        Expanded(
          flex: 3,
          child: SpringButton(
            onTap: _triggerReadNow,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x59FFFFFF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.bookOpen, color: Colors.white, size: 19),
                      SizedBox(width: 8),
                      Text(
                        'Read Notes Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Download / Offline PDF
        Expanded(
          flex: 2,
          child: SpringButton(
            onTap: _triggerDownload,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isDownloading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else ...[
                        const Icon(LucideIcons.download, color: Colors.white, size: 17),
                        const SizedBox(width: 6),
                        const Text(
                          'Offline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Segmented Tab Header ───────────────────────────────────────────────────
  Widget _buildSegmentedTabHeader() {
    final tabs = ['Overview', 'Full Review', 'Chapters (${_book.chapters.length})'];
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = index);
                _tabController.animateTo(index);
              },
              child: AnimatedContainer(
                duration: AppAnimations.quick,
                curve: AppAnimations.snappy,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0x38FFFFFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected ? Border.all(color: const Color(0x33FFFFFF)) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0x80FFFFFF),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Tab Content ────────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildReviewTab();
      case 2:
        return _buildChaptersTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // 1. Overview Tab
  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Text(
          'About this Book',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _book.description,
          style: GoogleFonts.inter(
            color: const Color(0xCCFFFFFF),
            fontSize: 13,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 20),

        // Key Takeaways
        Text(
          'Key Takeaways & Core Concepts',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(_book.keyTakeaways.length, (i) {
          final item = _book.keyTakeaways[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x4DFFFFFF)),
                  ),
                  child: const Icon(LucideIcons.check, color: Colors.white, size: 11),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Color(0xDEFFFFFF),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // 2. Full Review Tab
  Widget _buildReviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editorial Summary Glass Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x26FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.sparkles, color: Colors.white, size: 17),
                  const SizedBox(width: 8),
                  Text(
                    'CodeSnap Editorial Verdict',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x26FFFFFF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x40FFFFFF)),
                    ),
                    child: const Text(
                      'MUST READ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _book.fullReviewSummary,
                style: GoogleFonts.inter(
                  color: const Color(0xCCFFFFFF),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Community Reader Reviews
        Text(
          'Community Reviews',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_book.reviews.length, (index) {
          final review = _book.reviews[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0x26FFFFFF),
                      child: Text(
                        review.avatarInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.authorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            review.authorRole,
                            style: const TextStyle(
                              color: Color(0x80FFFFFF),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(5, (starIdx) {
                        return Icon(
                          LucideIcons.star,
                          size: 11,
                          color: starIdx < review.rating.floor()
                              ? Colors.white
                              : Colors.white24,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  review.comment,
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // 3. Chapters Tab
  Widget _buildChaptersTab() {
    return Column(
      children: List.generate(_book.chapters.length, (i) {
        final ch = _book.chapters[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${ch.number}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ch.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ch.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0x80FFFFFF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ch.duration,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── "Down Suggestions" (You Might Also Like) ───────────────────────────────
  Widget _buildDownSuggestionsSection(List<BookNote> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.sparkle, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Down Suggestions & Related Notes',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Text(
              'Swipe >',
              style: TextStyle(color: Color(0x80FFFFFF), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final sugBook = suggestions[index];
              return SpringButton(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      transitionDuration: AppAnimations.expressive,
                      pageBuilder: (_, __, ___) => BookDetailScreen(book: sugBook),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Container(
                  width: 135,
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x26FFFFFF)),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mini Cover Art in smoked glass
                      Container(
                        height: 95,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              sugBook.primaryColor,
                              sugBook.secondaryColor,
                            ],
                          ),
                          border: Border.all(color: Colors.white24),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sugBook.category.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              sugBook.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sugBook.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sugBook.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0x80FFFFFF),
                          fontSize: 9.5,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.star, color: Colors.white, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                '${sugBook.rating}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            sugBook.price,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── In-App Document & Reader Modal ──────────────────────────────────────
  Widget _buildReadingReaderSheet(BuildContext ctx) {
    final previewPages = (_book.pages * 0.05).ceil().clamp(1, _book.pages);
    int currentPage = 1;
    bool isPaperMode = false;

    return StatefulBuilder(
      builder: (readerCtx, setReaderState) {
        final isUnlocked = _isUnlocked;
        final isPageLocked = !isUnlocked && currentPage > previewPages;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.90,
          decoration: const BoxDecoration(
            color: Color(0xFF101117),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0x33FFFFFF))),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Reader Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF54C5F8).withOpacity(0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.fileText, color: Color(0xFF54C5F8), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Page $currentPage of ${_book.pages} • ${isUnlocked ? "Full Document Unlocked" : "5% Preview Mode"}',
                            style: TextStyle(
                              color: isUnlocked ? const Color(0xFF10B981) : const Color(0xFF54C5F8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Paper / Dark mode toggle
                    IconButton(
                      tooltip: isPaperMode ? 'Switch to Dark Mode' : 'Switch to Paper Mode',
                      onPressed: () => setReaderState(() => isPaperMode = !isPaperMode),
                      icon: Icon(
                        isPaperMode ? LucideIcons.moon : LucideIcons.sun,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0x1FFFFFFF), height: 1),

              // Page Navigation Controls Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white.withOpacity(0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
                    SpringButton(
                      onTap: () {
                        if (currentPage > 1) {
                          setReaderState(() => currentPage--);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: currentPage > 1 ? Colors.white.withOpacity(0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.chevronLeft, size: 14, color: currentPage > 1 ? Colors.white : Colors.white24),
                            const SizedBox(width: 4),
                            Text(
                              'Prev',
                              style: TextStyle(
                                color: currentPage > 1 ? Colors.white : Colors.white24,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Quick Page Jump Pills
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: List.generate(_book.pages, (index) {
                            final pageNum = index + 1;
                            final isCur = pageNum == currentPage;
                            final isLockedChip = !isUnlocked && pageNum > previewPages;

                            return GestureDetector(
                              onTap: () => setReaderState(() => currentPage = pageNum),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isCur
                                      ? const Color(0xFF54C5F8)
                                      : (isLockedChip ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.08)),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isCur
                                        ? const Color(0xFF54C5F8)
                                        : (isLockedChip ? Colors.white10 : Colors.white24),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLockedChip) ...[
                                      Icon(LucideIcons.lock, size: 9, color: isCur ? Colors.black : Colors.white38),
                                      const SizedBox(width: 3),
                                    ],
                                    Text(
                                      'p.$pageNum',
                                      style: TextStyle(
                                        color: isCur ? Colors.black : (isLockedChip ? Colors.white38 : Colors.white70),
                                        fontSize: 10.5,
                                        fontWeight: isCur ? FontWeight.w800 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    // Next button
                    SpringButton(
                      onTap: () {
                        if (currentPage < _book.pages) {
                          setReaderState(() => currentPage++);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: currentPage < _book.pages ? Colors.white.withOpacity(0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                color: currentPage < _book.pages ? Colors.white : Colors.white24,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(LucideIcons.chevronRight, size: 14, color: currentPage < _book.pages ? Colors.white : Colors.white24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page Display Canvas
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isPaperMode ? const Color(0xFFF9F7F1) : const Color(0xFF161822),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPaperMode ? const Color(0xFFE5DEC9) : Colors.white.withOpacity(0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: isPageLocked
                            // 🔒 LOCKED PAGE VIEW
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Fake blurred content in background
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ImageFiltered(
                                      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        color: isPaperMode ? Colors.black.withOpacity(0.04) : Colors.white.withOpacity(0.03),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Section $currentPage: In-Depth Architecture & Production Guide',
                                              style: GoogleFonts.inter(
                                                color: isPaperMode ? Colors.black87 : Colors.white70,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'In this section we cover end-to-end multi-tier architectural implementations, state serialization pipelines, and reactive client-server communication channels.\n\nCode samples, schemas, diagrams, performance benchmarks, and automated test runners for large scale enterprise solutions.\n\nComprehensive review of optimization tradeoffs, memory allocation safety, and runtime fault tolerance protocols.',
                                              style: GoogleFonts.inter(
                                                color: isPaperMode ? Colors.black54 : Colors.white54,
                                                fontSize: 12,
                                                height: 1.6,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF54C5F8).withOpacity(0.14),
                                      border: Border.all(color: const Color(0xFF54C5F8), width: 1.5),
                                    ),
                                    child: const Icon(LucideIcons.lock, color: Color(0xFF54C5F8), size: 30),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Page $currentPage is Locked',
                                    style: GoogleFonts.inter(
                                      color: isPaperMode ? Colors.black : Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'This is a paid document. The free preview covers the first 5% (Pages 1–$previewPages).\nUnlock all ${_book.pages} pages to read the entire document inside the app.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isPaperMode ? Colors.black54 : Colors.white60,
                                      fontSize: 12.5,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _showPaymentModal(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF54C5F8),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(LucideIcons.shoppingBag, size: 16),
                                    label: Text(
                                      'Unlock Document for ${_book.price}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                  ),
                                ],
                              )
                            // 📖 READABLE PAGE VIEW
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Page Header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _book.category.toUpperCase(),
                                        style: TextStyle(
                                          color: isPaperMode ? const Color(0xFF2563EB) : const Color(0xFF54C5F8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isPaperMode ? Colors.black.withOpacity(0.06) : Colors.white.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'PAGE $currentPage OF ${_book.pages}',
                                          style: TextStyle(
                                            color: isPaperMode ? Colors.black87 : Colors.white70,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(
                                    color: isPaperMode ? Colors.black12 : Colors.white12,
                                    height: 24,
                                  ),

                                  // Page 1: Abstract / Introduction / Overview
                                  if (currentPage == 1) ...[
                                    Text(
                                      _book.title,
                                      style: GoogleFonts.inter(
                                        color: isPaperMode ? Colors.black : Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'By ${_book.author} • Difficulty: ${_book.difficulty} • Read Time: ${_book.readTime}',
                                      style: TextStyle(
                                        color: isPaperMode ? Colors.black54 : Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Document Overview & Abstract',
                                      style: GoogleFonts.inter(
                                        color: isPaperMode ? Colors.black87 : Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _book.description,
                                      style: GoogleFonts.inter(
                                        color: isPaperMode ? const Color(0xFF2C2C2C) : const Color(0xDEFFFFFF),
                                        fontSize: 13,
                                        height: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Core Key Takeaways',
                                      style: GoogleFonts.inter(
                                        color: isPaperMode ? Colors.black87 : Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._book.keyTakeaways.map(
                                      (t) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 3),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('• ', style: TextStyle(color: isPaperMode ? Colors.black87 : Colors.white, fontSize: 14)),
                                            Expanded(
                                              child: Text(
                                                t,
                                                style: GoogleFonts.inter(
                                                  color: isPaperMode ? const Color(0xFF2C2C2C) : const Color(0xDEFFFFFF),
                                                  fontSize: 12.5,
                                                  height: 1.45,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    // Page 2..N: Chapter or Section Breakdown
                                    Builder(
                                      builder: (_) {
                                        final chapterIdx = currentPage - 2;
                                        final hasChapter = chapterIdx >= 0 && chapterIdx < _book.chapters.length;
                                        final chapter = hasChapter ? _book.chapters[chapterIdx] : null;
                                        final sectionTitle = chapter?.title ?? 'Section $currentPage: Technical Specifications & Diagrams';
                                        final sectionSummary = chapter?.summary ??
                                            'Detailed architecture design principles, production constraints, performance optimization benchmarks, and modular component structures.';

                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sectionTitle,
                                              style: GoogleFonts.inter(
                                                color: isPaperMode ? Colors.black : Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              sectionSummary,
                                              style: GoogleFonts.inter(
                                                color: isPaperMode ? const Color(0xFF2C2C2C) : const Color(0xDEFFFFFF),
                                                fontSize: 13,
                                                height: 1.6,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            Container(
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: isPaperMode ? Colors.black.withOpacity(0.04) : Colors.white.withOpacity(0.04),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isPaperMode ? Colors.black12 : Colors.white10,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Page Notes & Execution Guidelines',
                                                    style: GoogleFonts.inter(
                                                      color: isPaperMode ? Colors.black87 : Colors.white70,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '1. Always verify lifecycle integrity and prevent unbounded allocations.\n2. Utilize cached observables for asynchronous multi-subscriber streams.\n3. Keep layout hierarchies shallow to eliminate jank during high-velocity updates.',
                                                    style: GoogleFonts.firaCode(
                                                      color: isPaperMode ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                                      fontSize: 11,
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],

                                  const SizedBox(height: 28),
                                  Divider(color: isPaperMode ? Colors.black12 : Colors.white12, height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'CodeSnap Document Engine',
                                        style: TextStyle(
                                          color: isPaperMode ? Colors.black38 : Colors.white38,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                      Text(
                                        'Page $currentPage of ${_book.pages}',
                                        style: TextStyle(
                                          color: isPaperMode ? Colors.black38 : Colors.white38,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
