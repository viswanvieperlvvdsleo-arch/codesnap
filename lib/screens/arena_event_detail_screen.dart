import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/task.dart';
import '../widgets/spring_button.dart';

/// ─── Arena Event Detail Screen ──────────────────────────────────────────────
/// Full-page interactive detail view for Hackathons, Bounties, and Showdowns.
/// 100% Liquid Glass theme with frosted transparent shades and fluid morph animations.
class ArenaEventDetailScreen extends StatefulWidget {
  final Task task;
  final ValueChanged<String> onOpenInWorkspace;

  const ArenaEventDetailScreen({
    super.key,
    required this.task,
    required this.onOpenInWorkspace,
  });

  @override
  State<ArenaEventDetailScreen> createState() => _ArenaEventDetailScreenState();
}

class _ArenaEventDetailScreenState extends State<ArenaEventDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Task _task;
  int _activeTabIndex = 0;
  bool _isBookmarked = false;
  bool _hasJoined = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _castVoteForTeam(TeamShowdown team) {
    setState(() {
      team.votes += 1;
      _task.totalVotes += 1;
    });

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1017).withOpacity(0.88),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.checkCircle2, color: Color(0xFF00E676), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Vote registered for ${team.teamName}! 🎉',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showJoinTeamModal() {
    final teamNameCtrl = TextEditingController();
    final ideaCtrl = TextEditingController();
    final membersCtrl = TextEditingController(text: 'Me, Alex');

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'JoinTeam',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  width: MediaQuery.of(context).size.width > 500 ? 460 : MediaQuery.of(context).size.width - 36,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
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
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 36,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: const Color(0xFF54C5F8).withOpacity(0.12),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF54C5F8).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.users, size: 18, color: Color(0xFF54C5F8)),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Register Team for Arena',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SpringButton(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.x, size: 15, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Team Name',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      _buildGlassInput(teamNameCtrl, 'e.g. CyberVanguard, NeuralHacks'),
                      const SizedBox(height: 14),
                      Text(
                        'Project Vision / Idea',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      _buildGlassInput(ideaCtrl, 'Briefly describe your project concept...', maxLines: 3),
                      const SizedBox(height: 14),
                      Text(
                        'Team Members',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      _buildGlassInput(membersCtrl, 'Comma separated handles'),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: SpringButton(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                                ),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SpringButton(
                              onTap: () {
                                if (teamNameCtrl.text.trim().isEmpty) return;
                                setState(() {
                                  _hasJoined = true;
                                  _task.teamsCount += 1;
                                  _task.teams.add(
                                    TeamShowdown(
                                      id: 'team-${DateTime.now().millisecondsSinceEpoch}',
                                      teamName: teamNameCtrl.text.trim(),
                                      projectTitle: ideaCtrl.text.trim().isNotEmpty ? ideaCtrl.text.trim() : 'New Challenger',
                                      growthUpdate: 'Just registered! Setting up project architecture in Bug Workspace.',
                                      votes: 1,
                                      memberAvatars: const [
                                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
                                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
                                      ],
                                    ),
                                  );
                                });
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Team successfully registered! Welcome to the Arena 🔥'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF54C5F8),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF54C5F8).withOpacity(0.4),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Confirm & Enter',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
                                ),
                              ),
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
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  void _showSubmitProjectModal() {
    final repoCtrl = TextEditingController();
    final demoUrlCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SubmitProject',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  width: MediaQuery.of(context).size.width > 500 ? 460 : MediaQuery.of(context).size.width - 36,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
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
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 36,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: const Color(0xFF00E676).withOpacity(0.12),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.uploadCloud, size: 18, color: Color(0xFF00E676)),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Submit Arena Project',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SpringButton(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.x, size: 15, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('Repository / Workspace Folder', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                      const SizedBox(height: 6),
                      _buildGlassInput(repoCtrl, 'https://github.com/... or codesnap://workspace/my-app'),
                      const SizedBox(height: 14),
                      Text('Live Preview URL (Optional)', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                      const SizedBox(height: 6),
                      _buildGlassInput(demoUrlCtrl, 'https://my-app.vercel.app'),
                      const SizedBox(height: 14),
                      Text('Project Summary & Highlights', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                      const SizedBox(height: 6),
                      _buildGlassInput(summaryCtrl, 'What did you build? What AI agents were integrated?', maxLines: 3),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: SpringButton(
                          onTap: () {
                            if (repoCtrl.text.trim().isEmpty) return;
                            setState(() {
                              _task.submissionCount += 1;
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Project submitted for judging! Community voting is open. 🚀'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E676).withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text('Submit Solution', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassInput(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deadlineDate = DateTime.tryParse(_task.deadline);
    final now = DateTime.now();
    final isPastDue = deadlineDate != null && deadlineDate.isBefore(now);

    String timeRemaining = 'Ended';
    if (deadlineDate != null && !isPastDue) {
      final diff = deadlineDate.difference(now);
      if (diff.inDays > 0) {
        timeRemaining = '${diff.inDays} days, ${diff.inHours % 24} hrs left';
      } else {
        timeRemaining = '${diff.inHours} hrs, ${diff.inMinutes % 60} mins left';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          // Background ambient glass glow
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF54C5F8).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFB388FF).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Body
          SafeArea(
            child: Column(
              children: [
                // Top Custom Glass Bar
                _buildTopHeader(),

                // Scrollable Content
                Expanded(
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: _buildHeroCard(timeRemaining, isPastDue),
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _SliverGlassTabBarDelegate(
                            tabBar: _buildLiquidTabBar(),
                          ),
                        ),
                      ];
                    },
                    body: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildOverviewTab(),
                        _buildShowdownTab(),
                        _buildGrowthFeedTab(),
                        _buildPrizesTab(),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Dock
                _buildBottomActionDock(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B).withOpacity(0.70),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.10))),
      ),
      child: Row(
        children: [
          SpringButton(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(LucideIcons.arrowLeft, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SpringButton(
            onTap: () {
              setState(() => _isBookmarked = !_isBookmarked);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isBookmarked ? 'Event bookmarked!' : 'Removed from bookmarks'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Icon(
                _isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                size: 16,
                color: _isBookmarked ? const Color(0xFF54C5F8) : Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SpringButton(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Arena event share link copied!'), duration: Duration(seconds: 1)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(LucideIcons.share2, size: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String timeRemaining, bool isPastDue) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.16), width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF54C5F8).withOpacity(0.15),
            const Color(0xFF9333EA).withOpacity(0.08),
            Colors.black.withOpacity(0.4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF54C5F8).withOpacity(0.20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.45)),
                          ),
                          child: Text(
                            _task.eventType.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF54C5F8),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: Color(0xFF00E676), size: 6),
                              SizedBox(width: 5),
                              Text('LIVE NOW', style: TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Prize Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.45)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.trophy, size: 13, color: Color(0xFFFFD700)),
                          const SizedBox(width: 5),
                          Text(
                            _task.prizePool,
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Main Title
                Text(
                  _task.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  _task.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.80),
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(LucideIcons.clock, timeRemaining, isPastDue ? Colors.redAccent : const Color(0xFF54C5F8)),
                      Container(width: 1, height: 24, color: Colors.white.withOpacity(0.12)),
                      _buildMetric(LucideIcons.users, '${_task.teamsCount} Teams', Colors.white70),
                      Container(width: 1, height: 24, color: Colors.white.withOpacity(0.12)),
                      _buildMetric(LucideIcons.vote, '${_task.totalVotes} Votes', const Color(0xFFB388FF)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildLiquidTabBar() {
    final tabs = ['Overview', 'Showdown', 'Growth Feed', 'Prizes'];
    return Container(
      color: const Color(0xFF09090B),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final isSel = _activeTabIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  _tabController.animateTo(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF54C5F8).withOpacity(0.22) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isSel ? Border.all(color: const Color(0xFF54C5F8).withOpacity(0.55)) : null,
                  ),
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      color: isSel ? const Color(0xFF54C5F8) : Colors.white60,
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Tab 1: Overview & Guidelines ──────────────────────────────────────────
  Widget _buildOverviewTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildSectionCard(
          title: 'Problem Statement & Scope',
          icon: LucideIcons.fileCode,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Developers must architect and deliver a fully functional software prototype adhering to the challenge themes. The application must feature responsive design, robust state management, and real-time interactive capabilities.',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _task.tags.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Text('#$t', style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 11.5, fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          title: 'Arena Rules & Guidelines',
          icon: LucideIcons.shieldCheck,
          content: Column(
            children: [
              _buildRuleItem('1', 'All code must be committed to your workspace repository before the deadline.'),
              _buildRuleItem('2', 'AI agent assistance is permitted and encouraged with transparent token usage.'),
              _buildRuleItem('3', 'Teams can post growth updates to the feed to earn community votes.'),
              _buildRuleItem('4', 'Zero external server costs required — code executes in sandbox or peer environments.'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          title: 'Organizer & Host Details',
          icon: LucideIcons.award,
          content: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CloudSnap Developer Guild', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Verified Community Host · Global Guild', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildRuleItem(String index, String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF54C5F8).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text(index, style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(rule, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.5, height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Community Showdown & Voting ─────────────────────────────────────
  Widget _buildShowdownTab() {
    final teams = _task.teams;
    final totalVotes = _task.totalVotes > 0 ? _task.totalVotes : 1;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFB388FF).withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFB388FF).withOpacity(0.30)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.swords, color: Color(0xFFB388FF), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Community Showdown: Vote for the most innovative project implementation. Winners take the prize pool!',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        ...teams.map((team) {
          final pct = ((team.votes / totalVotes) * 100).toInt();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      team.teamName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SpringButton(
                      onTap: () => _castVoteForTeam(team),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF54C5F8).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF54C5F8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.vote, size: 14, color: Color(0xFF54C5F8)),
                            const SizedBox(width: 6),
                            Text('Vote (${team.votes})', style: const TextStyle(color: Color(0xFF54C5F8), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  team.projectTitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.rss, size: 13, color: Colors.white54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          team.growthUpdate,
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: team.votes / totalVotes,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF54C5F8)),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$pct% of total votes',
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 100),
      ],
    );
  }

  // ── Tab 3: Live Growth Feed ───────────────────────────────────────────────
  Widget _buildGrowthFeedTab() {
    final updates = [
      {
        'team': 'NeuroCoder',
        'time': '10m ago',
        'update': 'Finished implementing WebSocket terminal protocol! Realtime streaming working at 60 FPS.',
        'tag': 'Milestone 2',
      },
      {
        'team': 'CloudSnap Prime',
        'time': '35m ago',
        'update': 'Merged PR #14: Integrated deep liquid glass UI theme with spring physics on Android.',
        'tag': 'UI Polish',
      },
      {
        'team': 'PyWasm Core',
        'time': '2h ago',
        'update': 'Successfully compiled Python 3.12 sandbox to WebAssembly. Executes math benchmarks in browser!',
        'tag': 'Backend',
      },
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        ...updates.map((u) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF54C5F8).withOpacity(0.2),
                          child: Text(
                            (u['team'] as String)[0],
                            style: const TextStyle(color: Color(0xFF54C5F8), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(u['team'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                      ],
                    ),
                    Text(u['time'] as String, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(u['update'] as String, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.4)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(u['tag'] as String, style: const TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 100),
      ],
    );
  }

  // ── Tab 4: Prizes & Rewards ───────────────────────────────────────────────
  Widget _buildPrizesTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildPrizeTier('1st Place Champion', '₹30,000 + Gold Guild Badge + Fast-Track Verification', const Color(0xFFFFD700), LucideIcons.trophy),
        const SizedBox(height: 12),
        _buildPrizeTier('2nd Place Runner-Up', '₹15,000 + Silver Showcase Feature', const Color(0xFFC0C0C0), LucideIcons.award),
        const SizedBox(height: 12),
        _buildPrizeTier('3rd Place Innovator', '₹5,000 + Community Bronze Honors', const Color(0xFFCD7F32), LucideIcons.medal),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Judging Criteria',
          icon: LucideIcons.checkSquare,
          content: Column(
            children: [
              _buildCriteriaItem('Technical Execution & Architecture', '40%'),
              _buildCriteriaItem('Liquid Glass Design & Fluid UX', '30%'),
              _buildCriteriaItem('Community Votes in Showdown', '30%'),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPrizeTier(String rank, String reward, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rank, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(reward, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaItem(String label, String weight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.5)),
          Text(weight, style: const TextStyle(color: Color(0xFF54C5F8), fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF54C5F8)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  // ── Floating Bottom Action Dock ───────────────────────────────────────────
  Widget _buildBottomActionDock() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B).withOpacity(0.88),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.12))),
      ),
      child: Row(
        children: [
          // Open in Workspace Button
          Expanded(
            flex: 2,
            child: SpringButton(
              onTap: () {
                widget.onOpenInWorkspace(_task.id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.code, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Workspace', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Register Team or Submit Solution
          Expanded(
            flex: 3,
            child: SpringButton(
              onTap: _hasJoined ? _showSubmitProjectModal : _showJoinTeamModal,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _hasJoined
                        ? [const Color(0xFF00E676), const Color(0xFF00B0FF)]
                        : [const Color(0xFF54C5F8), const Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (_hasJoined ? const Color(0xFF00E676) : const Color(0xFF54C5F8)).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_hasJoined ? LucideIcons.uploadCloud : LucideIcons.rocket, size: 16, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      _hasJoined ? 'Submit Project' : 'Register / Join Team',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverGlassTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;
  _SliverGlassTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => 58;
  @override
  double get maxExtent => 58;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return tabBar;
  }

  @override
  bool shouldRebuild(covariant _SliverGlassTabBarDelegate oldDelegate) => true;
}
