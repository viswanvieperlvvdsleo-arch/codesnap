import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_animations.dart';
import 'spring_button.dart';
import '../screens/notifications_screen.dart';
import '../screens/admin_dashboard_screen.dart';


/// ─── Header ──────────────────────────────────────────────────────────────────
/// Premium header with:
/// - Dynamic blur cascade — blurs more as you scroll down
/// - Spring nav tabs — active tab animated with spring physics
/// - Jiggling notification bell
/// - Spring press on all interactive elements
class Header extends StatefulWidget implements PreferredSizeWidget {
  final int activeIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback? onMenuPressed;
  final ScrollController? scrollController;

  const Header({
    super.key,
    required this.activeIndex,
    required this.onTabChanged,
    this.onMenuPressed,
    this.scrollController,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = (widget.scrollController?.offset ?? 0).clamp(0.0, 80.0);
    if (mounted && offset != _scrollOffset) {
      setState(() => _scrollOffset = offset);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final user = authProvider.currentUser;

    // Scroll-linked blur
    final blurSigma = 20.0 + (_scrollOffset / 80.0) * 20.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: AnimatedContainer(
          duration: AppAnimations.micro,
          decoration: BoxDecoration(
            color: const Color(0xFF09090B).withOpacity(0.85),
            border: const Border(
              bottom: BorderSide(
                color: Color(0x26FFFFFF), // rgba(255,255,255,0.15)
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SafeArea(
            child: Row(
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        '<>',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Bug',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 40),

                // Desktop nav
                if (isDesktop)
                  Expanded(
                    child: _SpringNavBar(
                      activeIndex: widget.activeIndex,
                      onTabChanged: widget.onTabChanged,
                    ),
                  )
                else
                  const Spacer(),

                // Right actions
                Row(
                  children: [
                    // Jiggling bell
                    _AnimatedNotificationBell(),

                    const SizedBox(width: 12),

                    // Avatar popup
                    SpringButton(
                      child: PopupMenuButton<String>(
                        offset: const Offset(0, 48),
                        color: const Color(0xFF111113),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0x26FFFFFF)),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          backgroundImage: (user != null && user.avatarUrl.isNotEmpty)
                              ? NetworkImage(user.avatarUrl)
                              : null,
                          child: (user == null || user.avatarUrl.isEmpty)
                              ? Text(
                                  (user?.name.isNotEmpty == true)
                                      ? user!.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                )
                              : null,
                        ),
                        onSelected: (value) {
                          if (value == 'logout') {
                            authProvider.logout();
                          } else if (value == 'profile') {
                            widget.onTabChanged(7);
                          } else if (value == 'admin') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            enabled: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user?.name ?? 'User Account',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                Text(user?.email ?? '',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF888899))),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(color: Color(0x26FFFFFF)),
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(children: [
                              Icon(LucideIcons.user,
                                  size: 18, color: Colors.white70),
                              SizedBox(width: 10),
                              Text('My Profile',
                                  style: TextStyle(color: Colors.white)),
                            ]),
                          ),
                          if (authProvider.isAdmin) ...[
                            const PopupMenuDivider(color: Color(0x26FFFFFF)),
                            const PopupMenuItem(
                              value: 'admin',
                              child: Row(children: [
                                Icon(LucideIcons.shieldCheck,
                                    size: 18, color: Color(0xFFFFD700)),
                                SizedBox(width: 10),
                                Text('Admin Console',
                                    style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                              ]),
                            ),
                          ],
                          const PopupMenuDivider(color: Color(0x26FFFFFF)),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(children: [
                              Icon(LucideIcons.logOut,
                                  size: 18, color: Colors.redAccent),
                              SizedBox(width: 10),
                              Text('Logout',
                                  style: TextStyle(color: Colors.redAccent)),
                            ]),
                          ),
                        ],
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
}

// ─── Spring Nav Bar ───────────────────────────────────────────────────────────

class _SpringNavBar extends StatefulWidget {
  final int activeIndex;
  final ValueChanged<int> onTabChanged;

  const _SpringNavBar({
    required this.activeIndex,
    required this.onTabChanged,
  });

  @override
  State<_SpringNavBar> createState() => _SpringNavBarState();
}

class _SpringNavBarState extends State<_SpringNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const _labels = ['Home', 'Chat', 'People', 'Arena', 'Notes', 'Projects', 'Workspace', 'Profile'];
  static const _icons = [
    LucideIcons.home,
    LucideIcons.messageSquare,
    LucideIcons.users,
    LucideIcons.trophy,
    LucideIcons.bookOpen,
    LucideIcons.folderKanban,
    LucideIcons.code,
    LucideIcons.user,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(_SpringNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      _controller
        ..reset()
        ..animateWith(SpringSimulation(AppAnimations.snappySpring, 0, 1, 6));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    // Filter available navigation items: on laptop view, hide the separate Chat button
    // because Chat is already integrated directly into the desktop split view beside the Home feed.
    final visibleIndices = <int>[];
    for (int i = 0; i < _labels.length; i++) {
      if (isDesktop && i == 1) continue; // Skip Chat
      visibleIndices.add(i);
    }

    return Row(
      children: visibleIndices.map((index) {
        final isSelected = widget.activeIndex == index;
        return SpringButton(
          onTap: () => widget.onTabChanged(index),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: AnimatedContainer(
              duration: AppAnimations.quick,
              curve: AppAnimations.snappy,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? ThemeProvider.primaryGold.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.15 : 1.0,
                    duration: AppAnimations.quick,
                    curve: AppAnimations.bounce,
                    child: Icon(
                      _icons[index],
                      size: 16,
                      color: isSelected
                          ? ThemeProvider.primaryGold
                          : ThemeProvider.mauve,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedDefaultTextStyle(
                    duration: AppAnimations.quick,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: isSelected
                          ? ThemeProvider.primaryGold
                          : ThemeProvider.mauve,
                      fontSize: 14,
                    ),
                    child: Text(_labels[index]),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Jiggling notification bell ───────────────────────────────────────────────

class _AnimatedNotificationBell extends StatefulWidget {
  @override
  State<_AnimatedNotificationBell> createState() =>
      _AnimatedNotificationBellState();
}

class _AnimatedNotificationBellState extends State<_AnimatedNotificationBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.07), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.07, end: -0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller.reset();
        _controller.forward();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => const NotificationsScreen(),
          ),
        );
      },

      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: AnimatedBuilder(
              animation: _rotation,
              builder: (context, child) => Transform.rotate(
                angle: _rotation.value,
                child: child,
              ),
              child: const Icon(LucideIcons.bell,
                  color: Color(0xFFAAAAAA), size: 20),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
