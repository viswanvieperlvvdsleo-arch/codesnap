import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/spring_button.dart';

class MediaItem {
  final String id;
  final String title;
  final String url;
  final bool isVideo;
  final String? videoDuration;
  final String dateGroup;
  final String subtitle;

  const MediaItem({
    required this.id,
    required this.title,
    required this.url,
    this.isVideo = false,
    this.videoDuration,
    required this.dateGroup,
    required this.subtitle,
  });
}

class DocItem {
  final String id;
  final String name;
  final String extension;
  final String size;
  final String date;
  final Color badgeColor;

  const DocItem({
    required this.id,
    required this.name,
    required this.extension,
    required this.size,
    required this.date,
    required this.badgeColor,
  });
}

class LinkItem {
  final String id;
  final String title;
  final String url;
  final String description;
  final IconData icon;

  const LinkItem({
    required this.id,
    required this.title,
    required this.url,
    required this.description,
    required this.icon,
  });
}

class MediaLinksDocsScreen extends StatefulWidget {
  final String contactName;
  final List<MediaItem>? customMediaItems;
  final List<DocItem>? customDocItems;
  final List<LinkItem>? customLinkItems;

  const MediaLinksDocsScreen({
    super.key,
    this.contactName = 'Alex Rivers',
    this.customMediaItems,
    this.customDocItems,
    this.customLinkItems,
  });

  @override
  State<MediaLinksDocsScreen> createState() => _MediaLinksDocsScreenState();
}

