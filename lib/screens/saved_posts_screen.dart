import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/saved_posts_manager.dart';
import '../utils/feed_mock_data.dart';
import '../models/book_note.dart';
import '../models/project.dart';
import '../widgets/spring_button.dart';
import 'full_screen_reels_screen.dart';
import 'book_detail_screen.dart';
import 'project_detail_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _kBgDark = Color(0xFF09090B);
  static const Color _kGlassSurface = Color(0x1AFFFFFF);
  static const Color _kGlassBorder = Color(0x26FFFFFF);
  static const Color _kAccentCyan = Color(0xFF54C5F8);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: SpringButton(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
          ),
        ),
        title: Row(
          children: [
            const Icon(LucideIcons.bookmark, color: _kAccentCyan, size: 18),
            const SizedBox(width: 8),
            Text(
              'Saved Collections',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: _kAccentCyan,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: _kAccentCyan,
                unselectedLabelColor: Colors.white60,
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Pics'),
                  Tab(text: 'Videos'),
                  Tab(text: 'Books'),
                  Tab(text: 'Projects'),
                ],
              ),
              Container(color: Colors.white.withOpacity(0.08), height: 1),
            ],
          ),
        ),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: SavedPostsManager.changeNotifier,
        builder: (context, _, __) {
          final pics = SavedPostsManager.getSavedPics();
          final videos = SavedPostsManager.getSavedVideos();
          final books = SavedPostsManager.getSavedBooks();
          final projects = SavedPostsManager.getSavedProjects();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPicsTab(pics),
              _buildVideosTab(videos),
              _buildBooksTab(books),
              _buildProjectsTab(projects),
            ],
          );
        },
      ),
    );
  }

  // ── Tab 1: Pics ────────────────────────────────────────────────────────────
  Widget _buildPicsTab(List<FeedPost> pics) {
    if (pics.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.image,
        title: 'No Saved Pics Yet',
        subtitle: 'Save image posts from your feed to view them here anytime.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: pics.length,
      itemBuilder: (context, index) {
        final post = pics[index];
        return _buildPostCard(post, pics, index, isVideo: false);
      },
    );
  }

  // ── Tab 2: Videos ──────────────────────────────────────────────────────────
  Widget _buildVideosTab(List<FeedPost> videos) {
    if (videos.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.video,
        title: 'No Saved Videos Yet',
        subtitle: 'Save coding clips and video tutorials from your feed to view them here.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final post = videos[index];
        return _buildPostCard(post, videos, index, isVideo: true);
      },
    );
  }

  // ── Post Card for Pics / Videos ───────────────────────────────────────────
  Widget _buildPostCard(FeedPost post, List<FeedPost> list, int index, {required bool isVideo}) {
    return SpringButton(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => FullScreenReelsScreen(
              posts: list,
              initialIndex: index,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGlassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.white10),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              if (isVideo)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(LucideIcons.play, color: Colors.white, size: 20),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: SpringButton(
                  onTap: () {
                    SavedPostsManager.toggleSave(post);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Removed from Saved List')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.65),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(LucideIcons.bookmarkCheck, size: 14, color: _kAccentCyan),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundImage: NetworkImage(post.avatarUrl),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            post.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      post.captionTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 10.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 3: Books / Notes ───────────────────────────────────────────────────
  Widget _buildBooksTab(List<BookNote> books) {
    if (books.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.bookOpen,
        title: 'No Saved Books Yet',
        subtitle: 'Bookmark study guides, roadmaps, and books from Notes to access them here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _kGlassSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kGlassBorder),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mini book cover
                    Container(
                      width: 54,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [book.primaryColor, book.secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Icon(book.categoryIcon, color: Colors.white70, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _kAccentCyan.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  book.category,
                                  style: const TextStyle(color: _kAccentCyan, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              SpringButton(
                                onTap: () {
                                  SavedPostsManager.toggleBookSave(book.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Removed book from Saved List')),
                                  );
                                },
                                child: const Icon(LucideIcons.bookmarkCheck, color: _kAccentCyan, size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'By ${book.author} • ${book.pages} pages',
                            style: GoogleFonts.inter(color: Colors.white60, fontSize: 11.5),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(LucideIcons.star, color: Colors.amber, size: 13),
                              const SizedBox(width: 4),
                              Text('${book.rating}', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Text(book.price, style: const TextStyle(color: _kAccentCyan, fontSize: 11.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 4: Projects ────────────────────────────────────────────────────────
  Widget _buildProjectsTab(List<Project> projects) {
    if (projects.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.folderGit2,
        title: 'No Saved Projects Yet',
        subtitle: 'Bookmark full-stack and frontend projects to practice coding anytime.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _kGlassSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kGlassBorder),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        project.thumbnailUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.white10,
                          child: const Icon(LucideIcons.code, color: Colors.white60),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  project.difficulty,
                                  style: TextStyle(
                                    color: project.difficulty == 'Advanced'
                                        ? const Color(0xFFEF4444)
                                        : (project.difficulty == 'Intermediate' ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                project.estimatedTime,
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              const Spacer(),
                              SpringButton(
                                onTap: () {
                                  SavedPostsManager.toggleProjectSave(project.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Removed project from Saved List')),
                                  );
                                },
                                child: const Icon(LucideIcons.bookmarkCheck, color: _kAccentCyan, size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            project.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            project.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(color: Colors.white60, fontSize: 11.5, height: 1.3),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            children: project.techStack.map((tech) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  tech,
                                  style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w600),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Icon(icon, size: 36, color: _kAccentCyan),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.55),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
