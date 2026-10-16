import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/project.dart';
import '../utils/mock_data.dart';
import '../widgets/project_card.dart';
import '../widgets/spring_button.dart';
import '../widgets/morphing_capsule.dart';
import '../services/github_workspace_service.dart';
import '../services/supabase_data_service.dart';
import '../services/realtime_sync_service.dart';
import 'project_detail_screen.dart';

class ProjectsScreen extends StatefulWidget {
  final ValueChanged<String> onOpenProjectInWorkspace;

  const ProjectsScreen({
    super.key,
    required this.onOpenProjectInWorkspace,
  });

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
  final List<Project> _linkedProjects = [];
  bool _loadingLinkedProjects = true;
  VoidCallback? _stopRealtime;
  Timer? _realtimeRefreshTimer;

  final List<String> _categories = [
    'All',
    'E-Commerce',
    'Dashboard',
    'Productivity Tools',
    'Education',
    'Portfolio',
    'Social Media',
  ];

  final List<String> _difficulties = [
    'All',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    _loadLinkedProjects();
    _stopRealtime = RealtimeSyncService.instance.subscribe(
      const {'workspace_projects', 'workspace_files'},
      (_) {
        _realtimeRefreshTimer?.cancel();
        _realtimeRefreshTimer =
            Timer(const Duration(milliseconds: 250), _loadLinkedProjects);
      },
    );
  }