class _MediaLinksDocsScreenState extends State<MediaLinksDocsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<MediaItem> _defaultMediaItems = [
    MediaItem(
      id: 'm1',
      title: 'Chat Attachment: Terminal Run Screenshot',
      url: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=600&auto=format&fit=crop&q=80',
      isVideo: true,
      videoDuration: '0:06',
      dateGroup: 'THIS MONTH',
      subtitle: 'Sent in chat • Sep 26',
    ),
    MediaItem(
      id: 'm2',
      title: 'Chat Attachment: Glass Theme Mockup',
      url: 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=600&auto=format&fit=crop&q=80',
      isVideo: false,
      dateGroup: 'THIS MONTH',
      subtitle: 'Sent in chat • Sep 24',
    ),
    MediaItem(
      id: 'm3',
      title: 'Chat Screen Recording: Zero-Cost Terminal',
      url: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop&q=80',
      isVideo: true,
      videoDuration: '9:02',
      dateGroup: 'THIS MONTH',
      subtitle: 'Sent in chat • Sep 20',
    ),
    MediaItem(
      id: 'm4',
      title: 'Chat Attachment: Architecture Whiteboard',
      url: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=600&auto=format&fit=crop&q=80',
      isVideo: false,
      dateGroup: 'THIS MONTH',
      subtitle: 'Sent in chat • Sep 18',
    ),
    MediaItem(
      id: 'm5',
      title: 'Chat Attachment: Code Review Clip',
      url: 'https://images.unsplash.com/photo-1534972195531-a756b1126f24?w=600&auto=format&fit=crop&q=80',
      isVideo: true,
      videoDuration: '1:45',
      dateGroup: 'THIS MONTH',
      subtitle: 'Sent in chat • Sep 15',
    ),
    MediaItem(
      id: 'm6',
      title: 'Chat Attachment: Custom Typography Preview',
      url: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&auto=format&fit=crop&q=80',
      isVideo: false,
      dateGroup: 'THIS MONTH',
      subtitle: 'Sent in chat • Sep 10',
    ),
    MediaItem(
      id: 'm7',
      title: 'Cloud Workspace Socket Sync',
      url: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=600&auto=format&fit=crop&q=80',
      isVideo: true,
      videoDuration: '3:18',
      dateGroup: 'AUGUST',
      subtitle: 'Websocket handshake protocol test',
    ),
    MediaItem(
      id: 'm8',
      title: 'File Explorer Tree View',
      url: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=600&auto=format&fit=crop&q=80',
      isVideo: false,
      dateGroup: 'AUGUST',
      subtitle: 'Virtual tree virtualized scroll test',
    ),
  ];

  static const List<DocItem> _defaultDocItems = [
    DocItem(
      id: 'd1',
      name: 'cloudsnap_kernel_runner.dart',
      extension: 'DART',
      size: '28.4 KB',
      date: 'Sep 26, 2026',
      badgeColor: Color(0xFF54C5F8),
    ),
    DocItem(
      id: 'd2',
      name: 'arena_voting_smart_contract.sol',
      extension: 'SOL',
      size: '14.2 KB',
      date: 'Sep 24, 2026',
      badgeColor: Color(0xFFB388FF),
    ),
    DocItem(
      id: 'd3',
      name: 'mobile_ide_specifications_v4.pdf',
      extension: 'PDF',
      size: '3.8 MB',
      date: 'Sep 20, 2026',
      badgeColor: Color(0xFFFF5252),
    ),
    DocItem(
      id: 'd4',
      name: 'terminal_ansi_colors_theme.json',
      extension: 'JSON',
      size: '6.1 KB',
      date: 'Sep 18, 2026',
      badgeColor: Color(0xFFFFD700),
    ),
    DocItem(
      id: 'd5',
      name: 'docker-compose.sandbox.yml',
      extension: 'YML',
      size: '4.7 KB',
      date: 'Aug 30, 2026',
      badgeColor: Color(0xFF69F0AE),
    ),
  ];

  static const List<LinkItem> _defaultLinkItems = [
    LinkItem(
      id: 'l1',
      title: 'codesnap / core-engine',
      url: 'https://github.com/codesnap/core-engine',
      description: 'Distributed workspace runner and terminal protocol engine.',
      icon: LucideIcons.code2,
    ),
    LinkItem(
      id: 'l2',
      title: 'Flutter Desktop & Mobile Embedder',
      url: 'https://docs.flutter.dev/platform-integration',
      description: 'Native C++ bridge for low-latency shell rendering.',
      icon: LucideIcons.globe,
    ),
    LinkItem(
      id: 'l3',
      title: 'CodeSnap Arena Hackathon Rulebook',
      url: 'https://codesnap.dev/arena/rules-2026',
      description: 'Terms of participation, submission requirements and judging rubrics.',
      icon: LucideIcons.trophy,
    ),
    LinkItem(
      id: 'l4',
      title: 'Bug AI Model Context Protocol Specs',
      url: 'https://spec.modelcontextprotocol.io',
      description: 'Standard protocol for external AI agent tools.',
      icon: LucideIcons.bot,
    ),
  ];

  late List<MediaItem> _mediaItems;
  late List<DocItem> _docItems;
  late List<LinkItem> _linkItems;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _mediaItems = widget.customMediaItems != null && widget.customMediaItems!.isNotEmpty
        ? widget.customMediaItems!
        : _defaultMediaItems;
    _docItems = widget.customDocItems != null && widget.customDocItems!.isNotEmpty
        ? widget.customDocItems!
        : _defaultDocItems;
    _linkItems = widget.customLinkItems != null && widget.customLinkItems!.isNotEmpty
        ? widget.customLinkItems!
        : _defaultLinkItems;
  }

  Widget _buildSafeImage(String url, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (url.startsWith('data:image')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(bytes, fit: fit, width: width, height: height);
      } catch (_) {}
    }
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => Container(
        height: height ?? 260,
        color: Colors.white.withOpacity(0.05),
        child: const Center(
          child: Icon(LucideIcons.image, size: 48, color: Colors.white38),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMediaPreview(MediaItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0D14).withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SpringButton(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: const Icon(LucideIcons.x, size: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Image / Video preview container
                    Flexible(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildSafeImage(
                            item.url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                          if (item.isVideo)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.65),
                                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                              ),
                              child: const Icon(LucideIcons.play, size: 36, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                    // Bottom actions bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildModalAction(LucideIcons.share2, 'Share', () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Media link ready to share')),
                            );
                          }),
                          _buildModalAction(LucideIcons.download, 'Save', () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Saved to device gallery')),
                            );
                          }),
                          _buildModalAction(LucideIcons.code, 'Use in IDE', () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Inserted asset into Workspace assets/')),
                            );
                          }),
                        ],
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
  }

  Widget _buildModalAction(IconData icon, String label, VoidCallback onTap) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0C0D14).withOpacity(0.85),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          SpringButton(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.06),
                              ),
                              child: const Icon(LucideIcons.chevronLeft, size: 22, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Media, links and docs',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.contactName,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SpringButton(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Search filter active')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.06),
                              ),
                              child: const Icon(LucideIcons.search, size: 20, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tabs
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF54C5F8),
                      indicatorWeight: 2.5,
                      labelColor: const Color(0xFF54C5F8),
                      unselectedLabelColor: Colors.white.withOpacity(0.6),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Media'),
                        Tab(text: 'Docs'),
                        Tab(text: 'Links'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMediaTab(),
          _buildDocsTab(),
          _buildLinksTab(),
        ],
      ),
    );
  }

  // 1. Media Tab (Grouped by THIS MONTH, AUGUST, etc. with video timestamp badges)
  Widget _buildMediaTab() {
    final groups = ['THIS MONTH', 'AUGUST'];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final items = _mediaItems.where((m) => m.dateGroup == group).toList();

        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
              child: Text(
                group,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, gIndex) {
                final item = items[gIndex];
                return SpringButton(
                  onTap: () => _showMediaPreview(item),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildSafeImage(
                          item.url,
                          fit: BoxFit.cover,
                        ),
                        // Dark glass gradient overlay for readability
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Video Badge
                        if (item.isVideo)
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.play, size: 10, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.videoDuration ?? '0:00',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
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
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // 2. Docs Tab (Extension badges, file size, download/inspect actions)
  Widget _buildDocsTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      itemCount: _docItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final doc = _docItems[index];
        return SpringButton(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening ${doc.name} in Workspace Editor')),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0D14).withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                // Extension badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: doc.badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: doc.badgeColor.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      doc.extension,
                      style: TextStyle(
                        color: doc.badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            doc.size,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(color: Colors.white.withOpacity(0.4)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            doc.date,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.download, size: 18, color: Colors.white70),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading ${doc.name}...')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. Links Tab (Rich link preview cards with copy/open)
  Widget _buildLinksTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      itemCount: _linkItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final link = _linkItems[index];
        return SpringButton(
          onTap: () {
            Clipboard.setData(ClipboardData(text: link.url));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied link: ${link.url}')),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0D14).withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF54C5F8).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.3)),
                  ),
                  child: Icon(link.icon, size: 22, color: const Color(0xFF54C5F8)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        link.url,
                        style: const TextStyle(
                          color: Color(0xFF54C5F8),
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        link.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.copy, size: 16, color: Colors.white70),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
