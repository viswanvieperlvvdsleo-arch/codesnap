import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/spring_button.dart';
import '../models/user_profile.dart';
import '../utils/mock_data.dart';
import 'user_profile_detail_screen.dart';
import 'chat_screen.dart';
import 'individual_chat_screen.dart';

// ── Liquid Glass Color Tokens ────────────────────────────────────────────────
const _kBgDark        = Color(0xFF09090B);
const _kGlassSurface   = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
const _kGlassElevated  = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
const _kGlassBorder    = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
const _kAccentCyan     = Color(0xFF54C5F8);
const _kAccentGold     = Color(0xFFFFD700);
const _kAccentPink     = Color(0xFFFF4864);
const _kAccentBlue     = Color(0xFF4A68FF);

enum NotificationCategory { all, snaps, likes, comments, mentions, system }

class NotificationItem {
  final String id;
  final String actorName;
  final String actorHandle;
  final String actorAvatar;
  final String message;
  final String timeAgo;
  final NotificationCategory category;
  final IconData icon;
  final Color iconColor;
  bool isRead;
  final String? postSnippet;

  NotificationItem({
    required this.id,
    required this.actorName,
    required this.actorHandle,
    required this.actorAvatar,
    required this.message,
    required this.timeAgo,
    required this.category,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
    this.postSnippet,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;

  late List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      NotificationItem(
        id: 'n1',
        actorName: 'Prabhatt',
        actorHandle: 'prabhatt_n07',
        actorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        message: 'liked your post "Fluid liquid glass shader on mobile"',
        timeAgo: '5m ago',
        category: NotificationCategory.likes,
        icon: LucideIcons.heart,
        iconColor: _kAccentPink,
        isRead: false,
        postSnippet: 'Liquid glass shader preview with live blur',
      ),
      NotificationItem(
        id: 'n2',
        actorName: 'Sowmya Sri',
        actorHandle: 'sowmya_sri__143_',
        actorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        message: 'started snapping with you',
        timeAgo: '18m ago',
        category: NotificationCategory.snaps,
        icon: LucideIcons.userPlus,
        iconColor: _kAccentBlue,
        isRead: false,
      ),
      NotificationItem(
        id: 'n3',
        actorName: 'Sairam Mallipudi',
        actorHandle: '_sairam_mallipudi_',
        actorAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
        message: 'commented: "The specular highlights and 60fps blur are super crisp! 🔥"',
        timeAgo: '42m ago',
        category: NotificationCategory.comments,
        icon: LucideIcons.messageSquare,
        iconColor: _kAccentCyan,
        isRead: false,
        postSnippet: 'CodeSnap architecture specs',
      ),
      NotificationItem(
        id: 'n4',
        actorName: 'Elena Rostova',
        actorHandle: 'elena.codes',
        actorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        message: 'mentioned you in a comment: "@you check out the GLSL shader pass"',
        timeAgo: '1h ago',
        category: NotificationCategory.mentions,
        icon: LucideIcons.atSign,
        iconColor: _kAccentGold,
        isRead: true,
      ),
      NotificationItem(
        id: 'n5',
        actorName: 'Gowtham Kumar',
        actorHandle: 'gowtham401945',
        actorAvatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200',
        message: 'started snapping with you',
        timeAgo: '3h ago',
        category: NotificationCategory.snaps,
        icon: LucideIcons.userPlus,
        iconColor: _kAccentBlue,
        isRead: true,
      ),
      NotificationItem(
        id: 'n6',
        actorName: 'CodeSnap Core',
        actorHandle: 'system',
        actorAvatar: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=200',
        message: 'Your moment was featured in the Community Daily Digest!',
        timeAgo: 'Yesterday',
        category: NotificationCategory.system,
        icon: LucideIcons.sparkles,
        iconColor: _kAccentGold,
        isRead: true,
      ),
      NotificationItem(
        id: 'n7',
        actorName: 'Nandhini',
        actorHandle: 'nandhini.11117',
        actorAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
        message: 'liked your moment "Kyoto Dusk Aesthetics"',
        timeAgo: '2d ago',
        category: NotificationCategory.likes,
        icon: LucideIcons.heart,
        iconColor: _kAccentPink,
        isRead: true,
      ),
    ];
  }

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openActorProfile(NotificationItem item) {
    final user = MockData.getUserProfileForAuthor(
      username: item.actorHandle,
      avatarUrl: item.actorAvatar,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => UserProfileDetailScreen(user: user),
      ),
    );
  }

  void _openDirectChatWithActor(NotificationItem item) {
    final store = ChatStateStore.instance;
    ChatConversation? conv;
    try {
      conv = store.conversations.firstWhere(
        (c) =>
            c.name.toLowerCase() == item.actorName.toLowerCase() ||
            c.name.toLowerCase() == item.actorHandle.toLowerCase(),
      );
    } catch (_) {
      conv = ChatConversation(
        id: 'user_${item.actorHandle}',
        name: item.actorName,
        role: '@${item.actorHandle}',
        avatarUrl: item.actorAvatar,
        isOnline: true,
        lastMessage: 'Started chatting',
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

  void _handleNotificationTap(NotificationItem item) {
    setState(() => item.isRead = true);

    if (item.category == NotificationCategory.snaps) {
      _openActorProfile(item);
    } else if (item.category == NotificationCategory.comments ||
        item.category == NotificationCategory.likes ||
        item.category == NotificationCategory.mentions) {
      _openActorProfile(item);
    } else {
      _openActorProfile(item);
    }
  }

  List<NotificationItem> get _filteredNotifications {
    if (_selectedCategory == NotificationCategory.all) {
      return _notifications;
    }
    return _notifications.where((n) => n.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: _kBgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────────────────────────
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
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kAccentCyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kAccentCyan.withOpacity(0.5)),
                      ),
                      child: Text(
                        '$unreadCount new',
                        style: const TextStyle(
                          color: _kAccentCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  SpringButton(
                    onTap: _markAllAsRead,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kGlassSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kGlassBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.checkCheck, color: Colors.white70, size: 15),
                          SizedBox(width: 6),
                          Text(
                            'Read all',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Category Filter Pills ─────────────────────────────────────────
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('All', NotificationCategory.all),
                  _buildCategoryChip('Snaps', NotificationCategory.snaps),
                  _buildCategoryChip('Likes', NotificationCategory.likes),
                  _buildCategoryChip('Comments', NotificationCategory.comments),
                  _buildCategoryChip('Mentions', NotificationCategory.mentions),
                  _buildCategoryChip('System', NotificationCategory.system),
                ],
              ),
            ),

            // ── Notifications List ───────────────────────────────────────────
            Expanded(
              child: _filteredNotifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.bellOff, size: 48, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications in this category',
                            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final item = _filteredNotifications[index];
                        return Dismissible(
                          key: ValueKey('notif_${item.id}'),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerLeft,
                            child: const Row(
                              children: [
                                Icon(LucideIcons.trash2, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          secondaryBackground: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                SizedBox(width: 8),
                                Icon(LucideIcons.trash2, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                          onDismissed: (direction) {
                            final removedItem = item;
                            final removedIndex = _notifications.indexOf(item);
                            setState(() {
                              _notifications.remove(item);
                            });
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1E1F2A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                content: const Text(
                                  'Notification removed',
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                ),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  textColor: const Color(0xFF54C5F8),
                                  onPressed: () {
                                    setState(() {
                                      if (removedIndex >= 0 && removedIndex <= _notifications.length) {
                                        _notifications.insert(removedIndex, removedItem);
                                      } else {
                                        _notifications.add(removedItem);
                                      }
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          child: _buildNotificationCard(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, NotificationCategory cat) {
    final isSelected = _selectedCategory == cat;

    return SpringButton(
      onTap: () => setState(() => _selectedCategory = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kAccentCyan.withOpacity(0.22) : _kGlassSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kAccentCyan.withOpacity(0.6) : _kGlassBorder,
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _kAccentCyan : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return GestureDetector(
      onTap: () => _handleNotificationTap(item),
      child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.isRead ? const Color(0xFF111218) : const Color(0xFF161824),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead ? _kGlassBorder : _kAccentCyan.withOpacity(0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with badge overlay
          GestureDetector(
            onTap: () => _openActorProfile(item),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF27272A),
                  backgroundImage: NetworkImage(item.actorAvatar),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF09090B),
                      shape: BoxShape.circle,
                      border: Border.all(color: item.iconColor, width: 1.2),
                    ),
                    child: Icon(item.icon, size: 10, color: item.iconColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Message & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35),
                    children: [
                      TextSpan(
                        text: item.actorName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: item.message,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      item.timeAgo,
                      style: TextStyle(
                        color: const Color(0xFF8E8E93),
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (!item.isRead)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _kAccentCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Action shortcut: Message or Profile
          if (item.category == NotificationCategory.snaps ||
              item.category == NotificationCategory.comments) ...[
            const SizedBox(width: 8),
            SpringButton(
              onTap: () {
                setState(() => item.isRead = true);
                _openDirectChatWithActor(item);
              },
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _kGlassElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kGlassBorder),
                ),
                child: const Icon(LucideIcons.messageSquare, size: 14, color: _kAccentCyan),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}