  Future<void> _loadLinkedProjects() async {
    try {
      final rows = await SupabaseDataService.fetchGitHubWorkspaceProjects();
      final projects = rows.map(_projectFromWorkspaceRow).toList();
      if (!mounted) return;
      setState(() {
        _linkedProjects
          ..clear()
          ..addAll(projects);
        _syncProjectsToWorkspace(projects);
        _loadingLinkedProjects = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingLinkedProjects = false);
    }
  }

  Project _projectFromWorkspaceRow(Map<String, dynamic> row) {
    return Project.fromWorkspaceRow(row);
  }

  void _syncProjectsToWorkspace(List<Project> projects) {
    for (final project in projects) {
      MockData.mockProjects.removeWhere((item) => item.id == project.id);
      MockData.mockProjects.insert(0, project);
    }
  }

  @override
  void dispose() {
    _stopRealtime?.call();
    _realtimeRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Project> get _filteredProjects {
    final linkedIds = _linkedProjects.map((project) => project.id).toSet();
    final allProjects = [
      ..._linkedProjects,
      ...MockData.mockProjects
          .where((project) => !linkedIds.contains(project.id)),
    ];
    return allProjects.where((project) {
      final matchesSearch = _searchTerm.isEmpty ||
          project.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          project.description
              .toLowerCase()
              .contains(_searchTerm.toLowerCase()) ||
          project.category.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          project.techStack
              .any((t) => t.toLowerCase().contains(_searchTerm.toLowerCase()));

      final matchesCategory =
          _selectedCategory == 'All' || project.category == _selectedCategory;
      final matchesDifficulty = _selectedDifficulty == 'All' ||
          project.difficulty == _selectedDifficulty;

      return matchesSearch && matchesCategory && matchesDifficulty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredProjects;

    return Container(
      color: const Color(0xFF09090B),
      child: Stack(
        children: [
          // Background ambient glass light
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.025),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width > 800 ? 32.0 : 16.0,
              16.0,
              MediaQuery.of(context).size.width > 800 ? 32.0 : 16.0,
              0.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Search & Filters Bar (Top of screen) ───
                _buildFiltersBar(context),
                const SizedBox(height: 16),

                // ─── Projects Grid Listing ───
                Expanded(
                  child: _loadingLinkedProjects
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF54C5F8)),
                        )
                      : filteredList.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 440,
                                mainAxisExtent: 310,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                              ),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final project = filteredList[index];
                                return ProjectCard(
                                  project: project,
                                  onDetails: () =>
                                      _showProjectDetails(context, project),
                                  onOpenInWorkspace:
                                      widget.onOpenProjectInWorkspace,
                                );
                              },
                            ),
                ),
              ],
            ),
          ),

          // ─── Floating Bottom-Right Action Button ───
          Positioned(
            bottom: 24,
            right: 28,
            child: SpringButton(
              onTap: _showUploadProjectSheet,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF181920),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.55),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.upload,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadProjectSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final gitUrlCtrl = TextEditingController();
    final branchCtrl = TextEditingController();
    final tokenCtrl = TextEditingController();
    String selectedCat = 'Dashboard';
    String selectedDiff = 'Intermediate';
    const thumbnailUrl =
        'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=600';
    final selectedTech = <String>['Flutter', 'Dart', 'Glassmorphism'];
    GitRepositoryInfo? repositoryInfo;
    List<GitTreeEntry> previewTree = [];
    bool checkingRepository = false;
    bool publishing = false;
    String? repositoryError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setSheetState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.88,
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0E14).withOpacity(0.96),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(LucideIcons.folderPlus,
                              color: Color(0xFF54C5F8), size: 22),
                          SizedBox(width: 8),
                          Text('Upload / Import Project',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x,
                            color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Project Title
                        const Text('Project Title',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12.5)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleCtrl,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. NeoDesk Glass AI Dashboard',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        const Text('Description',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12.5)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText:
                                'Describe key capabilities, architecture, and live features...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Category & Difficulty Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Category',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedCat,
                                        dropdownColor: const Color(0xFF14151C),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 13),
                                        isExpanded: true,
                                        items: [
                                          'Dashboard',
                                          'Productivity Tools',
                                          'E-Commerce',
                                          'Education',
                                          'Portfolio',
                                          'Social Media'
                                        ]
                                            .map((c) => DropdownMenuItem(
                                                value: c, child: Text(c)))
                                            .toList(),
                                        onChanged: (v) => setSheetState(
                                            () => selectedCat = v!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Difficulty',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedDiff,
                                        dropdownColor: const Color(0xFF14151C),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 13),
                                        isExpanded: true,
                                        items: [
                                          'Beginner',
                                          'Intermediate',
                                          'Advanced'
                                        ]
                                            .map((d) => DropdownMenuItem(
                                                value: d, child: Text(d)))
                                            .toList(),
                                        onChanged: (v) => setSheetState(
                                            () => selectedDiff = v!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // GitHub repository source
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GitHub repository',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Only repository metadata is saved in Supabase. Source files stay in GitHub.',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 11.5),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: gitUrlCtrl,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12.5),
                                decoration: InputDecoration(
                                  hintText:
                                      'https://github.com/owner/repository',
                                  hintStyle:
                                      const TextStyle(color: Colors.white38),
                                  prefixIcon: const Icon(LucideIcons.gitBranch,
                                      color: Colors.white60, size: 16),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.04),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: branchCtrl,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12.5),
                                      decoration: InputDecoration(
                                        hintText: 'Branch (auto-detected)',
                                        hintStyle: const TextStyle(
                                            color: Colors.white38),
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.04),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SpringButton(
                                    onTap: checkingRepository
                                        ? null
                                        : () async {
                                            setSheetState(() {
                                              checkingRepository = true;
                                              repositoryError = null;
                                            });
                                            try {
                                              if (tokenCtrl.text
                                                  .trim()
                                                  .isNotEmpty) {
                                                GithubWorkspaceService
                                                    .setSessionToken(
                                                        tokenCtrl.text);
                                              }
                                              final info =
                                                  await GithubWorkspaceService
                                                      .inspectRepository(
                                                          gitUrlCtrl.text);
                                              final branch =
                                                  branchCtrl.text.trim().isEmpty
                                                      ? info.defaultBranch
                                                      : branchCtrl.text.trim();
                                              final tree =
                                                  await GithubWorkspaceService
                                                      .fetchTree(
                                                owner: info.owner,
                                                repo: info.name,
                                                branch: branch,
                                              );
                                              if (!modalCtx.mounted) return;
                                              setSheetState(() {
                                                repositoryInfo = info;
                                                previewTree = tree;
                                                branchCtrl.text = branch;
                                                if (titleCtrl.text
                                                    .trim()
                                                    .isEmpty) {
                                                  titleCtrl.text = info.name;
                                                }
                                                if (descCtrl.text
                                                        .trim()
                                                        .isEmpty &&
                                                    info.description != null) {
                                                  descCtrl.text =
                                                      info.description!;
                                                }
                                              });
                                            } catch (error) {
                                              if (modalCtx.mounted) {
                                                setSheetState(() =>
                                                    repositoryError = error
                                                        .toString()
                                                        .replaceFirst(
                                                            'Bad state: ', ''));
                                              }
                                            } finally {
                                              if (modalCtx.mounted) {
                                                setSheetState(() =>
                                                    checkingRepository = false);
                                              }
                                            }
                                          },
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1D4ED8)
                                            .withOpacity(0.75),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: checkingRepository
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white),
                                            )
                                          : const Text('Preview tree',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: tokenCtrl,
                                obscureText: true,
                                enableSuggestions: false,
                                autocorrect: false,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12.5),
                                decoration: InputDecoration(
                                  hintText: GithubWorkspaceService
                                          .hasWriteCredential
                                      ? 'GitHub credential available for this session'
                                      : 'Fine-grained GitHub token (session only; required for private/push)',
                                  hintStyle:
                                      const TextStyle(color: Colors.white38),
                                  prefixIcon: const Icon(
                                      LucideIcons.lockKeyhole,
                                      color: Colors.white60,
                                      size: 16),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.04),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              if (repositoryError != null) ...[
                                const SizedBox(height: 8),
                                Text(repositoryError!,
                                    style: const TextStyle(
                                        color: Color(0xFFF87171),
                                        fontSize: 11.5)),
                              ],
                              if (repositoryInfo != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.checkCircle2,
                                        size: 15, color: Color(0xFF10B981)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${repositoryInfo!.owner}/${repositoryInfo!.name} • ${previewTree.length} entries',
                                        style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  constraints:
                                      const BoxConstraints(maxHeight: 190),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF09090B),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: ListView(
                                    shrinkWrap: true,
                                    children:
                                        previewTree.take(100).map((entry) {
                                      final depth =
                                          '/'.allMatches(entry.path).length;
                                      return Padding(
                                        padding: EdgeInsets.fromLTRB(
                                            10 + depth * 12.0, 5, 8, 5),
                                        child: Row(
                                          children: [
                                            Icon(
                                              entry.isDirectory
                                                  ? LucideIcons.folder
                                                  : LucideIcons.fileCode,
                                              size: 13,
                                              color: entry.isDirectory
                                                  ? const Color(0xFFFBBF24)
                                                  : Colors.white54,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                entry.path.split('/').last,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 11.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Link repository button
                  SpringButton(
                    onTap: publishing || repositoryInfo == null
                        ? null
                        : () async {
                            setSheetState(() => publishing = true);
                            try {
                              if (tokenCtrl.text.trim().isNotEmpty) {
                                GithubWorkspaceService.setSessionToken(
                                    tokenCtrl.text);
                              }
                              final info = repositoryInfo!;
                              final title = titleCtrl.text.trim().isNotEmpty
                                  ? titleCtrl.text.trim()
                                  : info.name;
                              final desc = descCtrl.text.trim().isNotEmpty
                                  ? descCtrl.text.trim()
                                  : 'Live GitHub repository ${info.owner}/${info.name}';
                              final row = await SupabaseDataService
                                  .linkGitHubWorkspaceProject(
                                projectName: title,
                                description: desc,
                                repoUrl: info.url,
                                branch: branchCtrl.text.trim(),
                                owner: info.owner,
                                repoName: info.name,
                              );
                              final newProject = Project(
                                id: row['id'].toString(),
                                title: title,
                                category: selectedCat,
                                difficulty: selectedDiff,
                                description: desc,
                                features: const [
                                  'Live GitHub file tree',
                                  'On-demand workspace loading',
                                  'Push commits to GitHub'
                                ],
                                techStack: selectedTech,
                                estimatedTime: 'Live repository',
                                thumbnailUrl: thumbnailUrl,
                                htmlTemplate: '',
                                cssTemplate: '',
                                jsTemplate: '',
                                isFeatured: true,
                                gitRepoUrl: info.url,
                                gitBranch: branchCtrl.text.trim(),
                                gitOwner: info.owner,
                                gitRepoName: info.name,
                              );
                              if (!mounted) return;
                              setState(() {
                                _linkedProjects.removeWhere(
                                    (project) => project.id == newProject.id);
                                _linkedProjects.insert(0, newProject);
                                _syncProjectsToWorkspace([newProject]);
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              MorphingCapsule.show(
                                context,
                                icon: LucideIcons.checkCheck,
                                label: 'GitHub repository linked',
                                color: const Color(0xFF54C5F8),
                              );
                            } catch (error) {
                              if (modalCtx.mounted) {
                                setSheetState(() {
                                  repositoryError = error
                                      .toString()
                                      .replaceFirst('Bad state: ', '');
                                  publishing = false;
                                });
                              }
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF54C5F8), Color(0xFF2563EB)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF54C5F8).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: publishing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Link GitHub Repository',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold)),
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

  Widget _buildFiltersBar(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    // Search input capsule
    final searchField = Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 16, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchTerm = val;
                });
              },
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
              ),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search projects, templates, or tags...',
                hintStyle: TextStyle(
                  color: Colors.white54,
                  fontSize: 13.5,
                ),
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (_searchTerm.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchController.clear();
                  _searchTerm = '';
                });
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
                child: const Icon(LucideIcons.x,
                    size: 12, color: Color(0xFFD1D5DB)),
              ),
            )
          else
            const Icon(LucideIcons.xCircle, size: 14, color: Color(0xFF4B5563)),
        ],
      ),
    );

    // Categories capsule dropdown
    final categoryDropdown = _buildCapsulePopup(
      icon: LucideIcons.layoutGrid,
      label: _selectedCategory == 'All' ? 'All Categories' : _selectedCategory,
      items: _categories,
      selectedItem: _selectedCategory,
      onSelected: (cat) => setState(() => _selectedCategory = cat),
    );

    // Difficulties capsule dropdown
    final difficultyDropdown = _buildCapsulePopup(
      icon: LucideIcons.slidersHorizontal,
      label: _selectedDifficulty == 'All'
          ? 'All Difficulties'
          : _selectedDifficulty,
      items: _difficulties,
      selectedItem: _selectedDifficulty,
      onSelected: (diff) => setState(() => _selectedDifficulty = diff),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: searchField),
          const SizedBox(width: 14),
          categoryDropdown,
          const SizedBox(width: 12),
          difficultyDropdown,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: categoryDropdown),
              const SizedBox(width: 10),
              Expanded(child: difficultyDropdown),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildCapsulePopup({
    required IconData icon,
    required String label,
    required List<String> items,
    required String selectedItem,
    required ValueChanged<String> onSelected,
  }) {
    return PopupMenuButton<String>(
      tooltip: '',
      color: const Color(0xFF16171E),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      offset: const Offset(0, 50),
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map((item) {
          final isCurrent = item == selectedItem;
          final displayText = item == 'All'
              ? (label.contains('Categories')
                  ? 'All Categories'
                  : 'All Difficulties')
              : item;

          return PopupMenuItem<String>(
            value: item,
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayText,
                  style: TextStyle(
                    color: isCurrent ? Colors.white : const Color(0xFF9CA3AF),
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                if (isCurrent)
                  const Icon(
                    LucideIcons.check,
                    color: Color(0xFF38BDF8),
                    size: 15,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131418),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFFD1D5DB)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE5E7EB),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              LucideIcons.chevronDown,
              size: 13,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.folderSearch,
            size: 56,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Projects Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search query or filter tags.',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          SpringButton(
            onTap: () {
              setState(() {
                _searchController.clear();
                _searchTerm = '';
                _selectedCategory = 'All';
                _selectedDifficulty = 'All';
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Text(
                'Reset Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProjectDetails(BuildContext context, Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(
          project: project,
          onOpenInWorkspace: widget.onOpenProjectInWorkspace,
        ),
      ),
    );
    return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          backgroundColor: const Color(0xFF131418),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 20, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x,
                    color: Color(0xFF9CA3AF), size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Difficulty & Category pills
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          project.category,
                          style: const TextStyle(
                            color: Color(0xFFE5E7EB),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          project.difficulty,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(LucideIcons.clock,
                              size: 12, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 4),
                          Text(
                            project.estimatedTime,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Description
                  const Text(
                    'About the Project',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    project.description,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Features Checklist
                  const Text(
                    'Key Features',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...project.features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(LucideIcons.check,
                                size: 14, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // Tech Stack tags
                  const Text(
                    'Technologies',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: project.techStack.map((tech) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          tech,
                          style: const TextStyle(
                            color: Color(0xFFD1D5DB),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ),
            SpringButton(
              onTap: () {
                Navigator.pop(context);
                widget.onOpenProjectInWorkspace(project.id);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(LucideIcons.code, size: 15, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Open in Workspace',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGitHubProjectDetails(Project project) async {
    final treeFuture = GithubWorkspaceService.fetchTree(
      owner: project.gitOwner!,
      repo: project.gitRepoName!,
      branch: project.gitBranch ?? 'main',
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF111318),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.14)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.folderGit2,
                        color: Color(0xFF54C5F8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(project.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          Text(
                            '${project.gitOwner}/${project.gitRepoName} • ${project.gitBranch}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(LucideIcons.x, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Live repository tree',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Expanded(
                  child: FutureBuilder<List<GitTreeEntry>>(
                    future: treeFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF54C5F8)));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            snapshot.error
                                .toString()
                                .replaceFirst('Bad state: ', ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFF87171)),
                          ),
                        );
                      }
                      final entries = snapshot.data ?? const [];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF09090B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: ListView.builder(
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final depth = '/'.allMatches(entry.path).length;
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                  12 + depth * 14.0, 6, 10, 6),
                              child: Row(
                                children: [
                                  Icon(
                                    entry.isDirectory
                                        ? LucideIcons.folder
                                        : LucideIcons.fileCode,
                                    size: 14,
                                    color: entry.isDirectory
                                        ? const Color(0xFFFBBF24)
                                        : Colors.white54,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      entry.path.split('/').last,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                SpringButton(
                  onTap: () {
                    Navigator.pop(dialogContext);
                    widget.onOpenProjectInWorkspace(project.id);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF54C5F8), Color(0xFF2563EB)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Load Project in Workspace',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
