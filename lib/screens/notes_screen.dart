import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/book_note.dart';
import '../utils/app_animations.dart';
import '../widgets/spring_button.dart';
import 'book_detail_screen.dart';
import '../widgets/morphing_capsule.dart';
import '../services/storage_picker.dart';
import '../widgets/expandable_text.dart';
import 'learn_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with TickerProviderStateMixin {
  late List<BookNote> _allBooks;
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;
  int _selectedFilterTabIndex = 0;
  bool _showRoadmapView = false; // Toggle between Library & 30-Day Roadmap

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': LucideIcons.layoutGrid},
    {'label': 'Programming', 'icon': LucideIcons.code},
    {'label': 'DSA', 'icon': LucideIcons.boxes},
    {'label': 'Web Dev', 'icon': LucideIcons.globe},
    {'label': 'AI/ML', 'icon': LucideIcons.brain},
    {'label': 'Resources', 'icon': LucideIcons.fileText},
  ];

  final List<Map<String, dynamic>> _filterTabs = [
    {'label': 'Popular', 'icon': LucideIcons.trendingUp},
    {'label': 'Latest', 'icon': LucideIcons.clock},
    {'label': 'Free', 'icon': LucideIcons.gift},
    {'label': 'Top Rated', 'icon': LucideIcons.star},
  ];

  @override
  void initState() {
    super.initState();
    _allBooks = BookNoteData.getAllBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BookNote> get _featuredBooks {
    return _allBooks.where((b) => b.isFeatured).toList();
  }

  List<BookNote> get _filteredBooks {
    var list = List<BookNote>.from(_allBooks);

    // 1. Category filter
    if (_selectedCategoryIndex > 0) {
      final selectedCat = _categories[_selectedCategoryIndex]['label'] as String;
      list = list.where((b) => b.category.toLowerCase() == selectedCat.toLowerCase()).toList();
    }

    // 2. Sub-tab filter
    switch (_selectedFilterTabIndex) {
      case 0: // Popular
        list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case 1: // Latest
        list = list.reversed.toList();
        break;
      case 2: // Free
        list = list.where((b) => b.isFree).toList();
        break;
      case 3: // Top Rated
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    // 3. Search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((b) =>
          b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.category.toLowerCase().contains(q) ||
          b.description.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  void _openBookDetail(BookNote book, {String? heroTag}) {
    final effectiveTag = heroTag ?? 'book-cover-${book.id}';
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return BookDetailScreen(
            book: book,
            heroTag: effectiveTag,
            onBookmarkToggle: () => setState(() {}),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          );
          return FadeTransition(
            opacity: fadeAnim,
            child: child,
          );
        },
      ),
    );
  }

  void _toggleBookmark(BookNote book) {
    setState(() {
      book.isBookmarked = !book.isBookmarked;
    });
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
              book.isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmarkMinus,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              book.isBookmarked
                  ? '${book.title} bookmarked'
                  : 'Removed from bookmarks',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openUploadDocumentSheet() async {
    PickedMediaResult? pickedDoc = await getStoragePicker().pickDocument();

    final titleCtrl = TextEditingController(
      text: pickedDoc != null
          ? pickedDoc.fileName.replaceAll('.pdf', '').replaceAll('_', ' ')
          : 'My Advanced Guide',
    );
    final authorCtrl = TextEditingController(text: 'You');
    final priceCtrl = TextEditingController(text: '199');
    int selectedPages = pickedDoc != null
        ? (pickedDoc.fileSize / (1024 * 16)).round().clamp(1, 500)
        : 7;
    final pagesCtrl = TextEditingController(text: '$selectedPages');
    String selectedCat = 'Document';
    bool isPaidDoc = true;
    String? coverImageUrl;
    Color coverPrimaryColor = const Color(0xFF0F172A);
    Color coverSecondaryColor = const Color(0xFF2563EB);

    final chapters = <Map<String, String>>[];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setSheetState) {
          final previewPages = (selectedPages * 0.05).ceil().clamp(1, selectedPages);

          void editOrAddChapter({int? index}) {
            final existing = index != null ? chapters[index] : null;
            final chTitleCtrl = TextEditingController(text: existing?['title'] ?? '');
            final chPagesCtrl = TextEditingController(text: existing?['pages'] ?? '');

            showDialog(
              context: context,
              builder: (dCtx) => BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AlertDialog(
                  backgroundColor: const Color(0xFF14151C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0x33FFFFFF)),
                  ),
                  title: Text(
                    index != null ? 'Edit Chapter' : 'Add Chapter',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: chTitleCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Chapter Title',
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: chPagesCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Page Range (e.g. 1–15)',
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dCtx),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF54C5F8), foregroundColor: Colors.black),
                      onPressed: () {
                        if (chTitleCtrl.text.trim().isNotEmpty) {
                          setSheetState(() {
                            if (index != null) {
                              chapters[index] = {
                                'title': chTitleCtrl.text.trim(),
                                'pages': chPagesCtrl.text.trim(),
                              };
                            } else {
                              chapters.add({
                                'title': chTitleCtrl.text.trim(),
                                'pages': chPagesCtrl.text.trim(),
                              });
                            }
                          });
                          Navigator.pop(dCtx);
                        }
                      },
                      child: Text(index != null ? 'Update' : 'Add'),
                    ),
                  ],
                ),
              ),
            );
          }

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.90,
              ),
              padding: EdgeInsets.only(
                top: 18,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF09090B).withOpacity(0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(LucideIcons.fileUp, color: Color(0xFF54C5F8), size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Upload PDF / Document',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Picked Document Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF54C5F8).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.fileText, color: Color(0xFF54C5F8), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pickedDoc?.fileName ?? 'Custom Document Upload.pdf',
                                style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${pickedDoc?.formattedSize ?? "3.4 MB"} • $selectedPages Pages detected',
                                style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        SpringButton(
                          onTap: () async {
                            final newPick = await getStoragePicker().pickDocument();
                            if (newPick != null) {
                              setSheetState(() {
                                pickedDoc = newPick;
                                selectedPages = (newPick.fileSize / (1024 * 16)).round().clamp(1, 500);
                                pagesCtrl.text = '$selectedPages';
                                titleCtrl.text = newPick.fileName.replaceAll('.pdf', '').replaceAll('_', ' ');
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Change', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // 1. Cover Page Option & Realistic 3D Book Cover Preview
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Book Cover Style', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                            SpringButton(
                              onTap: () async {
                                final pickedImg = await getStoragePicker().pickImage();
                                if (pickedImg != null) {
                                  setSheetState(() {
                                    coverImageUrl = pickedImg.pathOrDataUrl;
                                  });
                                }
                              },
                              child: Row(
                                children: const [
                                  Icon(LucideIcons.imagePlus, color: Color(0xFF54C5F8), size: 14),
                                  SizedBox(width: 4),
                                  Text('Upload Cover Image', style: TextStyle(color: Color(0xFF54C5F8), fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // 3D Glass Book Preview Container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              // 3D Book Graphic
                              Container(
                                width: 72,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: coverImageUrl != null
                                      ? null
                                      : LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [coverPrimaryColor, coverSecondaryColor, const Color(0xFF121216)],
                                        ),
                                  image: coverImageUrl != null
                                      ? DecorationImage(image: NetworkImage(coverImageUrl!), fit: BoxFit.cover)
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.6),
                                      blurRadius: 10,
                                      offset: const Offset(2, 4),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Stack(
                                  children: [
                                    // Book spine
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      bottom: 0,
                                      width: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.25),
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          titleCtrl.text.isNotEmpty ? titleCtrl.text : 'Guide',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      coverImageUrl != null ? 'Custom Photo Cover Set' : 'Gradient Book Theme',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('Choose theme colors or upload custom art', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                    const SizedBox(height: 8),
                                    // Theme pills
                                    Row(
                                      children: [
                                        ...[
                                          {'name': 'Obsidian', 'p': const Color(0xFF0F172A), 's': const Color(0xFF2563EB)},
                                          {'name': 'Emerald', 'p': const Color(0xFF064E3B), 's': const Color(0xFF10B981)},
                                          {'name': 'Sunset', 'p': const Color(0xFF7C2D12), 's': const Color(0xFFF59E0B)},
                                          {'name': 'Violet', 'p': const Color(0xFF4C1D95), 's': const Color(0xFFA855F7)},
                                        ].map((th) {
                                          final isSel = coverPrimaryColor == th['p'] && coverImageUrl == null;
                                          return GestureDetector(
                                            onTap: () {
                                              setSheetState(() {
                                                coverImageUrl = null;
                                                coverPrimaryColor = th['p'] as Color;
                                                coverSecondaryColor = th['s'] as Color;
                                              });
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(right: 6),
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(colors: [th['p'] as Color, th['s'] as Color]),
                                                border: Border.all(
                                                  color: isSel ? Colors.white : Colors.transparent,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text('Document Title', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.5)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleCtrl,
                          onChanged: (_) => setSheetState(() {}),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Category Selector
                        Text('Category', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.5)),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['Document', 'Notes', 'Architecture', 'Programming', 'Cheatsheet'].map((cat) {
                              final isSel = selectedCat == cat;
                              return GestureDetector(
                                onTap: () => setSheetState(() => selectedCat = cat),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF54C5F8).withOpacity(0.2) : Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isSel ? const Color(0xFF54C5F8) : Colors.white12),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      color: isSel ? const Color(0xFF54C5F8) : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Page Count adjuster
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Pages', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                                Text('5% Free Preview: $previewPages page${previewPages > 1 ? "s" : ""}', style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 11)),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.minusCircle, color: Colors.white70, size: 20),
                                  onPressed: () {
                                    if (selectedPages > 1) {
                                      setSheetState(() {
                                        selectedPages -= 1;
                                        pagesCtrl.text = '$selectedPages';
                                      });
                                    }
                                  },
                                ),
                                SizedBox(
                                  width: 64,
                                  height: 36,
                                  child: TextField(
                                    controller: pagesCtrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.zero,
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.08),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
                                    ),
                                    onChanged: (v) {
                                      final p = int.tryParse(v);
                                      if (p != null && p > 0) {
                                        setSheetState(() => selectedPages = p);
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.plusCircle, color: Colors.white70, size: 20),
                                  onPressed: () {
                                    setSheetState(() {
                                      selectedPages += 1;
                                      pagesCtrl.text = '$selectedPages';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Dynamic Interactive Chapters (Add, Edit, Delete)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('Chapters (', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                                Text('${chapters.length})', style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SpringButton(
                              onTap: () => editOrAddChapter(),
                              child: Row(
                                children: const [
                                  Icon(LucideIcons.plus, color: Color(0xFF54C5F8), size: 14),
                                  SizedBox(width: 4),
                                  Text('+ Add Chapter', style: TextStyle(color: Color(0xFF54C5F8), fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (chapters.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: const Row(
                              children: [
                                Icon(LucideIcons.filePlus, color: Colors.white38, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No chapters added. Tap "+ Add Chapter" to add chapters from fresh.',
                                    style: TextStyle(color: Colors.white54, fontSize: 11.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...chapters.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final ch = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(ch['title']!, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text('Pages: ${ch['pages']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.pencil, color: Colors.white60, size: 14),
                                    onPressed: () => editOrAddChapter(index: idx),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 14),
                                    onPressed: () {
                                      setSheetState(() {
                                        chapters.removeAt(idx);
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 16),

                        // Access & Paid toggle with Indian Rupees (₹)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('Paid Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      SizedBox(height: 2),
                                      Text('Only 5% preview visible, 95% blurred until unlocked', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                    ],
                                  ),
                                  Switch(
                                    value: isPaidDoc,
                                    activeColor: const Color(0xFF54C5F8),
                                    onChanged: (val) => setSheetState(() => isPaidDoc = val),
                                  ),
                                ],
                              ),
                              if (isPaidDoc) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text('Price (INR ₹):', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 100,
                                      height: 38,
                                      child: TextField(
                                        controller: priceCtrl,
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        decoration: InputDecoration(
                                          prefixText: '₹ ',
                                          prefixStyle: const TextStyle(color: Color(0xFF54C5F8), fontWeight: FontWeight.bold),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.08),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Publish Button
                  SpringButton(
                    onTap: () {
                      final title = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'Flutter Architecture Notes';
                      final priceFormatted = isPaidDoc ? '₹${priceCtrl.text.trim()}' : 'Free';
                      final newBook = BookNote(
                        id: 'book_uploaded_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        subtitle: 'Uploaded Document • $selectedPages Pages',
                        author: authorCtrl.text.trim(),
                        category: selectedCat,
                        rating: 5.0,
                        reviewCount: 1,
                        pages: selectedPages,
                        price: priceFormatted,
                        isFree: !isPaidDoc,
                        badge: 'New',
                        primaryColor: coverPrimaryColor,
                        secondaryColor: coverSecondaryColor,
                        coverImageUrl: coverImageUrl,
                        pdfUrl: pickedDoc?.pathOrDataUrl,
                        categoryIcon: selectedCat == 'Programming'
                            ? LucideIcons.code2
                            : (selectedCat == 'Architecture' ? LucideIcons.layers : LucideIcons.fileText),
                        coverCodeSnippet: selectedCat == 'Programming'
                            ? '// $title\nclass DocumentOverview {\n  final pages = $selectedPages;\n  final access = "${isPaidDoc ? "5% Preview Blur" : "Free"}";\n}'
                            : '',
                        description: 'Complete uploaded reference document with $selectedPages pages of detailed notes, diagrams, and cheat sheets.',
                        keyTakeaways: [
                          'Comprehensive high-yield notes across $selectedPages pages',
                          'Includes diagrams, architecture schematics and code samples',
                          'Offline reading and download ready',
                        ],
                        fullReviewSummary: 'Top-rated newly uploaded developer guide.',
                        reviews: [],
                        chapters: chapters.map((c) => BookChapter(
                          number: chapters.indexOf(c) + 1,
                          title: c['title']!,
                          duration: '15 min',
                          summary: 'Chapter covers pages ${c['pages']}',
                        )).toList(),
                        readTime: '${(selectedPages * 1.5).toInt()} mins',
                        difficulty: 'Intermediate',
                        isFeatured: true,
                      );

                      setState(() {
                        _allBooks.insert(0, newBook);
                      });

                      Navigator.pop(ctx);
                      MorphingCapsule.show(
                        context,
                        icon: LucideIcons.checkCheck,
                        label: 'Document uploaded ($selectedPages pages in INR ₹)!',
                        color: const Color(0xFF54C5F8),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF54C5F8), Color(0xFF2563EB)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF54C5F8).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Publish Document ($selectedPages Pages)',
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
    final filtered = _filteredBooks;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          // Background ambient frosted glass lights (strictly glass white / deep obsidian)
          Positioned(
            top: -60,
            right: -60,
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
            top: 280,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
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

          SafeArea(
            child: Column(
              children: [
                // Top Header & View Mode Switcher
                _buildTopNavigationHeader(),

                // Main body content (Library vs 30-Day Roadmap)
                Expanded(
                  child: _showRoadmapView
                      ? const LearnScreen()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 40 : 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Liquid Glass Search Bar + Filter Pill
                              _buildSearchBar(),
                              const SizedBox(height: 18),

                              // 2. Liquid Glass Category Chips
                              _buildCategoryChips(),
                              const SizedBox(height: 24),

                              // 3. Featured Books Carousel (shown when not searching)
                              if (_searchQuery.trim().isEmpty && _selectedCategoryIndex == 0) ...[
                                _buildFeaturedSectionHeader(),
                                const SizedBox(height: 14),
                                _buildFeaturedBooksCarousel(),
                                const SizedBox(height: 24),
                              ],

                              // 4. Liquid Glass Sub-Tab Pills (Popular, Latest, Free, Top Rated)
                              _buildFilterTabsBar(),
                              const SizedBox(height: 16),

                              // 5. Vertical Liquid Glass Book & Notes List
                              _buildVerticalBooksList(filtered),
                              const SizedBox(height: 100),
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

  // ── Top Navigation & View Switcher ──────────────────────────────────────────
  Widget _buildTopNavigationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Liquid Glass Icon & Title (Flexible & responsive)
          Expanded(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x38FFFFFF)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.bookOpen, color: Colors.white, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Notes & Books',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Handcrafted Cheat Sheets & Guides',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0x80FFFFFF),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Liquid Glass Mode Toggle Capsule: Library vs 30-Day Roadmap
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: Row(
              children: [
                _buildModeCapsuleButton(
                  title: 'Library',
                  isSelected: !_showRoadmapView,
                  onTap: () => setState(() => _showRoadmapView = false),
                ),
                _buildModeCapsuleButton(
                  title: 'Upload',
                  isSelected: _showRoadmapView,
                  onTap: _openUploadDocumentSheet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCapsuleButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.quick,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x38FFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: const Color(0x40FFFFFF)) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0x80FFFFFF),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── 1. Liquid Glass Search Bar & Filter ────────────────────────────────────
  Widget _buildSearchBar() {
    return Row(
      children: [
        // Frosted Glass Search Input Field
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x26FFFFFF)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(LucideIcons.search, color: Color(0x80FFFFFF), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        cursorColor: Colors.white,
                        decoration: const InputDecoration(
                          hintText: 'Search books, notes, guides...',
                          hintStyle: TextStyle(color: Color(0x66FFFFFF), fontSize: 13),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(LucideIcons.x, color: Colors.white70, size: 16),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Liquid Glass Filter Button
        SpringButton(
          onTap: () {
            setState(() {
              _selectedCategoryIndex = (_selectedCategoryIndex + 1) % _categories.length;
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.slidersHorizontal, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Filter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. Liquid Glass Category Chips ─────────────────────────────────────────
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategoryIndex == index;

          return SpringButton(
            onTap: () {
              setState(() => _selectedCategoryIndex = index);
            },
            child: AnimatedContainer(
              duration: AppAnimations.quick,
              curve: AppAnimations.snappy,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0x38FFFFFF) : const Color(0x12FFFFFF),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: isSelected ? const Color(0x66FFFFFF) : const Color(0x26FFFFFF),
                  width: isSelected ? 1.2 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 14,
                    color: isSelected ? Colors.white : const Color(0xB3FFFFFF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xCCFFFFFF),
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
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

  // ── 3. Liquid Glass Featured Books Carousel ────────────────────────────────
  Widget _buildFeaturedSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Featured Books',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        SpringButton(
          onTap: () {
            setState(() {
              _selectedFilterTabIndex = 3;
            });
          },
          child: const Row(
            children: [
              Text(
                'See all',
                style: TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Icon(LucideIcons.chevronRight, color: Color(0xB3FFFFFF), size: 15),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedBooksCarousel() {
    final featured = _featuredBooks;

    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: featured.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final book = featured[index];

          return SpringButton(
            onTap: () => _openBookDetail(book),
            child: Container(
              width: 155,
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x26FFFFFF)),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Cover with Hero & Badge
                  Stack(
                    children: [
                      Hero(
                        tag: 'book-cover-${book.id}',
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: book.coverImageUrl != null
                                ? null
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      book.primaryColor,
                                      book.secondaryColor,
                                      const Color(0xFF101014),
                                    ],
                                  ),
                            image: book.coverImageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(book.coverImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Spacer(),
                              Text(
                                book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                book.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Floating Liquid Glass Badge pill (pure frosted glass)
                      if (book.badge != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0x38FFFFFF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0x4DFFFFFF)),
                                ),
                                child: Text(
                                  book.badge!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title below cover
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),

                  // Rating & Price row in pure liquid glass
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.star, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            book.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x1FFFFFFF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0x26FFFFFF)),
                        ),
                        child: Text(
                          book.price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
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
    );
  }

  // ── 4. Liquid Glass Sub-Tab Pills ──────────────────────────────────────────
  Widget _buildFilterTabsBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Row(
        children: List.generate(_filterTabs.length, (index) {
          final tab = _filterTabs[index];
          final isSelected = _selectedFilterTabIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilterTabIndex = index);
              },
              child: AnimatedContainer(
                duration: AppAnimations.quick,
                curve: AppAnimations.snappy,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0x38FFFFFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: isSelected ? Border.all(color: const Color(0x33FFFFFF)) : null,
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab['icon'] as IconData,
                        size: 13,
                        color: isSelected ? Colors.white : const Color(0x80FFFFFF),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        tab['label'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0x80FFFFFF),
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── 5. Vertical Liquid Glass Book & Notes List ──────────────────────────────
  Widget _buildVerticalBooksList(List<BookNote> books) {
    if (books.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(LucideIcons.searchX, color: Colors.white30, size: 40),
            const SizedBox(height: 12),
            const Text(
              'No books found matching your criteria',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SpringButton(
              onTap: () {
                setState(() {
                  _searchQuery = '';
                  _selectedCategoryIndex = 0;
                  _searchController.clear();
                });
              },
              child: const Text(
                'Reset Filters',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final book = books[index];

        return SpringButton(
          onTap: () => _openBookDetail(book, heroTag: 'book-list-${book.id}'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x12FFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Row(
              children: [
                // Book Thumbnail in Smoked Glass with Hero Morph Animation
                Hero(
                  tag: 'book-list-${book.id}',
                  child: Container(
                    width: 58,
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: book.coverImageUrl != null
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                book.primaryColor,
                                book.secondaryColor,
                              ],
                            ),
                      image: book.coverImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(book.coverImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      border: Border.all(color: Colors.white24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(book.categoryIcon, color: Colors.white70, size: 14),
                        const Spacer(),
                        Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Details (Title, Author, Category Chip, Pages)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0x80FFFFFF),
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Liquid glass category capsule
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0x26FFFFFF)),
                            ),
                            child: Text(
                              book.category.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            '${book.pages} pages',
                            style: const TextStyle(
                              color: Color(0x80FFFFFF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Liquid Glass Price Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: Text(
                    book.price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Liquid Glass Bookmark Icon Button
                SpringButton(
                  onTap: () => _toggleBookmark(book),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: book.isBookmarked
                          ? const Color(0x40FFFFFF)
                          : const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: book.isBookmarked
                            ? Colors.white
                            : const Color(0x26FFFFFF),
                      ),
                    ),
                    child: Icon(
                      book.isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
