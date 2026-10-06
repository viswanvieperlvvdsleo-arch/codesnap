import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/spring_button.dart';
import '../services/storage_picker.dart';
import 'contact_info_screen.dart';
import 'chat_screen.dart';
import '../widgets/full_screen_media_viewer.dart';

/// ─── Individual Chat Screen (Dedicated Page / Route) ────────────────────────
/// Opened as a separate Navigator route on mobile/normal view so pressing the back
/// button cleanly pops back to the contacts list and never exits the application.
/// In desktop expand mode, can also be embedded directly in the right panel.
class IndividualChatScreen extends StatefulWidget {
  final ChatConversation conversation;
  final ChatWallpaperConfig defaultWallpaper;
  final List<ChatConversation> allConversations;
  final ValueChanged<ChatWallpaperConfig?>? onWallpaperUpdated;
  final VoidCallback? onBack;
  final bool isEmbedded;

  const IndividualChatScreen({
    super.key,
    required this.conversation,
    required this.defaultWallpaper,
    required this.allConversations,
    this.onWallpaperUpdated,
    this.onBack,
    this.isEmbedded = false,
  });

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _messagesScrollCtrl = ScrollController();
  ChatMessage? _replyingToMessage;
  bool _isTyping = false;

  // Multi-Select Mode
  bool _isMultiSelectMode = false;
  final Set<String> _selectedMessageIds = {};

  // Inline Contact Info Panel (stays same small size when not expanded)
  bool _showingContactInfo = false;

  // Search in chat
  bool _isSearching = false;
  final TextEditingController _chatSearchCtrl = TextEditingController();
  final List<int> _matchedMessageIndices = [];
  int _currentSearchMatchIndex = 0;
  String? _highlightedMessageId;

  late String _currentAiModel;

