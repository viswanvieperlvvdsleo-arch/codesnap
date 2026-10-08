import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/header.dart';
import '../utils/app_animations.dart';
import 'tasks_screen.dart';
import 'learn_screen.dart';
import 'notes_screen.dart';
import 'projects_screen.dart';
import 'workspace_screen.dart';
import 'profile_screen.dart';
import 'home_feed_screen.dart';
import 'chat_screen.dart';
import 'people_screen.dart';

// ── Glass constants matching the Run button ────────────────────────────────────
const _kBg      = Color(0xFF09090B);
const _kGlass   = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
const _kBorder  = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
const _kHigh    = Color(0x38FFFFFF); // rgba(255,255,255,0.22)
const _kBlur    = 40.0;
const _kRadius  = 30.0;

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final List<int> _tabHistory = [0];
  bool _menuVisible = true;


  // For swipe-to-hide gesture tracking
  double _swipeDeltaY = 0;
  static const _swipeThreshold = 40.0;

  // Animation for show/hide
  late AnimationController _menuAnim;
  late Animation<double> _menuFade;
  late Animation<Offset> _menuSlide;

  // Parameters to pass to Workspace
  String? _selectedTaskId;
  String? _selectedProjectId;
  bool _isInsideChatConversation = false;
  bool _isChatExpanded = false;

  // All 8 nav items — People placed right beside Chat (before Arena)
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
    _menuAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1.0,
    );
    _menuFade  = CurvedAnimation(parent: _menuAnim, curve: AppAnimations.snappy);
    _menuSlide = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _menuAnim, curve: AppAnimations.snappy));
  }

  @override
  void dispose() {
    _menuAnim.dispose();
    super.dispose();
  }

  void _navigateToTab(int index, {String? taskId, String? projectId}) {
    if (_currentIndex == index) return;
    setState(() {
      _tabHistory.add(index);
      _currentIndex = index;
      _selectedTaskId  = taskId;
      _selectedProjectId = projectId;
    });
  }


  void _showMenu() {
    setState(() => _menuVisible = true);
    _menuAnim.forward();
  }

  void _hideMenu() {
    _menuAnim.reverse().then((_) {
      if (mounted) setState(() => _menuVisible = false);
    });
  }

  // ── Persistent Screens (State preserved across all tab switches) ───────────
  final Widget _homeFeedScreen = const HomeFeedScreen();
  final Widget _peopleScreen = const PeopleScreen();
  final Widget _notesScreen = const NotesScreen();
  final Widget _profileScreen = const ProfileScreen();

  /// Content builder that handles Windows desktop split view vs Mobile separate pages
  /// Wrapped in IndexedStack so posts, scroll positions, and input states are NEVER lost when switching tabs!
  Widget _buildContent(bool isDesktop) {
    if (isDesktop) {
      final int activeDesktopIndex = (_currentIndex == 0 || _currentIndex == 1)
          ? (_isChatExpanded ? 1 : 0)
          : _currentIndex;

      return IndexedStack(
        index: activeDesktopIndex,
        children: [
          // 0: Desktop Split view (Chat panel on left, Home Feed on right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 390,
                child: ChatScreen(
                  isEmbedded: true,
                  isExpanded: false,
                  onToggleExpand: (expanded) {
                    setState(() => _isChatExpanded = expanded);
                  },
                  onActiveConversationChanged: (active) {
                    if (mounted) setState(() => _isInsideChatConversation = active);
                  },
                ),
              ),
              Container(
                width: 1,
                color: const Color(0x26FFFFFF),
              ),
              Expanded(
                child: _homeFeedScreen,
              ),
            ],
          ),
          // 1: Expanded full Chat mode
          ChatScreen(
            isEmbedded: false,
            isExpanded: true,
            onToggleExpand: (expanded) {
              setState(() => _isChatExpanded = expanded);
            },
            onActiveConversationChanged: (active) {
              if (mounted) setState(() => _isInsideChatConversation = active);
            },
          ),
          // 2: People / Community
          _peopleScreen,
          // 3: Tasks
          TasksScreen(
            onOpenTaskInWorkspace: (id) => _navigateToTab(6, taskId: id),
          ),
          // 4: Notes
          _notesScreen,
          // 5: Projects
          ProjectsScreen(
            onOpenProjectInWorkspace: (id) => _navigateToTab(6, projectId: id),
          ),
          // 6: Workspace
          WorkspaceScreen(
            initialTaskId: _selectedTaskId,
            initialProjectId: _selectedProjectId,
            onClearSelection: () {
              _selectedTaskId = null;
              _selectedProjectId = null;
            },
          ),
          // 7: Profile
          _profileScreen,
        ],
      );
    }

    // Mobile Phone view (IndexedStack preserves all tabs)
    return IndexedStack(
      index: _currentIndex,
      children: [
        _homeFeedScreen,
        ChatScreen(
          isExpanded: _isChatExpanded,
          onToggleExpand: (expanded) {
            setState(() => _isChatExpanded = expanded);
          },
          onActiveConversationChanged: (active) {
            if (mounted) setState(() => _isInsideChatConversation = active);
          },
        ),
        _peopleScreen,
        TasksScreen(
          onOpenTaskInWorkspace: (id) => _navigateToTab(6, taskId: id),
        ),
        _notesScreen,
        ProjectsScreen(
          onOpenProjectInWorkspace: (id) => _navigateToTab(6, projectId: id),
        ),
        WorkspaceScreen(
          initialTaskId: _selectedTaskId,
          initialProjectId: _selectedProjectId,
          onClearSelection: () {
            _selectedTaskId = null;
            _selectedProjectId = null;
          },
        ),
        _profileScreen,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDesktop = media.size.width > 800;
    final isLandscape = media.orientation == Orientation.landscape;

    // On laptop view (isDesktop), keep the top header visible even on Workspace so top menu buttons never vanish!
    // On mobile phone view, remove the top header for Chat and Workspace for maximum screen space.
    final hideTopHeader = !isDesktop && (_currentIndex == 1 || _currentIndex == 6);

    final isKeyboardOpen = media.viewInsets.bottom > 0;


    // If on workspace in phone landscape or in an active mobile chat conversation, or if keyboard is visible, hide bottom nav
    final hideBottomNav = (isLandscape && _currentIndex == 6) ||
        (!isDesktop && _currentIndex == 1 && _isInsideChatConversation) ||
        isKeyboardOpen;

    return PopScope(
      canPop: _currentIndex == 0 && !_isInsideChatConversation && _tabHistory.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Priority 1: If inside active chat conversation on mobile, exit conversation back to contacts!
        if (!isDesktop && _currentIndex == 1 && _isInsideChatConversation) {
          ChatStateStore.instance.selectConversation(null);
          setState(() {
            _isInsideChatConversation = false;
          });
          return;
        }
        // Priority 2: Pop previous tab from history stack
        if (_tabHistory.length > 1) {
          setState(() {
            _tabHistory.removeLast();
            _currentIndex = _tabHistory.isNotEmpty ? _tabHistory.last : 0;
            _isChatExpanded = false;
          });
          return;
        }
        // Priority 3: Fallback return to Home tab if not already at Home
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _tabHistory.clear();
            _tabHistory.add(0);
            _isChatExpanded = false;
          });
          return;
        }
      },

      child: Scaffold(
        backgroundColor: _kBg,
        appBar: hideTopHeader
            ? null
            : Header(
                activeIndex: _currentIndex,
                onTabChanged: _navigateToTab,
              ),
      body: GestureDetector(
        // Detect vertical swipes anywhere on body to show/hide nav
        onVerticalDragUpdate: (d) {
          _swipeDeltaY += d.delta.dy;
        },
        onVerticalDragEnd: (_) {
          if (_swipeDeltaY > _swipeThreshold && _menuVisible) {
            // Swiped DOWN → hide
            _hideMenu();
          } else if (_swipeDeltaY < -_swipeThreshold && !_menuVisible) {
            // Swiped UP → show
            _showMenu();
          }
          _swipeDeltaY = 0;
        },
        child: Stack(
          children: [
            // ── Main content (Split on Desktop for Home/Chat, separate on Mobile) ──
            Positioned.fill(
              child: Container(
                color: _kBg,
                child: _buildContent(isDesktop),
              ),
            ),

            // ── Glass horizontal bottom nav bar (Mobile only) ─────────────
            if (!isDesktop && _menuVisible && !hideBottomNav)
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: SlideTransition(
                  position: _menuSlide,
                  child: FadeTransition(
                    opacity: _menuFade,
                    child: _buildGlassNavBar(),
                  ),
                ),
              ),

            if (!isDesktop && !_menuVisible && !hideBottomNav)
              Positioned(
                right: 24,
                bottom: 24,
                child: _buildCollapseButton(collapsed: true),
              ),
          ],
        ),
      ),
    ),
  );
}

  // ── Full glass horizontal nav bar ──────────────────────────────────────────
  Widget _buildGlassNavBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _kBlur / 2, sigmaY: _kBlur / 2),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF09090B).withOpacity(0.72),
            borderRadius: BorderRadius.circular(_kRadius),
            border: Border.all(color: _kBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.50),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // 4 primary nav icons (scrollable row for all 6)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(
                      _icons.length,
                      (i) => _navIcon(i),
                    ),
                  ),
                ),
              ),

              // Thin divider
              Container(
                width: 1,
                height: 28,
                color: _kBorder,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),

              // Hide / collapse button — same glass style
              _buildCollapseButton(collapsed: false),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }

  // ── Individual nav icon ────────────────────────────────────────────────────
  Widget _navIcon(int index) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _navigateToTab(index),
      child: AnimatedContainer(
        duration: AppAnimations.micro,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          // Exactly like the Run button — glass highlight when active
          color: isActive ? _kHigh : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? _kHigh : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.12),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            _icons[index],
            size: 20,
            color: isActive ? Colors.white : const Color(0xFF666680),
          ),
        ),
      ),
    );
  }

  // ── Hide / Expand button ───────────────────────────────────────────────────
  Widget _buildCollapseButton({required bool collapsed}) {
    return GestureDetector(
      onTap: collapsed ? _showMenu : _hideMenu,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _kBlur / 2, sigmaY: _kBlur / 2),
          child: AnimatedContainer(
            duration: AppAnimations.micro,
            width: collapsed ? 42 : 38,
            height: collapsed ? 42 : 38,
            decoration: BoxDecoration(
              color: _kGlass,
              shape: BoxShape.circle,
              border: Border.all(color: _kBorder, width: 1.2),
              boxShadow: collapsed
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                collapsed ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                color: Colors.white,
                size: collapsed ? 20 : 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
