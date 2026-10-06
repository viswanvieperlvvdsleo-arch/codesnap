import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/project.dart';
import '../utils/mock_data.dart';
import '../widgets/project_card.dart';
import '../widgets/spring_button.dart';
import '../services/storage_picker.dart';
import '../widgets/morphing_capsule.dart';
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Project> get _filteredProjects {
    return MockData.mockProjects.where((project) {
      final matchesSearch = _searchTerm.isEmpty ||
          project.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          project.description.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          project.category.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          project.techStack.any((t) => t.toLowerCase().contains(_searchTerm.toLowerCase()));

      final matchesCategory = _selectedCategory == 'All' || project.category == _selectedCategory;
      final matchesDifficulty = _selectedDifficulty == 'All' || project.difficulty == _selectedDifficulty;

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
                  child: filteredList.isEmpty
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
    String selectedCat = 'Dashboard';
    String selectedDiff = 'Intermediate';
    PickedMediaResult? pickedFile;
    const thumbnailUrl = 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=600';
    final selectedTech = <String>['Flutter', 'Dart', 'Glassmorphism'];

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
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0E14).withOpacity(0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
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
                      Row(
                        children: const [
                          Icon(LucideIcons.folderPlus, color: Color(0xFF54C5F8), size: 22),
                          SizedBox(width: 8),
                          Text('Upload / Import Project', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
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
                        const Text('Project Title', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. NeoDesk Glass AI Dashboard',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        const Text('Description', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Describe key capabilities, architecture, and live features...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                  const Text('Category', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedCat,
                                        dropdownColor: const Color(0xFF14151C),
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        isExpanded: true,
                                        items: ['Dashboard', 'Productivity Tools', 'E-Commerce', 'Education', 'Portfolio', 'Social Media']
                                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                            .toList(),
                                        onChanged: (v) => setSheetState(() => selectedCat = v!),
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
                                  const Text('Difficulty', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedDiff,
                                        dropdownColor: const Color(0xFF14151C),
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        isExpanded: true,
                                        items: ['Beginner', 'Intermediate', 'Advanced']
                                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                            .toList(),
                                        onChanged: (v) => setSheetState(() => selectedDiff = v!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Upload Source / Document
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Package / Archive (.zip / code)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  SpringButton(
                                    onTap: () async {
                                      final pick = await getStoragePicker().pickDocument();
                                      if (pick != null) {
                                        setSheetState(() => pickedFile = pick);
                                      }
                                    },
                                    child: Row(
                                      children: const [
                                        Icon(LucideIcons.fileCode, color: Color(0xFF54C5F8), size: 14),
                                        SizedBox(width: 4),
                                        Text('Choose File', style: TextStyle(color: Color(0xFF54C5F8), fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (pickedFile != null) ...[
                                const SizedBox(height: 8),
                                Text('Attached: ${pickedFile!.fileName} (${pickedFile!.formattedSize})',
                                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                              const SizedBox(height: 8),
                              TextField(
                                controller: gitUrlCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                decoration: InputDecoration(
                                  hintText: 'Or paste GitHub / Git repository URL',
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  prefixIcon: const Icon(LucideIcons.gitBranch, color: Colors.white60, size: 16),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.04),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Publish Project Button
                  SpringButton(
                    onTap: () {
                      final title = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'New Custom Project';
                      final desc = descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : 'Interactive production-ready template with reactive components.';
                      final newProj = Project(
                        id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        category: selectedCat,
                        difficulty: selectedDiff,
                        description: desc,
                        features: [
                          'Modular state architecture and responsive fluid layouts',
                          'Dark liquid glass theme with real-time blur shaders',
                          'Full source files with test suites ready to deploy',
                        ],
                        techStack: selectedTech,
                        estimatedTime: '3-4 hours',
                        thumbnailUrl: thumbnailUrl,
                        htmlTemplate: '<div class="glass-app"><h1>$title</h1></div>',
                        cssTemplate: 'body { background: #09090b; color: white; }',
                        jsTemplate: 'console.log("$title loaded successfully");',
                        isFeatured: true,
                      );

                      setState(() {
                        MockData.mockProjects.insert(0, newProj);
                      });

                      Navigator.pop(ctx);
                      MorphingCapsule.show(
                        context,
                        icon: LucideIcons.checkCheck,
                        label: 'Project published to library!',
                        color: const Color(0xFF54C5F8),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF54C5F8), Color(0xFF2563EB)]),
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
                      child: const Text('Publish Project', style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold)),
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
                child: const Icon(LucideIcons.x, size: 12, color: Color(0xFFD1D5DB)),
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
      label: _selectedDifficulty == 'All' ? 'All Difficulties' : _selectedDifficulty,
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
          final displayText = item == 'All' ? (label.contains('Categories') ? 'All Categories' : 'All Difficulties') : item;

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
                icon: const Icon(LucideIcons.x, color: Color(0xFF9CA3AF), size: 18),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                          const Icon(LucideIcons.clock, size: 12, color: Color(0xFF9CA3AF)),
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
                            child: Icon(LucideIcons.check, size: 14, color: Color(0xFF10B981)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
}
