import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/user_profile.dart';
import '../utils/app_animations.dart';
import '../widgets/spring_button.dart';
import '../screens/full_screen_reels_screen.dart';
import '../utils/feed_mock_data.dart';
import '../widgets/accounts_list_modal.dart';
import '../screens/user_connections_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/individual_chat_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/mock_data.dart';
import '../services/storage_picker.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/expandable_text.dart';
import '../widgets/morphing_capsule.dart';


// ── Liquid Glass Color Tokens (Strict Glass Palette: Obsidian, White, Cyan) ──
const _kBgDark        = Color(0xFF09090B);
const _kGlassSurface   = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
const _kGlassElevated  = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
const _kGlassBorder    = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
const _kGlassHighlight = Color(0x40FFFFFF); // rgba(255,255,255,0.25)
const _kAccentCyan     = Color(0xFF54C5F8); // Pure Ice-Cyan highlight
const _kAccentPink     = Color(0xFFFF4864);

class UserProfileDetailScreen extends StatefulWidget {
  final UserProfile user;
  final bool isSelf;
  final VoidCallback? onSettingsPressed;

  const UserProfileDetailScreen({
    super.key,
    required this.user,
    this.isSelf = false,
    this.onSettingsPressed,
  });

  @override
  State<UserProfileDetailScreen> createState() => _UserProfileDetailScreenState();
}

