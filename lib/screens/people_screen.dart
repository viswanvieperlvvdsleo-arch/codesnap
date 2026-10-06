import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/user_profile.dart';
import '../utils/mock_data.dart';
import '../utils/app_animations.dart';
import '../widgets/spring_button.dart';
import 'user_profile_detail_screen.dart';

// ── Liquid Glass Color Tokens ────────────────────────────────────────────────
const _kBgDark        = Color(0xFF09090B);
const _kGlassSurface   = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
const _kGlassCard      = Color(0xFF131418);
const _kGlassElevated  = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
const _kGlassBorder    = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
const _kGlassHighlight = Color(0x40FFFFFF); // rgba(255,255,255,0.25)
const _kAccentCyan     = Color(0xFF54C5F8); // Pure Ice-Cyan highlight

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  late List<UserProfile> _allUsers;

  final List<String> _categories = [
    'All',
    'Top Contributors',
    'Mentors',
    'Frontend',
    'AI/ML',
    'Designers',
  ];

  @override
  void initState() {
    super.initState();
    _allUsers = MockData.mockPeople;
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserProfile> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();

    return _allUsers.where((user) {
      // Category filter
      if (_selectedCategory == 'Top Contributors' &&
          !user.roleBadge.toLowerCase().contains('contributor') &&
          !user.roleBadge.toLowerCase().contains('core')) {
        return false;
      }
      if (_selectedCategory == 'Mentors' &&
          !user.roleBadge.toLowerCase().contains('mentor')) {
        return false;
      }
      if (_selectedCategory == 'Frontend' &&
          !user.skills.any((s) => ['Flutter', 'React', 'TypeScript', 'VisionOS', 'Three.js'].contains(s))) {
        return false;
      }
      if (_selectedCategory == 'AI/ML' &&
          !user.skills.any((s) => ['PyTorch', 'TensorFlow', 'LLMs', 'CUDA', 'Python', 'MLOps'].contains(s))) {
        return false;
      }
      if (_selectedCategory == 'Designers' &&
          !user.roleBadge.toLowerCase().contains('design') &&
          !user.skills.any((s) => ['Figma', 'UI/UX', 'Glassmorphism', 'Design Systems'].contains(s))) {
        return false;
      }

      // Search query
      if (query.isNotEmpty) {
        final matchesName = user.name.toLowerCase().contains(query);
        final matchesHandle = user.handle.toLowerCase().contains(query);
        final matchesHeadline = user.headline.toLowerCase().contains(query);
        final matchesBio = user.bio.toLowerCase().contains(query);
        final matchesSkills = user.skills.any((s) => s.toLowerCase().contains(query));
        return matchesName || matchesHandle || matchesHeadline || matchesBio || matchesSkills;
      }

      return true;
    }).toList();
  }

  void _openProfile(UserProfile user) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) {
          return UserProfileDetailScreen(user: user);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: AppAnimations.snappy),
            child: child,
          );
        },
      ),
    ).then((_) {
      // Refresh UI state when coming back from detail screen
      if (mounted) setState(() {});
    });
  }

  void _toggleFollow(UserProfile user) {
    setState(() {
      user.isFollowing = !user.isFollowing;
      user.followersCount += user.isFollowing ? 1 : -1;
    });

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        content: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF121318).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: user.isFollowing ? _kAccentCyan.withOpacity(0.4) : _kGlassBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.isFollowing ? LucideIcons.userCheck : LucideIcons.userMinus,
                      size: 16,
                      color: user.isFollowing ? _kAccentCyan : Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      user.isFollowing
                          ? 'Now snapping with ${user.name}'
                          : 'Stopped snapping with ${user.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _kBgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header / Search Capsule ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _kGlassElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kGlassBorder),
                        ),
                        child: const Icon(
                          LucideIcons.users,
                          size: 20,
                          color: _kAccentCyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'People & Community',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Discover creators, mentors, and fellow engineers',
                              style: TextStyle(
                                color: Color(0xFF888899),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Liquid Glass Search Capsule
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _kGlassSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _kGlassBorder, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.search,
                              size: 18,
                              color: Color(0xFF888899),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                cursorColor: Colors.white,
                                decoration: const InputDecoration(
                                  hintText: 'Search people, skills, handles...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF666677),
                                    fontSize: 13.5,
                                  ),
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              SpringButton(
                                onTap: () => _searchController.clear(),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    LucideIcons.x,
                                    size: 16,
                                    color: Color(0xFF888899),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Pills Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SpringButton(
                            onTap: () => setState(() => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: AppAnimations.micro,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _kAccentCyan.withOpacity(0.18)
                                    : _kGlassSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? _kAccentCyan.withOpacity(0.55)
                                      : _kGlassBorder,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected
                                      ? _kAccentCyan
                                      : const Color(0xFFD4D4D8),
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── "Suggested for You" Carousel ───────────────────────────────────
          if (_searchController.text.isEmpty && _selectedCategory == 'All') ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Row(
                  children: [
                    const Icon(LucideIcons.sparkles,
                        size: 15, color: _kAccentCyan),
                    const SizedBox(width: 8),
                    const Text(
                      'Suggested for You',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_allUsers.length} active peers',
                      style: const TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _allUsers.length,
                  itemBuilder: (context, index) {
                    final user = _allUsers[index];
                    return _buildSuggestedPeerCard(user);
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],

          // ── Community Members Section Header ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Text(
                    _selectedCategory == 'All'
                        ? 'All Members (${filtered.length})'
                        : '$_selectedCategory (${filtered.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Community Grid ─────────────────────────────────────────────────
          if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kGlassSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kGlassBorder),
                ),
                child: const Column(
                  children: [
                    Icon(LucideIcons.userX, color: Colors.white38, size: 40),
                    SizedBox(height: 12),
                    Text(
                      'No profiles match your search criteria',
                      style: TextStyle(color: Color(0xFF888899), fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  mainAxisExtent: 315,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = filtered[index];
                    return _buildUserCard(user);
                  },
                  childCount: filtered.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  // ── Suggested Peer Card (Horizontal Carousel) ──────────────────────────────
  Widget _buildSuggestedPeerCard(UserProfile user) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: _kGlassCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGlassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openProfile(user),
          splashColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.white.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'people-avatar-${user.id}',
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(user.avatarUrl),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.handle,
                            style: const TextStyle(
                              color: Color(0xFF888899),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  user.headline,
                  style: const TextStyle(
                    color: Color(0xFFA1A1AA),
                    fontSize: 11,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kGlassElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.roleBadge,
                        style: const TextStyle(
                          color: _kAccentCyan,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SpringButton(
                      onTap: () => _toggleFollow(user),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.isFollowing
                              ? _kGlassSurface
                              : _kAccentCyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: user.isFollowing
                                ? _kGlassBorder
                                : _kAccentCyan.withOpacity(0.6),
                          ),
                        ),
                        child: Text(
                          user.isFollowing ? 'Snapping' : 'Snap',
                          style: TextStyle(
                            color: user.isFollowing
                                ? Colors.white70
                                : _kAccentCyan,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Main User Card ─────────────────────────────────────────────────────────
  Widget _buildUserCard(UserProfile user) {
    return Container(
      decoration: BoxDecoration(
        color: _kGlassCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGlassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openProfile(user),
          splashColor: Colors.white.withOpacity(0.04),
          highlightColor: Colors.white.withOpacity(0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner & Avatar Stack
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Hero Banner Header
                  Hero(
                    tag: 'people-banner-${user.id}',
                    child: Container(
                      height: 70,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(user.bannerUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              _kGlassCard.withOpacity(0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Avatar overlapping banner
                  Positioned(
                    bottom: -22,
                    left: 14,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _openProfile(user),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _kGlassHighlight, width: 1.5),
                              image: DecorationImage(
                                image: NetworkImage(user.avatarUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        if (user.isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _kGlassCard, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Role badge at top right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kGlassBorder),
                      ),
                      child: Text(
                        user.roleBadge,
                        style: const TextStyle(
                          color: _kAccentCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Profile identity & details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Handle
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.handle,
                        style: const TextStyle(
                          color: Color(0xFF888899),
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Bio truncated
                      Text(
                        user.bio,
                        style: const TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),

                      // Skills tags preview
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: user.skills.take(3).map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF181A22),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _kGlassBorder),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                color: Color(0xFFCCCCCC),
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kGlassSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kGlassBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _cardStat('Snapped', '${user.followersCount}'),
                            Container(
                                width: 1, height: 16, color: _kGlassBorder),
                            _cardStat('Snapping', '${user.followingCount}'),
                            Container(
                                width: 1, height: 16, color: _kGlassBorder),
                            _cardStat('Media', '${user.mediaItems.length}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // Action Buttons Row (Follow / View Profile)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: _kGlassBorder, width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SpringButton(
                        onTap: () => _toggleFollow(user),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: user.isFollowing
                                ? _kGlassSurface
                                : _kAccentCyan.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: user.isFollowing
                                  ? _kGlassBorder
                                  : _kAccentCyan.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user.isFollowing
                                    ? LucideIcons.check
                                    : LucideIcons.userPlus,
                                size: 13,
                                color: user.isFollowing
                                    ? Colors.white70
                                    : _kAccentCyan,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.isFollowing ? 'Snapping' : 'Snap',
                                style: TextStyle(
                                  color: user.isFollowing
                                      ? Colors.white
                                      : _kAccentCyan,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SpringButton(
                        onTap: () => _openProfile(user),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _kGlassSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kGlassBorder),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                LucideIcons.chevronRight,
                                size: 13,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
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

  Widget _cardStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF71717A),
            fontSize: 9.5,
          ),
        ),
      ],
    );
  }
}
