import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/user_profile.dart';
import '../services/supabase_data_service.dart';
import '../services/supabase_service.dart';
import '../services/realtime_sync_service.dart';
import '../utils/app_animations.dart';
import '../widgets/spring_button.dart';
import 'people_profile_detail_screen.dart';

const _background = Color(0xFF09090B);
const _card = Color(0xFF131418);
const _glass = Color(0x14FFFFFF);
const _border = Color(0x26FFFFFF);
const _cyan = Color(0xFF54C5F8);

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _searchController = TextEditingController();
  final Set<String> _savingSnapIds = {};
  List<UserProfile> _people = const [];
  String _filter = 'All';
  bool _loading = true;
  String? _error;
  VoidCallback? _stopRealtime;
  Timer? _realtimeRefreshTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadPeople();
    _stopRealtime = RealtimeSyncService.instance.subscribe(
      const {'profiles', 'followers', 'posts'},
      (_) {
        _realtimeRefreshTimer?.cancel();
        _realtimeRefreshTimer =
            Timer(const Duration(milliseconds: 250), _loadPeople);
      },
    );
  }

  @override
  void dispose() {
    _stopRealtime?.call();
    _realtimeRefreshTimer?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  Future<void> _loadPeople() async {
    if (SupabaseService.currentUserId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Sign in to discover CodeSnap accounts.';
        _people = const [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await SupabaseDataService.fetchDevelopers(limit: 200);
      if (!mounted) return;
      setState(() {
        _people = rows
            .map(UserProfile.fromPeopleDirectory)
            .where((profile) => profile.id.isNotEmpty)
            .toList(growable: false);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load accounts from Supabase.\n$error';
      });
    }
  }

  List<UserProfile> get _filteredPeople {
    final query = _searchController.text.trim().toLowerCase();
    return _people.where((profile) {
      if (_filter == 'Snapping' && !profile.isFollowing) return false;
      if (_filter == 'Developers' && profile.skills.isEmpty) return false;
      if (query.isEmpty) return true;
      return <String>[
        profile.name,
        profile.handle,
        profile.headline,
        profile.bio,
        profile.department,
        profile.location,
        ...profile.skills,
      ].join(' ').toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Future<void> _setSnapping(UserProfile profile) async {
    if (_savingSnapIds.contains(profile.id) ||
        profile.id == SupabaseService.currentUserId) {
      return;
    }
    final shouldSnap = !profile.isFollowing;
    setState(() => _savingSnapIds.add(profile.id));
    try {
      await SupabaseDataService.setSnapping(
        targetUserId: profile.id,
        shouldSnap: shouldSnap,
      );
      final row = await SupabaseDataService.fetchDeveloperById(profile.id);
      if (!mounted) return;
      if (row != null) {
        setState(() {
          final index = _people.indexWhere((item) => item.id == profile.id);
          if (index >= 0) _people[index] = UserProfile.fromPeopleDirectory(row);
        });
      }
      _showMessage(shouldSnap
          ? 'Now snapping ${profile.name}'
          : 'Stopped snapping ${profile.name}');
    } catch (error) {
      if (mounted) _showMessage('Snap update failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _savingSnapIds.remove(profile.id));
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFF7F1D1D) : const Color(0xFF17232B),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _openProfile(UserProfile profile) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PeopleProfileDetailScreen(userId: profile.id),
    ));
    if (mounted) await _loadPeople();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPeople;
    final suggested = _people
        .where((profile) => profile.id != SupabaseService.currentUserId)
        .take(8)
        .toList(growable: false);
    return Scaffold(
      backgroundColor: _background,
      body: RefreshIndicator(
        color: _cyan,
        backgroundColor: _card,
        onRefresh: _loadPeople,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(color: _cyan)),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _StatePanel(
                  title: 'People unavailable',
                  message: _error!,
                  actionLabel: SupabaseService.currentUserId == null
                      ? null
                      : 'Try again',
                  onAction: SupabaseService.currentUserId == null
                      ? null
                      : _loadPeople,
                ),
              )
            else ...[
              if (_searchController.text.isEmpty &&
                  _filter == 'All' &&
                  suggested.isNotEmpty) ...[
                _section('Suggested accounts', '${_people.length} registered'),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 156,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: suggested.length,
                      itemBuilder: (_, index) =>
                          _suggestedCard(suggested[index]),
                    ),
                  ),
                ),
              ],
              _section('Accounts', '${filtered.length} found'),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _StatePanel(
                    title: 'No accounts found',
                    message: 'Try another name, handle, skill, or filter.',
                  ),
                )
              else
                SliverLayoutBuilder(builder: (context, constraints) {
                  if (constraints.crossAxisExtent <= 40) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 390,
                        mainAxisExtent: 286,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, index) => _profileCard(filtered[index]),
                        childCount: filtered.length,
                      ),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(LucideIcons.users, color: _cyan, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('People & Community',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    Text('Real CodeSnap accounts from Supabase',
                        style:
                            TextStyle(color: Color(0xFF888899), fontSize: 12)),
                  ]),
            ),
          ]),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search name, handle, skill, or location',
                  hintStyle: const TextStyle(color: Color(0xFF6F6F7B)),
                  prefixIcon: const Icon(LucideIcons.search,
                      color: Color(0xFF888899), size: 18),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(LucideIcons.x,
                              color: Color(0xFF888899), size: 18),
                        ),
                  filled: true,
                  fillColor: _glass,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _cyan),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['All', 'Snapping', 'Developers'].map((label) {
              final selected = _filter == label;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => setState(() => _filter = label),
                selectedColor: _cyan.withValues(alpha: .18),
                backgroundColor: _glass,
                side: BorderSide(color: selected ? _cyan : _border),
                labelStyle: TextStyle(
                  color: selected ? _cyan : const Color(0xFFB8B8C1),
                ),
              );
            }).toList(growable: false),
          ),
        ]),
      );

  SliverToBoxAdapter _section(String title, String count) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            Text(count,
                style: const TextStyle(color: Color(0xFF777782), fontSize: 11)),
          ]),
        ),
      );

  Widget _suggestedCard(UserProfile profile) => Container(
        width: 238,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Avatar(profile: profile, radius: 22),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _openProfile(profile),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      Text(profile.handle,
                          maxLines: 1,
                          style: const TextStyle(
                              color: Color(0xFF888899), fontSize: 12)),
                    ]),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(profile.headline.isEmpty ? 'CodeSnap member' : profile.headline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFB0B0BA), fontSize: 12)),
          const Spacer(),
          Row(children: [
            Expanded(
              child: Text('${profile.followersCount} snapped',
                  style:
                      const TextStyle(color: Color(0xFF888899), fontSize: 11)),
            ),
            _SnapButton(
              following: profile.isFollowing,
              busy: _savingSnapIds.contains(profile.id),
              onTap: () => _setSnapping(profile),
            ),
          ]),
        ]),
      );

  Widget _profileCard(UserProfile profile) {
    final isSelf = profile.id == SupabaseService.currentUserId;
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openProfile(profile),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(20),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 62,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF15394B), Color(0xFF171722)],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(14, -25),
              child: _Avatar(profile: profile, radius: 27),
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(profile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ),
                          if (isSelf)
                            const Text('You',
                                style: TextStyle(color: _cyan, fontSize: 12)),
                        ]),
                        Text(profile.handle,
                            style: const TextStyle(
                                color: Color(0xFF888899), fontSize: 12)),
                        const SizedBox(height: 7),
                        Text(
                          profile.bio.isNotEmpty
                              ? profile.bio
                              : (profile.headline.isNotEmpty
                                  ? profile.headline
                                  : 'No bio added yet.'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFFB0B0BA),
                              fontSize: 12,
                              height: 1.3),
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 5,
                          children: profile.skills
                              .take(3)
                              .map((skill) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _glass,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _border),
                                    ),
                                    child: Text(skill,
                                        style: const TextStyle(
                                            color: Color(0xFFD0D0D6),
                                            fontSize: 10)),
                                  ))
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 12),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _stat('${profile.followersCount}', 'Snapped'),
                              _stat('${profile.followingCount}', 'Snapping'),
                              _stat('${profile.postsCount}', 'Posts'),
                              if (!isSelf)
                                _SnapButton(
                                  following: profile.isFollowing,
                                  busy: _savingSnapIds.contains(profile.id),
                                  onTap: () => _setSnapping(profile),
                                ),
                            ]),
                      ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        Text(label,
            style: const TextStyle(color: Color(0xFF777782), fontSize: 9)),
      ]);
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
      backgroundColor: _cyan.withValues(alpha: .5),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF20242B),
        foregroundImage:
            profile.avatarUrl.isEmpty ? null : NetworkImage(profile.avatarUrl),
        child: profile.avatarUrl.isEmpty
            ? Text(initial,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: radius * .8,
                    fontWeight: FontWeight.w700))
            : null,
      ),
    );
  }
}

class _SnapButton extends StatelessWidget {
  final bool following;
  final bool busy;
  final VoidCallback onTap;

  const _SnapButton({
    required this.following,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SpringButton(
        onTap: busy ? () {} : onTap,
        child: AnimatedContainer(
          duration: AppAnimations.micro,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: following ? _glass : _cyan.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: following ? _border : _cyan.withValues(alpha: .7)),
          ),
          child: busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: _cyan),
                )
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(following ? LucideIcons.check : LucideIcons.userPlus,
                      size: 13, color: following ? Colors.white70 : _cyan),
                  const SizedBox(width: 5),
                  Text(following ? 'Snapping' : 'Snap',
                      style: TextStyle(
                          color: following ? Colors.white70 : _cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
        ),
      );
}

class _StatePanel extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatePanel({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.users, color: Colors.white38, size: 44),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF888899), height: 1.4)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ]),
        ),
      );
}