  @override
  void initState() {
    super.initState();
    _currentAiModel = widget.conversation.activeModel ?? 'Claude 3.5 Sonnet';
    widget.conversation.unreadCount = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatStateStore.instance.notifyConversationsUpdated();
    });
    _msgCtrl.addListener(() {
      final isNowTyping = _msgCtrl.text.trim().isNotEmpty;
      if (isNowTyping != _isTyping) {
        setState(() => _isTyping = isNowTyping);
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _messagesScrollCtrl.dispose();
    _chatSearchCtrl.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_isSearching) {
      _closeChatSearch();
      return;
    }
    if (_showingContactInfo) {
      setState(() => _showingContactInfo = false);
      return;
    }
    if (_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = false;
        _selectedMessageIds.clear();
      });
      return;
    }
    ChatStateStore.instance.selectConversation(null);
    ChatStateStore.instance.notifyConversationsUpdated();
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _performChatSearch(String query) {
    _matchedMessageIndices.clear();
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      for (int i = 0; i < widget.conversation.messages.length; i++) {
        final m = widget.conversation.messages[i];
        if (m.text.toLowerCase().contains(q) ||
            (m.mediaCaption != null && m.mediaCaption!.toLowerCase().contains(q))) {
          _matchedMessageIndices.add(i);
        }
      }
    }
    if (_matchedMessageIndices.isNotEmpty) {
      _currentSearchMatchIndex = 0;
      _jumpToSearchMatch(_currentSearchMatchIndex);
    } else {
      setState(() {
        _highlightedMessageId = null;
      });
    }
  }

  void _nextSearchMatch() {
    if (_matchedMessageIndices.isEmpty) return;
    setState(() {
      _currentSearchMatchIndex = (_currentSearchMatchIndex + 1) % _matchedMessageIndices.length;
    });
    _jumpToSearchMatch(_currentSearchMatchIndex);
  }

  void _prevSearchMatch() {
    if (_matchedMessageIndices.isEmpty) return;
    setState(() {
      _currentSearchMatchIndex = (_currentSearchMatchIndex - 1 + _matchedMessageIndices.length) % _matchedMessageIndices.length;
    });
    _jumpToSearchMatch(_currentSearchMatchIndex);
  }

  void _jumpToSearchMatch(int matchIdx) {
    if (matchIdx < 0 || matchIdx >= _matchedMessageIndices.length) return;
    final msgIdx = _matchedMessageIndices[matchIdx];
    final targetMsg = widget.conversation.messages[msgIdx];
    setState(() {
      _highlightedMessageId = targetMsg.id;
    });

    if (_messagesScrollCtrl.hasClients) {
      final double targetOffset = (msgIdx * 90.0).clamp(0.0, _messagesScrollCtrl.position.maxScrollExtent);
      _messagesScrollCtrl.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _closeChatSearch() {
    setState(() {
      _isSearching = false;
      _chatSearchCtrl.clear();
      _matchedMessageIndices.clear();
      _highlightedMessageId = null;
    });
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      widget.conversation.messages.add(
        ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          isMe: true,
          time: timeStr,
          replyingTo: _replyingToMessage,
          isDelivered: true,
        ),
      );
      widget.conversation.lastMessage = text;
      widget.conversation.time = timeStr;
      _replyingToMessage = null;
      _msgCtrl.clear();
    });

    final store = ChatStateStore.instance;
    store.conversations.removeWhere((c) => c.id == widget.conversation.id);
    store.conversations.insert(0, widget.conversation);
    store.notifyConversationsUpdated();

    _scrollToBottom();

    if (widget.conversation.isAiAssistant || widget.conversation.id == 'server_terminal_ai') {
      _handleAiTerminalResponse(text);
    }
  }

  void _sendMediaMessage({
    required String mediaType,
    required String mediaUrl,
    String? caption,
  }) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final newMsg = ChatMessage(
      id: 'media_${DateTime.now().millisecondsSinceEpoch}',
      text: caption ?? '',
      isMe: true,
      time: timeStr,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      mediaCaption: caption,
      isUploading: true,
      uploadProgress: 0.0,
      isDelivered: false,
    );

    final captionTrim = caption?.trim();
    final previewMsg = captionTrim != null && captionTrim.isNotEmpty
        ? captionTrim
        : (mediaType == 'video' ? '🎥 Video' : '📷 Photo');

    setState(() {
      widget.conversation.messages.add(newMsg);
      widget.conversation.lastMessage = previewMsg;
      widget.conversation.time = timeStr;
    });

    final store = ChatStateStore.instance;
    store.conversations.removeWhere((c) => c.id == widget.conversation.id);
    store.conversations.insert(0, widget.conversation);
    store.notifyConversationsUpdated();

    _scrollToBottom();

    // Simulate smooth upload progress
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => newMsg.uploadProgress = 0.4);
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => newMsg.uploadProgress = 0.8);
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        newMsg.uploadProgress = 1.0;
        newMsg.isUploading = false;
        newMsg.isDelivered = true;
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messagesScrollCtrl.hasClients) {
        _messagesScrollCtrl.animateTo(
          _messagesScrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  // ── Single Emoji Reaction Logic (One reaction per message) ────────────────
  void _toggleEmojiReaction(ChatMessage msg, String emoji) {
    setState(() {
      if (msg.reactions.contains(emoji)) {
        msg.reactions.remove(emoji);
      } else {
        msg.reactions = [emoji];
      }
    });
  }

  void _navigateToContactInfo() {
    setState(() => _showingContactInfo = true);
  }

  @override
  Widget build(BuildContext context) {
    final wallpaper = widget.conversation.customWallpaper ?? widget.defaultWallpaper;

    if (_showingContactInfo) {
      return ContactInfoScreen(
        contactName: widget.conversation.name,
        contactAvatar: widget.conversation.avatarUrl,
        contactHandle: '@${widget.conversation.name.toLowerCase().replaceAll(' ', '_')}',
        isOnline: widget.conversation.isOnline,
        wallpaper: wallpaper,
        onBack: () => setState(() => _showingContactInfo = false),
      );
    }

    return PopScope(
      canPop: !_showingContactInfo && !_isMultiSelectMode && !widget.isEmbedded && Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF07080A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Live Wallpaper Background for this specific chat
            buildWallpaperBackground(wallpaper),

            SafeArea(
              top: !widget.isEmbedded,
              bottom: false,
              child: Column(
                children: [
                  // Top Bar
                  if (_isSearching)
                    _buildSearchTopBar()
                  else if (_isMultiSelectMode)
                    _buildMultiSelectTopBar()
                  else ...[
                    _buildNormalTopBar(),
                    if (widget.conversation.isAiAssistant || widget.conversation.id == 'server_terminal_ai')
                      _buildServerTerminalBar(),
                  ],

                  // Message Stream with "Today" capsule (safely at index 0)
                  Expanded(
                    child: ListView.builder(
                      controller: _messagesScrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: widget.conversation.messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withOpacity(0.18)),
                              ),
                              child: Text(
                                'Today',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }

                        final msg = widget.conversation.messages[index - 1];
                        return _buildMessageBubbleRow(msg);
                      },
                    ),
                  ),

                  // Replying banner preview (if active)
                  if (_replyingToMessage != null) _buildReplyingBanner(),

                  // Bottom Input Pill
                  _buildBottomInputBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Normal Top Bar (Liquid Glass Transparent, Zero Blur) ──────────────────
  Widget _buildNormalTopBar() {
    final c = widget.conversation;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.20), width: 1.2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.18),
              Colors.white.withOpacity(0.06),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SpringButton(
              onTap: _handleBack,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(LucideIcons.chevronLeft, size: 22, color: Colors.white),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SpringButton(
                onTap: _navigateToContactInfo,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundImage: NetworkImage(c.avatarUrl),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'last seen today at 23:18',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            SpringButton(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Starting video call with ${c.name}...')),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Icon(LucideIcons.video, size: 19, color: Colors.white),
              ),
            ),
            SpringButton(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Starting voice call with ${c.name}...')),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Icon(LucideIcons.phone, size: 19, color: Colors.white),
              ),
            ),
            SpringButton(
              onTap: () {
                setState(() => _isSearching = true);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Icon(LucideIcons.search, size: 19, color: Colors.white),
              ),
            ),
            SpringButton(
              onTap: _openThreeDotsMenu,
              child: const Padding(
                padding: EdgeInsets.only(left: 3, right: 3),
                child: Icon(LucideIcons.moreVertical, size: 19, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Remote Server Terminal Bar ─────────────────────────────────────────────
  Widget _buildServerTerminalBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF090A10).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.35), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFF10B981), blurRadius: 6, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TERMINAL BRIDGE · ${widget.conversation.terminalSession ?? "tmux:0 (dev-worker)"}',
                  style: GoogleFonts.firaCode(
                    color: const Color(0xFF10B981),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SpringButton(
                onTap: _showModelPickerSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.bot, size: 12, color: Color(0xFFFFD700)),
                      const SizedBox(width: 5),
                      Text(
                        _currentAiModel,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(LucideIcons.chevronDown, size: 12, color: Color(0xFFFFD700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildQuickTerminalChip('flutter analyze', LucideIcons.terminal),
                _buildQuickTerminalChip('git diff --stat', LucideIcons.gitBranch),
                _buildQuickTerminalChip('flutter test', LucideIcons.play),
                _buildQuickTerminalChip('generate fix', LucideIcons.sparkles),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTerminalChip(String command, IconData icon) {
    return SpringButton(
      onTap: () {
        _msgCtrl.text = command;
        _sendMessage();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: const Color(0xFF54C5F8)),
            const SizedBox(width: 4),
            Text(
              command,
              style: GoogleFonts.firaCode(
                color: Colors.white.withOpacity(0.85),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModelPickerSheet() {
    final models = [
      {'name': 'Claude 3.5 Sonnet', 'badge': 'Anthropic · Deep Logic', 'desc': 'Best for complex coding, architecture, refactoring'},
      {'name': 'GPT-4o', 'badge': 'OpenAI · Multimodal', 'desc': 'High-speed reasoning, versatile coding & bug fixing'},
      {'name': 'Codex', 'badge': 'OpenAI · Code Native', 'desc': 'Specialized code completion and CLI execution'},
      {'name': 'Antigravity', 'badge': 'Google DeepMind · Agentic', 'desc': 'Multi-step autonomous terminal tool execution'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0E17).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
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
              const SizedBox(height: 14),
              const Text(
                'Select Active Terminal Model',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Zero API billing: commands run through your server terminal session',
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11.5),
              ),
              const SizedBox(height: 14),
              ...models.map((m) {
                final isSelected = _currentAiModel == m['name'];
                return SpringButton(
                  onTap: () {
                    setState(() {
                      _currentAiModel = m['name']!;
                      widget.conversation.activeModel = m['name'];
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF161824),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        content: Text('Switched terminal engine to ${m['name']}'),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFD700).withOpacity(0.14) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFFD700).withOpacity(0.65) : Colors.white.withOpacity(0.1),
                        width: isSelected ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                          size: 18,
                          color: isSelected ? const Color(0xFFFFD700) : Colors.white38,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    m['name']!,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      m['badge']!,
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9.5),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                m['desc']!,
                                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAiTerminalResponse(String userText) {
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      String responseText;
      String? snippet;
      String? lang;

      final lower = userText.toLowerCase();
      if (lower.contains('test') || lower.contains('flutter test')) {
        responseText = '[$_currentAiModel via Server Terminal]\nExecuted test suite in tmux session:';
        snippet = '00:03 +14: All tests passed!\n✓ notifications_dismissible_test.dart\n✓ story_wave_bounds_test.dart\n✓ like_toggle_counter_test.dart';
        lang = 'bash';
      } else if (lower.contains('diff') || lower.contains('git')) {
        responseText = '[$_currentAiModel via Server Terminal]\nGit status across modified modules:';
        snippet = 'M  lib/screens/home_feed_screen.dart\nM  lib/screens/notifications_screen.dart\nM  lib/screens/chat_screen.dart\nM  lib/screens/individual_chat_screen.dart\nM  lib/widgets/swipe_action_bar.dart';
        lang = 'bash';
      } else if (lower.contains('analyze') || lower.contains('flutter analyze')) {
        responseText = '[$_currentAiModel via Server Terminal]\nRunning static analysis...';
        snippet = 'Analyzing codesnap...\nNo issues found! (ran in 1.2s)';
        lang = 'bash';
      } else {
        responseText = '[$_currentAiModel via Server Terminal]\nExecuted on remote node. Generated verified patch:';
        snippet = '// Server terminal execution: \$_currentAiModel\nvoid updateWorkspace() {\n  // Code changes ready to apply\n}';
        lang = 'dart';
      }

      setState(() {
        final aiMsg = ChatMessage(
          id: 'ai_resp_\${DateTime.now().millisecondsSinceEpoch}',
          text: responseText,
          isMe: false,
          time: timeStr,
          codeSnippet: snippet,
          codeLang: lang,
          isDelivered: true,
        );
        widget.conversation.messages.add(aiMsg);
        widget.conversation.lastMessage = responseText.split('\n').first;
        widget.conversation.time = timeStr;
      });

      final store = ChatStateStore.instance;
      store.conversations.removeWhere((c) => c.id == widget.conversation.id);
      store.conversations.insert(0, widget.conversation);
      store.notifyConversationsUpdated();
      _scrollToBottom();
    });
  }

  // ── Search Top Bar (Interactive Query Input & Match Counter) ───────────────
  Widget _buildSearchTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.55), width: 1.2),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF54C5F8).withOpacity(0.18),
              Colors.white.withOpacity(0.06),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SpringButton(
              onTap: _closeChatSearch,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(LucideIcons.chevronLeft, size: 22, color: Colors.white),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _chatSearchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                cursorColor: const Color(0xFF54C5F8),
                decoration: InputDecoration(
                  hintText: 'Search word or sentence...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: _performChatSearch,
                onSubmitted: _performChatSearch,
              ),
            ),
            if (_matchedMessageIndices.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF54C5F8).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_currentSearchMatchIndex + 1}/${_matchedMessageIndices.length}',
                  style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 4),
              SpringButton(
                onTap: _prevSearchMatch,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(LucideIcons.chevronUp, size: 18, color: Colors.white),
                ),
              ),
              SpringButton(
                onTap: _nextSearchMatch,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(LucideIcons.chevronDown, size: 18, color: Colors.white),
                ),
              ),
            ],
            SpringButton(
              onTap: _closeChatSearch,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(LucideIcons.x, size: 18, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Multi-Select Action Top Bar ───────────────────────────────────────────
  Widget _buildMultiSelectTopBar() {
    final count = _selectedMessageIds.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.45), width: 1.2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF54C5F8).withOpacity(0.18),
              Colors.white.withOpacity(0.06),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF54C5F8).withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SpringButton(
              onTap: () {
                setState(() {
                  _isMultiSelectMode = false;
                  _selectedMessageIds.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
                child: const Icon(LucideIcons.x, size: 18, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$count selected',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            SpringButton(
              onTap: count > 0 ? _starSelectedMessages : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  LucideIcons.star,
                  size: 19,
                  color: count > 0 ? const Color(0xFFFFD700) : Colors.white24,
                ),
              ),
            ),
            SpringButton(
              onTap: count > 0 ? _copySelectedMessages : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  LucideIcons.copy,
                  size: 19,
                  color: count > 0 ? Colors.white : Colors.white24,
                ),
              ),
            ),
            SpringButton(
              onTap: count > 0 ? _forwardSelectedMessages : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  LucideIcons.forward,
                  size: 19,
                  color: count > 0 ? Colors.white : Colors.white24,
                ),
              ),
            ),
            SpringButton(
              onTap: count > 0 ? _deleteSelectedMessagesPrompt : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  LucideIcons.trash2,
                  size: 19,
                  color: count > 0 ? const Color(0xFFFF5252) : Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Replying Preview Banner ────────────────────────────────────────────────
  Widget _buildReplyingBanner() {
    final msg = _replyingToMessage!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.4)),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF54C5F8).withOpacity(0.18),
              Colors.white.withOpacity(0.06),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF54C5F8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.isMe ? 'You' : widget.conversation.name,
                    style: const TextStyle(
                      color: Color(0xFF54C5F8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    msg.mediaCaption?.isNotEmpty == true
                        ? msg.mediaCaption!
                        : (msg.text.isNotEmpty ? msg.text : 'Media attachment'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            SpringButton(
              onTap: () => setState(() => _replyingToMessage = null),
              child: const Icon(LucideIcons.x, size: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message Bubble Row with Hitbox-Constrained Swipe ────────────────────────
  Widget _buildMessageBubbleRow(ChatMessage msg) {
    final isSelected = _selectedMessageIds.contains(msg.id);

    return Builder(
      builder: (bubbleContext) {
        final bubbleWidget = GestureDetector(
          onLongPress: () {
            if (_isMultiSelectMode) {
              setState(() {
                if (isSelected) {
                  _selectedMessageIds.remove(msg.id);
                } else {
                  _selectedMessageIds.add(msg.id);
                }
              });
            } else {
              _openMessageActionSheetOnBubble(msg, bubbleContext);
            }
          },
          onTap: _isMultiSelectMode
              ? () {
                  setState(() {
                    if (isSelected) {
                      _selectedMessageIds.remove(msg.id);
                    } else {
                      _selectedMessageIds.add(msg.id);
                    }
                  });
                }
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: const BoxConstraints(maxWidth: 320),
            child: _buildBubbleContent(msg),
          ),
        );

        if (_isMultiSelectMode) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SpringButton(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedMessageIds.remove(msg.id);
                      } else {
                        _selectedMessageIds.add(msg.id);
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10, bottom: 8),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF54C5F8) : Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF54C5F8) : Colors.white30,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected ? const Icon(LucideIcons.check, size: 14, color: Colors.black) : null,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: bubbleWidget,
                  ),
                ),
              ],
            ),
          );
        }

        // Swipe Delete (Right) & Swipe Reply (Left) strictly on the bubble card
        return Align(
          alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Dismissible(
            key: ValueKey('msg_${msg.id}'),
            direction: DismissDirection.horizontal,
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 12, bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.6)),
                ),
                child: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFFF5252)),
              ),
            ),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 12, bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF54C5F8).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.6)),
                ),
                child: const Icon(LucideIcons.reply, size: 18, color: Color(0xFF54C5F8)),
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                HapticFeedback.mediumImpact();
                _promptDeleteSingleMessage(msg);
                return false;
              } else if (direction == DismissDirection.endToStart) {
                HapticFeedback.lightImpact();
                setState(() => _replyingToMessage = msg);
                return false;
              }
              return false;
            },
            child: bubbleWidget,
          ),
        );
      },
    );
  }

  // ── Liquid Glass Transparent Bubble Card (Zero Blur) ──────────────────────
  Widget _buildBubbleContent(ChatMessage msg) {
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(msg.isMe ? 18 : 4),
      bottomRight: Radius.circular(msg.isMe ? 4 : 18),
    );

    final isHighlighted = msg.id == _highlightedMessageId;

    return Column(
      crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: msg.isMe
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isHighlighted ? const Color(0xFFFFD54F).withOpacity(0.35) : Colors.white.withOpacity(0.26),
                      Colors.white.withOpacity(0.14),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isHighlighted ? const Color(0xFFFFD54F).withOpacity(0.35) : Colors.white.withOpacity(0.14),
                      Colors.white.withOpacity(0.07),
                    ],
                  ),
            borderRadius: bubbleRadius,
            border: Border.all(
              color: isHighlighted
                  ? const Color(0xFFFFD54F)
                  : (msg.isMe ? Colors.white.withOpacity(0.30) : Colors.white.withOpacity(0.18)),
              width: isHighlighted ? 2.2 : 1.1,
            ),
            boxShadow: [
              if (isHighlighted)
                BoxShadow(
                  color: const Color(0xFFFFD54F).withOpacity(0.55),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Replied-to Quote Snippet
              if (msg.replyingTo != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF54C5F8), width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.replyingTo!.isMe ? 'You' : widget.conversation.name,
                        style: const TextStyle(
                          color: Color(0xFF54C5F8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        msg.replyingTo!.text.isNotEmpty ? msg.replyingTo!.text : 'Media attachment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],

              // Media Preview
              if (msg.mediaUrl != null) ...[
                _buildMessageMediaItem(msg),
                if (msg.text.isNotEmpty) const SizedBox(height: 6),
              ],

              // Main Text (with search highlighting)
              if (msg.text.isNotEmpty)
                _buildHighlightedText(msg.text, _chatSearchCtrl.text),

              // Code Snippet & Interactive Actions
              if (msg.codeSnippet != null) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF090A10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.35), width: 1.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with language & Copy button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF54C5F8).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (msg.codeLang ?? 'CODE').toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF54C5F8),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            SpringButton(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: msg.codeSnippet!));
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Code copied to clipboard'),
                                    duration: Duration(milliseconds: 1200),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.copy, size: 12, color: Colors.white70),
                                  SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Code body
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: SelectableText(
                          msg.codeSnippet!,
                          style: GoogleFonts.firaCode(
                            color: const Color(0xFF67E8F9),
                            fontSize: 11.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                      // Action buttons: [Apply to File] & [Run in Terminal]
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
                        ),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            SpringButton(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    content: const Text(
                                      '⚡ Changes applied to codebase via remote server bridge!',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.sparkles, size: 11, color: Color(0xFF10B981)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Apply to File',
                                      style: TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SpringButton(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                final now = DateTime.now();
                                final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                                setState(() {
                                  widget.conversation.messages.add(
                                    ChatMessage(
                                      id: 'exec_${DateTime.now().millisecondsSinceEpoch}',
                                      text: '✓ [tmux:0] Command executed successfully with status 0.',
                                      isMe: false,
                                      time: timeStr,
                                      isDelivered: true,
                                    ),
                                  );
                                });
                                _scrollToBottom();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF54C5F8).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.play, size: 11, color: Color(0xFF54C5F8)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Run in Terminal',
                                      style: TextStyle(color: Color(0xFF54C5F8), fontSize: 10.5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 4),

              // Timestamp & Status (Three Dots "..." instead of checkmarks)
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    msg.time,
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10),
                  ),
                  if (msg.isMe) ...[
                    const SizedBox(width: 5),
                    Text(
                      '...',
                      style: TextStyle(
                        color: msg.isDelivered ? const Color(0xFF54C5F8) : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Emoji Reaction Pill (One reaction per message)
        if (msg.reactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.20)),
              ),
              child: Text(
                msg.reactions.first,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    final q = query.trim().toLowerCase();
    if (!_isSearching || q.isEmpty || !text.toLowerCase().contains(q)) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          height: 1.35,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lowerText.indexOf(q, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + q.length),
          style: const TextStyle(
            color: Colors.black,
            backgroundColor: Color(0xFFFFD54F),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = idx + q.length;
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35),
        children: spans,
      ),
    );
  }

  void _openFullScreenMedia(ChatMessage msg) {
    if (msg.mediaUrl == null || msg.mediaUrl!.isEmpty) return;

    FullScreenMediaViewer.show(
      context,
      message: msg,
      senderName: msg.isMe ? 'You' : widget.conversation.name,
      senderAvatar: msg.isMe
          ? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80'
          : widget.conversation.avatarUrl,
      onShowInChat: () => _scrollToMessage(msg.id),
      onShare: () => _forwardMessages([msg]),
    );
  }

  void _scrollToMessage(String messageId) {
    final idx = widget.conversation.messages.indexWhere((m) => m.id == messageId);
    if (idx != -1 && _messagesScrollCtrl.hasClients) {
      final total = widget.conversation.messages.length;
      final targetOffset = (idx / total) * _messagesScrollCtrl.position.maxScrollExtent;
      _messagesScrollCtrl.animateTo(
        targetOffset.clamp(0.0, _messagesScrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      setState(() => _highlightedMessageId = messageId);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _highlightedMessageId = null);
      });
    }
  }

  Widget _buildMessageMediaItem(ChatMessage msg) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openFullScreenMedia(msg),
      child: _buildMediaItemBody(msg),
    );
  }

  Widget _buildMediaItemBody(ChatMessage msg) {
    if (msg.mediaType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (msg.mediaUrl!.startsWith('data:image'))
              Image.memory(
                base64Decode(msg.mediaUrl!.split(',').last),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 180,
              )
            else
              Image.network(
                msg.mediaUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 180,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: Colors.black26,
                  child: const Center(child: Icon(LucideIcons.image, color: Colors.white38)),
                ),
              ),
            if (msg.isUploading)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: msg.uploadProgress,
                      color: const Color(0xFF54C5F8),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Video or Document Capsule
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            msg.mediaType == 'video' ? LucideIcons.playCircle : LucideIcons.fileText,
            color: const Color(0xFF54C5F8),
            size: 24,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.mediaCaption ?? (msg.mediaType == 'video' ? 'Video Attachment' : 'Document'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  msg.mediaType == 'video' ? '0:24 • MP4' : 'PDF Document • 2.4 MB',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Input Bar (Liquid Glass Transparent, Zero Blur) ─────────────────
  Widget _buildBottomInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0.06),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SpringButton(
                    onTap: _showAttachmentOptions,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(LucideIcons.paperclip, size: 20, color: Colors.white.withOpacity(0.85)),
                    ),
                  ),
                  SpringButton(
                    onTap: () {
                      _msgCtrl.text += '🚀 ';
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(LucideIcons.smile, size: 20, color: Colors.white.withOpacity(0.85)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: const Color(0xFF54C5F8),
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Right circular Mic or Send button (Liquid Glass)
          SpringButton(
            onTap: _isTyping
                ? _sendMessage
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Audio note recording started...')),
                    );
                  },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _isTyping
                    ? const LinearGradient(
                        colors: [Color(0xFF54C5F8), Color(0xFF0091EA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.20),
                          Colors.white.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isTyping ? const Color(0xFF54C5F8) : Colors.white.withOpacity(0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isTyping
                        ? const Color(0xFF54C5F8).withOpacity(0.4)
                        : Colors.black.withOpacity(0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _isTyping ? LucideIcons.send : LucideIcons.mic,
                  size: 20,
                  color: _isTyping ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Long-Press Message Reaction & Dropdown / Dropup Liquid Glass Menu ───────
  void _openMessageActionSheetOnBubble(ChatMessage msg, BuildContext bubbleContext) {
    HapticFeedback.mediumImpact();
    final RenderBox? box = bubbleContext.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset bubblePos = box.localToGlobal(Offset.zero);
    final Size bubbleSize = box.size;
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    final emojis = ['👍', '❤️', '🔥', '😂', '😮', '😢', '🙏'];

    const double pillHeight = 44.0;
    const double pillWidth = 280.0;
    const double menuWidth = 210.0;
    const double preferredMenuHeight = 330.0;
    const double gap = 8.0;

    final double bubbleTop = bubblePos.dy;
    final double bubbleBottom = bubblePos.dy + bubbleSize.height;

    final double spaceAboveBubble = bubbleTop - topPadding;
    final double spaceBelowBubble = screenSize.height - bubbleBottom - bottomPadding;

    // Check if message is "too low" (towards bottom of screen):
    final bool isLow = spaceBelowBubble < (preferredMenuHeight + gap + 16.0) ||
        (bubbleTop > screenSize.height * 0.50 && spaceAboveBubble >= 240.0);

    double pillTop;
    double menuTop;
    double maxMenuHeight;

    if (isLow) {
      // ── DROPUP: Message is too low -> Drop UP above bubble ──
      // [Menu] -> [Emoji Reaction Pill] -> [Message Bubble]
      pillTop = bubbleTop - pillHeight - gap;
      final double availableAbovePill = pillTop - topPadding - gap - 8.0;
      maxMenuHeight = availableAbovePill.clamp(140.0, preferredMenuHeight);
      menuTop = pillTop - gap - maxMenuHeight;

      if (menuTop < topPadding + 8.0) {
        menuTop = topPadding + 8.0;
        maxMenuHeight = (pillTop - gap - menuTop).clamp(120.0, preferredMenuHeight);
      }
    } else {
      // ── DROPDOWN: Message is near top/mid -> Drop DOWN below bubble ──
      if (spaceAboveBubble >= pillHeight + gap + 4.0) {
        // [Emoji Reaction Pill] -> [Message Bubble] -> [Dropdown Menu]
        pillTop = bubbleTop - pillHeight - gap;
        menuTop = bubbleBottom + gap;
        final double availableBelowMenu = screenSize.height - menuTop - bottomPadding - 12.0;
        maxMenuHeight = availableBelowMenu.clamp(140.0, preferredMenuHeight);
      } else {
        // [Message Bubble] -> [Emoji Reaction Pill] -> [Dropdown Menu]
        pillTop = bubbleBottom + gap;
        menuTop = pillTop + pillHeight + gap;
        final double availableBelowMenu = screenSize.height - menuTop - bottomPadding - 12.0;
        maxMenuHeight = availableBelowMenu.clamp(140.0, preferredMenuHeight);
      }
    }

    // Horizontal placement:
    final double maxPillLeft = math.max(12.0, screenSize.width - pillWidth - 12.0);
    final double maxMenuLeft = math.max(12.0, screenSize.width - menuWidth - 12.0);

    double pillLeft;
    double menuLeft;

    if (msg.isMe) {
      pillLeft = (bubblePos.dx + bubbleSize.width - pillWidth).clamp(12.0, maxPillLeft);
      menuLeft = (bubblePos.dx + bubbleSize.width - menuWidth).clamp(12.0, maxMenuLeft);
    } else {
      pillLeft = bubblePos.dx.clamp(12.0, maxPillLeft);
      menuLeft = bubblePos.dx.clamp(12.0, maxMenuLeft);
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Menu',
      barrierColor: Colors.transparent, // Completely clear - no dark screen behind
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogCtx, anim1, anim2) {
        return Stack(
          children: [
            // Tap outside to close
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(dialogCtx),
                child: Container(color: Colors.transparent),
              ),
            ),

            // 1. Glowing highlight outline around the selected message bubble
            Positioned(
              left: bubblePos.dx - 2,
              top: bubblePos.dy - 2,
              width: bubbleSize.width + 4,
              height: bubbleSize.height + 4,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF54C5F8).withOpacity(0.55),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF54C5F8).withOpacity(0.20),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Floating Emoji Reaction Pill (Transparent Liquid Glass, Zero Blur)
            Positioned(
              left: pillLeft,
              top: pillTop,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141926).withOpacity(0.70),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.2),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.22),
                        const Color(0xFF141926).withOpacity(0.68),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFF54C5F8).withOpacity(0.12),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...emojis.map((emoji) {
                        final hasReacted = msg.reactions.contains(emoji);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SpringButton(
                            onTap: () {
                              Navigator.pop(dialogCtx);
                              _toggleEmojiReaction(msg, emoji);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: hasReacted ? const Color(0xFF54C5F8).withOpacity(0.22) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(emoji, style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                        );
                      }),
                      // Plus button
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: SpringButton(
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            _toggleEmojiReaction(msg, '🚀');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.14),
                            ),
                            child: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Floating Dropdown/Dropup Menu (Transparent Liquid Glass, Zero Blur)
            Positioned(
              left: menuLeft,
              top: menuTop,
              width: menuWidth,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141926).withOpacity(0.70),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.2),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.22),
                        const Color(0xFF141926).withOpacity(0.68),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: const Color(0xFF54C5F8).withOpacity(0.12),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxMenuHeight),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAnchorMenuItem(
                            icon: LucideIcons.info,
                            title: 'Message info',
                            onTap: () {
                              Navigator.pop(dialogCtx);
                              _showMessageInfo(msg);
                            },
                          ),
                          _buildAnchorMenuItem(
                            icon: LucideIcons.reply,
                            title: 'Reply',
                            onTap: () {
                              Navigator.pop(dialogCtx);
                              setState(() => _replyingToMessage = msg);
                            },
                          ),
                          _buildAnchorMenuItem(
                            icon: LucideIcons.copy,
                            title: 'Copy',
                            onTap: () {
                              Navigator.pop(dialogCtx);
                              Clipboard.setData(ClipboardData(text: msg.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Message copied to clipboard')),
                              );
                            },
                          ),
                          _buildAnchorMenuItem(
                            icon: LucideIcons.forward,
                            title: 'Forward',
                            onTap: () {
                              Navigator.pop(dialogCtx);
                              _forwardSingleMessage(msg);
                            },
                          ),
                          _buildAnchorMenuItem(
                            icon: LucideIcons.pin,
                            title: msg.isPinned ? 'Unpin' : 'Pin',
                            onTap: () {
                              Navigator.pop(dialogCtx);
                              setState(() => msg.isPinned = !msg.isPinned);
                            },
                          ),

                          _buildAnchorMenuItem(
                            icon: LucideIcons.star,
                            title: msg.isStarred ? 'Unstar' : 'Star',
                            accentColor: msg.isStarred ? const Color(0xFFFFD700) : null,
                            onTap: () {
                              Navigator.pop(dialogCtx);
                              setState(() => msg.isStarred = !msg.isStarred);
                            },
                          ),
                          Divider(color: Colors.white.withOpacity(0.08), height: 1),
                          _buildAnchorMenuItem(
                            icon: LucideIcons.checkSquare,
                            title: 'Select',
                            onTap: () {
                              Navigator.pop(dialogCtx);
                              setState(() {
                                _isMultiSelectMode = true;
                                _selectedMessageIds.add(msg.id);
                              });
                            },
                          ),
                          _buildAnchorMenuItem(
                            icon: LucideIcons.trash2,
                            title: 'Delete',
                            isDestructive: true,
                            onTap: () {
                              Navigator.pop(dialogCtx);
                              _promptDeleteSingleMessage(msg);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnchorMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    Color? accentColor,
  }) {
    final color = isDestructive
        ? const Color(0xFFFF5252)
        : (accentColor ?? Colors.white.withOpacity(0.92));

    return SpringButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageInfo(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF101420).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Message Info', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              _buildInfoRow('Sent', msg.time),
              _buildInfoRow('Status', 'Delivered & Read (...)'),
              _buildInfoRow('Encryption', 'End-to-end Encrypted'),
              if (msg.reactions.isNotEmpty)
                _buildInfoRow('Reactions', msg.reactions.join(' ')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }



  // ── Three Dots Menu in Top Bar ──────────────────────────────────────────────
  void _openThreeDotsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0F18).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              _buildSheetActionTile(LucideIcons.user, 'Contact Info', () {
                Navigator.pop(ctx);
                _navigateToContactInfo();
              }),
              _buildSheetActionTile(LucideIcons.image, 'Wallpaper for this Chat', () {
                Navigator.pop(ctx);
                _openWallpaperPickerForThisChat();
              }),
              _buildSheetActionTile(LucideIcons.search, 'Search in Conversation', () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search in conversation active')),
                );
              }),
              _buildSheetActionTile(LucideIcons.bellOff, 'Mute Notifications', () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications muted')),
                );
              }),
              _buildSheetActionTile(
                LucideIcons.trash2,
                'Clear Chat History',
                () {
                  Navigator.pop(ctx);
                  setState(() => widget.conversation.messages.clear());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat messages cleared')),
                  );
                },
                isDestructive: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetActionTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDestructive ? const Color(0xFFFF5252).withOpacity(0.08) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isDestructive ? const Color(0xFFFF5252) : Colors.white70),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? const Color(0xFFFF5252) : Colors.white,
                fontSize: 13.5,
                fontWeight: isDestructive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Wallpaper Picker for This Chat ────────────────────────────────────────
  void _openWallpaperPickerForThisChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (pickerCtx) {
        return _buildWallpaperPickerSheet(pickerCtx, widget.conversation);
      },
    );
  }

  Widget _buildWallpaperPickerSheet(BuildContext pickerCtx, ChatConversation conv) {
    final curatedWallpapers = [
      {'name': 'Cyber Neon', 'url': 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800'},
      {'name': 'Deep Nebula', 'url': 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=800'},
      {'name': 'Mountain Mist', 'url': 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800'},
      {'name': 'Tokyo Night', 'url': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800'},
      {'name': 'Dark Aurora', 'url': 'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?w=800'},
      {'name': 'Geometric Glass', 'url': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800'},
    ];

    final gradients = [
      {'name': 'Midnight Cyan', 'colors': [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]},
      {'name': 'Deep Purple', 'colors': [const Color(0xFF14072B), const Color(0xFF2D0C54), const Color(0xFF0D041A)]},
      {'name': 'Emerald Dark', 'colors': [const Color(0xFF051911), const Color(0xFF0C3827), const Color(0xFF030D08)]},
      {'name': 'Sunset Ember', 'colors': [const Color(0xFF2C0B0E), const Color(0xFF4A1521), const Color(0xFF150407)]},
    ];

    final solidColors = [
      {'name': 'Obsidian Void', 'color': const Color(0xFF07080A), 'id': 'obsidian'},
      {'name': 'OLED Pure Black', 'color': const Color(0xFF000000), 'id': 'oled'},
      {'name': 'Charcoal Navy', 'color': const Color(0xFF0D1117), 'id': 'charcoal'},
      {'name': 'Deep Slate', 'color': const Color(0xFF11141C), 'id': 'slate'},
      {'name': 'Gunmetal Gray', 'color': const Color(0xFF16181F), 'id': 'gunmetal'},
      {'name': 'Night Indigo', 'color': const Color(0xFF0E1020), 'id': 'indigo'},
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0D14).withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chat Wallpaper',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Customizing for ${conv.name}',
                        style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 12),
                      ),
                    ],
                  ),
                  SpringButton(
                    onTap: () => Navigator.pop(pickerCtx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                      child: const Icon(LucideIcons.x, size: 18, color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Choose from Device Gallery
              SpringButton(
                onTap: () async {
                  try {
                    final result = await getStoragePicker().pickImage();
                    if (result != null) {
                      Navigator.pop(pickerCtx);
                      _openWallpaperAdjustSheet(
                        ChatWallpaperConfig(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          name: result.fileName,
                          type: 'image',
                          imageUrl: result.pathOrDataUrl,
                          blur: 0.0,
                          opacity: 0.85,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Storage access error: $e')),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF54C5F8).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF54C5F8).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.imagePlus, color: Color(0xFF54C5F8), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Choose Photo from Gallery',
                              style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Adjust size, placement, zoom & dimming',
                              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, color: Color(0xFF54C5F8), size: 18),
                    ],
                  ),
                ),
              ),

              if (conv.customWallpaper != null) ...[
                const SizedBox(height: 10),
                SpringButton(
                  onTap: () {
                    setState(() => conv.customWallpaper = null);
                    widget.onWallpaperUpdated?.call(null);
                    Navigator.pop(pickerCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reset wallpaper for ${conv.name} to default')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.rotateCcw, size: 15, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text('Reset to Default Wallpaper', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.5)),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Text('Curated Art & Photos', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.72,
                ),
                itemCount: curatedWallpapers.length,
                itemBuilder: (context, i) {
                  final wp = curatedWallpapers[i];
                  return SpringButton(
                    onTap: () {
                      Navigator.pop(pickerCtx);
                      _openWallpaperAdjustSheet(
                        ChatWallpaperConfig(
                          id: 'curated_$i',
                          name: wp['name']!,
                          type: 'image',
                          imageUrl: wp['url']!,
                          blur: 0.0,
                          opacity: 0.85,
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(wp['url']!, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            left: 6,
                            right: 6,
                            child: Text(
                              wp['name']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              const Text('Minimalist Gradients', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2,
                ),
                itemCount: gradients.length,
                itemBuilder: (context, i) {
                  final g = gradients[i];
                  final colors = g['colors'] as List<Color>;
                  return SpringButton(
                    onTap: () {
                      Navigator.pop(pickerCtx);
                      _openWallpaperAdjustSheet(
                        ChatWallpaperConfig(
                          id: 'grad_$i',
                          name: g['name'] as String,
                          type: 'gradient',
                          gradientColors: colors,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: Text(
                          g['name'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              const Text('Solid Minimalist Darks', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.6,
                ),
                itemCount: solidColors.length,
                itemBuilder: (context, i) {
                  final s = solidColors[i];
                  final color = s['color'] as Color;
                  return SpringButton(
                    onTap: () {
                      Navigator.pop(pickerCtx);
                      _openWallpaperAdjustSheet(
                        ChatWallpaperConfig(
                          id: s['id'] as String,
                          name: s['name'] as String,
                          type: 'solid',
                          solidColor: color,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Center(
                        child: Text(
                          s['name'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openWallpaperAdjustSheet(ChatWallpaperConfig config) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (adjustCtx) {
        return WallpaperAdjustSheet(
          conv: widget.conversation,
          wallpaper: config,
          isForContacts: false,
          onApply: (appliedConfig, forAllChats) {
            setState(() {
              widget.conversation.customWallpaper = appliedConfig;
            });
            widget.onWallpaperUpdated?.call(appliedConfig);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  forAllChats
                      ? 'Wallpaper applied to all chats'
                      : 'Wallpaper set for ${widget.conversation.name}',
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0F18).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
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
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachOption(LucideIcons.camera, 'Camera', () {
                    Navigator.pop(ctx);
                    _pickFromStorage(isCamera: true);
                  }),
                  _buildAttachOption(LucideIcons.image, 'Gallery', () {
                    Navigator.pop(ctx);
                    _pickFromStorage(mediaType: 'image');
                  }),
                  _buildAttachOption(LucideIcons.video, 'Video', () {
                    Navigator.pop(ctx);
                    _pickFromStorage(mediaType: 'video');
                  }),
                  _buildAttachOption(LucideIcons.fileText, 'Document', () {
                    Navigator.pop(ctx);
                    _pickFromStorage(mediaType: 'document');
                  }),
                  _buildAttachOption(LucideIcons.code, 'Code', () {
                    Navigator.pop(ctx);
                    _msgCtrl.text += '```dart\n// Code snippet\n```';
                  }),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachOption(IconData icon, String label, VoidCallback onTap) {
    return SpringButton(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF54C5F8).withOpacity(0.15),
              border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.35)),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF54C5F8)),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromStorage({String mediaType = 'image', bool isCamera = false}) async {
    try {
      PickedMediaResult? result;
      if (isCamera) {
        result = await getStoragePicker().pickImage(fromCamera: true);
      } else if (mediaType == 'image') {
        result = await getStoragePicker().pickImage(fromCamera: false);
      } else if (mediaType == 'video') {
        result = await getStoragePicker().pickVideo();
      } else {
        result = await getStoragePicker().pickDocument();
      }

      if (result == null) return;

      _openMediaEditorModal(
        mediaType: result.mediaType,
        mediaUrl: result.pathOrDataUrl,
        mediaTitle: result.fileName,
        initialCaption: result.mediaType == 'document' ? result.fileName : '',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage access error: $e')),
        );
      }
    }
  }

  void _openMediaEditorModal({
    required String mediaType,
    required String mediaUrl,
    required String mediaTitle,
    String? initialCaption,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return MediaEditorSheet(
          mediaType: mediaType,
          mediaUrl: mediaUrl,
          mediaTitle: mediaTitle,
          initialCaption: initialCaption,
          onSend: (type, url, caption, filterName) {
            _sendMediaMessage(
              mediaType: type,
              mediaUrl: url,
              caption: caption,
            );
          },
        );
      },
    );
  }

  void _promptDeleteSingleMessage(ChatMessage msg) {
    final now = DateTime.now();
    final bool isSentByMe = msg.isMe;
    final bool isWithin24Hours = now.difference(msg.sentAt).inHours < 24;
    final bool canDeleteForEveryone = isSentByMe && isWithin24Hours;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF141926).withOpacity(0.82),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.24), width: 1.2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.20),
                  const Color(0xFF121724).withOpacity(0.78),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.40),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF54C5F8).withOpacity(0.12),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withOpacity(0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.35)),
                  ),
                  child: const Icon(LucideIcons.trash2, size: 24, color: Color(0xFFFF5252)),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Delete Message?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  canDeleteForEveryone
                      ? 'You can delete this message for everyone or only for yourself.'
                      : (isSentByMe
                          ? 'This message was sent over 24 hours ago. It can only be deleted for yourself.'
                          : 'Delete this message from your chat history?'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Delete for everyone (Only if sent by me & within 24 hours)
                if (canDeleteForEveryone) ...[
                  _buildGlassDeleteBtn(
                    title: 'Delete for everyone',
                    icon: LucideIcons.trash2,
                    color: const Color(0xFFFF5252),
                    isPrimary: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => widget.conversation.messages.remove(msg));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message deleted for everyone')),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],

                // 2. Delete for me (Always available)
                _buildGlassDeleteBtn(
                  title: 'Delete for me',
                  icon: LucideIcons.trash,
                  color: canDeleteForEveryone ? Colors.white.withOpacity(0.9) : const Color(0xFFFF5252),
                  isPrimary: !canDeleteForEveryone,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => widget.conversation.messages.remove(msg));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message deleted for me')),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // 3. Cancel
                _buildGlassDeleteBtn(
                  title: 'Cancel',
                  icon: LucideIcons.x,
                  color: Colors.white.withOpacity(0.65),
                  isPrimary: false,
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassDeleteBtn({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? color.withOpacity(0.18) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary ? color.withOpacity(0.55) : Colors.white.withOpacity(0.20),
            width: 1.1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _starSelectedMessages() {
    setState(() {
      for (final msg in widget.conversation.messages) {
        if (_selectedMessageIds.contains(msg.id)) {
          msg.isStarred = true;
        }
      }
      _isMultiSelectMode = false;
      _selectedMessageIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messages starred')),
    );
  }

  void _copySelectedMessages() {
    final selectedMsgs = widget.conversation.messages.where((m) => _selectedMessageIds.contains(m.id)).toList();
    final combined = selectedMsgs.map((m) => m.text).join('\n');
    Clipboard.setData(ClipboardData(text: combined));
    setState(() {
      _isMultiSelectMode = false;
      _selectedMessageIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messages copied to clipboard')),
    );
  }

  void _forwardMessages(List<ChatMessage> messagesToForward) {
    if (messagesToForward.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final candidates = widget.allConversations
                .where((c) => c.id != widget.conversation.id)
                .where((c) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return c.name.toLowerCase().contains(q) || c.role.toLowerCase().contains(q);
            }).toList();

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E17).withOpacity(0.96),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
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
                          const Icon(LucideIcons.forward, color: Color(0xFF54C5F8), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            messagesToForward.length == 1
                                ? 'Forward Message'
                                : 'Forward ${messagesToForward.length} Messages',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.search, size: 16, color: Colors.white54),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (val) {
                                  setSheetState(() => searchQuery = val.trim());
                                },
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                cursorColor: const Color(0xFF54C5F8),
                                decoration: InputDecoration(
                                  hintText: 'Search contacts or connections...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: candidates.isEmpty
                            ? Center(
                                child: Text(
                                  'No matching contacts found',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: candidates.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final conn = candidates[i];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundImage: NetworkImage(conn.avatarUrl),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                conn.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                conn.role,
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.5),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SpringButton(
                                          onTap: () {
                                            for (final m in messagesToForward) {
                                              conn.messages.add(
                                                ChatMessage(
                                                  id: 'fwd_${DateTime.now().millisecondsSinceEpoch}_${m.id}',
                                                  text: m.text,
                                                  isMe: true,
                                                  time: 'Just now',
                                                  sentAt: DateTime.now(),
                                                  mediaUrl: m.mediaUrl,
                                                  mediaType: m.mediaType,
                                                  mediaCaption: m.mediaCaption,
                                                  reactions: [],
                                                ),
                                              );
                                            }
                                            final lastOne = messagesToForward.last;
                                            conn.lastMessage = lastOne.mediaCaption?.isNotEmpty == true
                                                ? lastOne.mediaCaption!
                                                : (lastOne.text.isNotEmpty
                                                    ? lastOne.text
                                                    : 'Forwarded message');

                                            Navigator.pop(ctx);
                                            if (_isMultiSelectMode) {
                                              setState(() {
                                                _isMultiSelectMode = false;
                                                _selectedMessageIds.clear();
                                              });
                                            }
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  messagesToForward.length == 1
                                                      ? 'Forwarded to ${conn.name}'
                                                      : '${messagesToForward.length} messages forwarded to ${conn.name}',
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF54C5F8).withOpacity(0.20),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.6)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(LucideIcons.send, color: Color(0xFF54C5F8), size: 13),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Send',
                                                  style: TextStyle(
                                                    color: Color(0xFF54C5F8),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
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
              ),
            );
          },
        );
      },
    );
  }

  void _forwardSelectedMessages() {
    final msgs = widget.conversation.messages
        .where((m) => _selectedMessageIds.contains(m.id))
        .toList();
    _forwardMessages(msgs);
  }

  void _forwardSingleMessage(ChatMessage msg) {
    _forwardMessages([msg]);
  }

  void _deleteSelectedMessagesPrompt() {
    final count = _selectedMessageIds.length;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF141926).withOpacity(0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.24), width: 1.2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.20),
                const Color(0xFF121724).withOpacity(0.78),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.40),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF54C5F8).withOpacity(0.12),
                blurRadius: 18,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withOpacity(0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.35)),
                ),
                child: const Icon(LucideIcons.trash2, size: 24, color: Color(0xFFFF5252)),
              ),
              const SizedBox(height: 14),
              Text(
                'Delete $count Messages?',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete $count selected messages from your chat?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 20),
              _buildGlassDeleteBtn(
                title: 'Delete for me',
                icon: LucideIcons.trash2,
                color: const Color(0xFFFF5252),
                isPrimary: true,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    widget.conversation.messages.removeWhere((m) => _selectedMessageIds.contains(m.id));
                    _isMultiSelectMode = false;
                    _selectedMessageIds.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted $count messages')),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildGlassDeleteBtn(
                title: 'Cancel',
                icon: LucideIcons.x,
                color: Colors.white.withOpacity(0.65),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─── Reusable Wallpaper Background Builder ─────────────────────────────────
Widget buildWallpaperBackground(ChatWallpaperConfig wallpaper) {
  if (wallpaper.type == 'image' && wallpaper.imageUrl != null) {
    final img = wallpaper.imageUrl!;
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
        imageWidget = Container(color: const Color(0xFF07080A));
      }
    } else {
      imageWidget = Image.network(
        img,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF07080A)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final dx = wallpaper.alignmentX * (w * 0.5);
            final dy = wallpaper.alignmentY * (h * 0.5);
            return ClipRect(
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.scale(
                  scale: wallpaper.scale,
                  alignment: Alignment.center,
                  child: SizedBox.expand(child: imageWidget),
                ),
              ),
            );
          },
        ),
        if (wallpaper.blur > 0.1)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: wallpaper.blur, sigmaY: wallpaper.blur),
            child: const SizedBox.expand(),
          ),
        Container(
          color: Colors.black.withOpacity((1.0 - wallpaper.opacity).clamp(0.0, 0.95)),
        ),
      ],
    );
  } else if (wallpaper.type == 'gradient' && wallpaper.gradientColors != null) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: wallpaper.gradientColors!,
        ),
      ),
    );
  } else {
    return Container(
      color: wallpaper.solidColor ?? const Color(0xFF07080A),
    );
  }
}

/// ─── Reusable Wallpaper Adjustment Modal Sheet ──────────────────────────────
class WallpaperAdjustSheet extends StatefulWidget {
  final ChatConversation? conv;
  final ChatWallpaperConfig wallpaper;
  final bool isForContacts;
  final Function(ChatWallpaperConfig appliedConfig, bool forAllChats) onApply;

  const WallpaperAdjustSheet({
    super.key,
    this.conv,
    required this.wallpaper,
    this.isForContacts = false,
    required this.onApply,
  });

  @override
  State<WallpaperAdjustSheet> createState() => _WallpaperAdjustSheetState();
}

class _WallpaperAdjustSheetState extends State<WallpaperAdjustSheet> {
  late double _blur;
  late double _opacity;
  late double _scale;
  late double _alignmentX;
  late double _alignmentY;
  int _activeTab = 0; // 0: Size & Placement, 1: Dimming & Blur

  @override
  void initState() {
    super.initState();
    _blur = widget.wallpaper.blur;
    _opacity = widget.wallpaper.opacity;
    _scale = widget.wallpaper.scale;
    _alignmentX = widget.wallpaper.alignmentX;
    _alignmentY = widget.wallpaper.alignmentY;
  }

  @override
  Widget build(BuildContext context) {
    final isImageType = widget.wallpaper.type == 'image' && widget.wallpaper.imageUrl != null;
    final draftConfig = widget.wallpaper.copyWith(
      blur: _blur,
      opacity: _opacity,
      scale: _scale,
      alignmentX: _alignmentX,
      alignmentY: _alignmentY,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D15).withOpacity(0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isForContacts ? 'Contacts Wallpaper' : 'Chat Wallpaper',
                        style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isForContacts
                            ? 'Customizing Contacts List Background'
                            : 'Customizing for ${widget.conv?.name ?? 'Chat'}',
                        style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 11.5),
                      ),
                    ],
                  ),
                  SpringButton(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
                      child: const Icon(LucideIcons.x, size: 16, color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Interactive Preview Window
              Center(
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Interactive panning
                      GestureDetector(
                        onPanUpdate: isImageType
                            ? (details) {
                                setState(() {
                                  _alignmentX = (_alignmentX + details.delta.dx / 100).clamp(-1.5, 1.5);
                                  _alignmentY = (_alignmentY + details.delta.dy / 100).clamp(-1.5, 1.5);
                                });
                              }
                            : null,
                        child: buildWallpaperBackground(draftConfig),
                      ),

                      // Overlay Preview Card
                      Center(
                        child: widget.isForContacts
                            ? Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200'),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Mohit Bro Bihar', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                          Text('Fullstack Dev • Online', style: TextStyle(color: Color(0xFF54C5F8), fontSize: 10.5)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4ADE80)),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                margin: const EdgeInsets.symmetric(horizontal: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.28)),
                                ),
                                child: const Text(
                                  'Clean liquid glass! Wallpaper preview 🔥',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isImageType) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SpringButton(
                          onTap: () => setState(() => _activeTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: _activeTab == 0 ? const Color(0xFF54C5F8) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Size & Placement',
                                style: TextStyle(
                                  color: _activeTab == 0 ? Colors.black : Colors.white70,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SpringButton(
                          onTap: () => setState(() => _activeTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: _activeTab == 1 ? const Color(0xFF54C5F8) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Dimming & Blur',
                                style: TextStyle(
                                  color: _activeTab == 1 ? Colors.black : Colors.white70,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (_activeTab == 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Wallpaper Size (Zoom)', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      Text('${(_scale * 100).toInt()}%', style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _scale,
                    min: 0.5,
                    max: 3.0,
                    activeColor: const Color(0xFF54C5F8),
                    onChanged: (val) => setState(() => _scale = val),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNudgeBtn(LucideIcons.arrowLeft, () => setState(() => _alignmentX = (_alignmentX - 0.1).clamp(-1.5, 1.5))),
                      const SizedBox(width: 8),
                      _buildNudgeBtn(LucideIcons.arrowUp, () => setState(() => _alignmentY = (_alignmentY - 0.1).clamp(-1.5, 1.5))),
                      const SizedBox(width: 8),
                      _buildNudgeBtn(LucideIcons.arrowDown, () => setState(() => _alignmentY = (_alignmentY + 0.1).clamp(-1.5, 1.5))),
                      const SizedBox(width: 8),
                      _buildNudgeBtn(LucideIcons.arrowRight, () => setState(() => _alignmentX = (_alignmentX + 0.1).clamp(-1.5, 1.5))),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Wallpaper Brightness', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      Text('${(_opacity * 100).toInt()}%', style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _opacity,
                    min: 0.20,
                    max: 1.0,
                    activeColor: const Color(0xFF54C5F8),
                    onChanged: (val) => setState(() => _opacity = val),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Frosted Blur (Optional)', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      Text('${_blur.toStringAsFixed(1)} px', style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _blur,
                    min: 0.0,
                    max: 18.0,
                    activeColor: const Color(0xFF54C5F8),
                    onChanged: (val) => setState(() => _blur = val),
                  ),
                ],
              ],

              const SizedBox(height: 16),

              SpringButton(
                onTap: () {
                  final finalConfig = widget.wallpaper.copyWith(
                    blur: _blur,
                    opacity: _opacity,
                    scale: _scale,
                    alignmentX: _alignmentX,
                    alignmentY: _alignmentY,
                  );
                  Navigator.pop(context);
                  widget.onApply(finalConfig, false);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF54C5F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      widget.isForContacts
                          ? 'Apply to Contacts List'
                          : 'Apply to ${widget.conv?.name ?? 'Chat'}',
                      style: const TextStyle(color: Colors.black, fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              if (!widget.isForContacts) ...[
                const SizedBox(height: 8),
                SpringButton(
                  onTap: () {
                    final finalConfig = widget.wallpaper.copyWith(
                      blur: _blur,
                      opacity: _opacity,
                      scale: _scale,
                      alignmentX: _alignmentX,
                      alignmentY: _alignmentY,
                    );
                    Navigator.pop(context);
                    widget.onApply(finalConfig, true);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Set for all chats', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNudgeBtn(IconData icon, VoidCallback onTap) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Center(child: Icon(icon, size: 15, color: Colors.white)),
      ),
    );
  }
}

/// ─── Media Editor Sheet ───────────────────────────────────────────────────
class MediaEditorSheet extends StatefulWidget {
  final String mediaType;
  final String mediaUrl;
  final String mediaTitle;
  final String? initialCaption;
  final Function(String type, String url, String? caption, String filterName) onSend;

  const MediaEditorSheet({
    super.key,
    required this.mediaType,
    required this.mediaUrl,
    required this.mediaTitle,
    this.initialCaption,
    required this.onSend,
  });

  @override
  State<MediaEditorSheet> createState() => _MediaEditorSheetState();
}

class _MediaEditorSheetState extends State<MediaEditorSheet> {
  late final TextEditingController _captionCtrl;
  String _selectedFilter = 'Normal';
  String? _selectedBadge;

  final Map<String, ColorFilter?> _filters = {
    'Normal': null,
    'Cyber Cyan': ColorFilter.mode(const Color(0x3354C5F8), BlendMode.color),
    'Neon Violet': ColorFilter.mode(const Color(0x33A855F7), BlendMode.color),
    'Matrix Green': ColorFilter.mode(const Color(0x3310B981), BlendMode.color),
    'Noir Mono': const ColorFilter.mode(Colors.black, BlendMode.saturation),
  };

  final List<String> _badges = ['🔥 Fire', '🚀 Launch', '✨ Clean', '🐞 Bug', '✅ Fixed'];

  @override
  void initState() {
    super.initState();
    _captionCtrl = TextEditingController(text: widget.initialCaption ?? '');
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E17).withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.mediaType == 'image'
                    ? 'Photo Preview'
                    : widget.mediaType == 'video'
                        ? 'Video Preview'
                        : 'Document Preview',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SpringButton(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
                  child: const Icon(LucideIcons.x, size: 16, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preview Canvas
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: _filters[_selectedFilter] ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                    child: widget.mediaUrl.startsWith('data:image')
                        ? Image.memory(base64Decode(widget.mediaUrl.split(',').last), fit: BoxFit.cover)
                        : Image.network(
                            widget.mediaUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.black26,
                              child: const Center(child: Icon(LucideIcons.image, size: 48, color: Colors.white38)),
                            ),
                          ),
                  ),
                  if (_selectedBadge != null)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF54C5F8), width: 1.2),
                        ),
                        child: Text(_selectedBadge!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          if (widget.mediaType != 'document') ...[
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _filters.keys.map((fName) {
                  final isSelected = _selectedFilter == fName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SpringButton(
                      onTap: () => setState(() => _selectedFilter = fName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF54C5F8).withOpacity(0.2) : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF54C5F8) : Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          fName,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF54C5F8) : Colors.white70,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Sticker / Badge Selector
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _badges.map((bName) {
                final isSelected = _selectedBadge == bName;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SpringButton(
                    onTap: () => setState(() => _selectedBadge = isSelected ? null : bName),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF54C5F8).withOpacity(0.2) : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF54C5F8) : Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        bName,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF54C5F8) : Colors.white70,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Caption & Send
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: TextField(
                    controller: _captionCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    cursorColor: const Color(0xFF54C5F8),
                    decoration: InputDecoration(
                      hintText: 'Add a caption...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SpringButton(
                onTap: () {
                  Navigator.pop(context);
                  widget.onSend(
                    widget.mediaType,
                    widget.mediaUrl,
                    _captionCtrl.text.trim().isEmpty ? null : _captionCtrl.text.trim(),
                    _selectedFilter,
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF54C5F8),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.send, color: Colors.black, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
