import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/user_profile.dart';
import '../services/chat_service.dart';
import '../services/realtime_sync_service.dart';
import '../services/supabase_data_service.dart';
import '../services/supabase_service.dart';
import '../utils/feed_mock_data.dart';
import 'chat_screen.dart';
import 'full_screen_reels_screen.dart';

const _background = Color(0xFF09090B);
const _card = Color(0xFF131418);
const _glass = Color(0x14FFFFFF);
const _border = Color(0x26FFFFFF);
const _cyan = Color(0xFF54C5F8);

enum _ConnectionTab { snapped, snapping, mutual }

class PeopleProfileDetailScreen extends StatefulWidget {
  final String userId;

  const PeopleProfileDetailScreen({super.key, required this.userId});

  @override
  State<PeopleProfileDetailScreen> createState() =>
      _PeopleProfileDetailScreenState();
}

class _PeopleProfileDetailScreenState extends State<PeopleProfileDetailScreen> {
  UserProfile? _profile;
  List<FeedPost> _posts = const [];
  bool _loading = true;
  bool _savingSnap = false;
  bool _openingChat = false;
  String? _error;
  VoidCallback? _stopRealtime;
  Timer? _realtimeRefreshTimer;
  Set<String> _snappedIds = const {};
  Set<String> _snappingIds = const {};

  Set<String> get _mutualIds => _snappedIds.intersection(_snappingIds);

