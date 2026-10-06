import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/user_profile.dart';
import '../utils/mock_data.dart';
import '../widgets/spring_button.dart';
import '../screens/user_profile_detail_screen.dart';

// ── Liquid Glass Color Tokens ────────────────────────────────────────────────
const _kBgDark        = Color(0xFF09090B);
const _kGlassSurface   = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
const _kGlassElevated  = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
const _kGlassBorder    = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
const _kGlassHighlight = Color(0x40FFFFFF); // rgba(255,255,255,0.25)
const _kAccentCyan     = Color(0xFF54C5F8); // Pure Ice-Cyan highlight

class AccountsListModal extends StatefulWidget {
  final UserProfile? currentUser;
  final int initialTab; // 0 for Snapped, 1 for Snapping
  final int snappedCount;
  final int snappingCount;

  const AccountsListModal({
    super.key,
    this.currentUser,
    this.initialTab = 0,
    required this.snappedCount,
    required this.snappingCount,
  });

  static void show(
    BuildContext context, {
    UserProfile? currentUser,
    int initialTab = 0,
    int snappedCount = 0,
    int snappingCount = 0,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AccountsListModal(
        currentUser: currentUser,
        initialTab: initialTab,
        snappedCount: snappedCount,
        snappingCount: snappingCount,
      ),
    );
  }

  @override
  State<AccountsListModal> createState() => _AccountsListModalState();
}

class _AccountsListModalState extends State<AccountsListModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _snappingUserIds = {};
  String _searchQuery = '';

  late List<UserProfile> _allAccounts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );

    // Filter out the current user if present
    _allAccounts = MockData.mockPeople
        .where((u) => u.id != widget.currentUser?.id)
        .toList();

    // Initialize snapping IDs based on model state
    for (final u in _allAccounts) {
      if (u.isFollowing) {
        _snappingUserIds.add(u.id);
      }
    }
    // Ensure at least some accounts are snapping for realistic preview
    if (_snappingUserIds.isEmpty && _allAccounts.length >= 2) {
      _snappingUserIds.add(_allAccounts[0].id);
      _snappingUserIds.add(_allAccounts[1].id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSnap(UserProfile account) {
    final isSnapping = _snappingUserIds.contains(account.id);
    setState(() {
      if (isSnapping) {
        _snappingUserIds.remove(account.id);
        account.isFollowing = false;
        account.followersCount = (account.followersCount - 1).clamp(0, 999999);
      } else {
        _snappingUserIds.add(account.id);
        account.isFollowing = true;
        account.followersCount += 1;
      }
    });

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kBgDark.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kGlassBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    isSnapping ? LucideIcons.userMinus : LucideIcons.userCheck,
                    color: isSnapping ? Colors.white70 : _kAccentCyan,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSnapping
                          ? 'Stopped snapping with ${account.name}'
                          : 'Now snapping with ${account.name}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _openProfile(UserProfile account) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) {
          return UserProfileDetailScreen(user: account);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  List<UserProfile> _getFilteredList(bool isSnappedTab) {
    var list = isSnappedTab
        ? _allAccounts
        : _allAccounts.where((u) => _snappingUserIds.contains(u.id) || u.isFollowing).toList();

    // If snapping tab is empty, show all accounts so user can start snapping
    if (!isSnappedTab && list.isEmpty) {
      list = _allAccounts;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((u) =>
          u.name.toLowerCase().contains(q) ||
          u.handle.toLowerCase().contains(q) ||
          u.headline.toLowerCase().contains(q) ||
          u.roleBadge.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight = MediaQuery.of(context).size.height * 0.78;

    return Container(
      height: sheetHeight,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xF00D0E12),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: _kGlassHighlight, width: 1.2),
          left: BorderSide(color: _kGlassBorder, width: 1),
          right: BorderSide(color: _kGlassBorder, width: 1),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Column(
            children: [
              // Top drag pill
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.24),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      widget.currentUser != null
                          ? '${widget.currentUser!.name}\'s Network'
                          : 'Accounts Network',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    SpringButton(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _kGlassSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: _kGlassBorder),
                        ),
                        child: const Icon(LucideIcons.x, color: Colors.white70, size: 16),
                      ),
                    ),
                  ],
                ),
              ),

              // Segmented Tabs: Snapped (Followers) vs Snapping (Following)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF14151B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kGlassBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _kGlassElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kGlassBorder),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF888899),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: [
                    Tab(text: 'Snapped (${widget.snappedCount})'),
                    Tab(text: 'Snapping (${widget.snappingCount})'),
                  ],
                ),
              ),

              // Liquid Glass Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: _kGlassSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kGlassBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.search, color: Color(0xFF888899), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          cursorColor: Colors.white,
                          decoration: const InputDecoration(
                            hintText: 'Search by name, handle or role...',
                            hintStyle: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(LucideIcons.x, color: Colors.white60, size: 14),
                        ),
                    ],
                  ),
                ),
              ),

              // Accounts list
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 0: Snapped
                    _buildAccountsList(_getFilteredList(true)),
                    // Tab 1: Snapping
                    _buildAccountsList(_getFilteredList(false)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsList(List<UserProfile> accounts) {
    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.users, color: Colors.white24, size: 40),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No accounts matching "$_searchQuery"'
                  : 'No accounts in this list yet',
              style: const TextStyle(color: Color(0xFF888899), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: accounts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final account = accounts[index];
        final isSnapping = _snappingUserIds.contains(account.id);

        return SpringButton(
          onTap: () => _openProfile(account),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kGlassSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kGlassBorder),
            ),
            child: Row(
              children: [
                // Avatar with online dot
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _kGlassHighlight, width: 1.2),
                        image: DecorationImage(
                          image: NetworkImage(account.avatarUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (account.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: _kBgDark, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name, Handle, Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              account.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.white, size: 12),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${account.handle} • ${account.roleBadge}',
                        style: const TextStyle(
                          color: Color(0xFF888899),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Action Button: "Snapping" or "Snap"
                SpringButton(
                  onTap: () => _toggleSnap(account),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSnapping ? _kGlassElevated : _kAccentCyan.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSnapping ? _kGlassBorder : _kAccentCyan.withOpacity(0.55),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSnapping ? LucideIcons.check : LucideIcons.userPlus,
                          size: 13,
                          color: isSnapping ? Colors.white70 : _kAccentCyan,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isSnapping ? 'Snapping' : 'Snap',
                          style: TextStyle(
                            color: isSnapping ? Colors.white : _kAccentCyan,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }
}
