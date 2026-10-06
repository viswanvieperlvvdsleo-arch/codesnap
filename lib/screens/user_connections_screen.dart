import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/user_profile.dart';
import '../utils/mock_data.dart';
import '../widgets/spring_button.dart';
import '../widgets/full_screen_image_viewer.dart';
import 'chat_screen.dart';
import 'individual_chat_screen.dart';
import 'user_profile_detail_screen.dart';

// ── Liquid Glass Color Tokens ────────────────────────────────────────────────
const _kBgDark        = Color(0xFF09090B);
const _kGlassSurface   = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
const _kGlassElevated  = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
const _kGlassBorder    = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
const _kAccentBlue     = Color(0xFF4A68FF); // Vibrant primary action blue matching Image 5
const _kAccentCyan     = Color(0xFF54C5F8);

class UserConnectionsScreen extends StatefulWidget {
  final UserProfile user;
  final int initialTab; // 0: Mutual, 1: Followers, 2: Following, 3: Suggested
  final int snappedCount;
  final int snappingCount;

  const UserConnectionsScreen({
    super.key,
    required this.user,
    this.initialTab = 1,
    required this.snappedCount,
    required this.snappingCount,
  });

  @override
  State<UserConnectionsScreen> createState() => _UserConnectionsScreenState();
}