  bool get _isSelf => widget.userId == SupabaseService.currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
    _stopRealtime = RealtimeSyncService.instance.subscribe(
      const {'profiles', 'followers', 'posts', 'post_likes', 'comments'},
      (_) {
        _realtimeRefreshTimer?.cancel();
        _realtimeRefreshTimer = Timer(const Duration(milliseconds: 220), _load);
      },
    );
  }

  @override
  void dispose() {
    _stopRealtime?.call();
    _realtimeRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profileFuture =
          SupabaseDataService.fetchDeveloperById(widget.userId);
      final postsFuture = SupabaseDataService.fetchUserPosts(widget.userId);
      final connectionsFuture =
          SupabaseDataService.fetchDeveloperConnectionIds(widget.userId);
      final row = await profileFuture;
      final posts = await postsFuture;
      final connections = await connectionsFuture;
      if (row == null) throw StateError('This account is no longer available.');
      final profile = UserProfile.fromPeopleDirectory(row);
      final feedPosts = posts.map((post) {
        final snippet = post['code_snippet']?.toString().trim() ?? '';
        final description = post['description']?.toString().trim() ?? '';
        final hasMedia = snippet.startsWith('https://') ||
            snippet.startsWith('http://') ||
            snippet.startsWith('data:image') ||
            snippet.startsWith('blob:');
        final username = profile.handle.startsWith('@')
            ? profile.handle.substring(1)
            : profile.name;
        return FeedPost(
          id: post['id'].toString(),
          ownerId: widget.userId,
          username: username,
          location: profile.location,
          avatarUrl: profile.avatarUrl,
          imageUrl: hasMedia ? snippet : '',
          commentsCount: (post['comments_count'] as num?)?.toInt() ?? 0,
          sharesCount: 0,
          likesCount: (post['likes_count'] as num?)?.toInt() ?? 0,
          captionTitle: post['title']?.toString().trim() ?? '',
          captionBody:
              description.isNotEmpty ? description : (hasMedia ? '' : snippet),
          musicTitle: 'No audio attached',
          musicArtist: '',
          musicCoverUrl: '',
          likedByAvatars: const [],
          likedByText: '',
        );
      }).toList(growable: false);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _posts = feedPosts;
        _snappedIds = connections.snapped;
        _snappingIds = connections.snapping;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _toggleSnap() async {
    final profile = _profile;
    if (profile == null || _isSelf || _savingSnap) return;
    setState(() => _savingSnap = true);
    try {
      await SupabaseDataService.setSnapping(
        targetUserId: profile.id,
        shouldSnap: !profile.isFollowing,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Snap update failed: $error'),
        backgroundColor: const Color(0xFF7F1D1D),
      ));
    } finally {
      if (mounted) setState(() => _savingSnap = false);
    }
  }

  Future<void> _openMessage() async {
    final profile = _profile;
    if (profile == null || _isSelf || _openingChat) return;
    setState(() => _openingChat = true);
    try {
      final conversationId =
          await ChatService.getOrCreateDirectConversation(profile.id);
      if (!mounted) return;
      final store = ChatStateStore.instance;
      ChatConversation conversation;
      try {
        conversation =
            store.conversations.firstWhere((item) => item.id == conversationId);
      } catch (_) {
        conversation = ChatConversation(
          id: conversationId,
          name: profile.name,
          role: profile.headline,
          avatarUrl: profile.avatarUrl.isNotEmpty
              ? profile.avatarUrl
              : 'https://api.dicebear.com/9.x/initials/png?seed=${Uri.encodeComponent(profile.name)}',
          isOnline: profile.isOnline,
          lastMessage: 'No messages yet',
          time: '',
          messages: [],
        );
        store.conversations.insert(0, conversation);
      }
      store.selectConversation(conversationId);
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const ChatScreen(),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open chat: $error')),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  void _openPost(int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FullScreenReelsScreen(
        posts: _posts,
        initialIndex: index,
      ),
    ));
  }

  Future<void> _showConnections(_ConnectionTab initialTab) async {
    final profile = _profile;
    if (profile == null) return;
    try {
      final ids =
          await SupabaseDataService.fetchDeveloperConnectionIds(profile.id);
      final rows = await SupabaseDataService.fetchDevelopersByIds(
        ids.snapped.union(ids.snapping),
      );
      final people = rows.map(UserProfile.fromPeopleDirectory).toList();
      if (!mounted) return;
      setState(() {
        _snappedIds = ids.snapped;
        _snappingIds = ids.snapping;
      });
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          var selected = initialTab;
          var query = '';
          return StatefulBuilder(builder: (context, updateSheet) {
            final selectedIds = switch (selected) {
              _ConnectionTab.snapped => ids.snapped,
              _ConnectionTab.snapping => ids.snapping,
              _ConnectionTab.mutual => ids.snapped.intersection(ids.snapping),
            };
            final normalized = query.trim().toLowerCase();
            final visible = people.where((item) {
              if (!selectedIds.contains(item.id)) return false;
              return normalized.isEmpty ||
                  item.name.toLowerCase().contains(normalized) ||
                  item.handle.toLowerCase().contains(normalized) ||
                  item.headline.toLowerCase().contains(normalized);
            }).toList(growable: false);
            return SafeArea(
              child: Container(
                height: MediaQuery.sizeOf(context).height * .78,
                margin: const EdgeInsets.fromLTRB(12, 48, 12, 8),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                decoration: BoxDecoration(
                  color: const Color(0xF2181B22),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _cyan.withOpacity(.42)),
                  boxShadow: [
                    BoxShadow(color: _cyan.withOpacity(.12), blurRadius: 28),
                  ],
                ),
                child: Column(children: [
                  Row(children: [
                    const Expanded(
                      child: Text('Connections',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(LucideIcons.x, color: Colors.white70),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                    children: _ConnectionTab.values.map((tab) {
                      final count = switch (tab) {
                        _ConnectionTab.snapped => ids.snapped.length,
                        _ConnectionTab.snapping => ids.snapping.length,
                        _ConnectionTab.mutual =>
                          ids.snapped.intersection(ids.snapping).length,
                      };
                      final label = switch (tab) {
                        _ConnectionTab.snapped => 'Snapped',
                        _ConnectionTab.snapping => 'Snapping',
                        _ConnectionTab.mutual => 'Mutual',
                      };
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            selected: selected == tab,
                            showCheckmark: false,
                            onSelected: (_) =>
                                updateSheet(() => selected = tab),
                            label: Text('$label $count'),
                            labelStyle: TextStyle(
                              color: selected == tab
                                  ? Colors.black
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            selectedColor: _cyan,
                            backgroundColor: _glass,
                            side: const BorderSide(color: _border),
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => updateSheet(() => query = value),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search accounts',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(LucideIcons.search, color: _cyan),
                      filled: true,
                      fillColor: _glass,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: visible.isEmpty
                        ? const Center(
                            child: Text('No matching accounts',
                                style: TextStyle(color: Color(0xFF888899))))
                        : ListView.separated(
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: _border),
                            itemBuilder: (_, index) {
                              final item = visible[index];
                              final mutual = ids.snapped.contains(item.id) &&
                                  ids.snapping.contains(item.id);
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                leading: _Avatar(profile: item, radius: 22),
                                title: Text(item.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                                subtitle: Text(item.handle,
                                    style: const TextStyle(
                                        color: Color(0xFF9B9BA8))),
                                trailing: Text(
                                    mutual
                                        ? 'Mutual'
                                        : (ids.snapping.contains(item.id)
                                            ? 'Snapping'
                                            : 'Snapped'),
                                    style: const TextStyle(
                                        color: _cyan, fontSize: 12)),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => PeopleProfileDetailScreen(
                                        userId: item.id),
                                  ));
                                },
                              );
                            },
                          ),
                  ),
                ]),
              ),
            );
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load accounts: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text('Account'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _cyan))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: _cyan,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 60),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(children: [
                              _identity(),
                              _postsSection(),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _identity() {
    final profile = _profile!;
    final details = <({IconData icon, String text})>[
      if (profile.headline.isNotEmpty)
        (icon: LucideIcons.briefcaseBusiness, text: profile.headline),
      if (profile.bio.isNotEmpty) (icon: LucideIcons.info, text: profile.bio),
      if (profile.department.isNotEmpty)
        (icon: LucideIcons.building2, text: profile.department),
      if (profile.location.isNotEmpty)
        (icon: LucideIcons.mapPin, text: profile.location),
      if (profile.githubHandle.isNotEmpty)
        (icon: Icons.code, text: 'github.com/${profile.githubHandle}'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 720;
      final photo = _ProfileImage(profile: profile, wide: wide);
      final info = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                profile.handle.isNotEmpty ? profile.handle : profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: wide ? 27 : 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(LucideIcons.ellipsis, color: Colors.white70),
          ]),
          if (profile.name.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(profile.name,
                style: const TextStyle(
                    color: Color(0xFFD4D4DA), fontWeight: FontWeight.w600)),
          ],
          if (details.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final detail in details)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(detail.icon, size: 16, color: _cyan),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(detail.text,
                          style: const TextStyle(
                              color: Color(0xFFC4C4CD), height: 1.3)),
                    ),
                  ],
                ),
              ),
          ],
          if (profile.skills.isNotEmpty) ...[
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: profile.skills
                  .take(6)
                  .map((skill) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: _glass,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: _border),
                        ),
                        child: Text(skill,
                            style: const TextStyle(
                                color: Color(0xFFCFCFD6), fontSize: 11)),
                      ))
                  .toList(growable: false),
            ),
          ],
        ],
      );

      return Container(
        margin: EdgeInsets.fromLTRB(wide ? 28 : 16, 20, wide ? 28 : 16, 0),
        padding: EdgeInsets.all(wide ? 26 : 16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _border),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF17191E), Color(0xFF101115)],
          ),
        ),
        child: Column(children: [
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                photo,
                const SizedBox(width: 30),
                Expanded(child: info),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                photo,
                const SizedBox(width: 16),
                Expanded(child: info),
              ],
            ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: _glass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(children: [
              Expanded(
                  child: _ProfileCount(value: _posts.length, label: 'Posts')),
              const _CountDivider(),
              Expanded(
                  child: _ProfileCount(
                      value: _snappedIds.length, label: 'Snapped')),
              const _CountDivider(),
              Expanded(
                  child: _ProfileCount(
                      value: _snappingIds.length, label: 'Snapping')),
              const _CountDivider(),
              Expanded(
                  child:
                      _ProfileCount(value: _mutualIds.length, label: 'Mutual')),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: () => _showConnections(_ConnectionTab.snapped),
                    child: const Text('Snapped'))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton(
                    onPressed: () => _showConnections(_ConnectionTab.snapping),
                    child: const Text('Snapping'))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton(
                    onPressed: () => _showConnections(_ConnectionTab.mutual),
                    child: const Text('Mutual'))),
          ]),
          const SizedBox(height: 14),
          if (_isSelf)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: _glass,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _border),
              ),
              child: const Text('Your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _cyan, fontWeight: FontWeight.w700)),
            )
          else
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _savingSnap ? null : _toggleSnap,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor:
                        profile.isFollowing ? const Color(0xFF292B31) : _cyan,
                    foregroundColor:
                        profile.isFollowing ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                  icon: _savingSnap
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(profile.isFollowing
                          ? LucideIcons.userCheck
                          : LucideIcons.userPlus),
                  label: Text(profile.isFollowing ? 'Snapping' : 'Snap'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openingChat ? null : _openMessage,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF25272D),
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                  icon: _openingChat
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.messageCircle, size: 18),
                  label: const Text('Message'),
                ),
              ),
            ]),
        ]),
      );
    });
  }

  Widget _postsSection() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(LucideIcons.grid3X3, size: 19, color: _cyan),
              const SizedBox(width: 9),
              Text('Posts (${_posts.length})',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            if (_posts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(34),
                decoration: BoxDecoration(
                  color: _glass,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: const Column(children: [
                  Icon(LucideIcons.fileText, color: Colors.white38, size: 34),
                  SizedBox(height: 10),
                  Text('No posts yet',
                      style: TextStyle(color: Color(0xFF888899))),
                ]),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _posts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                  childAspectRatio: .82,
                ),
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return InkWell(
                    onTap: () => _openPost(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Stack(fit: StackFit.expand, children: [
                        if (post.imageUrl.isNotEmpty)
                          Image.network(
                            post.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _postTextPreview(post),
                          )
                        else
                          _postTextPreview(post),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xB8000000)],
                              stops: [.55, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 7,
                          child: Row(children: [
                            const Icon(LucideIcons.heart,
                                size: 13, color: Colors.white),
                            const SizedBox(width: 3),
                            Text('${post.likesCount}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.messageCircle,
                                size: 13, color: Colors.white),
                            const SizedBox(width: 3),
                            Text('${post.commentsCount}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ]),
                    ),
                  );
                },
              ),
          ],
        ),
      );

  Widget _postTextPreview(FeedPost post) => Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF17374A), Color(0xFF171827), Color(0xFF101115)],
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            post.captionTitle.isNotEmpty ? post.captionTitle : post.captionBody,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      );
}

