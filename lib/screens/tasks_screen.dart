import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/task.dart';
import '../utils/mock_data.dart';
import '../widgets/task_card.dart';
import '../widgets/spring_button.dart';
import '../providers/theme_provider.dart';
import 'arena_event_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  final ValueChanged<String> onOpenTaskInWorkspace;

  const TasksScreen({
    super.key,
    required this.onOpenTaskInWorkspace,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';

  // Tab filter: 'all', 'hackathons', 'bounties', 'showdown'
  String _activeTab = 'all';

  // Tech category filter
  String _selectedCategory = 'All';

  // Local state reference for dynamic updates (voting, hosting)
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List.from(MockData.mockTasks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> get _filteredTasks {
    return _tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          task.tags.any((tag) => tag.toLowerCase().contains(_searchTerm.toLowerCase()));

      final matchesTab = switch (_activeTab) {
        'hackathons' => task.eventType.toLowerCase() == 'hackathon',
        'bounties' => task.eventType.toLowerCase() == 'bounty',
        'showdown' => task.status == 'VOTING' || task.teams.isNotEmpty,
        _ => true,
      };

      final matchesCategory = switch (_selectedCategory) {
        'All' => true,
        'AI & Agents' => task.tags.any((t) => t.toLowerCase().contains('ai') || t.toLowerCase().contains('agent') || t.toLowerCase().contains('llm')),
        'Mobile / Flutter' => task.tags.any((t) => t.toLowerCase().contains('flutter') || t.toLowerCase().contains('mobile')),
        'WASM / Systems' => task.tags.any((t) => t.toLowerCase().contains('wasm') || t.toLowerCase().contains('terminal') || t.toLowerCase().contains('fastapi')),
        'UI / UX' => task.tags.any((t) => t.toLowerCase().contains('design') || t.toLowerCase().contains('glass') || t.toLowerCase().contains('ui')),
        'Web3' => task.tags.any((t) => t.toLowerCase().contains('web3') || t.toLowerCase().contains('crypto') || t.toLowerCase().contains('escrow')),
        _ => true,
      };

      return matchesSearch && matchesTab && matchesCategory;
    }).toList();
  }

  // Cast vote for a team
  void _castVote(Task task, TeamShowdown team) {
    setState(() {
      team.votes += 1;
      task.totalVotes += 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E2028),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Color(0xFF00E676), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Vote registered for ${team.teamName}! 🎉',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Open Full Arena Event Detail Screen
  void _openEventDetail(Task task) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ArenaEventDetailScreen(
            task: task,
            onOpenInWorkspace: widget.onOpenTaskInWorkspace,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(curve),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // Open Showdown Modal
  void _openShowdownModal(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1015).withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.swords, size: 16, color: Color(0xFF54C5F8)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'COMMUNITY SHOWDOWN',
                                    style: TextStyle(
                                      color: const Color(0xFF54C5F8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                task.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.trophy, size: 14, color: Color(0xFFFFD700)),
                              const SizedBox(width: 6),
                              Text(
                                task.prizePool,
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vote for the most innovative project built during this event. The winning team claims the prize pool when the deadline passes!',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // Teams Showdown List
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: task.teams.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final team = task.teams[index];
                          final totalVotes = task.totalVotes > 0 ? task.totalVotes : 1;
                          final votePercent = ((team.votes / totalVotes) * 100).toInt();

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 1,
                              ),
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
                                          radius: 16,
                                          backgroundColor: const Color(0xFF54C5F8).withOpacity(0.2),
                                          child: Text(
                                            team.teamName.isNotEmpty ? team.teamName[0] : 'T',
                                            style: const TextStyle(
                                              color: Color(0xFF54C5F8),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              team.teamName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              team.projectTitle,
                                              style: TextStyle(
                                                color: const Color(0xFF54C5F8).withOpacity(0.9),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Vote Button
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _castVote(task, team);
                                        setModalState(() {});
                                      },
                                      icon: const Icon(LucideIcons.heart, size: 14, color: Colors.white),
                                      label: Text('Vote (${team.votes})'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF54C5F8),
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Growth Update / Feed Post preview
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(LucideIcons.rss, size: 13, color: Colors.white54),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          team.growthUpdate,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Vote Progress Bar
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: team.votes / totalVotes,
                                          minHeight: 6,
                                          backgroundColor: Colors.white.withOpacity(0.1),
                                          valueColor: const AlwaysStoppedAnimation(Color(0xFF54C5F8)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '$votePercent%',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
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
              ),
            );
          },
        );
      },
    );
  }

  // Host Hackathon / Post Bounty Modal
  void _openHostEventModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final prizeCtrl = TextEditingController(text: '₹20,000');
    final tagsCtrl = TextEditingController(text: 'Flutter, AI Agents');
    String eventType = 'Hackathon';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1015).withOpacity(0.96),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Title
                        Row(
                          children: [
                            const Icon(LucideIcons.sparkles, color: Color(0xFFFFD700), size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Host a Hackathon or Bounty',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Inspire builders to create together, share growth feeds, and win rewards.',
                          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
                        ),
                        const SizedBox(height: 18),

                        // Event Type Selector
                        Row(
                          children: ['Hackathon', 'Bounty', 'Challenge'].map((type) {
                            final isSel = eventType == type;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(type),
                                selected: isSel,
                                selectedColor: const Color(0xFF54C5F8),
                                backgroundColor: Colors.white.withOpacity(0.08),
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                onSelected: (_) => setModalState(() => eventType = type),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // Title Field
                        TextField(
                          controller: titleCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Event Title',
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintText: 'e.g. Mobile AI Agents Sprint 2026',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Prize Pool & Tags
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: prizeCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Prize Pool',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.08),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: tagsCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Tags (comma separated)',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.08),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Description Field
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Problem Statement & Requirements',
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintText: 'Describe the goal, expected output, and guidelines...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              if (titleCtrl.text.trim().isEmpty) return;

                              final newTask = Task(
                                id: 'event-${DateTime.now().millisecondsSinceEpoch}',
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim().isNotEmpty
                                    ? descCtrl.text.trim()
                                    : 'A fast-paced developer competition.',
                                course: 'Community',
                                branch: 'Global',
                                section: 'A',
                                year: '2026',
                                deadline: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
                                createdAt: DateTime.now().toIso8601String(),
                                ownerId: 'user-self',
                                submissionCount: 1,
                                prizePool: prizeCtrl.text.trim().isNotEmpty ? prizeCtrl.text.trim() : '₹10,000',
                                eventType: eventType,
                                status: 'LIVE',
                                tags: tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                                teamsCount: 1,
                                totalVotes: 0,
                                teams: [
                                  TeamShowdown(
                                    id: 'team-new-1',
                                    teamName: 'Team Pioneer',
                                    projectTitle: 'Initial Submission',
                                    growthUpdate: 'Registered in the arena!',
                                    votes: 0,
                                    memberAvatars: [],
                                  ),
                                ],
                              );

                              setState(() {
                                _tasks.insert(0, newTask);
                                MockData.mockTasks.insert(0, newTask);
                              });

                              Navigator.pop(ctx);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF1E2028),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  content: Row(
                                    children: [
                                      const Icon(LucideIcons.checkCheck, color: Color(0xFF00E676), size: 18),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Hackathon live in Arena! 🚀',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF54C5F8),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            child: const Text('Publish to Arena'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksList = _filteredTasks;
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount = 1;
    if (width > 1200) {
      crossAxisCount = 3;
    } else if (width > 800) {
      crossAxisCount = 2;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search & Host Bar (Direct, Compact, Overflow-free) ────────────
          _buildSearchAndHostBar(),
          const SizedBox(height: 12),

          // ── Category Pills Filter ─────────────────────────────────────────
          _buildCategoryPills(),
          const SizedBox(height: 12),

          // ── Tabs Bar (All Events, Hackathons, Bounties, Showdown) ───────────
          _buildTabBar(),
          const SizedBox(height: 14),

          // ── Featured Spotlight Banner ─────────────────────────────────────
          if (_tasks.isNotEmpty && _searchTerm.isEmpty && _activeTab == 'all') ...[
            _buildSpotlightBanner(_tasks.first),
            const SizedBox(height: 14),
          ],

          // ── Main Content Grid / List ──────────────────────────────────────
          tasksList.isEmpty
              ? _buildEmptyState()
              : crossAxisCount > 1
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        mainAxisExtent: 385,
                      ),
                      itemCount: tasksList.length,
                      itemBuilder: (context, index) {
                        return TaskCard(
                          task: tasksList[index],
                          onOpenInWorkspace: widget.onOpenTaskInWorkspace,
                          onOpenShowdown: _openShowdownModal,
                          onOpenDetail: _openEventDetail,
                        );
                      },
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasksList.length,
                      itemBuilder: (context, index) {
                        return TaskCard(
                          task: tasksList[index],
                          onOpenInWorkspace: widget.onOpenTaskInWorkspace,
                          onOpenShowdown: _openShowdownModal,
                          onOpenDetail: _openEventDetail,
                        );
                      },
                    ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // Featured Spotlight Hero Banner
  // Featured Spotlight Hero Banner
  Widget _buildSpotlightBanner(Task featured) {
    return SpringButton(
      onTap: () => _openEventDetail(featured),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF54C5F8).withOpacity(0.35),
            width: 1.2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF54C5F8).withOpacity(0.14),
              const Color(0xFFB388FF).withOpacity(0.08),
              Colors.black.withOpacity(0.4),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                              ),
                              child: const Text(
                                'FEATURED ARENA',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            Text(
                              'Prize: ${featured.prizePool}',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          featured.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          featured.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _openEventDetail(featured),
                    icon: const Icon(LucideIcons.rocket, size: 13, color: Colors.black),
                    label: const Text('Enter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF54C5F8),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Tab switcher pills
  Widget _buildTabBar() {
    final tabs = [
      {'id': 'all', 'label': 'All Events', 'icon': LucideIcons.sparkles},
      {'id': 'hackathons', 'label': 'Live Hackathons', 'icon': LucideIcons.flame},
      {'id': 'bounties', 'label': 'Code Bounties', 'icon': LucideIcons.coins},
      {'id': 'showdown', 'label': 'Community Showdown', 'icon': LucideIcons.swords},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tabs.map((tab) {
          final isSel = _activeTab == tab['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _activeTab = tab['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF54C5F8) : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel ? const Color(0xFF54C5F8) : Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 14,
                      color: isSel ? Colors.black : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        color: isSel ? Colors.black : Colors.white,
                        fontSize: 12.5,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Search & Host Bar in one unified glass row
  Widget _buildSearchAndHostBar() {
    return Row(
      children: [
        // Transparent glass search field
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchTerm = val),
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              cursorColor: const Color(0xFF54C5F8),
              decoration: InputDecoration(
                hintText: 'Search hackathons, bounties, tech tags...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12.5),
                prefixIcon: const Icon(LucideIcons.search, size: 16, color: Colors.white70),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchTerm = '');
                        },
                      )
                    : null,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Host Event Button (Liquid Glass Cyan Glow)
        SpringButton(
          onTap: _openHostEventModal,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF54C5F8), Color(0xFF00B0FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF54C5F8).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(LucideIcons.plus, size: 15, color: Colors.black),
                SizedBox(width: 5),
                Text(
                  'Host',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Category pills
  Widget _buildCategoryPills() {
    final categories = [
      'All',
      'AI & Agents',
      'Mobile / Flutter',
      'WASM / Systems',
      'UI / UX',
      'Web3',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final isSel = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF54C5F8).withOpacity(0.18) : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel ? const Color(0xFF54C5F8) : Colors.white.withOpacity(0.10),
                    width: 1,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSel ? const Color(0xFF54C5F8) : Colors.white70,
                    fontSize: 11.5,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.trophy,
            size: 56,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Events Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try switching categories or clear your search terms.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
