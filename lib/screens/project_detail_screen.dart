import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/project.dart';
import '../models/user_profile.dart';
import '../utils/mock_data.dart';
import '../widgets/spring_button.dart';
import '../widgets/morphing_capsule.dart';
import '../widgets/expandable_text.dart';
import '../widgets/full_screen_image_viewer.dart';
import 'individual_chat_screen.dart';
import 'chat_screen.dart';
import 'user_profile_detail_screen.dart';

class ProjectReviewItem {
  final String id;
  final String username;
  final String avatarUrl;
  final double rating;
  final String timeAgo;
  final String comment;
  int likes;
  bool isLiked;

  ProjectReviewItem({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.rating,
    required this.timeAgo,
    required this.comment,
    this.likes = 0,
    this.isLiked = false,
  });
}

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final ValueChanged<String>? onOpenInWorkspace;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    this.onOpenInWorkspace,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool _isSaved = false;
  bool _isSnappedAuthor = true;
  bool _showDetailsSection = true; // Image 3 Project Overview & Features
  bool _isScreenshotsExpanded = true;
  bool _isRelatedExpanded = true;

  late List<ProjectReviewItem> _reviews;

  @override
  void initState() {
    super.initState();
    _initReviews();
  }

  void _initReviews() {
    _reviews = [
      ProjectReviewItem(
        id: 'r1',
        username: 'Alex Rivera',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        rating: 5.0,
        timeAgo: '2 hours ago',
        comment: 'Clean structure and outstanding responsive layouts! Easily integrated into my workflow.',
        likes: 14,
      ),
      ProjectReviewItem(
        id: 'r2',
        username: 'Elena Rostova',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        rating: 4.8,
        timeAgo: 'Yesterday',
        comment: 'Great documentation. The state handling and widget breakdown made customizing it a breeze.',
        likes: 8,
      ),
    ];
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF10B981);
      case 'intermediate':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  void _openReviewModal() {
    final commentCtrl = TextEditingController();
    double selectedRating = 5.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.88,
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(LucideIcons.messageSquareQuote, color: Color(0xFF54C5F8), size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Project Review',
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
                  const SizedBox(height: 16),
                  Text(
                    'Rate this project',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      final isSelected = starValue <= selectedRating;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedRating = starValue),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            LucideIcons.star,
                            size: 28,
                            color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Your Feedback & Review',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: TextField(
                        controller: commentCtrl,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
                        decoration: InputDecoration(
                          hintText: 'Share your thoughts on the code architecture, responsiveness, and UI components...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13.5),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SpringButton(
                    onTap: () {
                      final text = commentCtrl.text.trim();
                      if (text.isNotEmpty) {
                        setState(() {
                          _reviews.insert(
                            0,
                            ProjectReviewItem(
                              id: 'r_${DateTime.now().millisecondsSinceEpoch}',
                              username: 'You',
                              avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                              rating: selectedRating,
                              timeAgo: 'Just now',
                              comment: text,
                              likes: 0,
                            ),
                          );
                        });
                        Navigator.pop(ctx);
                        MorphingCapsule.show(
                          context,
                          icon: LucideIcons.checkCheck,
                          label: 'Review submitted!',
                          color: const Color(0xFF54C5F8),
                        );
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
                            color: const Color(0xFF54C5F8).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Submit Review',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
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

  void _openAuthorProfile() {
    final authorProfile = UserProfile(
      id: 'author_sarah_chen',
      name: 'Sarah Chen',
      handle: 'sarah_chen',
      headline: 'Full-stack UI Architect · Design Systems Lead',
      roleBadge: 'Featured Creator',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      bannerUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
      isOnline: true,
      isFollowing: _isSnappedAuthor,
      followersCount: 2480,
      followingCount: 310,
      postsCount: 16,
      mediaCount: 8,
      badges: ['Core', 'Creator'],
      tags: ['Flutter', 'React', 'CSS', 'UI/UX'],
      posts: [],
      media: [],
      projects: [],
      bio: 'Crafting responsive design systems and open-source UI libraries. Passionate about micro-interactions and developer ergonomics.',
      department: 'Design Engineering',
      location: 'San Francisco, CA',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileDetailScreen(user: authorProfile, isSelf: false),
      ),
    );
  }

  void _messageAuthor() {
    final conversation = ChatConversation(
      id: 'chat_sarah_chen',
      name: 'Sarah Chen',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      role: 'UI Architect',
      isOnline: true,
      unreadCount: 0,
      lastMessage: 'Hi! Let me know if you need help customizing the ${widget.project.title}!',
      time: '10:30 AM',
      messages: [
        ChatMessage(
          id: 'sc_1',
          time: '10:30 AM',
          text: 'Hi! Let me know if you need help customizing the ${widget.project.title}!',
          // Sent from project details
          isMe: false,
        ),
      ],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IndividualChatScreen(
          conversation: conversation,
          defaultWallpaper: const ChatWallpaperConfig(
            id: 'default_dark',
            name: 'Obsidian Liquid',
            type: 'solid',
            solidColor: Color(0xFF09090B),
          ),
          allConversations: [conversation],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _getDifficultyColor(widget.project.difficulty);

    final relatedProjects = MockData.mockProjects
        .where((p) => p.id != widget.project.id)
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0E14),
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
        title: Text(
          'Project Details',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          SpringButton(
            onTap: () {
              setState(() => _isSaved = !_isSaved);
              MorphingCapsule.show(
                context,
                icon: _isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmarkMinus,
                label: _isSaved ? 'Project saved!' : 'Removed from Saved',
                color: const Color(0xFFFFD700),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Icon(
                _isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                color: _isSaved ? const Color(0xFFFFD700) : Colors.white,
                size: 18,
              ),
            ),
          ),
          SpringButton(
            onTap: () {
              MorphingCapsule.show(
                context,
                icon: LucideIcons.share2,
                label: 'Project link copied!',
                color: const Color(0xFF54C5F8),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(LucideIcons.share2, color: Colors.white, size: 18),
            ),
          ),
          SpringButton(
            onTap: _openReviewModal,
            child: Container(
              margin: const EdgeInsets.fromLTRB(4, 8, 12, 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(LucideIcons.ellipsis, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. FEATURED CARD (Exact Image 2 Specification) ───
            _buildFeaturedCard(diffColor),
            const SizedBox(height: 16),

            // ─── 2. VIEW DETAILS (Exact Image 3 Specifications) ───
            if (_showDetailsSection) ...[
              _buildProjectOverviewCard(),
              const SizedBox(height: 14),
              _buildFeaturesCard(),
              const SizedBox(height: 16),
            ],

            // ─── 3. SCREENSHOTS & DEMO (Exact Image 2 Specification) ───
            _buildScreenshotsSection(),
            const SizedBox(height: 16),

            // ─── 4. AUTHOR ACCOUNT CARD (Snap & Message buttons) ───
            _buildAuthorAccountCard(),
            const SizedBox(height: 16),

            // ─── 5. RELATED PROJECTS (Exact Image 2 Specification) ───
            _buildRelatedProjectsCard(relatedProjects),
            const SizedBox(height: 16),

            // ─── 6. REVIEWS & RATINGS LIST ───
            _buildReviewsSection(),
          ],
        ),
      ),
    );
  }

  // ─── Exact Image 2 Featured Card ───────────────────────────────────────────
  Widget _buildFeaturedCard(Color diffColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13151D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image with Featured pill and options circle
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  widget.project.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.white12),
                ),
              ),
              // Featured Pill (Top-left)
              Positioned(
                top: 14,
                left: 14,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(LucideIcons.star, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Three dots button (Top-right)
              Positioned(
                top: 14,
                right: 14,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(LucideIcons.ellipsis, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content Area
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Difficulty & Time Estimate Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: diffColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          widget.project.difficulty,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFC4C4C8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(LucideIcons.clock, size: 14, color: Color(0xFF9E9EA4)),
                        const SizedBox(width: 6),
                        Text(
                          widget.project.estimatedTime,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFC4C4C8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  widget.project.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Description with ExpandableText
                ExpandableText(
                  text: widget.project.description,
                  maxLines: 4,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9E9EA4),
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),

                // Tech Stack Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: widget.project.techStack.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFD4D4D8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Action Buttons Row: View Details & Load Project
                Row(
                  children: [
                    Expanded(
                      child: SpringButton(
                        onTap: () => setState(() => _showDetailsSection = !_showDetailsSection),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _showDetailsSection ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.16)),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showDetailsSection ? LucideIcons.eyeOff : LucideIcons.eye,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _showDetailsSection ? 'Hide Details' : 'View Details',
                                style: GoogleFonts.inter(
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: SpringButton(
                        onTap: () {
                          if (widget.onOpenInWorkspace != null) {
                            widget.onOpenInWorkspace!(widget.project.id);
                          } else {
                            MorphingCapsule.show(context, icon: LucideIcons.checkCircle, label: 'Loaded project files to workspace');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.16)),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Load Project',
                                style: GoogleFonts.inter(
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Exact Image 3 Project Overview Card ───────────────────────────────────
  Widget _buildProjectOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF13151D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(LucideIcons.fileText, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Project Overview',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOverviewRow(LucideIcons.layoutGrid, 'Category', widget.project.category),
          const SizedBox(height: 12),
          _buildOverviewRow(LucideIcons.barChart2, 'Difficulty', widget.project.difficulty),
          const SizedBox(height: 12),
          _buildOverviewRow(LucideIcons.clock, 'Time Estimate', widget.project.estimatedTime),
          const SizedBox(height: 12),
          _buildOverviewRow(LucideIcons.layers, 'Technologies', widget.project.techStack.join(', ')),
        ],
      ),
    );
  }

  Widget _buildOverviewRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 14),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13.5),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ─── Exact Image 3 Features Card ───────────────────────────────────────────
  Widget _buildFeaturesCard() {
    final features = widget.project.features.isNotEmpty
        ? widget.project.features
        : [
            'Product listing with filter sidebar',
            'Responsive design (mobile + desktop)',
            'Add to cart functionality',
            'Cart management with quantity update',
            'Clean and modern UI/UX',
          ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF13151D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Features',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...features.map((feat) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.checkCircle2, color: Colors.white70, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feat,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFE4E4E7),
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Exact Image 2 Screenshots & Demo Card ─────────────────────────────────
  Widget _buildScreenshotsSection() {
    final screenshots = [
      {'title': 'Main Page', 'url': widget.project.thumbnailUrl, 'isVideo': false},
      {'title': 'Cart View', 'url': 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=600', 'isVideo': false},
      {'title': 'Demo Video', 'url': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=600', 'isVideo': true, 'duration': '0:32'},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF13151D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isScreenshotsExpanded = !_isScreenshotsExpanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(LucideIcons.image, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Screenshots & Demo',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Icon(
                  _isScreenshotsExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  color: Colors.white60,
                  size: 18,
                ),
              ],
            ),
          ),
          if (_isScreenshotsExpanded) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: screenshots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = screenshots[index];
                  final isVideo = item['isVideo'] as bool;
                  return SpringButton(
                    onTap: () {
                      FullScreenImageViewer.show(
                        context,
                        imageUrl: item['url'] as String,
                        title: item['title'] as String,
                      );
                    },
                    child: Container(
                      width: 190,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  item['url'] as String,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: Colors.white12),
                                ),
                                if (isVideo)
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white38),
                                      ),
                                      child: const Icon(LucideIcons.play, color: Colors.white, size: 16),
                                    ),
                                  ),
                                if (isVideo && item['duration'] != null)
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item['duration'] as String,
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  isVideo ? LucideIcons.video : LucideIcons.image,
                                  size: 13,
                                  color: Colors.white60,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item['title'] as String,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Author Account Card (Snap / Snapping & Message) ───────────────────────
  Widget _buildAuthorAccountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13151D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          // Avatar: Tapping opens full-screen avatar image
          GestureDetector(
            onTap: () => FullScreenImageViewer.show(
              context,
              imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600',
              title: 'Sarah Chen',
            ),
            child: const CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200'),
            ),
          ),
          const SizedBox(width: 14),
          // Name and Headline: Tapping opens profile
          Expanded(
            child: GestureDetector(
              onTap: _openAuthorProfile,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Sarah Chen',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF54C5F8).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Author', style: TextStyle(color: Color(0xFF54C5F8), fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Full-stack UI Architect',
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          // Snap / Snapping button
          SpringButton(
            onTap: () {
              setState(() => _isSnappedAuthor = !_isSnappedAuthor);
              MorphingCapsule.show(
                context,
                icon: _isSnappedAuthor ? LucideIcons.check : LucideIcons.userPlus,
                label: _isSnappedAuthor ? 'Snapping Sarah!' : 'Unsnapped',
                color: _isSnappedAuthor ? const Color(0xFF54C5F8) : Colors.white70,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isSnappedAuthor ? Colors.white.withOpacity(0.08) : const Color(0xFF54C5F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSnappedAuthor ? Colors.white.withOpacity(0.18) : const Color(0xFF54C5F8),
                ),
              ),
              child: Text(
                _isSnappedAuthor ? 'Snapping' : 'Snap',
                style: TextStyle(
                  color: _isSnappedAuthor ? Colors.white : Colors.black,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Message Button
          SpringButton(
            onTap: _messageAuthor,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
              ),
              child: const Icon(LucideIcons.messageSquare, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Exact Image 2 Related Projects Card ───────────────────────────────────
  Widget _buildRelatedProjectsCard(List<Project> related) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF13151D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isRelatedExpanded = !_isRelatedExpanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(LucideIcons.fileCode2, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Related Projects',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Icon(
                  _isRelatedExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  color: Colors.white60,
                  size: 18,
                ),
              ],
            ),
          ),
          if (_isRelatedExpanded) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final rel = related[index];
                  final diffC = _getDifficultyColor(rel.difficulty);

                  return SpringButton(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(
                            project: rel,
                            onOpenInWorkspace: widget.onOpenInWorkspace,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 210,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Image.network(
                              rel.thumbnailUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: Colors.white12),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(width: 6, height: 6, decoration: BoxDecoration(color: diffC, shape: BoxShape.circle)),
                                          const SizedBox(width: 5),
                                          Text(rel.difficulty, style: TextStyle(color: diffC, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      Text(rel.estimatedTime, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    rel.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    rel.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
                                  ),
                                  const Spacer(),
                                  Wrap(
                                    spacing: 4,
                                    children: rel.techStack.take(3).map((t) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 9)),
                                    )).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Reviews & Ratings List ────────────────────────────────────────────────
  Widget _buildReviewsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF13151D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.star, color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Community Reviews (${_reviews.length})',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              SpringButton(
                onTap: _openReviewModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF54C5F8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.plus, size: 13, color: Color(0xFF54C5F8)),
                      SizedBox(width: 4),
                      Text('Review', style: TextStyle(color: Color(0xFF54C5F8), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._reviews.map((rev) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 14, backgroundImage: NetworkImage(rev.avatarUrl)),
                      const SizedBox(width: 8),
                      Text(rev.username, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Row(
                        children: List.generate(5, (sIdx) {
                          return Icon(
                            LucideIcons.star,
                            size: 12,
                            color: sIdx < rev.rating ? const Color(0xFFFFD700) : Colors.white24,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ExpandableText(
                    text: rev.comment,
                    maxLines: 4,
                    style: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