class _ProfileImage extends StatelessWidget {
  final UserProfile profile;
  final bool wide;

  const _ProfileImage({required this.profile, required this.wide});

  @override
  Widget build(BuildContext context) {
    final width = wide ? 190.0 : 112.0;
    final height = wide ? 205.0 : 142.0;
    final initial = profile.name.trim().isEmpty
        ? '?'
        : profile.name.trim().substring(0, 1).toUpperCase();
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(wide ? 30 : 22),
        border: Border.all(color: _cyan, width: 2),
        boxShadow: [
          BoxShadow(color: _cyan.withOpacity(.14), blurRadius: 24),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: profile.avatarUrl.isEmpty
          ? ColoredBox(
              color: const Color(0xFF23262D),
              child: Center(
                child: Text(initial,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: wide ? 68 : 42,
                        fontWeight: FontWeight.w800)),
              ),
            )
          : Image.network(
              profile.avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF23262D),
                child: Icon(LucideIcons.user, color: Colors.white54, size: 42),
              ),
            ),
    );
  }
}

class _ProfileCount extends StatelessWidget {
  final int value;
  final String label;

  const _ProfileCount({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$value',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF9B9BA8), fontSize: 11)),
        ]),
      );
}

class _CountDivider extends StatelessWidget {
  const _CountDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: _border);
}

class _Avatar extends StatelessWidget {
  final UserProfile profile;
  final double radius;

  const _Avatar({required this.profile, required this.radius});

  @override
  Widget build(BuildContext context) {
    final name = profile.name.trim();
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: radius + 2,
      backgroundColor: _cyan,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF22252B),
        foregroundImage:
            profile.avatarUrl.isEmpty ? null : NetworkImage(profile.avatarUrl),
        child: profile.avatarUrl.isEmpty
            ? Text(initial,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: radius * .72,
                    fontWeight: FontWeight.w800))
            : null,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.users, color: Colors.white38, size: 44),
            const SizedBox(height: 12),
            const Text('Could not load account',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF888899))),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ]),
        ),
      );
}
