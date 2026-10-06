import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/spring_button.dart';
import 'media_links_docs_screen.dart';
import 'chat_screen.dart';

class CommonGroup {
  final String name;
  final String membersDescription;
  final String iconEmoji;

  const CommonGroup({
    required this.name,
    required this.membersDescription,
    required this.iconEmoji,
  });
}

class ContactInfoScreen extends StatefulWidget {
  final String contactName;
  final String contactAvatar;
  final String contactHandle;
  final String contactBio;
  final bool isOnline;
  final ChatWallpaperConfig? wallpaper;
  final VoidCallback? onBack;

  const ContactInfoScreen({
    super.key,
    this.contactName = 'Alex Rivers',
    this.contactAvatar = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&auto=format&fit=crop&q=80',
    this.contactHandle = '+1 (555) 382-9104',
    this.contactBio = 'Building next-gen distributed mobile developer tools & zero-cost AI agents. 🚀',
    this.isOnline = true,
    this.wallpaper,
    this.onBack,
  });

  @override
  State<ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<ContactInfoScreen> {
  bool _muteNotifications = false;
  String _disappearingMessages = 'Off';
  bool _isStarred = false;

  final List<String> _mediaThumbnails = const [
    'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=300&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=300&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=300&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=300&auto=format&fit=crop&q=80',
  ];

  final List<CommonGroup> _commonGroups = const [
    CommonGroup(
      name: 'CodeSnap Mobile IDE Core',
      membersDescription: 'You, Alex, Sarah, +5 others',
      iconEmoji: '⚡',
    ),
    CommonGroup(
      name: 'Arena Hackathon Alpha Team',
      membersDescription: 'You, Alex, Ryan',
      iconEmoji: '🏆',
    ),
    CommonGroup(
      name: 'Zero-Cost AI Terminal Ops',
      membersDescription: 'You, Alex, DevAdmin',
      iconEmoji: '🤖',
    ),
  ];

  void _openMediaLinksDocs() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => MediaLinksDocsScreen(contactName: widget.contactName),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            child: child,
          );
        },
      ),
    );
  }

  void _showActionToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF181824),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.20),
                    const Color(0xFF222B3D).withOpacity(0.55),
                    const Color(0xFF141926).withOpacity(0.65),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: const Color(0xFF54C5F8).withOpacity(0.12),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmColor.withOpacity(0.2),
                          foregroundColor: confirmColor,
                          side: BorderSide(color: confirmColor.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWallpaperBackground() {
    final wp = widget.wallpaper;
    if (wp == null) {
      return Container(color: const Color(0xFF09090B));
    }

    if (wp.type == 'image' && wp.imageUrl != null) {
      final img = wp.imageUrl!;
      Widget imageWidget;
      if (img.startsWith('data:image')) {
        try {
          final bytes = base64Decode(img.split(',').last);
          imageWidget = Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        } catch (_) {
          imageWidget = Container(color: const Color(0xFF09090B));
        }
      } else {
        imageWidget = Image.network(
          img,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF09090B)),
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final dx = wp.alignmentX * (w * 0.5);
              final dy = wp.alignmentY * (h * 0.5);
              return ClipRect(
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.scale(
                    scale: wp.scale,
                    alignment: Alignment.center,
                    child: SizedBox.expand(child: imageWidget),
                  ),
                ),
              );
            },
          ),
          if (wp.blur > 0.1)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: wp.blur, sigmaY: wp.blur),
              child: const SizedBox.expand(),
            ),
          Container(
            color: Colors.black.withOpacity((1.0 - wp.opacity).clamp(0.0, 0.95)),
          ),
        ],
      );
    } else if (wp.type == 'gradient' && wp.gradientColors != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: wp.gradientColors!,
          ),
        ),
      );
    } else {
      return Container(
        color: wp.solidColor ?? const Color(0xFF09090B),
      );
    }
  }

  BoxDecoration _glassCardDecoration({BorderRadius? borderRadius}) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.12),
          Colors.white.withOpacity(0.04),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.18),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.onBack == null && Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.onBack != null) {
          widget.onBack!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background Wallpaper
            _buildWallpaperBackground(),

            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Transparent App Bar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  leading: SpringButton(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                          border: Border.all(color: Colors.white.withOpacity(0.20)),
                        ),
                        child: const Icon(LucideIcons.chevronLeft, size: 22, color: Colors.white),
                      ),
                    ),
                  ),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
                    onPressed: () {
                      _showActionToast('Contact options menu');
                    },
                  ),
                ],
                title: const Text(
                  'Contact info',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),

              // Main Profile Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // 1. Profile Avatar & Name Card
                      _buildProfileHero(),
                      const SizedBox(height: 16),

                      // 2. Action Buttons (Audio, Video, Search)
                      _buildActionButtonsRow(),
                      const SizedBox(height: 16),

                      // 3. Bio / About Section
                      _buildAboutSection(),
                      const SizedBox(height: 16),

                      // 4. Media, Links and Docs Preview Container
                      _buildMediaLinksDocsPreview(),
                      const SizedBox(height: 16),

                      // 5. Notifications & Preferences
                      _buildPreferencesCard(),
                      const SizedBox(height: 16),

                      // 6. Security & Encryption
                      _buildEncryptionCard(),
                      const SizedBox(height: 16),

                      // 7. Groups in Common
                      _buildGroupsInCommonCard(),
                      const SizedBox(height: 16),

                      // 8. Danger Zone / Actions (Block, Report, Clear)
                      _buildDangerZoneActions(),
                      const SizedBox(height: 40),
                    ],
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

  // 1. Profile Hero Avatar & Names
  Widget _buildProfileHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _glassCardDecoration(borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          // Avatar with liquid glass ring
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF54C5F8), Color(0xFFB388FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF54C5F8).withOpacity(0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundImage: NetworkImage(widget.contactAvatar),
                ),
              ),
              if (widget.isOnline)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF09090B), width: 3.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.contactName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.contactHandle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: (widget.isOnline ? const Color(0xFF00E676) : Colors.white24).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.isOnline ? 'Active in Workspace' : 'Last seen recently',
              style: TextStyle(
                color: widget.isOnline ? const Color(0xFF00E676) : Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Action Buttons (Audio, Video, Search)
  Widget _buildActionButtonsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: LucideIcons.phone,
            label: 'Audio',
            onTap: () => _showActionToast('Starting voice call with ${widget.contactName}...'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: LucideIcons.video,
            label: 'Video',
            onTap: () => _showActionToast('Starting video code review session...'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: LucideIcons.search,
            label: 'Search',
            onTap: () => _showActionToast('Search in conversation active'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: _glassCardDecoration(borderRadius: BorderRadius.circular(18)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF54C5F8).withOpacity(0.12),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF54C5F8)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. About / Bio section
  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _glassCardDecoration(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.info, size: 16, color: Color(0xFF54C5F8)),
              const SizedBox(width: 8),
              Text(
                'About',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.contactBio,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Updated Yesterday at 18:24',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Media, Links and Docs Preview Container
  Widget _buildMediaLinksDocsPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _glassCardDecoration(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          SpringButton(
            onTap: _openMediaLinksDocs,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Media, links and docs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '84 shared files & items',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '84',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronRight, size: 18, color: Colors.white54),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 4 horizontal thumbnail previews
          Row(
            children: _mediaThumbnails.map((thumbUrl) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SpringButton(
                    onTap: _openMediaLinksDocs,
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          thumbUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.white.withOpacity(0.1),
                            child: const Icon(LucideIcons.image, size: 18, color: Colors.white38),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 5. Notifications & Preferences
  Widget _buildPreferencesCard() {
    return Container(
      decoration: _glassCardDecoration(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          // Mute Notifications
          SwitchListTile(
            title: const Text(
              'Mute notifications',
              style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _muteNotifications ? 'Muted' : 'Unmuted',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
            value: _muteNotifications,
            activeColor: const Color(0xFF54C5F8),
            onChanged: (val) {
              setState(() => _muteNotifications = val);
              _showActionToast(val ? 'Notifications muted' : 'Notifications unmuted');
            },
          ),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          // Custom Notifications
          ListTile(
            title: const Text('Custom notifications', style: TextStyle(color: Colors.white, fontSize: 14.5)),
            trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.white54),
            onTap: () => _showActionToast('Custom notification tone settings'),
          ),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          // Starred Messages
          ListTile(
            leading: const Icon(LucideIcons.star, size: 20, color: Color(0xFFFFD700)),
            title: const Text('Starred messages', style: TextStyle(color: Colors.white, fontSize: 14.5)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('6', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronRight, size: 18, color: Colors.white54),
              ],
            ),
            onTap: () => _showActionToast('Opening starred messages'),
          ),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          // Disappearing Messages
          ListTile(
            leading: const Icon(LucideIcons.clock, size: 20, color: Color(0xFFB388FF)),
            title: const Text('Disappearing messages', style: TextStyle(color: Colors.white, fontSize: 14.5)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_disappearingMessages, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronRight, size: 18, color: Colors.white54),
              ],
            ),
            onTap: () {
              setState(() {
                _disappearingMessages = _disappearingMessages == 'Off' ? '24 hours' : 'Off';
              });
              _showActionToast('Disappearing messages set to $_disappearingMessages');
            },
          ),
        ],
      ),
    );
  }

  // 6. Security & Encryption
  Widget _buildEncryptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassCardDecoration(borderRadius: BorderRadius.circular(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00E676).withOpacity(0.12),
            ),
            child: const Icon(LucideIcons.lock, size: 18, color: Color(0xFF00E676)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'End-to-end encryption',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Messages and calls are end-to-end encrypted. No one outside of this chat, not even CodeSnap, can read or listen to them.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 7. Groups & Projects in Common
  Widget _buildGroupsInCommonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassCardDecoration(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Teams in common',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${_commonGroups.length}',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Create group with Alex
          SpringButton(
            onTap: () => _showActionToast('Creating new shared team with ${widget.contactName}...'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF54C5F8).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.users, size: 20, color: Color(0xFF54C5F8)),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Create team with ${widget.contactName}',
                    style: const TextStyle(
                      color: Color(0xFF54C5F8),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.08)),
          // Common groups list
          ..._commonGroups.map((group) {
            return SpringButton(
              onTap: () => _showActionToast('Opening ${group.name} workspace'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Center(
                        child: Text(group.iconEmoji, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            group.membersDescription,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 16, color: Colors.white38),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 8. Danger Zone Actions
  Widget _buildDangerZoneActions() {
    return Container(
      decoration: _glassCardDecoration(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          // Add to Favourites
          ListTile(
            leading: const Icon(LucideIcons.heart, size: 20, color: Color(0xFFFF5252)),
            title: const Text('Add to favourites', style: TextStyle(color: Colors.white, fontSize: 14.5)),
            onTap: () => _showActionToast('Added ${widget.contactName} to favourites'),
          ),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          // Export Chat
          ListTile(
            leading: const Icon(LucideIcons.share2, size: 20, color: Colors.white70),
            title: const Text('Export chat', style: TextStyle(color: Colors.white, fontSize: 14.5)),
            onTap: () => _showActionToast('Exporting conversation transcript...'),
          ),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          // Clear Chat
          ListTile(
            leading: const Icon(LucideIcons.trash2, size: 20, color: Colors.white70),
            title: const Text('Clear chat', style: TextStyle(color: Colors.white, fontSize: 14.5)),
            onTap: () {
              _showConfirmDialog(
                title: 'Clear Chat?',
                message: 'All messages in this chat will be cleared from this device.',
                confirmText: 'Clear Chat',
                confirmColor: const Color(0xFFFF5252),
                onConfirm: () => _showActionToast('Chat cleared'),
              );
            },
          ),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          // Block Contact
          ListTile(
            leading: const Icon(LucideIcons.ban, size: 20, color: Color(0xFFFF5252)),
            title: Text(
              'Block ${widget.contactName}',
              style: const TextStyle(color: Color(0xFFFF5252), fontSize: 14.5, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              _showConfirmDialog(
                title: 'Block ${widget.contactName}?',
                message: 'Blocked contacts will not be able to call you or send you messages.',
                confirmText: 'Block',
                confirmColor: const Color(0xFFFF5252),
                onConfirm: () => _showActionToast('${widget.contactName} blocked'),
              );
            },
          ),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          // Report Contact
          ListTile(
            leading: const Icon(LucideIcons.flag, size: 20, color: Color(0xFFFF5252)),
            title: Text(
              'Report ${widget.contactName}',
              style: const TextStyle(color: Color(0xFFFF5252), fontSize: 14.5, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              _showConfirmDialog(
                title: 'Report ${widget.contactName}?',
                message: 'The last 5 messages from this contact will be forwarded to CodeSnap Safety team.',
                confirmText: 'Report',
                confirmColor: const Color(0xFFFF5252),
                onConfirm: () => _showActionToast('Report submitted. Thank you for keeping CodeSnap safe.'),
              );
            },
          ),
        ],
      ),
    );
  }
}