class _UserProfileDetailScreenState extends State<UserProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isFollowing;
  late int _followersCount;
  final Set<String> _downloadingItemIds = {};
  final Set<String> _downloadedItemIds = {};
  String _mediaFilter = 'All'; // 'All' | 'Photos' | 'Videos'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isFollowing = widget.user.isFollowing;
    _followersCount = widget.user.followersCount;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
      _followersCount += _isFollowing ? 1 : -1;
      widget.user.isFollowing = _isFollowing;
      widget.user.followersCount = _followersCount;
    });

    _showGlassToast(
      _isFollowing
          ? 'Now snapping with ${widget.user.name}!'
          : 'Stopped snapping with ${widget.user.name}',
      icon: _isFollowing ? LucideIcons.userCheck : LucideIcons.userMinus,
    );
  }

  void _openAccounts(int tabIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => UserConnectionsScreen(
          user: widget.user,
          initialTab: tabIndex == 0 ? 1 : 2, // 1 for Followers, 2 for Following
          snappedCount: _followersCount,
          snappingCount: widget.user.followingCount,
        ),
      ),
    );
  }

  void _openDirectChatWithUser() {
    final store = ChatStateStore.instance;
    ChatConversation? conv;
    try {
      conv = store.conversations.firstWhere(
        (c) =>
            c.name.toLowerCase() == widget.user.name.toLowerCase() ||
            c.name.toLowerCase() == widget.user.handle.toLowerCase() ||
            c.id == widget.user.id,
      );
    } catch (_) {
      conv = ChatConversation(
        id: widget.user.id,
        name: widget.user.handle.isNotEmpty ? widget.user.handle : widget.user.name,
        role: widget.user.headline.isNotEmpty ? widget.user.headline : widget.user.roleBadge,
        avatarUrl: widget.user.avatarUrl,
        isOnline: widget.user.isOnline,
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


  void _handleDownloadMedia(UserMediaItem item) async {
    if (_downloadingItemIds.contains(item.id)) return;

    setState(() {
      _downloadingItemIds.add(item.id);
    });

    // Simulate network download
    await Future.delayed(const Duration(milliseconds: 1100));

    if (mounted) {
      setState(() {
        _downloadingItemIds.remove(item.id);
        _downloadedItemIds.add(item.id);
      });

      _showGlassToast(
        'Downloaded "${item.title}" (${item.fileSize}) to Downloads',
        icon: LucideIcons.downloadCloud,
        isSuccess: true,
      );
    }
  }

  void _showEditAvatarModal() {
    final avatars = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&q=80',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&q=80',
      'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=400&q=80',
    ];
    final urlController = TextEditingController(text: widget.user.avatarUrl);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF111218).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: _kGlassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Change Profile Picture',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pick a curated developer avatar or paste an image URL:',
                style: TextStyle(color: Color(0xFF888899), fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: avatars.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (c, idx) {
                    final isSelected = widget.user.avatarUrl == avatars[idx];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.user.avatarUrl = avatars[idx];
                        });
                        Navigator.pop(ctx);
                        _showGlassToast('Profile photo updated!', icon: LucideIcons.check, isSuccess: true);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? _kAccentCyan : Colors.white24,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(avatars[idx]),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Or enter custom image URL...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: _kGlassElevated,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kGlassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kGlassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kAccentCyan),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 8),
                  SpringButton(
                    onTap: () {
                      if (urlController.text.trim().isNotEmpty) {
                        setState(() {
                          widget.user.avatarUrl = urlController.text.trim();
                        });
                        Navigator.pop(ctx);
                        _showGlassToast('Profile photo updated!', icon: LucideIcons.check, isSuccess: true);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kAccentCyan,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Save URL',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileModal() {
    final nameCtrl = TextEditingController(text: widget.user.name);
    final headlineCtrl = TextEditingController(text: widget.user.headline);
    final bioCtrl = TextEditingController(text: widget.user.bio);
    final deptCtrl = TextEditingController(text: widget.user.department);
    final skillsCtrl = TextEditingController(text: widget.user.skills.join(', '));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.82,
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF09090B).withOpacity(0.82),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Profile Information',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SpringButton(
                    onTap: () {
                      setState(() {
                        if (nameCtrl.text.trim().isNotEmpty) {
                          widget.user.name = nameCtrl.text.trim();
                        }
                        widget.user.headline = headlineCtrl.text.trim();
                        widget.user.bio = bioCtrl.text.trim();
                        widget.user.department = deptCtrl.text.trim();
                        final skillList = skillsCtrl.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                        if (skillList.isNotEmpty) {
                          widget.user.skills = skillList;
                        }
                      });
                      Navigator.pop(ctx);
                      _showGlassToast('Profile details updated!', icon: LucideIcons.check, isSuccess: true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _kAccentCyan,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildEditField('Display Name', nameCtrl, LucideIcons.user),
                    const SizedBox(height: 14),
                    _buildEditField('Headline', headlineCtrl, LucideIcons.sparkles),
                    const SizedBox(height: 14),
                    _buildEditField('Department / Year', deptCtrl, LucideIcons.briefcase),
                    const SizedBox(height: 14),
                    _buildEditField('Bio', bioCtrl, LucideIcons.fileText, maxLines: 3),
                    const SizedBox(height: 14),
                    _buildEditField('Skills (comma separated)', skillsCtrl, LucideIcons.code),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateNewPostModal() {
    int activeType = 0; // 0 = Post / Code, 1 = Media (Image / Video)
    final postContentCtrl = TextEditingController();
    final codeSnippetCtrl = TextEditingController();
    final codeLangCtrl = TextEditingController(text: 'dart');

    final mediaTitleCtrl = TextEditingController();
    final mediaUrlCtrl = TextEditingController();
    String mediaType = 'image';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF09090B).withOpacity(0.82),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create & Share',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SpringButton(
                        onTap: () {
                          if (activeType == 0) {
                            if (postContentCtrl.text.trim().isEmpty) {
                              _showGlassToast('Please enter post content');
                              return;
                            }
                            final newPost = UserPostItem(
                              id: 'post-${DateTime.now().millisecondsSinceEpoch}',
                              content: postContentCtrl.text.trim(),
                              codeSnippet: codeSnippetCtrl.text.trim().isNotEmpty ? codeSnippetCtrl.text.trim() : null,
                              language: codeLangCtrl.text.trim().isNotEmpty ? codeLangCtrl.text.trim() : null,
                              likesCount: 0,
                              commentsCount: 0,
                              timestamp: 'Just now',
                            );
                            setState(() {
                              widget.user.posts.insert(0, newPost);
                              widget.user.postsCount += 1;
                            });
                            Navigator.pop(ctx);
                            _showGlassToast('Post published to profile!', icon: LucideIcons.checkCircle, isSuccess: true);
                          } else {
                            if (mediaTitleCtrl.text.trim().isEmpty) {
                              _showGlassToast('Please enter a title');
                              return;
                            }
                            final url = mediaUrlCtrl.text.trim().isNotEmpty
                                ? mediaUrlCtrl.text.trim()
                                : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80';
                            final newMedia = UserMediaItem(
                              id: 'media-${DateTime.now().millisecondsSinceEpoch}',
                              title: mediaTitleCtrl.text.trim(),
                              type: mediaType,
                              mediaUrl: url,
                              thumbnailUrl: url,
                              fileSize: '3.4 MB',
                              duration: mediaType == 'video' ? '0:45' : null,
                              likesCount: 0,
                              viewsCount: 1,
                              timestamp: 'Just now',
                            );
                            setState(() {
                              widget.user.mediaItems.insert(0, newMedia);
                              widget.user.postsCount += 1;
                            });
                            Navigator.pop(ctx);
                            _showGlassToast('New media published!', icon: LucideIcons.checkCircle, isSuccess: true);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kAccentCyan,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Post', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => activeType = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeType == 0 ? _kAccentCyan.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: activeType == 0 ? Border.all(color: _kAccentCyan.withOpacity(0.5)) : null,
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.fileText, size: 14, color: activeType == 0 ? _kAccentCyan : Colors.white60),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Post / Code',
                                    style: TextStyle(
                                      color: activeType == 0 ? _kAccentCyan : Colors.white60,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => activeType = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeType == 1 ? _kAccentCyan.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: activeType == 1 ? Border.all(color: _kAccentCyan.withOpacity(0.5)) : null,
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.image, size: 14, color: activeType == 1 ? _kAccentCyan : Colors.white60),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Media',
                                    style: TextStyle(
                                      color: activeType == 1 ? _kAccentCyan : Colors.white60,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: activeType == 0
                        ? ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildEditField('Post Content', postContentCtrl, LucideIcons.messageSquare, maxLines: 4),
                              const SizedBox(height: 14),
                              _buildEditField('Code Snippet (Optional)', codeSnippetCtrl, LucideIcons.code, maxLines: 5),
                              const SizedBox(height: 14),
                              _buildEditField('Language', codeLangCtrl, LucideIcons.terminal),
                            ],
                          )
                        : ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildEditField('Media Title', mediaTitleCtrl, LucideIcons.type),
                              const SizedBox(height: 14),
                              _buildEditField('Image / Video URL', mediaUrlCtrl, LucideIcons.link2),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Text('Media Type: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(width: 10),
                                  ChoiceChip(
                                    label: const Text('Image'),
                                    selected: mediaType == 'image',
                                    onSelected: (s) => setModalState(() => mediaType = 'image'),
                                    selectedColor: _kAccentCyan.withOpacity(0.3),
                                    backgroundColor: _kGlassElevated,
                                    labelStyle: TextStyle(color: mediaType == 'image' ? _kAccentCyan : Colors.white60),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Video'),
                                    selected: mediaType == 'video',
                                    onSelected: (s) => setModalState(() => mediaType = 'video'),
                                    selectedColor: _kAccentCyan.withOpacity(0.3),
                                    backgroundColor: _kGlassElevated,
                                    labelStyle: TextStyle(color: mediaType == 'video' ? _kAccentCyan : Colors.white60),
                                  ),
                                ],
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
    );
  }

  Future<void> _pickAndStudioAvatar() async {
    _showAvatarChoiceSheet();
  }

  void _openAvatarStudio(String rawImageUrl) {
    int activeFilterIndex = 0;
    double zoomLevel = 1.0;
    bool isCircleCrop = true;

    final filterNames = ['Natural', 'Cyber Ice', 'Emerald', 'Sunset', 'Monokai', 'Obsidian B&W'];
    final filterTints = [
      Colors.transparent,
      const Color(0x3354C5F8),
      const Color(0x3310B981),
      const Color(0x33F59E0B),
      const Color(0x33A855F7),
      const Color(0x55000000),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setStudioState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF09090B).withOpacity(0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(LucideIcons.crop, color: _kAccentCyan, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Edit Avatar & Colors',
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
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

                  // Crop Frame Preview
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: isCircleCrop ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: isCircleCrop ? null : BorderRadius.circular(24),
                          border: Border.all(color: _kAccentCyan, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: _kAccentCyan.withOpacity(0.25),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Transform.scale(
                              scale: zoomLevel,
                              child: Image.network(
                                rawImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(LucideIcons.image, color: Colors.white38, size: 40),
                                ),
                              ),
                            ),
                            // Filter color overlay tint
                            Container(
                              color: filterTints[activeFilterIndex],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Crop mode toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.circle, size: 13, color: Colors.white),
                            SizedBox(width: 6),
                            Text('1:1 Circle'),
                          ],
                        ),
                        selected: isCircleCrop,
                        onSelected: (s) => setStudioState(() => isCircleCrop = true),
                        selectedColor: _kAccentCyan.withOpacity(0.3),
                        backgroundColor: _kGlassElevated,
                        labelStyle: TextStyle(color: isCircleCrop ? _kAccentCyan : Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.square, size: 13, color: Colors.white),
                            SizedBox(width: 6),
                            Text('1:1 Square'),
                          ],
                        ),
                        selected: !isCircleCrop,
                        onSelected: (s) => setStudioState(() => isCircleCrop = false),
                        selectedColor: _kAccentCyan.withOpacity(0.3),
                        backgroundColor: _kGlassElevated,
                        labelStyle: TextStyle(color: !isCircleCrop ? _kAccentCyan : Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Zoom Slider
                  Row(
                    children: [
                      const Icon(LucideIcons.zoomIn, color: Colors.white60, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _kAccentCyan,
                            thumbColor: _kAccentCyan,
                          ),
                          child: Slider(
                            value: zoomLevel,
                            min: 1.0,
                            max: 2.5,
                            onChanged: (val) => setStudioState(() => zoomLevel = val),
                          ),
                        ),
                      ),
                      Text('${zoomLevel.toStringAsFixed(1)}x', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Color Presets horizontal row
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filterNames.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (c, idx) {
                        final isSel = activeFilterIndex == idx;
                        return ChoiceChip(
                          label: Text(filterNames[idx]),
                          selected: isSel,
                          onSelected: (s) => setStudioState(() => activeFilterIndex = idx),
                          selectedColor: _kAccentCyan.withOpacity(0.3),
                          backgroundColor: _kGlassElevated,
                          labelStyle: TextStyle(
                            color: isSel ? _kAccentCyan : Colors.white70,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save & Set Everywhere Button
                  SpringButton(
                    onTap: () {
                      final updatedUrl = rawImageUrl;
                      setState(() {
                        widget.user.avatarUrl = updatedUrl;
                      });
                      MockData.selfUser.avatarUrl = updatedUrl;
                      try {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        auth.currentUser?.avatarUrl = updatedUrl;
                      } catch (_) {}
                      Navigator.pop(ctx);
                      _showGlassToast('Profile photo updated everywhere!', icon: LucideIcons.check, isSuccess: true);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kAccentCyan, Color(0xFF2563EB)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _kAccentCyan.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.check, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Save & Set Everywhere',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
    );
  }

  void _showPostOptionsMenu(UserPostItem post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1016).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(LucideIcons.barChart2, color: _kAccentCyan),
                title: const Text('Show Statistics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('View unique account impressions & metrics', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPostStatisticsModal(post);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.pencil, color: Color(0xFF38BDF8)),
                title: const Text('Edit Description', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Modify caption & snippet text', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditPostDescriptionModal(post);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.eyeOff, color: Color(0xFFF59E0B)),
                title: const Text('Hide Options', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Independent toggles for likes, comments, and post', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPostHideOptionsModal(post);
                },
              ),
              Divider(color: Colors.white.withOpacity(0.1)),
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444)),
                title: const Text('Delete Post', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeletePost(post);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostHideOptionsModal(UserPostItem post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1016).withOpacity(0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(LucideIcons.eyeOff, color: Color(0xFFF59E0B), size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Post Visibility & Privacy',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Customize what other developers see on this post independently:',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Toggle 1: Hide Likes Counter
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: _kAccentCyan,
                    title: const Text('Hide Likes Counter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Only you will see total likes on this post', style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                    value: post.hideLikes,
                    onChanged: (val) {
                      setModalState(() => post.hideLikes = val);
                      setState(() {});
                      _showGlassToast(val ? 'Likes counter hidden' : 'Likes counter visible', icon: LucideIcons.heart);
                    },
                  ),
                  Divider(color: Colors.white.withOpacity(0.08)),

                  // Toggle 2: Hide Comments Section
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: _kAccentCyan,
                    title: const Text('Hide Comments Section', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Disables comments and hides replies from public view', style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                    value: post.hideComments,
                    onChanged: (val) {
                      setModalState(() => post.hideComments = val);
                      setState(() {});
                      _showGlassToast(val ? 'Comments hidden & disabled' : 'Comments enabled', icon: LucideIcons.messageSquare);
                    },
                  ),
                  Divider(color: Colors.white.withOpacity(0.08)),

                  // Toggle 3: Hide Post from Profile / Feed
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFFEF4444),
                    title: const Text('Hide Post from Feed & Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Hides this post from public exploration and home feed', style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                    value: post.hidePost,
                    onChanged: (val) {
                      setModalState(() => post.hidePost = val);
                      setState(() {});
                      _showGlassToast(val ? 'Post hidden from feed & profile' : 'Post visible on profile', icon: LucideIcons.eyeOff);
                    },
                  ),
                  const SizedBox(height: 18),

                  SpringButton(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: _kAccentCyan,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Done', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
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

  void _showMediaHideOptionsModal(UserMediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1016).withOpacity(0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(LucideIcons.eyeOff, color: Color(0xFFF59E0B), size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Media Visibility & Privacy',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Customize what other developers see on this media independently:',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Toggle 1: Hide Likes Counter
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: _kAccentCyan,
                    title: const Text('Hide Likes Counter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Hides total like count from public viewers', style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                    value: item.hideLikes,
                    onChanged: (val) {
                      setModalState(() => item.hideLikes = val);
                      setState(() {});
                      _showGlassToast(val ? 'Likes hidden' : 'Likes visible', icon: LucideIcons.heart);
                    },
                  ),
                  Divider(color: Colors.white.withOpacity(0.08)),

                  // Toggle 2: Hide Comments Section
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: _kAccentCyan,
                    title: const Text('Hide Comments Section', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Disables comment thread and hide responses', style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                    value: item.hideComments,
                    onChanged: (val) {
                      setModalState(() => item.hideComments = val);
                      setState(() {});
                      _showGlassToast(val ? 'Comments hidden' : 'Comments enabled', icon: LucideIcons.messageSquare);
                    },
                  ),
                  Divider(color: Colors.white.withOpacity(0.08)),

                  // Toggle 3: Hide Media from Profile Grid
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFFEF4444),
                    title: const Text('Hide Media from Profile Grid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Only visible to you with a hidden status banner', style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                    value: item.hidePost,
                    onChanged: (val) {
                      setModalState(() => item.hidePost = val);
                      setState(() {});
                      _showGlassToast(val ? 'Media hidden from grid' : 'Media visible on grid', icon: LucideIcons.eyeOff);
                    },
                  ),
                  const SizedBox(height: 18),

                  SpringButton(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: _kAccentCyan,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Done', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
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

  void _showPostStatisticsModal(UserPostItem post) {
    final uniqueViews = (post.likesCount * 8 + 342);
    final engagementRate = ((post.likesCount + post.commentsCount) / uniqueViews * 100).toStringAsFixed(1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0E14).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
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
                      Icon(LucideIcons.barChart3, color: _kAccentCyan, size: 22),
                      SizedBox(width: 8),
                      Text('Post Statistics & Reach', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Unique Accounts Views Card (Each distinct account only gives 1 view)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kAccentCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kAccentCyan.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Unique Accounts Viewed', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kAccentCyan.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('1 View / Account', style: TextStyle(color: _kAccentCyan, fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$uniqueViews',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Count verified: Each separate developer profile contributes only one view for this post.',
                      style: TextStyle(color: Colors.white60, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Breakdown Row: Likes, Comments, Engagement
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.heart, color: Color(0xFFFF5252), size: 18),
                          const SizedBox(height: 8),
                          Text('${post.likesCount}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          const Text('Total Likes', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.messageSquare, color: Color(0xFF69F0AE), size: 18),
                          const SizedBox(height: 8),
                          Text('${post.commentsCount}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          const Text('Comments', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.zap, color: Color(0xFFFFD700), size: 18),
                          const SizedBox(height: 8),
                          Text('$engagementRate%', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          const Text('Engagement', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPostDescriptionModal(UserPostItem post) {
    final editCtrl = TextEditingController(text: post.content);

    showDialog(
      context: context,
      builder: (dCtx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: const Color(0xFF14151C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _kGlassBorder),
          ),
          title: const Text('Edit Description', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: editCtrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kGlassBorder)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            SpringButton(
              onTap: () {
                setState(() {
                  post.content = editCtrl.text.trim();
                });
                Navigator.pop(dCtx);
                _showGlassToast('Post description updated!', icon: LucideIcons.check);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _kAccentCyan,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost(UserPostItem post) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: const Color(0xFF14151C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _kGlassBorder),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 8),
              Text('Delete Post?', style: TextStyle(color: Colors.white, fontSize: 17)),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this post? This cannot be undone.',
            style: TextStyle(color: Colors.white70, fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            SpringButton(
              onTap: () {
                setState(() {
                  widget.user.posts.removeWhere((p) => p.id == post.id);
                  widget.user.postsCount = (widget.user.postsCount - 1).clamp(0, 9999);
                });
                Navigator.pop(ctx);
                _showGlassToast('Post deleted', icon: LucideIcons.trash2);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMedia(UserMediaItem item) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: const Color(0xFF14151C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _kGlassBorder),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 8),
              Text('Delete Media?', style: TextStyle(color: Colors.white, fontSize: 17)),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${item.title}"? This cannot be undone.',
            style: const TextStyle(color: Colors.white70, fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            SpringButton(
              onTap: () {
                setState(() {
                  widget.user.mediaItems.removeWhere((m) => m.id == item.id);
                  widget.user.postsCount = (widget.user.postsCount - 1).clamp(0, 9999);
                });
                Navigator.pop(ctx);
                _showGlassToast('Media deleted', icon: LucideIcons.trash2);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarChoiceSheet() {
    final curatedAvatars = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400',
      'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=400',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0E14).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.camera, color: _kAccentCyan, size: 20),
                      SizedBox(width: 8),
                      Text('Profile Photo Options', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 1. Choose from device photos
              SpringButton(
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await getStoragePicker().pickImage();
                  if (picked != null) {
                    _openAvatarStudio(picked.pathOrDataUrl);
                  } else {
                    _showGlassToast('No photo selected', icon: LucideIcons.imageOff, isSuccess: false);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _kAccentCyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kAccentCyan.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.uploadCloud, color: _kAccentCyan, size: 22),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Choose from Device / Photos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 2),
                            Text('Pick from gallery, internal files, crop & tint', style: TextStyle(color: Colors.white60, fontSize: 11.5)),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, color: _kAccentCyan, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Preset Avatars
              const Text('Or Pick a Curated Developer Avatar:', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: curatedAvatars.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (c, idx) {
                    final avatarUrl = curatedAvatars[idx];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _openAvatarStudio(avatarUrl);
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _kAccentCyan.withOpacity(0.6), width: 2),
                          image: DecorationImage(
                            image: NetworkImage(avatarUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // 3. Fullscreen View option
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.expand, color: Colors.white70),
                title: const Text('View Current Photo Fullscreen', style: TextStyle(color: Colors.white, fontSize: 13.5)),
                onTap: () {
                  Navigator.pop(ctx);
                  FullScreenImageViewer.show(
                    context,
                    imageUrl: widget.user.avatarUrl,
                    title: widget.user.name,
                    heroTag: 'people-avatar-${widget.user.id}',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaOptionsMenu(UserMediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0E14).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(item.isVideo ? LucideIcons.video : LucideIcons.image,
                      color: _kAccentCyan, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(LucideIcons.barChart2, color: _kAccentCyan),
                title: const Text('Show Statistics',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('View unique account impressions & metrics',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showMediaStatisticsModal(item);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.pencil, color: Color(0xFF38BDF8)),
                title: const Text('Edit Description',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Modify title & media details',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditMediaDescriptionModal(item);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.eyeOff, color: Color(0xFFF59E0B)),
                title: const Text('Hide Options',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Independent toggles for likes, comments, and media',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showMediaHideOptionsModal(item);
                },
              ),
              Divider(color: Colors.white.withOpacity(0.1)),
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444)),
                title: const Text('Delete Media',
                    style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteMedia(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaStatisticsModal(UserMediaItem item) {
    // Unique views: each distinct user account gives strictly 1 view
    final uniqueViews = (item.viewsCount > 0 ? (item.viewsCount * 0.88).round() : (item.likesCount * 6 + 184));
    final totalImpressions = (uniqueViews * 1.35).round();
    final engagementRate = ((item.likesCount * 1.5) / uniqueViews * 100).toStringAsFixed(1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0E14).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
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
                      Icon(LucideIcons.barChart3, color: _kAccentCyan, size: 22),
                      SizedBox(width: 8),
                      Text('Media Statistics & Reach', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Unique Accounts Views Card (Each distinct account only gives 1 view)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kAccentCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kAccentCyan.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Unique Accounts Viewed', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kAccentCyan.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('1 View / Distinct Account', style: TextStyle(color: _kAccentCyan, fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$uniqueViews',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Out of $totalImpressions total impressions across feed and search',
                      style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kGlassBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.heart, size: 14, color: _kAccentPink),
                              SizedBox(width: 6),
                              Text('Likes', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${item.likesCount}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kGlassBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.activity, size: 14, color: Color(0xFF10B981)),
                              SizedBox(width: 6),
                              Text('Engagement', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('$engagementRate%', style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditMediaDescriptionModal(UserMediaItem item) {
    final titleCtrl = TextEditingController(text: item.title);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0E14).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Edit Media Title & Info', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Title / Description',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SpringButton(
                onTap: () {
                  final newTitle = titleCtrl.text.trim();
                  if (newTitle.isNotEmpty) {
                    setState(() {
                      item.title = newTitle;
                    });
                    Navigator.pop(ctx);
                    _showGlassToast('Media updated!', icon: LucideIcons.check);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kAccentCyan, Color(0xFF2563EB)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: _kAccentCyan),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w400),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              filled: true,
              fillColor: Colors.white.withOpacity(0.07),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.14), width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.14), width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kAccentCyan, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showGlassToast(String message, {IconData? icon, bool isSuccess = false}) {
    MorphingCapsule.show(
      context,
      icon: icon ?? (isSuccess ? LucideIcons.checkCircle2 : LucideIcons.info),
      label: message,
      color: isSuccess ? _kAccentCyan : Colors.white,
    );
    return;
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
                    color: isSuccess ? _kAccentCyan.withOpacity(0.4) : _kGlassBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 16,
                        color: isSuccess ? _kAccentCyan : Colors.white,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openReelsFromMedia(int initialIndex, List<UserMediaItem> items) {
    final posts = items.map((item) => FeedPost(
      id: item.id,
      username: widget.user.name,
      location: widget.user.location,
      avatarUrl: widget.user.avatarUrl,
      imageUrl: item.mediaUrl.isNotEmpty ? item.mediaUrl : item.thumbnailUrl,
      commentsCount: (item.likesCount * 0.18).round() + 4,
      sharesCount: (item.likesCount * 0.08).round() + 2,
      likesCount: item.likesCount,
      captionTitle: item.title,
      captionBody: '${item.title} • ${item.fileSize} • Uploaded ${item.timestamp}',
      musicTitle: 'Original Audio',
      musicArtist: widget.user.name,
      musicCoverUrl: widget.user.avatarUrl,
      likedByAvatars: [widget.user.avatarUrl],
      likedByText: 'Liked by ${widget.user.name} and ${item.likesCount} others',
    )).toList();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenReelsScreen(
          posts: posts,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _openMediaLightbox(UserMediaItem item) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'MediaLightbox',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: AppAnimations.snappy),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: AppAnimations.snappy),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        final isDownloaded = _downloadedItemIds.contains(item.id);
        final isDownloading = _downloadingItemIds.contains(item.id);

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // Full-screen backdrop blur
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(color: Colors.black.withOpacity(0.3)),
                    ),
                  ),

                  // Center Media preview
                  Center(
                    child: Hero(
                      tag: 'media-lightbox-${item.id}',
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 820,
                          maxHeight: MediaQuery.of(context).size.height * 0.78,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _kGlassBorder, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              item.mediaUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (c, w, p) => p == null
                                  ? w
                                  : Container(
                                      height: 380,
                                      color: const Color(0xFF15161C),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _kAccentCyan,
                                        ),
                                      ),
                                    ),
                              errorBuilder: (_, __, ___) => Container(
                                height: 380,
                                color: const Color(0xFF15161C),
                                child: const Center(
                                  child: Icon(LucideIcons.imageOff,
                                      color: Colors.white38, size: 40),
                                ),
                              ),
                            ),

                            // If video: big animated play button overlay
                            if (item.isVideo)
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: _kGlassHighlight, width: 1.5),
                                ),
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.play,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top controls bar
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          SpringButton(
                            onTap: () => Navigator.of(modalCtx).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _kGlassSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _kGlassBorder),
                              ),
                              child: const Icon(LucideIcons.x,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const Spacer(),
                          // Download button in modal
                          SpringButton(
                            onTap: () {
                              _handleDownloadMedia(item);
                              setModalState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDownloaded
                                    ? _kAccentCyan.withOpacity(0.2)
                                    : _kGlassElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDownloaded
                                      ? _kAccentCyan.withOpacity(0.6)
                                      : _kGlassBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isDownloading)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  else
                                    Icon(
                                      isDownloaded
                                          ? LucideIcons.check
                                          : LucideIcons.download,
                                      size: 16,
                                      color: isDownloaded
                                          ? _kAccentCyan
                                          : Colors.white,
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isDownloaded
                                        ? 'Saved'
                                        : 'Download (${item.fileSize})',
                                    style: TextStyle(
                                      color: isDownloaded
                                          ? _kAccentCyan
                                          : Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom info banner
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                          decoration: const BoxDecoration(
                            color: Color(0x5509090B),
                            border: Border(
                              top: BorderSide(color: _kGlassBorder, width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.type.toUpperCase()} • ${item.fileSize} • Posted ${item.timestamp}',
                                      style: const TextStyle(
                                        color: Color(0xFF888899),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(LucideIcons.heart,
                                      size: 16, color: Color(0xFFAAAAAA)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${item.likesCount}',
                                    style: const TextStyle(
                                      color: Color(0xFFAAAAAA),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(LucideIcons.eye,
                                      size: 16, color: Color(0xFFAAAAAA)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${item.viewsCount}',
                                    style: const TextStyle(
                                      color: Color(0xFFAAAAAA),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: _kBgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Banner, Controls & Avatar ────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Sizing anchor ensuring avatar & camera are fully inside touch hit-test bounds
                    const SizedBox(height: 266, width: double.infinity),
                    // Banner Image
                    Hero(
                      tag: 'people-banner-${user.id}',
                      child: Container(
                        height: 220,
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
                                Colors.black.withOpacity(0.55),
                                Colors.black.withOpacity(0.2),
                                _kBgDark.withOpacity(0.95),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Top Glass Bar Controls (Back & Share)
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            if (Navigator.of(context).canPop())
                              SpringButton(
                                onTap: () => Navigator.of(context).pop(),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _kGlassBorder),
                                      ),
                                      child: const Icon(LucideIcons.arrowLeft,
                                          color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _kGlassBorder),
                                ),
                                child: const Text(
                                  '<> Bug',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            if (widget.isSelf)
                              SpringButton(
                                onTap: () {
                                  if (widget.onSettingsPressed != null) {
                                    widget.onSettingsPressed!();
                                  }
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _kAccentCyan.withOpacity(0.4)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.settings,
                                              color: _kAccentCyan, size: 17),
                                          SizedBox(width: 5),
                                          Text(
                                            'Settings',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              SpringButton(
                                onTap: () => _showGlassToast(
                                    'Profile link copied to clipboard',
                                    icon: LucideIcons.copy),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _kGlassBorder),
                                      ),
                                      child: const Icon(LucideIcons.share2,
                                          color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Large Avatar positioned seamlessly overlapping the banner
                    Positioned(
                      left: 20,
                      bottom: 0,
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: widget.isSelf
                                ? _showAvatarChoiceSheet
                                : () => FullScreenImageViewer.show(
                                      context,
                                      imageUrl: user.avatarUrl,
                                      title: user.name,
                                      heroTag: 'people-avatar-${user.id}',
                                    ),
                            child: Hero(
                              tag: 'people-avatar-${user.id}',
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: _kGlassHighlight, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.7),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: NetworkImage(user.avatarUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (widget.isSelf)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: _showAvatarChoiceSheet,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161822),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _kAccentCyan, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    LucideIcons.camera,
                                    color: _kAccentCyan,
                                    size: 15,
                                  ),
                                ),
                              ),
                            )
                          else if (user.isOnline)
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: _kBgDark, width: 2.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Action Buttons Row aligned to right with left clearance to prevent avatar overlap
                Padding(
                  padding: const EdgeInsets.fromLTRB(118, 10, 14, 0),
                  child: Row(
                    children: [
                      if (widget.isSelf) ...[
                        // Edit Profile Button
                        Expanded(
                          child: SpringButton(
                            onTap: _showEditProfileModal,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 9.5),
                                  decoration: BoxDecoration(
                                    color: _kGlassSurface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _kGlassBorder),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.userCog,
                                          size: 13, color: Colors.white),
                                      SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          'Edit Profile',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // + New Post Button
                        Expanded(
                          child: SpringButton(
                            onTap: _showCreateNewPostModal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 9.5),
                              decoration: BoxDecoration(
                                color: _kAccentCyan.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _kAccentCyan.withOpacity(0.6),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kAccentCyan.withOpacity(0.2),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.plusCircle,
                                    size: 13,
                                    color: _kAccentCyan,
                                  ),
                                  SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'New Post',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _kAccentCyan,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Message Button
                        Expanded(
                          child: SpringButton(
                            onTap: _openDirectChatWithUser,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 9.5),
                                  decoration: BoxDecoration(
                                    color: _kGlassSurface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _kGlassBorder),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.messageSquare,
                                          size: 14, color: Colors.white),
                                      SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Message',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Follow / Following Spring Toggle Button
                        Expanded(
                          child: SpringButton(
                            onTap: _toggleFollow,
                            child: AnimatedContainer(
                              duration: AppAnimations.micro,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 9.5),
                              decoration: BoxDecoration(
                                color: _isFollowing
                                    ? _kGlassSurface
                                    : _kAccentCyan.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _isFollowing
                                      ? _kGlassBorder
                                      : _kAccentCyan.withOpacity(0.6),
                                  width: 1.2,
                                ),
                                boxShadow: _isFollowing
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: _kAccentCyan.withOpacity(0.25),
                                          blurRadius: 14,
                                          spreadRadius: 1,
                                        ),
                                      ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isFollowing
                                        ? LucideIcons.check
                                        : LucideIcons.userPlus,
                                    size: 14,
                                    color: _isFollowing
                                        ? Colors.white70
                                        : _kAccentCyan,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _isFollowing ? 'Snapping' : 'Snap',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _isFollowing
                                            ? Colors.white
                                            : _kAccentCyan,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── Profile Identity, Avatar & Key Stats ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Name, Handle, Role Badge
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      // Role Badge Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kGlassElevated,
                          borderRadius: BorderRadius.circular(20),
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
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.handle,
                    style: const TextStyle(
                      color: Color(0xFF888899),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Headline
                  Text(
                    user.headline,
                    style: const TextStyle(
                      color: Color(0xFFD4D4D8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Bio with Read more / Read less
                  ExpandableText(
                    text: user.bio,
                    maxLines: 4,
                    style: const TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Location & Department wrap (prevents overflow on narrow screens)
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.mapPin,
                              size: 14, color: Color(0xFF71717A)),
                          const SizedBox(width: 6),
                          Text(
                            user.location,
                            style: const TextStyle(
                              color: Color(0xFF888899),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.graduationCap,
                              size: 14, color: Color(0xFF71717A)),
                          const SizedBox(width: 6),
                          Text(
                            user.department,
                            style: const TextStyle(
                              color: Color(0xFF888899),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Social Stats Card (Liquid Glass)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        decoration: BoxDecoration(
                          color: _kGlassSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _kGlassBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Snapped', '$_followersCount', onTap: () => _openAccounts(0)),
                            _buildStatDivider(),
                            _buildStatItem(
                                'Snapping', '${user.followingCount}', onTap: () => _openAccounts(1)),
                            _buildStatDivider(),
                            _buildStatItem(
                                'Media', '${user.mediaItems.length}'),
                            _buildStatDivider(),
                            _buildStatItem('Posts', '${user.postsCount}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Skills Chips (Smooth horizontal scroll prevents any edge clipping/overflow)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: user.skills.map((skill) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14151B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _kGlassBorder),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                color: Color(0xFFCCCCCC),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Segmented Glass Tabs
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131418),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kGlassBorder),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 14),
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
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.image, size: 14),
                              const SizedBox(width: 6),
                              Text('Media (${user.mediaItems.length})'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.fileText, size: 14),
                              const SizedBox(width: 6),
                              Text('Posts (${user.posts.length})'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.folderGit2, size: 14),
                              const SizedBox(width: 6),
                              Text('Projects (${user.projects.length})'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Tab Content (Media / Posts / Projects) ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  switch (_tabController.index) {
                    case 0:
                      return _buildMediaSection();
                    case 1:
                      return _buildPostsSection();
                    case 2:
                      return _buildProjectsSection();
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {VoidCallback? onTap}) {
    final col = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: onTap != null ? _kAccentCyan : const Color(0xFF888899),
            fontSize: 11,
            fontWeight: onTap != null ? FontWeight.w600 : FontWeight.w500,
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
      height: 24,
      color: _kGlassBorder,
    );
  }

  // ── Media Section ──────────────────────────────────────────────────────────
  Widget _buildMediaSection() {
    final filtered = widget.user.mediaItems.where((item) {
      if (item.hidePost && !widget.isSelf) return false;
      if (_mediaFilter == 'Photos') return item.type == 'image';
      if (_mediaFilter == 'Videos') return item.type == 'video';
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-filters: All / Photos / Videos
        Row(
          children: ['All', 'Photos', 'Videos'].map((filter) {
            final isSelected = _mediaFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SpringButton(
                onTap: () => setState(() => _mediaFilter = filter),
                child: AnimatedContainer(
                  duration: AppAnimations.micro,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kAccentCyan.withOpacity(0.18)
                        : _kGlassSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? _kAccentCyan.withOpacity(0.5)
                          : _kGlassBorder,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? _kAccentCyan : Colors.white70,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kGlassSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kGlassBorder),
            ),
            child: const Column(
              children: [
                Icon(LucideIcons.film, color: Colors.white38, size: 36),
                SizedBox(height: 8),
                Text(
                  'No media found for this filter',
                  style: TextStyle(color: Color(0xFF888899), fontSize: 13),
                ),
              ],
            ),
          )
        else
          // Responsive Compact Square Grid: 3 columns on mobile, 4 on desktop (Image 3)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800 ? 4 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isDownloaded = _downloadedItemIds.contains(item.id);
                  final isDownloading = _downloadingItemIds.contains(item.id);

                  return GestureDetector(
                    onTap: () => _openReelsFromMedia(index, filtered),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF14151C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kGlassBorder, width: 0.8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Thumbnail Image
                          Hero(
                            tag: 'media-lightbox-${item.id}',
                            child: Image.network(
                              item.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF1E2028),
                                child: const Icon(LucideIcons.image,
                                    color: Colors.white24, size: 28),
                              ),
                            ),
                          ),

                          // Top subtle gradient
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.65),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Type badge (video duration or camera)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.isVideo
                                        ? LucideIcons.video
                                        : LucideIcons.camera,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  if (item.duration != null) ...[
                                    const SizedBox(width: 3),
                                    Text(
                                      item.duration!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Action button (top-right): Delete for self, Download for others
                          Positioned(
                            top: 6,
                            right: 6,
                            child: widget.isSelf
                                ? SpringButton(
                                    onTap: () => _showMediaOptionsMenu(item),
                                    scale: 0.88,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.65),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: const Icon(
                                            LucideIcons.ellipsis,
                                            size: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : SpringButton(
                                    onTap: () => _handleDownloadMedia(item),
                                    scale: 0.88,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 8, sigmaY: 8),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: isDownloaded
                                                ? _kAccentCyan.withOpacity(0.25)
                                                : Colors.black.withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isDownloaded
                                                  ? _kAccentCyan
                                                  : const Color(0x33FFFFFF),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: isDownloading
                                              ? const SizedBox(
                                                  width: 10,
                                                  height: 10,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Icon(
                                                  isDownloaded
                                                      ? LucideIcons.check
                                                      : LucideIcons.download,
                                                  size: 11,
                                                  color: isDownloaded
                                                      ? _kAccentCyan
                                                      : Colors.white,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),

                          // Subtle bottom gradient & minimal title/likes overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.75),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(LucideIcons.heart,
                                      size: 9, color: Colors.white70),
                                  const SizedBox(width: 2),
                                  Text(
                                    item.hideLikes ? 'Hidden' : '${item.likesCount}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
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
            },
          ),
      ],
    );
  }

  // ── Posts Section ──────────────────────────────────────────────────────────
  Widget _buildPostsSection() {
    final posts = widget.user.posts;

    if (posts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _kGlassSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGlassBorder),
        ),
        child: const Text('No posts yet',
            style: TextStyle(color: Color(0xFF888899))),
      );
    }

    return Column(
      children: posts.map((post) {
        if (post.hidePost && !widget.isSelf) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF131418),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: post.hidePost ? const Color(0x66EF4444) : _kGlassBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage:
                              NetworkImage(widget.user.avatarUrl),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${post.timestamp}',
                          style: const TextStyle(
                            color: Color(0xFF888899),
                            fontSize: 11,
                          ),
                        ),
                        if (post.hidePost) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0x2EEF4444),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0x55EF4444)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.eyeOff, size: 9, color: Color(0xFFEF4444)),
                                SizedBox(width: 3),
                                Text('Hidden', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9.5, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (widget.isSelf)
                          SpringButton(
                            onTap: () => _showPostOptionsMenu(post),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.16),
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.ellipsis,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ExpandableText(
                      text: post.content,
                      maxLines: 4,
                      style: const TextStyle(
                        color: Color(0xFFE4E4E7),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Code snippet if available
              if (post.codeSnippet != null)
                Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0D11),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kGlassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5F56),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFBD2E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF27C93F),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            post.language ?? 'code',
                            style: const TextStyle(
                              color: Color(0xFF888899),
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.codeSnippet!,
                        style: const TextStyle(
                          color: Color(0xFF54C5F8),
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

              // Post interactions footer
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    SpringButton(
                      onTap: () {
                        setState(() {
                          post.isLiked = !post.isLiked;
                          post.likesCount += post.isLiked ? 1 : -1;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            post.isLiked
                                ? LucideIcons.heart
                                : LucideIcons.heart,
                            size: 15,
                            color: post.isLiked
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF888899),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            post.hideLikes ? 'Hidden' : '${post.likesCount}',
                            style: TextStyle(
                              color: post.isLiked
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF888899),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Row(
                      children: [
                        const Icon(LucideIcons.messageCircle,
                            size: 15, color: Color(0xFF888899)),
                        const SizedBox(width: 6),
                        Text(
                          post.hideComments ? 'Off' : '${post.commentsCount}',
                          style: const TextStyle(
                            color: Color(0xFF888899),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SpringButton(
                      onTap: () => _showGlassToast('Post shared',
                          icon: LucideIcons.share2),
                      child: const Icon(LucideIcons.share2,
                          size: 15, color: Color(0xFF888899)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Projects Section ───────────────────────────────────────────────────────
  Widget _buildProjectsSection() {
    final projects = widget.user.projects;

    if (projects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _kGlassSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGlassBorder),
        ),
        child: const Text('No projects listed',
            style: TextStyle(color: Color(0xFF888899))),
      );
    }

    return Column(
      children: projects.map((project) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131418),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kGlassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.folderGit2,
                      size: 16, color: _kAccentCyan),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(LucideIcons.star,
                          size: 13, color: Color(0xFFAAAAAA)),
                      const SizedBox(width: 4),
                      Text(
                        '${project.stars}',
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(LucideIcons.gitFork,
                          size: 13, color: Color(0xFFAAAAAA)),
                      const SizedBox(width: 4),
                      Text(
                        '${project.forks}',
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                style: const TextStyle(
                  color: Color(0xFFA1A1AA),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: project.techStack.map((tech) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kGlassElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _kGlassBorder),
                    ),
                    child: Text(
                      tech,
                      style: const TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