class _UserConnectionsScreenState extends State<UserConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Set<String> _followingUserIds = {};
  late List<UserProfile> _allAccounts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );

    // Initialize list of users with exact handles and names matching the platform
    final basePeople = MockData.mockPeople
        .where((u) => u.id != widget.user.id)
        .toList();

    final customAccounts = [
      UserProfile(
        id: 'c_viswan',
        name: 'viswanvieperlvvds',
        handle: 'viswanvieperlvvds',
        headline: 'WHO • ME',
        roleBadge: 'Admin',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        bannerUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
        isOnline: true,
        isFollowing: true,
        followersCount: 1420,
        followingCount: 310,
        postsCount: 18,
        mediaCount: 1,
        badges: ['Core', 'Creator'],
        tags: ['Flutter', 'Mobile', 'Design', 'Dart'],
        posts: [],
        media: [],
        projects: [],
      ),
      UserProfile(
        id: 'c_prabhatt',
        name: 'prabhatt_n07',
        handle: 'prabhatt_n07',
        headline: 'guddu⛅',
        roleBadge: 'Designer',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        bannerUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800',
        isOnline: true,
        isFollowing: false,
        followersCount: 840,
        followingCount: 220,
        postsCount: 6,
        mediaCount: 2,
        badges: ['Dev'],
        tags: ['React', 'CSS'],
        posts: [],
        media: [],
        projects: [],
      ),
      UserProfile(
        id: 'c_gowtham',
        name: 'gowtham401945',
        handle: 'gowtham401945',
        headline: 'gowtham Kumar',
        roleBadge: 'Developer',
        avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200',
        bannerUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800',
        isOnline: false,
        isFollowing: false,
        followersCount: 512,
        followingCount: 190,
        postsCount: 4,
        mediaCount: 1,
        badges: ['Pro'],
        tags: ['Python', 'AI'],
        posts: [],
        media: [],
        projects: [],
      ),
      UserProfile(
        id: 'c_sruthi',
        name: 'sruthi_ghantasala',
        handle: 'sruthi_ghantasala',
        headline: 'sruthi😇',
        roleBadge: 'Frontend Dev',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        bannerUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800',
        isOnline: true,
        isFollowing: false,
        followersCount: 1200,
        followingCount: 410,
        postsCount: 12,
        mediaCount: 4,
        badges: ['Active'],
        tags: ['Vue', 'Design'],
        posts: [],
        media: [],
        projects: [],
      ),
      UserProfile(
        id: 'c_syam',
        name: 'syam_7421',
        handle: 'syam_7421',
        headline: 'syam',
        roleBadge: 'Coder',
        avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
        bannerUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
        isOnline: false,
        isFollowing: false,
        followersCount: 380,
        followingCount: 110,
        postsCount: 2,
        mediaCount: 1,
        badges: ['Explorer'],
        tags: ['Go', 'Cloud'],
        posts: [],
        media: [],
        projects: [],
      ),
      UserProfile(
        id: 'c_adurthisiri',
        name: 'adurthisiri',
        handle: 'adurthisiri',
        headline: 'Premakumari Adu...',
        roleBadge: 'Fullstack',
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
        bannerUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800',
        isOnline: true,
        isFollowing: false,
        followersCount: 710,
        followingCount: 300,
        postsCount: 9,
        mediaCount: 3,
        badges: ['Contributor'],
        tags: ['Node', 'Next.js'],
        posts: [],
        media: [],
        projects: [],
      ),
      UserProfile(
        id: 'c_nandhini',
        name: 'nandhini.11117',
        handle: 'nandhini.11117',
        headline: 'Nandhini',
        roleBadge: 'Creative Dev',
        avatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
        bannerUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800',
        isOnline: true,
        isFollowing: false,
        followersCount: 950,
        followingCount: 280,
        postsCount: 15,
        mediaCount: 5,
        badges: ['Artist'],
        tags: ['WebGL', 'Three.js'],
        posts: [],
        media: [],
        projects: [],
      ),
      UserProfile(
        id: 'c_sairam',
        name: '_sairam_mallipudi_',
        handle: '_sairam_mallipudi_',
        headline: 'Sairam..🚩',
        roleBadge: 'Software Engineer',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
        bannerUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800',
        isOnline: true,
        isFollowing: true,
        followersCount: 1640,
        followingCount: 420,
        postsCount: 22,
        mediaCount: 8,
        badges: ['Mentor'],
        tags: ['Flutter', 'Rust', 'Docker'],
        posts: [],
        media: [],
        projects: [],
      ),
    ];

    _allAccounts = [...customAccounts, ...basePeople];

    for (final u in _allAccounts) {
      if (u.isFollowing) {
        _followingUserIds.add(u.id);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFollow(UserProfile account) {
    setState(() {
      if (_followingUserIds.contains(account.id)) {
        _followingUserIds.remove(account.id);
        account.isFollowing = false;
      } else {
        _followingUserIds.add(account.id);
        account.isFollowing = true;
      }
    });
  }

  void _openChatWithUser(UserProfile targetUser) {
    final store = ChatStateStore.instance;
    ChatConversation? conv;
    try {
      conv = store.conversations.firstWhere(
        (c) =>
            c.name.toLowerCase() == targetUser.name.toLowerCase() ||
            c.name.toLowerCase() == targetUser.handle.toLowerCase() ||
            c.id == targetUser.id,
      );
    } catch (_) {
      conv = ChatConversation(
        id: targetUser.id,
        name: targetUser.handle.isNotEmpty ? targetUser.handle : targetUser.name,
        role: targetUser.headline.isNotEmpty ? targetUser.headline : targetUser.roleBadge,
        avatarUrl: targetUser.avatarUrl,
        isOnline: targetUser.isOnline,
        lastMessage: 'Tap to send message',
        time: 'Now',
        unreadCount: 0,
        messages: [],
      );
      store.conversations.insert(0, conv);
    }

    store.selectedConversationId = conv.id;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => IndividualChatScreen(
          conversation: conv!,
          defaultWallpaper: store.defaultWallpaper,
          allConversations: store.conversations,
        ),
      ),
    );
  }

  void _openUserProfile(UserProfile targetUser) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => UserProfileDetailScreen(user: targetUser),
      ),
    );
  }

  List<UserProfile> _getTabList(int tabIndex) {
    List<UserProfile> list;
    switch (tabIndex) {
      case 0: // Mutual
        list = _allAccounts.where((u) => _followingUserIds.contains(u.id)).toList();
        if (list.isEmpty) list = _allAccounts.take(3).toList();
        break;
      case 1: // Followers (Snapped)
        list = _allAccounts;
        break;
      case 2: // Following (Snapping)
        list = _allAccounts.where((u) => _followingUserIds.contains(u.id) || u.isFollowing).toList();
        if (list.isEmpty) list = _allAccounts.take(2).toList();
        break;
      case 3: // Suggested
        list = _allAccounts.where((u) => !_followingUserIds.contains(u.id)).toList();
        break;
      default:
        list = _allAccounts;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((u) =>
          u.name.toLowerCase().contains(q) ||
          u.handle.toLowerCase().contains(q) ||
          u.headline.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final handleText = widget.user.handle.isNotEmpty
        ? widget.user.handle
        : widget.user.name.toLowerCase().replaceAll(' ', '_');

    return Scaffold(
      backgroundColor: _kBgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Bar: Back Button + Username Header ────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SpringButton(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kGlassSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kGlassBorder),
                      ),
                      child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    handleText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Horizontal Tabs (Mutual, Followers, Following, Suggested) ─────
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0x1FFFFFFF), width: 1.0),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: Colors.white,
                indicatorWeight: 2.0,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF888899),
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: [
                  const Tab(text: 'Mutual'),
                  Tab(text: '${widget.snappedCount} snapped'),
                  Tab(text: '${widget.snappingCount} snapping'),
                  const Tab(text: 'Suggested'),
                ],
              ),
            ),

            // ── Pill Search Input ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF161822),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGlassBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(LucideIcons.search, color: Color(0xFF8E8E93), size: 17),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        cursorColor: Colors.white,
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 13.5),
                          border: InputBorder.none,
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
                        child: const Icon(LucideIcons.x, color: Colors.white60, size: 15),
                      ),
                  ],
                ),
              ),
            ),

            // ── Tab Views (Accounts List) ──────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(4, (tabIdx) => _buildAccountsList(tabIdx)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsList(int tabIdx) {
    final list = _getTabList(tabIdx);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 44, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'No accounts match "$_searchQuery"' : 'No accounts found',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13.5),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final account = list[index];
        final isFollowing = _followingUserIds.contains(account.id);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // User Avatar
              GestureDetector(
                onTap: () => FullScreenImageViewer.show(context, imageUrl: account.avatarUrl, title: account.name),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF27272A),
                  backgroundImage: NetworkImage(account.avatarUrl),
                ),
              ),
              const SizedBox(width: 14),

              // Username + Subtitle / Headline
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openUserProfile(account),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        account.handle.isNotEmpty ? account.handle : account.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        account.headline.isNotEmpty ? account.headline : account.name,
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Action button: Follow / Message
              if (isFollowing) ...[
                // Message button (Dark glass)
                SpringButton(
                  onTap: () => _openChatWithUser(account),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E202B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kGlassBorder),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Message',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Follow button (Vibrant blue matching Image 5)
                SpringButton(
                  onTap: () => _toggleFollow(account),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    decoration: BoxDecoration(
                      color: _kAccentBlue,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _kAccentBlue.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Snap',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
