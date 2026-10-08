import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/spring_button.dart';
import '../widgets/accounts_list_modal.dart';
import '../models/user_profile.dart';
import '../utils/app_animations.dart';
import '../utils/mock_data.dart';
import 'user_profile_detail_screen.dart';
import 'saved_posts_screen.dart';
import '../widgets/morphing_capsule.dart';
import '../services/payment_service.dart';
import '../services/supabase_service.dart';
import 'admin_dashboard_screen.dart';

// ── Liquid Glass Color Tokens (Strict Glass Palette: Obsidian, White, Cyan) ──
const _kBgDark        = Color(0xFF09090B);
const _kGlassSurface   = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
const _kGlassElevated  = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
const _kGlassBorder    = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
const _kGlassHighlight = Color(0x40FFFFFF); // rgba(255,255,255,0.25)
const _kAccentCyan     = Color(0xFF54C5F8); // Pure Ice-Cyan highlight

class ProfileScreen extends StatefulWidget {
  final bool isSettingsOnly;
  const ProfileScreen({super.key, this.isSettingsOnly = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late bool _showingSettings;

  @override
  void initState() {
    super.initState();
    _showingSettings = widget.isSettingsOnly;
  }
  // ── Local Settings State ───────────────────────────────────────────────────
  // Appearance & Glass
  double _glassBlurSigma = 24.0;
  String _editorTheme = 'Liquid Obsidian';
  bool _compactMobileUI = false;
  bool _fluidSpringPhysics = true;

  // Snaps, Feed & Privacy
  bool _privateAccount = false;
  bool _autoPlayFeedVideos = true;
  bool _highQualityUploads = true;
  bool _showOnlineStatus = true;
  String _hideUiSensitivity = 'Normal';

  // Developer Tools & Workspace
  String _defaultLanguage = 'Flutter / Dart';
  bool _autoSaveCode = true;
  bool _formatOnRun = true;
  String _terminalShell = 'Integrated Zsh';
  bool _githubSyncConnected = true;

  // Notifications
  bool _pushNotifications = true;
  bool _snapsAndMentions = true;
  bool _codeReviewReminders = true;
  bool _hapticFeedback = true;

  // Storage & Cache
  double _notesCacheMb = 142.4;
  double _mediaCacheMb = 48.6;
  bool _isClearingCache = false;

  // Account & Security
  bool _twoFactorAuth = true;

  // Network stats
  int _snappedCount = 1840;
  int _snappingCount = 320;

  void _showGlassToast(String message, {IconData? icon, bool isSuccess = true}) {
    MorphingCapsule.show(
      context,
      icon: icon ?? (isSuccess ? LucideIcons.checkCircle2 : LucideIcons.info),
      label: message,
      color: isSuccess ? _kAccentCyan : Colors.white70,
    );
    return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kBgDark.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kGlassBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    icon ?? (isSuccess ? LucideIcons.checkCircle2 : LucideIcons.info),
                    color: isSuccess ? _kAccentCyan : Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
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
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  void _clearCache() async {
    setState(() => _isClearingCache = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        _notesCacheMb = 0.0;
        _mediaCacheMb = 0.0;
        _isClearingCache = false;
      });
      _showGlassToast('Local books & media cache cleared (191 MB freed)!',
          icon: LucideIcons.trash2);
    }
  }

  void _openAccountsModal(int initialTab) {
    AccountsListModal.show(
      context,
      initialTab: initialTab,
      snappedCount: _snappedCount,
      snappingCount: _snappingCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (!_showingSettings) {
      final realProfile = user != null
          ? user.toUserProfile()
          : UserProfile(
              id: 'guest',
              name: 'My Profile',
              handle: '@developer',
              avatarUrl: '',
              bannerUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1200&q=80',
              headline: '',
              bio: '',
              roleBadge: 'Developer',
              followersCount: 0,
              followingCount: 0,
              postsCount: 0,
            );
      return UserProfileDetailScreen(
        user: realProfile,
        isSelf: true,
        onSettingsPressed: () => setState(() => _showingSettings = true),
      );
    }
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: _kBgDark,
      body: Stack(
        children: [
          // Background ambient frosted glass lights
          Positioned(
            top: -120,
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
            top: 300,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 18,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Title Row with Back to Profile button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SpringButton(
                            onTap: () {
                              if (widget.isSettingsOnly && Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                setState(() => _showingSettings = false);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _kGlassElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _kGlassBorder),
                              ),
                              child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 18),
                            ),
                          ),
                          const Text(
                            'Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kGlassElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kGlassBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.shieldCheck, color: _kAccentCyan, size: 13),
                            SizedBox(width: 5),
                            Text(
                              'Verified Dev',
                              style: TextStyle(
                                color: _kAccentCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 2. Liquid Glass User Identity Card
                  _buildUserIdentityCard(user),
                  const SizedBox(height: 20),

                  // 3. Pro Subscription Card
                  _buildSubscriptionCard(),
                  const SizedBox(height: 14),
                  _buildPaymentHistoryCard(),
                  const SizedBox(height: 24),

                  // 4. Section: Appearance & Glass Theme
                  _buildSectionHeader('Appearance & Glass Theme', LucideIcons.palette),
                  const SizedBox(height: 10),
                  _buildAppearanceCard(),
                  const SizedBox(height: 22),

                  // 5. Section: Snaps, Feed & Privacy
                  _buildSectionHeader('Snaps, Feed & Privacy', LucideIcons.lock),
                  const SizedBox(height: 10),
                  _buildPrivacyCard(),
                  const SizedBox(height: 22),

                  // 6. Section: Developer Tools & Workspace
                  _buildSectionHeader('Developer Tools & Workspace', LucideIcons.code),
                  const SizedBox(height: 10),
                  _buildWorkspaceSettingsCard(),
                  const SizedBox(height: 22),

                  // 7. Section: Notifications & Alerts
                  _buildSectionHeader('Notifications & Reminders', LucideIcons.bell),
                  const SizedBox(height: 10),
                  _buildNotificationsCard(),
                  const SizedBox(height: 22),

                  // 8. Section: Storage, Books & Cache
                  _buildSectionHeader('Storage & Offline Cache', LucideIcons.hardDrive),
                  const SizedBox(height: 10),
                  _buildStorageCard(),
                  const SizedBox(height: 22),

                  // 9. Section: Account, Security & Sessions
                  _buildSectionHeader('Account & Security', LucideIcons.key),
                  const SizedBox(height: 10),
                  _buildSecurityCard(authProvider),
                  const SizedBox(height: 22),

                  // 10. Section: About Bug
                  _buildSectionHeader('About Bug', LucideIcons.info),
                  const SizedBox(height: 10),
                  _buildAboutBugCard(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. User Identity & Social Network Card ──────────────────────────────────
  Widget _buildUserIdentityCard(dynamic user) {
    return GestureDetector(
      onTap: () {
        if (widget.isSettingsOnly && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          setState(() => _showingSettings = false);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: _kGlassSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _kGlassBorder),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
        children: [
          Row(
            children: [
              // Avatar with Online dot and clean fallback
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _kGlassHighlight, width: 2),
                      color: _kGlassElevated,
                    ),
                    child: ClipOval(
                      child: (user?.avatarUrl != null && (user!.avatarUrl as String).isNotEmpty)
                          ? Image.network(
                              user!.avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(LucideIcons.user, color: Colors.white70, size: 36),
                            )
                          : const Icon(LucideIcons.user, color: Colors.white70, size: 36),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBgDark, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Name, Handle, Department
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            (user?.name != null && (user!.name as String).isNotEmpty)
                                ? user!.name
                                : (user?.email != null && (user!.email as String).isNotEmpty
                                    ? user!.email.split('@').first
                                    : 'Developer'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: _kAccentCyan, size: 15),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'Logged in via Supabase',
                      style: const TextStyle(
                        color: Color(0xFF888899),
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kGlassElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kGlassBorder),
                      ),
                      child: Text(
                        (user?.section != null && (user!.section as String).isNotEmpty)
                            ? '@${user!.section}'
                            : (user?.department != null && (user!.department as String).isNotEmpty
                                ? user!.department
                                : 'Developer · CodeSnap'),
                        style: const TextStyle(
                          color: _kAccentCyan,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SpringButton(
            onTap: () {
              if (widget.isSettingsOnly && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                setState(() => _showingSettings = false);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: _kAccentCyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kAccentCyan.withOpacity(0.4)),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.userCheck, size: 14, color: _kAccentCyan),
                  SizedBox(width: 8),
                  Text(
                    'Customize Profile & Set Bio',
                    style: TextStyle(
                      color: _kAccentCyan,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Snapped (Followers) & Snapping (Following) Social Stats
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF121318),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kGlassBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildClickableStat(
                  label: 'Snapped',
                  value: '$_snappedCount',
                  icon: LucideIcons.users,
                  onTap: () => _openAccountsModal(0),
                ),
                _buildStatDivider(),
                _buildClickableStat(
                  label: 'Snapping',
                  value: '$_snappingCount',
                  icon: LucideIcons.userCheck,
                  onTap: () => _openAccountsModal(1),
                ),
                _buildStatDivider(),
                _buildClickableStat(
                  label: 'Tasks',
                  value: '24',
                  icon: LucideIcons.checkSquare,
                ),
                _buildStatDivider(),
                _buildClickableStat(
                  label: 'Streak',
                  value: '12d 🔥',
                  icon: LucideIcons.flame,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action buttons: Edit Profile & Share Network
          Row(
            children: [
              Expanded(
                child: SpringButton(
                  onTap: () {
                    if (widget.isSettingsOnly && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() => _showingSettings = false);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _kGlassElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kGlassBorder),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.userCog, color: Colors.white, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SpringButton(
                  onTap: () => _showGlassToast('Profile link copied to clipboard!', icon: LucideIcons.share2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _kAccentCyan.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kAccentCyan.withOpacity(0.55)),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.share2, color: _kAccentCyan, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Share Network',
                          style: TextStyle(
                            color: _kAccentCyan,
                            fontSize: 12.5,
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
    );
  }

  Widget _buildClickableStat({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final col = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: onTap != null ? _kAccentCyan : Colors.white70, size: 12),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: onTap != null ? _kAccentCyan : const Color(0xFF888899),
            fontSize: 11,
            fontWeight: onTap != null ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return SpringButton(
        onTap: onTap,
        scale: 0.92,
        child: col,
      );
    }
    return col;
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 22,
      color: _kGlassBorder,
    );
  }

  // ── 2. Subscription Card ───────────────────────────────────────────────────
  Widget _buildSubscriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kGlassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGlassBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kAccentCyan.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: _kAccentCyan.withOpacity(0.5)),
            ),
            child: const Icon(LucideIcons.sparkles, color: _kAccentCyan, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bug Workspace Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Active: ₹ 149 / mo • Unlimited Cloud Terminals',
                  style: TextStyle(
                    color: Color(0xFF888899),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          SpringButton(
            onTap: () => _showGlassToast('Manage subscription portal loaded'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _kGlassElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kGlassBorder),
              ),
              child: const Text(
                'Manage',
                style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryCard() {
    final paymentService = PaymentService.instance;
    return Container(
      decoration: BoxDecoration(
        color: _kGlassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGlassBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: const Icon(LucideIcons.receipt, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment History & Invoices',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Unlocked books, notes, and memberships',
                      style: TextStyle(
                        color: Color(0xFF888899),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              SpringButton(
                onTap: () => _openPaymentHistoryModal(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kGlassElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kGlassBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 4),
                      Icon(LucideIcons.chevronRight, color: Colors.white70, size: 13),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: _kGlassBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    paymentService.history.isNotEmpty
                        ? paymentService.history.first.itemTitle
                        : 'Flutter & Dart: Production Architecture',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Text(
                paymentService.history.isNotEmpty
                    ? '\$${paymentService.history.first.amount.toStringAsFixed(2)}'
                    : '\$4.99',
                style: const TextStyle(color: _kAccentCyan, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openPaymentHistoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final history = PaymentService.instance.history;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF111217),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0x33FFFFFF))),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Icon(LucideIcons.receipt, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Payment History & Receipts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0x1FFFFFFF), height: 1),
              Expanded(
                child: history.isEmpty
                    ? const Center(
                        child: Text(
                          'No payment transactions yet',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0x14FFFFFF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0x22FFFFFF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.itemTitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.timestamp} • ${item.paymentMethod}',
                                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${item.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Receipt: ${item.receiptId}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 10.5, fontFamily: 'monospace'),
                                    ),
                                    SpringButton(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _showGlassToast('Receipt ${item.receiptId} downloaded to device', icon: LucideIcons.fileCheck);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(LucideIcons.download, size: 11, color: Colors.white70),
                                            SizedBox(width: 4),
                                            Text('Invoice', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Section Header Helper ──────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _kAccentCyan, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ── 3. Appearance & Glass Settings Card ─────────────────────────────────────
  Widget _buildAppearanceCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kGlassSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGlassBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Glass Blur Intensity Slider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Liquid Glass Blur Sigma',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${_glassBlurSigma.toInt()} px',
                      style: const TextStyle(color: _kAccentCyan, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _kAccentCyan,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Colors.white,
                    overlayColor: _kAccentCyan.withOpacity(0.2),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: _glassBlurSigma,
                    min: 10,
                    max: 50,
                    divisions: 8,
                    onChanged: (val) {
                      setState(() => _glassBlurSigma = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: _kGlassBorder, height: 1),

          // Code Editor Syntax Theme
          _buildDropdownTile(
            label: 'Code Editor Theme',
            subtitle: 'Syntax colors in Workspace editor',
            value: _editorTheme,
            options: const ['Liquid Obsidian', 'Cyberpunk', 'One Dark', 'GitHub Dark'],
            onChanged: (val) {
              if (val != null) {
                setState(() => _editorTheme = val);
                _showGlassToast('Editor theme set to $val');
              }
            },
          ),
          const Divider(color: _kGlassBorder, height: 1),

          // Compact Mobile UI
          _buildSwitchTile(
            label: 'Compact Mobile UI',
            subtitle: 'Reduces padding for dense code viewing on small screens',
            value: _compactMobileUI,
            onChanged: (val) => setState(() => _compactMobileUI = val),
          ),
          const Divider(color: _kGlassBorder, height: 1),

          // Fluid Spring Physics
          _buildSwitchTile(
            label: 'Fluid Spring Physics',
            subtitle: 'Interactive physics bounce on buttons and modals',
            value: _fluidSpringPhysics,
            onChanged: (val) => setState(() => _fluidSpringPhysics = val),
          ),
        ],
      ),
    );
  }

  // ── 4. Privacy & Snaps Card ────────────────────────────────────────────────
  Widget _buildPrivacyCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kGlassSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGlassBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Saved List Entry
          _buildTileRow(
            label: 'Saved List',
            subtitle: 'Posts, snippets, and project reels you saved from the feed',
            trailing: SpringButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kAccentCyan.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kAccentCyan.withOpacity(0.45)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.bookmark, color: _kAccentCyan, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Saved List',
                      style: TextStyle(
                        color: _kAccentCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(LucideIcons.chevronRight, color: _kAccentCyan, size: 14),
                  ],
                ),
              ),
            ),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildSwitchTile(
            label: 'Private Account',
            subtitle: 'Only accounts you approve can see your Snaps & code snippets',
            value: _privateAccount,
            onChanged: (val) {
              setState(() => _privateAccount = val);
              _showGlassToast(val ? 'Account is now Private' : 'Account is now Public');
            },
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildSwitchTile(
            label: 'Auto-Play Feed Videos',
            subtitle: 'Play code walkthrough videos automatically while scrolling',
            value: _autoPlayFeedVideos,
            onChanged: (val) => setState(() => _autoPlayFeedVideos = val),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildSwitchTile(
            label: 'High-Quality Media Uploads',
            subtitle: 'Upload full-resolution code screenshots and screen captures',
            value: _highQualityUploads,
            onChanged: (val) => setState(() => _highQualityUploads = val),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildSwitchTile(
            label: 'Show Online Activity Status',
            subtitle: 'Allow snapped connections to see your green active dot',
            value: _showOnlineStatus,
            onChanged: (val) => setState(() => _showOnlineStatus = val),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildDropdownTile(
            label: 'Hold-To-Hide UI Sensitivity',
            subtitle: 'Long-press duration on full screen feeds to hide controls',
            value: _hideUiSensitivity,
            options: const ['Normal', 'High (Instant)', 'Relaxed'],
            onChanged: (val) {
              if (val != null) setState(() => _hideUiSensitivity = val);
            },
          ),
        ],
      ),
    );
  }

  // ── 5. Developer Tools & Workspace Settings Card ───────────────────────────
  Widget _buildWorkspaceSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kGlassSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGlassBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildDropdownTile(
            label: 'Default Runtime',
            subtitle: 'Primary compiler initialized on new projects',
            value: _defaultLanguage,
            options: const ['Flutter / Dart', 'Python 3.12', 'TypeScript / Node', 'Rust 1.78', 'C++ 20'],
            onChanged: (val) {
              if (val != null) setState(() => _defaultLanguage = val);
            },
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildSwitchTile(
            label: 'Auto-Save Code Changes',
            subtitle: 'Automatically persist edits to local workspace storage',
            value: _autoSaveCode,
            onChanged: (val) => setState(() => _autoSaveCode = val),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildSwitchTile(
            label: 'Format Code on Run / Save',
            subtitle: 'Run dart format / prettier automatically before compiling',
            value: _formatOnRun,
            onChanged: (val) => setState(() => _formatOnRun = val),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildDropdownTile(
            label: 'Terminal Shell',
            subtitle: 'Default command line environment in Workspace',
            value: _terminalShell,
            options: const ['Integrated Zsh', 'Bash Linux', 'PowerShell Core'],
            onChanged: (val) {
              if (val != null) setState(() => _terminalShell = val);
            },
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildTileRow(
            label: 'GitHub Integration',
            subtitle: _githubSyncConnected ? 'Connected as @alexj-dev' : 'Not linked',
            trailing: SpringButton(
              onTap: () {
                setState(() => _githubSyncConnected = !_githubSyncConnected);
                _showGlassToast(_githubSyncConnected ? 'Connected to GitHub' : 'Disconnected from GitHub');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _githubSyncConnected ? _kGlassElevated : _kAccentCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _githubSyncConnected ? _kGlassBorder : _kAccentCyan.withOpacity(0.6)),
                ),
                child: Text(
                  _githubSyncConnected ? 'Disconnect' : 'Connect',
                  style: TextStyle(
                    color: _githubSyncConnected ? Colors.white70 : _kAccentCyan,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. Notifications & Reminders Card ──────────────────────────────────────
  Widget _buildNotificationsCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kGlassSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGlassBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildSwitchTile(
            label: 'Push Notifications',
            subtitle: 'Receive alerts when the app is running in background',
            value: _pushNotifications,
            onChanged: (val) => setState(() => _pushNotifications = val),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildSwitchTile(
            label: 'New Snaps & Mentions',
            subtitle: 'Notify when people snap with you or mention your handle',
            value: _snapsAndMentions,
            onChanged: (val) => setState(() => _snapsAndMentions = val),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildSwitchTile(
            label: 'Code Review & Task Reminders',
            subtitle: 'Daily learning streak and pending project task notifications',
            value: _codeReviewReminders,
            onChanged: (val) => setState(() => _codeReviewReminders = val),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildSwitchTile(
            label: 'Haptic Feedback',
            subtitle: 'Subtle device vibration on button springs and swipes',
            value: _hapticFeedback,
            onChanged: (val) => setState(() => _hapticFeedback = val),
          ),
        ],
      ),
    );
  }

  // ── 7. Storage, Offline Books & Cache Card ──────────────────────────────────
  Widget _buildStorageCard() {
    final totalMb = _notesCacheMb + _mediaCacheMb;

    return Container(
      decoration: BoxDecoration(
        color: _kGlassSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGlassBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Local Offline Storage',
                    style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Books: ${_notesCacheMb.toStringAsFixed(1)} MB • Media: ${_mediaCacheMb.toStringAsFixed(1)} MB',
                    style: const TextStyle(color: Color(0xFF888899), fontSize: 11.5),
                  ),
                ],
              ),
              Text(
                '${totalMb.toStringAsFixed(1)} MB',
                style: const TextStyle(color: _kAccentCyan, fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SpringButton(
            onTap: totalMb > 0 && !_isClearingCache ? _clearCache : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: totalMb > 0 ? _kGlassElevated : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: totalMb > 0 ? _kGlassBorder : Colors.transparent),
              ),
              alignment: Alignment.center,
              child: _isClearingCache
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.trash2, color: totalMb > 0 ? Colors.white70 : Colors.white24, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          totalMb > 0 ? 'Clear Offline Cache' : 'Cache Cleaned',
                          style: TextStyle(
                            color: totalMb > 0 ? Colors.white : Colors.white38,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 8. Security & Account Sessions Card ────────────────────────────────────
  Widget _buildSecurityCard(AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        color: _kGlassSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGlassBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Account & Security Details
          _buildTileRow(
            label: 'Email Address',
            subtitle: (authProvider.currentUser?.email != null && authProvider.currentUser!.email.isNotEmpty)
                ? authProvider.currentUser!.email
                : 'No active session',
            trailing: const Icon(LucideIcons.mail, color: _kAccentCyan, size: 16),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildTileRow(
            label: 'Username',
            subtitle: (authProvider.currentUser?.section != null && authProvider.currentUser!.section!.isNotEmpty)
                ? '@${authProvider.currentUser!.section}'
                : (authProvider.currentUser?.name != null && authProvider.currentUser!.name.isNotEmpty
                    ? '@${authProvider.currentUser!.name.toLowerCase().replaceAll(' ', '')}'
                    : '@developer'),
            trailing: const Icon(LucideIcons.user, color: Color(0xFF888899), size: 16),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildTileRow(
            label: 'Account Status',
            subtitle: 'Active Developer Account',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('VERIFIED', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
            ),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          if (authProvider.isAdmin) ...[
            _buildTileRow(
              label: 'Admin Command Center',
              subtitle: 'Manage telemetry, reported content & broadcasts',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                ),
                child: const Text('👑 ADMIN', style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
            const Divider(color: _kGlassBorder, height: 1),
          ],
          _buildSwitchTile(
            label: 'Two-Factor Authentication (2FA)',
            subtitle: 'Secure sign-ins with authenticator app or biometric key',
            value: _twoFactorAuth,
            onChanged: (val) {
              setState(() => _twoFactorAuth = val);
              _showGlassToast(val ? '2FA Enabled' : '2FA Disabled');
            },
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildTileRow(
            label: 'Change Password',
            subtitle: 'Send password reset link to your email',
            trailing: const Icon(LucideIcons.chevronRight, color: Color(0xFF888899), size: 16),
            onTap: () async {
              final email = authProvider.currentUser?.email;
              if (email != null && email.isNotEmpty) {
                try {
                  await SupabaseService.client.auth.resetPasswordForEmail(email);
                  _showGlassToast('Password reset link sent to $email', icon: LucideIcons.mail, isSuccess: true);
                } catch (e) {
                  _showGlassToast('Could not send reset link: $e', icon: LucideIcons.alertTriangle, isSuccess: false);
                }
              }
            },
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildTileRow(
            label: 'Log Out of Bug',
            subtitle: 'Sign out on this device',
            labelColor: Colors.redAccent,
            trailing: const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: AlertDialog(
                    backgroundColor: const Color(0xFF121318),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: _kGlassBorder),
                    ),
                    title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    content: const Text(
                      'Are you sure you want to log out of Bug?',
                      style: TextStyle(color: Color(0xFFCCCCCC)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          authProvider.logout();
                        },
                        child: const Text('Log Out', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 9. About Bug Card ──────────────────────────────────────────────────────
  Widget _buildAboutBugCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kGlassSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGlassBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildTileRow(
            label: 'Version',
            subtitle: 'Bug v2.4.0 (Liquid Glass Edition)',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kGlassElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Up to date', style: TextStyle(color: _kAccentCyan, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildTileRow(
            label: 'Open Source Licenses',
            subtitle: 'MIT / Flutter SDK / Lucide',
            trailing: const Icon(LucideIcons.externalLink, color: Color(0xFF888899), size: 15),
            onTap: () => _showGlassToast('Licenses opened'),
          ),
          const Divider(color: _kGlassBorder, height: 1),
          _buildTileRow(
            label: 'Report a Bug / Send Feedback',
            subtitle: 'Help us make Bug even better',
            trailing: const Icon(LucideIcons.messageSquarePlus, color: _kAccentCyan, size: 16),
            onTap: () => _showGlassToast('Feedback form submitted. Thank you!'),
          ),
        ],
      ),
    );
  }

  // ── Helper Tiles ───────────────────────────────────────────────────────────
  Widget _buildSwitchTile({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF888899), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeColor: _kAccentCyan,
            activeTrackColor: _kAccentCyan.withOpacity(0.4),
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: Colors.white12,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String label,
    required String subtitle,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF888899), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kGlassElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kGlassBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                dropdownColor: const Color(0xFF14151B),
                icon: const Icon(LucideIcons.chevronDown, color: Colors.white70, size: 14),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                items: options.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt,
                    child: Text(opt),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTileRow({
    required String label,
    required String subtitle,
    Widget? trailing,
    Color? labelColor,
    VoidCallback? onTap,
  }) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: labelColor ?? Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF888899), fontSize: 11),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );

    if (onTap != null) {
      return SpringButton(
        onTap: onTap,
        scale: 0.98,
        child: row,
      );
    }
    return row;
  }
}
