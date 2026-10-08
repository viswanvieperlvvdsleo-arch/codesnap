import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/spring_button.dart';
import 'dart:convert';
import 'contact_info_screen.dart';
import 'media_links_docs_screen.dart';
import 'chat_settings_screen.dart';
import '../services/storage_picker.dart';
import 'individual_chat_screen.dart';
import '../services/supabase_service.dart';
import '../services/supabase_data_service.dart';

/// ─── Chat Data Models ────────────────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final String time;
  final DateTime sentAt;
  final String? codeSnippet;
  final String? codeLang;
  List<String> reactions;
  bool isStarred;
  bool isPinned;
  final ChatMessage? replyingTo;
  final String? mediaUrl;
  final String? mediaType; // 'image', 'video', 'document'
  final String? mediaCaption;
  bool isUploading;
  double uploadProgress;
  bool isDelivered;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    DateTime? sentAt,
    this.codeSnippet,
    this.codeLang,
    List<String>? reactions,
    this.isStarred = false,
    this.isPinned = false,
    this.replyingTo,
    this.mediaUrl,
    this.mediaType,
    this.mediaCaption,
    this.isUploading = false,
    this.uploadProgress = 1.0,
    this.isDelivered = true,
  })  : sentAt = sentAt ?? DateTime.now(),
        reactions = reactions ?? [];
}

class ChatWallpaperConfig {
  final String id;
  final String name;
  final String type; // 'solid', 'gradient', 'image'
  final Color? solidColor;
  final List<Color>? gradientColors;
  final String? imageUrl;
  final double blur;
  final double opacity;
  final double scale;
  final double alignmentX; // -1.5 (left) to 1.5 (right)
  final double alignmentY; // -1.5 (top) to 1.5 (down)

  const ChatWallpaperConfig({
    required this.id,
    required this.name,
    required this.type,
    this.solidColor,
    this.gradientColors,
    this.imageUrl,
    this.blur = 0.0,
    this.opacity = 0.85,
    this.scale = 1.0,
    this.alignmentX = 0.0,
    this.alignmentY = 0.0,
  });

  ChatWallpaperConfig copyWith({
    String? id,
    String? name,
    String? type,
    Color? solidColor,
    List<Color>? gradientColors,
    String? imageUrl,
    double? blur,
    double? opacity,
    double? scale,
    double? alignmentX,
    double? alignmentY,
  }) {
    return ChatWallpaperConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      solidColor: solidColor ?? this.solidColor,
      gradientColors: gradientColors ?? this.gradientColors,
      imageUrl: imageUrl ?? this.imageUrl,
      blur: blur ?? this.blur,
      opacity: opacity ?? this.opacity,
      scale: scale ?? this.scale,
      alignmentX: alignmentX ?? this.alignmentX,
      alignmentY: alignmentY ?? this.alignmentY,
    );
  }
}

class ChatConversation {
  final String id;
  final String name;
  final String role;
  final String avatarUrl;
  final bool isOnline;
  String lastMessage;
  String time;
  int unreadCount;
  final List<ChatMessage> messages;
  ChatWallpaperConfig? customWallpaper;
  final bool isAiAssistant;
  String? activeModel;
  String? terminalSession;

  ChatConversation({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.isOnline,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    required this.messages,
    this.customWallpaper,
    this.isAiAssistant = false,
    this.activeModel,
    this.terminalSession,
  });
}

/// ─── Chat Screen ─────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;
  final ValueChanged<bool>? onActiveConversationChanged;
  final bool? isExpanded;
  final ValueChanged<bool>? onToggleExpand;

  const ChatScreen({
    super.key,
    this.isEmbedded = false,
    this.onBack,
    this.onActiveConversationChanged,
    this.isExpanded,
    this.onToggleExpand,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

/// ─── Chat Persistent State Store ───────────────────────────────────────────
/// Preserves wallpapers, conversations, active selection, and user edits across
/// tab navigations, page changes, and screen rebuilds.
class ChatStateStore {
  static final ChatStateStore instance = ChatStateStore._();
  ChatStateStore._() {
    initDefaultConversations();
  }

  ChatWallpaperConfig defaultWallpaper = const ChatWallpaperConfig(
    id: 'obsidian',
    name: 'Obsidian Void',
    type: 'solid',
    solidColor: Color(0xFF07080A),
  );

  ChatWallpaperConfig contactsWallpaper = const ChatWallpaperConfig(
    id: 'contacts_obsidian',
    name: 'Obsidian Void',
    type: 'solid',
    solidColor: Color(0xFF07080A),
  );

  String? selectedConversationId;
  final ValueNotifier<String?> selectedConversationNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<int> conversationsUpdateNotifier = ValueNotifier<int>(0);

  void notifyConversationsUpdated() {
    conversationsUpdateNotifier.value++;
  }

  void selectConversation(String? id) {
    if (id != null && _conversations != null) {
      for (final conv in _conversations!) {
        if (conv.id == id) {
          conv.unreadCount = 0;
          break;
        }
      }
    }
    selectedConversationId = id;
    selectedConversationNotifier.value = id;
    notifyConversationsUpdated();
  }

  List<ChatConversation>? _conversations;

  List<ChatConversation> get conversations {
    if (_conversations == null) {
      initDefaultConversations();
    }
    return _conversations!;
  }

  set conversations(List<ChatConversation> list) {
    _conversations = list;
    notifyConversationsUpdated();
  }

  void initDefaultConversations() {
    if (_conversations != null && _conversations!.isNotEmpty) return;
    _conversations = [
      ChatConversation(
        id: 'server_terminal_ai',
        name: 'Remote Terminal AI',
        role: 'Claude 3.5 · GPT-4o · Codex Bridge',
        avatarUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=200',
        isOnline: true,
        isAiAssistant: true,
        activeModel: 'Claude 3.5 Sonnet',
        terminalSession: 'tmux:0 · dev-worker',
        lastMessage: '⚡ Code analysis complete: swipe actions & stories fixes verified.',
        time: 'Just now',
        unreadCount: 1,
        messages: [
          ChatMessage(
            id: 'ai_init_1',
            text: '⚡ [Zero-Cost Server Terminal Bridge Connected]\nHost: dev-worker (tmux:0)\nProtocol: Remote Terminal Engine · Zero direct API billing\nSupported Models: Claude 3.5 Sonnet, GPT-4o, Codex, Antigravity',
            isMe: false,
            time: '19:40',
            isDelivered: true,
          ),
          ChatMessage(
            id: 'ai_init_2',
            text: 'Inspected recent mobile feed updates. Verified story card height translation and like toggle counters:',
            isMe: false,
            time: '19:41',
            codeLang: 'dart',
            codeSnippet: '''// Fixed story container height and ListView clipping
final storiesHeight = isDesktop ? 168.0 : 220.0;
ListView.builder(
  clipBehavior: Clip.none,
  padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 8),
  ...
);''',
            isDelivered: true,
          ),
          ChatMessage(
            id: 'ai_init_3',
            text: 'Type your instruction or terminal command below (e.g., "run flutter test", "check git diff", "generate model"). The server terminal will execute it and stream output here!',
            isMe: false,
            time: '19:42',
            isDelivered: true,
          ),
        ],
      ),
      ChatConversation(
        id: '1',
        name: 'Mohit Bro Bihar',
        role: 'Fullstack Dev',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        isOnline: true,
        lastMessage: 'Okay',
        time: '19:48',
        unreadCount: 0,
        messages: [
          ChatMessage(
            id: 'm1',
            text: 'I want to crack a gov job it would be safe happy less tention',
            isMe: true,
            time: '23:34',
          ),
          ChatMessage(
            id: 'm2',
            text: 'That to I want in bank',
            isMe: true,
            time: '23:34',
          ),
          ChatMessage(
            id: 'm3',
            text: 'Hmm best of luck',
            isMe: false,
            time: '23:35',
          ),
          ChatMessage(
            id: 'm4',
            text: 'Mm 🫠 once we get no family tentions, holidays tention, work tentions.\nMoney tention.',
            isMe: true,
            time: '23:34',
            reactions: ['👍'],
          ),
          ChatMessage(
            id: 'm5',
            text: 'Yes',
            isMe: false,
            time: '23:46',
            replyingTo: ChatMessage(
              id: 'm4_reply',
              text: 'Mm 🫠 once we get no family tentions, holidays tentions...',
              isMe: true,
              time: '23:34',
            ),
          ),
          ChatMessage(
            id: 'm_media1',
            text: 'Here is the liquid glass shader prototype on mobile!',
            isMe: false,
            time: '23:48',
            mediaUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
            mediaType: 'image',
            mediaCaption: 'Liquid glass shader preview with live blur',
            isDelivered: true,
          ),
          ChatMessage(
            id: 'm_media2',
            text: 'CodeSnap_Architecture_Specs.pdf',
            isMe: true,
            time: '23:50',
            mediaUrl: 'mock_pdf',
            mediaType: 'document',
            mediaCaption: 'CodeSnap_Architecture_Specs.pdf',
            isDelivered: true,
          ),
          ChatMessage(
            id: 'm6',
            text: 'After dinner',
            isMe: false,
            time: '18:47',
          ),
          ChatMessage(
            id: 'm7',
            text: 'Come',
            isMe: false,
            time: '19:47',
          ),
          ChatMessage(
            id: 'm8',
            text: 'Not coming',
            isMe: true,
            time: 'Yesterday 19:47',
            sentAt: DateTime.now().subtract(const Duration(hours: 30)),
          ),
          ChatMessage(
            id: 'm9',
            text: 'Having work',
            isMe: true,
            time: 'Yesterday 19:47',
            sentAt: DateTime.now().subtract(const Duration(hours: 30)),
          ),
          ChatMessage(
            id: 'm10',
            text: 'Okay',
            isMe: false,
            time: '19:48',
          ),
        ],
      ),
      ChatConversation(
        id: '2',
        name: 'Sarah Chen',
        role: 'Core Lead',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        isOnline: true,
        lastMessage: 'The new terminal engine runs with zero errors in Linux & Android!',
        time: '15m',
        unreadCount: 1,
        messages: [
          ChatMessage(
            id: 's1',
            text: 'Did the zero-cost terminal engine compile properly on Android?',
            isMe: true,
            time: '13:40',
          ),
          ChatMessage(
            id: 's2',
            text: 'The new terminal engine runs with zero errors in Linux & Android!',
            isMe: false,
            time: '13:45',
            reactions: ['🔥'],
          ),
        ],
      ),
      ChatConversation(
        id: '3',
        name: 'Arena Hackathon Alpha',
        role: 'Team Room',
        avatarUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200',
        isOnline: true,
        lastMessage: 'Submissions are open! Lets review our live showdown demo.',
        time: '1h',
        unreadCount: 4,
        messages: [
          ChatMessage(
            id: 'a1',
            text: 'Submissions are open! Lets review our live showdown demo.',
            isMe: false,
            time: '12:30',
          ),
        ],
      ),
    ];
  }
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatConversation> get _conversations => ChatStateStore.instance.conversations;
  set _conversations(List<ChatConversation> list) => ChatStateStore.instance.conversations = list;

  String? get _selectedConversationId => ChatStateStore.instance.selectedConversationId;
  set _selectedConversationId(String? id) => ChatStateStore.instance.selectedConversationId = id;

  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _messagesScrollCtrl = ScrollController();
  String _searchQuery = '';
  ChatMessage? _replyingToMessage;
  String _activeWallpaper = 'obsidian';

  ChatWallpaperConfig get _defaultWallpaper => ChatStateStore.instance.defaultWallpaper;
  set _defaultWallpaper(ChatWallpaperConfig wp) => ChatStateStore.instance.defaultWallpaper = wp;

  // Out-chat Contacts List Wallpaper
  ChatWallpaperConfig get _contactsWallpaper => ChatStateStore.instance.contactsWallpaper;
  set _contactsWallpaper(ChatWallpaperConfig wp) => ChatStateStore.instance.contactsWallpaper = wp;

  bool _isExpanded = false;

  // Multi-Select Mode
  bool _isMultiSelectMode = false;
  final Set<String> _selectedMessageIds = {};

  // Text listener for mic vs send button toggle
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    if (widget.isExpanded != null) {
      _isExpanded = widget.isExpanded!;
    }
    _initMockConversations();
    _msgCtrl.addListener(() {
      final isNowTyping = _msgCtrl.text.trim().isNotEmpty;
      if (isNowTyping != _isTyping) {
        setState(() => _isTyping = isNowTyping);
      }
    });
    ChatStateStore.instance.selectedConversationNotifier.addListener(_onStoreConversationChanged);
    ChatStateStore.instance.conversationsUpdateNotifier.addListener(_onConversationsUpdated);
    _selectedConversationId = ChatStateStore.instance.selectedConversationId;
  }

  void _onConversationsUpdated() {
    if (mounted) setState(() {});
  }

  void _onStoreConversationChanged() {
    if (mounted && _selectedConversationId != ChatStateStore.instance.selectedConversationNotifier.value) {
      setState(() {
        _selectedConversationId = ChatStateStore.instance.selectedConversationNotifier.value;
      });
      widget.onActiveConversationChanged?.call(_selectedConversationId != null);
    }
  }


  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != null && widget.isExpanded != _isExpanded) {
      setState(() => _isExpanded = widget.isExpanded!);
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded && _selectedConversationId == null && _conversations.isNotEmpty) {
        _selectedConversationId = _conversations.first.id;
      }
    });
    widget.onToggleExpand?.call(_isExpanded);
  }

  void _initMockConversations() {
    ChatStateStore.instance.initDefaultConversations();
  }

  void _selectConversation(String? id) {
    if (id != null) {
      for (final c in _conversations) {
        if (c.id == id) {
          c.unreadCount = 0;
          break;
        }
      }
    }
    ChatStateStore.instance.selectConversation(id);
    setState(() {
      _selectedConversationId = id;
      _isMultiSelectMode = false;
      _selectedMessageIds.clear();
      _replyingToMessage = null;
    });
    widget.onActiveConversationChanged?.call(id != null);
  }


  ChatConversation? get _activeConversation {
    if (_selectedConversationId == null) return null;
    try {
      return _conversations.firstWhere((c) => c.id == _selectedConversationId);
    } catch (_) {
      return null;
    }
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _selectedConversationId == null) return;

    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      replyingTo: _replyingToMessage,
    );

    setState(() {
      final conv = _conversations.firstWhere((c) => c.id == _selectedConversationId);
      conv.messages.add(newMsg);
      _replyingToMessage = null;
    });

    _msgCtrl.clear();
    if (SupabaseService.isAuthenticated && _selectedConversationId != null) {
      SupabaseDataService.sendMessage(
        conversationId: _selectedConversationId!,
        text: text,
      );
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_messagesScrollCtrl.hasClients) {
        _messagesScrollCtrl.animateTo(
          _messagesScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _sendMediaMessage({
    required String mediaType,
    required String mediaUrl,
    String? caption,
  }) {
    final conv = _activeConversation;
    if (conv == null) return;

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newMsg = ChatMessage(
      id: newId,
      text: caption?.trim().isNotEmpty == true
          ? caption!.trim()
          : (mediaType == 'document' ? 'Shared document' : ''),
      isMe: true,
      time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      mediaCaption: caption?.trim(),
      isUploading: true,
      uploadProgress: 0.12,
      isDelivered: false,
    );

    setState(() {
      conv.messages.add(newMsg);
      _replyingToMessage = null;
    });

    // Auto-scroll to newly sent media
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_messagesScrollCtrl.hasClients) {
        _messagesScrollCtrl.animateTo(
          _messagesScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });

    // Staged realistic upload progress animation: 12% -> 42% -> 78% -> 95% -> 100%
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => newMsg.uploadProgress = 0.42);
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => newMsg.uploadProgress = 0.78);
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => newMsg.uploadProgress = 0.95);
    });
    Future.delayed(const Duration(milliseconds: 1850), () {
      if (mounted) {
        setState(() {
          newMsg.uploadProgress = 1.0;
          newMsg.isUploading = false;
          newMsg.isDelivered = true;
        });
      }
    });
  }

  // Multi-Select Actions
  void _starSelectedMessages() {
    final conv = _activeConversation;
    if (conv == null) return;
    final selected = conv.messages.where((m) => _selectedMessageIds.contains(m.id)).toList();
    final anyUnstarred = selected.any((m) => !m.isStarred);
    setState(() {
      for (final m in selected) {
        m.isStarred = anyUnstarred;
      }
      _isMultiSelectMode = false;
      _selectedMessageIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(anyUnstarred ? 'Messages starred' : 'Messages unstarred')),
    );
  }

  void _copySelectedMessages() {
    final conv = _activeConversation;
    if (conv == null) return;
    final selected = conv.messages.where((m) => _selectedMessageIds.contains(m.id)).toList();
    final buffer = StringBuffer();
    for (final m in selected) {
      final sender = m.isMe ? 'You' : conv.name;
      buffer.writeln('[$sender ${m.time}]: ${m.text}');
      if (m.mediaCaption != null && m.mediaCaption!.isNotEmpty) {
        buffer.writeln('Caption: ${m.mediaCaption}');
      }
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    setState(() {
      _isMultiSelectMode = false;
      _selectedMessageIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${selected.length} messages copied to clipboard')),
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
            final allList = _conversations;
            final currentId = _selectedConversationId;
            final candidates = allList
                .where((c) => c.id != currentId)
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
    final conv = _activeConversation;
    if (conv == null) return;
    final msgs = conv.messages
        .where((m) => _selectedMessageIds.contains(m.id))
        .toList();
    _forwardMessages(msgs);
  }

  void _forwardSingleMessage(ChatMessage msg) {
    _forwardMessages([msg]);
  }

  void _deleteSingleMessage(ChatMessage msg, {required bool forEveryone}) {
    setState(() {
      final conv = _activeConversation;
      if (conv != null) conv.messages.remove(msg);
      _selectedMessageIds.remove(msg.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(forEveryone ? 'Message deleted for everyone' : 'Message deleted for me')),
    );
  }

  void _deleteSelectedMessagesPrompt() {
    final count = _selectedMessageIds.length;
    if (count == 0) return;

    final conv = _activeConversation;
    if (conv == null) return;

    final selectedMsgs = conv.messages.where((m) => _selectedMessageIds.contains(m.id)).toList();
    final now = DateTime.now();
    // Only if all selected messages were sent by me AND sent within 24 hours, can delete for everyone
    final canDeleteForEveryone = selectedMsgs.isNotEmpty &&
        selectedMsgs.every((m) => m.isMe && now.difference(m.sentAt).inHours < 24);

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
                'Delete $count ${count == 1 ? 'Message' : 'Messages'}?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                canDeleteForEveryone
                    ? 'You can delete these messages for everyone or only for yourself.'
                    : 'Delete selected messages from your chat history?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              if (canDeleteForEveryone) ...[
                _buildGlassDeleteBtn(
                  title: 'Delete for everyone',
                  icon: LucideIcons.trash2,
                  color: const Color(0xFFFF5252),
                  isPrimary: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      conv.messages.removeWhere((m) => _selectedMessageIds.contains(m.id));
                      _selectedMessageIds.clear();
                      _isMultiSelectMode = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$count messages deleted for everyone')),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
              _buildGlassDeleteBtn(
                title: 'Delete for me',
                icon: LucideIcons.trash,
                color: canDeleteForEveryone ? Colors.white.withOpacity(0.9) : const Color(0xFFFF5252),
                isPrimary: !canDeleteForEveryone,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    conv.messages.removeWhere((m) => _selectedMessageIds.contains(m.id));
                    _selectedMessageIds.clear();
                    _isMultiSelectMode = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$count messages deleted for me')),
                  );
                },
              ),
              const SizedBox(height: 10),
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
      ),
    );
  }

  void _navigateToContactInfo(ChatConversation conv) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => ContactInfoScreen(
          contactName: conv.name,
          contactAvatar: conv.avatarUrl,
          contactHandle: '@${conv.name.toLowerCase().replaceAll(' ', '')} · ${conv.role}',
          isOnline: conv.isOnline,
          wallpaper: conv.customWallpaper ?? _defaultWallpaper,
        ),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            child: child,
          );
        },
      ),
    );
  }

  void _openMediaLinksDocsScreen(ChatConversation conv) {
    final List<MediaItem> sharedMedia = [];
    final List<DocItem> sharedDocs = [];
    final List<LinkItem> sharedLinks = [];

    for (final msg in conv.messages) {
      if (msg.mediaUrl != null && msg.mediaType != 'document') {
        sharedMedia.add(
          MediaItem(
            id: msg.id,
            title: msg.mediaCaption?.isNotEmpty == true
                ? msg.mediaCaption!
                : (msg.mediaType == 'video' ? 'Video Recording' : 'Chat Image'),
            url: msg.mediaUrl!,
            isVideo: msg.mediaType == 'video',
            videoDuration: msg.mediaType == 'video' ? '0:18' : null,
            dateGroup: 'SHARED IN CHAT',
            subtitle: '${msg.isMe ? "Sent by you" : conv.name} • ${msg.time}',
          ),
        );
      } else if (msg.mediaType == 'document' || (msg.mediaUrl != null && msg.mediaType == 'document')) {
        final docName = msg.mediaCaption?.isNotEmpty == true
            ? msg.mediaCaption!
            : (msg.text.isNotEmpty ? msg.text : 'Project_Doc.pdf');
        final ext = docName.contains('.') ? docName.split('.').last.toUpperCase() : 'PDF';
        sharedDocs.add(
          DocItem(
            id: msg.id,
            name: docName,
            extension: ext,
            size: '2.4 MB',
            date: msg.time,
            badgeColor: ext == 'PDF'
                ? const Color(0xFFFF5252)
                : (ext == 'JSON' ? const Color(0xFFFFD700) : const Color(0xFF54C5F8)),
          ),
        );
      }

      if (msg.text.contains('http://') || msg.text.contains('https://')) {
        final words = msg.text.split(RegExp(r'\s+'));
        for (final word in words) {
          if (word.startsWith('http://') || word.startsWith('https://')) {
            sharedLinks.add(
              LinkItem(
                id: 'link_${msg.id}_${word.hashCode}',
                title: word.replaceAll('https://', '').replaceAll('http://', '').split('/').first,
                url: word,
                description: 'Shared by ${msg.isMe ? "you" : conv.name} at ${msg.time}',
                icon: LucideIcons.link,
              ),
            );
          }
        }
      }
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => MediaLinksDocsScreen(
          contactName: conv.name,
          customMediaItems: sharedMedia.isNotEmpty ? sharedMedia : null,
          customDocItems: sharedDocs.isNotEmpty ? sharedDocs : null,
          customLinkItems: sharedLinks.isNotEmpty ? sharedLinks : null,
        ),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            child: child,
          );
        },
      ),
    );
  }

  // ── Long-Press Menu Anchored ON SPECIFIC MESSAGE (Liquid Glass Theme) ──────
  void _openMessageActionSheetOnBubble(ChatMessage msg, BuildContext bubbleContext) {
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

            // 1. Subtle glowing highlight outline around the selected message bubble
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
                              setState(() {
                                if (hasReacted) {
                                  msg.reactions.remove(emoji);
                                } else {
                                  msg.reactions = [emoji];
                                }
                              });
                              Navigator.pop(dialogCtx);
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
                            setState(() {
                              if (msg.reactions.contains('🚀')) {
                                msg.reactions.remove('🚀');
                              } else {
                                msg.reactions = ['🚀'];
                              }
                            });
                            Navigator.pop(dialogCtx);
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
                              _promptDeleteMessage(msg);
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
        : (accentColor ?? Colors.white.withOpacity(0.9));

    return SpringButton(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
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

  // ── Three-Dots Menu Modal (Wallpaper, Report, Block, Clear Chat) ───────────
  void _openThreeDotsMenu(ChatConversation conv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0D14).withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    _buildThreeDotOption(
                      icon: LucideIcons.user,
                      title: 'View contact',
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateToContactInfo(conv);
                      },
                    ),
                    _buildThreeDotOption(
                      icon: LucideIcons.image,
                      title: 'Media, links, and docs',
                      onTap: () {
                        Navigator.pop(ctx);
                        _openMediaLinksDocsScreen(conv);
                      },
                    ),
                    _buildThreeDotOption(
                      icon: LucideIcons.search,
                      title: 'Search in chat',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chat search active')),
                        );
                      },
                    ),
                    _buildThreeDotOption(
                      icon: LucideIcons.bellOff,
                      title: 'Mute notifications',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifications muted')),
                        );
                      },
                    ),
                    _buildThreeDotOption(
                      icon: LucideIcons.palette,
                      title: 'Chat Wallpaper',
                      onTap: () {
                        Navigator.pop(ctx);
                        _openWallpaperPicker(conv);
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.08), height: 16),
                    _buildThreeDotOption(
                      icon: LucideIcons.trash2,
                      title: 'Clear chat',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showConfirmDialog(
                          title: 'Clear Chat?',
                          message: 'All messages in this chat will be cleared permanently.',
                          confirmText: 'Clear Chat',
                          confirmColor: const Color(0xFFFF5252),
                          onConfirm: () {
                            setState(() => conv.messages.clear());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chat cleared')),
                            );
                          },
                        );
                      },
                    ),
                    _buildThreeDotOption(
                      icon: LucideIcons.ban,
                      title: 'Block ${conv.name}',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showConfirmDialog(
                          title: 'Block ${conv.name}?',
                          message: 'Blocked users cannot message or call you.',
                          confirmText: 'Block',
                          confirmColor: const Color(0xFFFF5252),
                          onConfirm: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${conv.name} blocked')),
                            );
                          },
                        );
                      },
                    ),
                    _buildThreeDotOption(
                      icon: LucideIcons.flag,
                      title: 'Report ${conv.name}',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Report submitted to CodeSnap Security team')),
                        );
                      },
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

  Widget _buildThreeDotOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFFF5252) : Colors.white;
    return SpringButton(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 14),
            Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── Wallpaper Picker Modal ────────────────────────────────────────────────
  void _openWallpaperPicker(ChatConversation conv) {
    final curatedPhotos = [
      {
        'id': 'p1',
        'name': 'Cyber Grid',
        'url': 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800',
      },
      {
        'id': 'p2',
        'name': 'Liquid Glass',
        'url': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
      },
      {
        'id': 'p3',
        'name': 'Deep Nebula',
        'url': 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=800',
      },
      {
        'id': 'p4',
        'name': 'Midnight Neon',
        'url': 'https://images.unsplash.com/photo-1519501025264-65ba15a82390?w=800',
      },
      {
        'id': 'p5',
        'name': 'Terminal Flow',
        'url': 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800',
      },
      {
        'id': 'p6',
        'name': 'Dark Minimal',
        'url': 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800',
      },
    ];

    final glassGradients = [
      {
        'id': 'g1',
        'name': 'Cyber Neon',
        'colors': [const Color(0xFF0F172A), const Color(0xFF0C1929), const Color(0xFF1E112A)],
      },
      {
        'id': 'g2',
        'name': 'Aurora Emerald',
        'colors': [const Color(0xFF051B17), const Color(0xFF07241C), const Color(0xFF0B1220)],
      },
      {
        'id': 'g3',
        'name': 'Sunset Blaze',
        'colors': [const Color(0xFF200E14), const Color(0xFF170C1E), const Color(0xFF0D0B16)],
      },
      {
        'id': 'g4',
        'name': 'Deep Abyss',
        'colors': [const Color(0xFF060B14), const Color(0xFF0A1526), const Color(0xFF05080E)],
      },
    ];

    final solidColors = [
      {'id': 'obsidian', 'name': 'Obsidian Void', 'color': const Color(0xFF07080A)},
      {'id': 'midnight', 'name': 'Midnight Slate', 'color': const Color(0xFF0E131C)},
      {'id': 'matrix', 'name': 'Cyber Terminal', 'color': const Color(0xFF07140E)},
      {'id': 'nebula', 'name': 'Cosmic Nebula', 'color': const Color(0xFF140A1E)},
      {'id': 'carbon', 'name': 'Steel Carbon', 'color': const Color(0xFF13151A)},
      {'id': 'black', 'name': 'Pure AMOLED', 'color': const Color(0xFF000000)},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (pickerCtx) {
        final currentWpId = conv.customWallpaper?.id ?? _defaultWallpaper.id;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
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
                              style: TextStyle(color: const Color(0xFF54C5F8).withOpacity(0.9), fontSize: 12),
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

                    // 1. Choose from Device Gallery / Photos Card
                    SpringButton(
                      onTap: () async {
                        try {
                          final result = await getStoragePicker().pickImage();
                          if (result != null) {
                            Navigator.pop(pickerCtx);
                            _openWallpaperAdjustSheet(
                              conv,
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
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF54C5F8).withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                    'Pick local photo, adjust blur & dimming',
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
                    // 2. Curated Wallpapers (Photos)
                    const Text(
                      'Curated Art & Photos',
                      style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
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
                      itemCount: curatedPhotos.length,
                      itemBuilder: (context, i) {
                        final p = curatedPhotos[i];
                        final isSel = currentWpId == p['id'];
                        return SpringButton(
                          onTap: () {
                            Navigator.pop(pickerCtx);
                            _openWallpaperAdjustSheet(
                              conv,
                              ChatWallpaperConfig(
                                id: p['id']!,
                                name: p['name']!,
                                type: 'image',
                                imageUrl: p['url']!,
                                blur: 1.5,
                                opacity: 0.75,
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSel ? const Color(0xFF54C5F8) : Colors.white.withOpacity(0.15),
                                  width: isSel ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    p['url']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.white10),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                      ),
                                    ),
                                  ),
                                  if (isSel)
                                    const Center(
                                      child: Icon(LucideIcons.check, color: Color(0xFF54C5F8), size: 24),
                                    ),
                                  Positioned(
                                    bottom: 6,
                                    left: 6,
                                    right: 6,
                                    child: Text(
                                      p['name']!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    // 3. Liquid Glass Gradients
                    const Text(
                      'Liquid Glass Gradients',
                      style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: glassGradients.length,
                      itemBuilder: (context, i) {
                        final g = glassGradients[i];
                        final colors = g['colors'] as List<Color>;
                        final isSel = currentWpId == g['id'];

                        return SpringButton(
                          onTap: () {
                            Navigator.pop(pickerCtx);
                            _openWallpaperAdjustSheet(
                              conv,
                              ChatWallpaperConfig(
                                id: g['id'] as String,
                                name: g['name'] as String,
                                type: 'gradient',
                                gradientColors: colors,
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: colors,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel ? const Color(0xFF54C5F8) : Colors.white.withOpacity(0.18),
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Text(
                                  g['name'] as String,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                if (isSel)
                                  const Icon(LucideIcons.check, color: Color(0xFF54C5F8), size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    // 4. Solid Dark Themes
                    const Text(
                      'Solid Minimalist Darks',
                      style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
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
                        final isSel = currentWpId == s['id'];

                        return SpringButton(
                          onTap: () {
                            Navigator.pop(pickerCtx);
                            _openWallpaperAdjustSheet(
                              conv,
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
                              border: Border.all(
                                color: isSel ? const Color(0xFF54C5F8) : Colors.white.withOpacity(0.15),
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                s['name'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSel ? const Color(0xFF54C5F8) : Colors.white70,
                                  fontSize: 10.5,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Open Wallpaper Adjust Modal Sheet ─────────────────────────────────────
  void _openWallpaperAdjustSheet(ChatConversation conv, ChatWallpaperConfig config) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (adjustCtx) {
        return _WallpaperAdjustSheet(
          conv: conv,
          wallpaper: config,
          onApply: (appliedConfig, forAllChats) {
            setState(() {
              if (forAllChats) {
                _defaultWallpaper = appliedConfig;
                for (final c in _conversations) {
                  c.customWallpaper = appliedConfig;
                }
              } else {
                conv.customWallpaper = appliedConfig;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  forAllChats
                      ? 'Wallpaper applied to all chats'
                      : 'Wallpaper set for ${conv.name}',
                ),
              ),
            );
          },
        );
      },
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
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(message, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmColor.withOpacity(0.2),
                          foregroundColor: confirmColor,
                          side: BorderSide(color: confirmColor.withOpacity(0.5)),
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

  void _showMessageInfo(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.18),
                  const Color(0xFF1E283C).withOpacity(0.70),
                  const Color(0xFF101420).withOpacity(0.85),
                ],
              ),
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



  void _promptDeleteMessage(ChatMessage msg) {
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
                      _deleteSingleMessage(msg, forEveryone: true);
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
                    _deleteSingleMessage(msg, forEveryone: false);
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

  @override
  void dispose() {
    ChatStateStore.instance.selectedConversationNotifier.removeListener(_onStoreConversationChanged);
    ChatStateStore.instance.conversationsUpdateNotifier.removeListener(_onConversationsUpdated);
    _msgCtrl.dispose();
    _messagesScrollCtrl.dispose();
    super.dispose();
  }


  Color _getWallpaperColor() {
    return _defaultWallpaper.solidColor ?? const Color(0xFF07080A);
  }

  @override
  Widget build(BuildContext context) {
    if (_isExpanded) {
      final activeConv = _activeConversation ?? (_conversations.isNotEmpty ? _conversations.first : null);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Contacts List with Contacts Wallpaper
          SizedBox(
            width: 380,
            child: _buildConversationList(),
          ),
          // Clean glass divider
          Container(
            width: 1,
            color: Colors.white.withOpacity(0.12),
          ),
          // Right: Active Conversation with In-Chat Wallpaper
          Expanded(
            child: activeConv != null
                ? IndividualChatScreen(
                    key: ValueKey('chat_${activeConv.id}'),
                    conversation: activeConv,
                    defaultWallpaper: _defaultWallpaper,
                    allConversations: _conversations,
                    isEmbedded: true,
                    onBack: () => _selectConversation(null),
                    onWallpaperUpdated: (newWp) {
                      setState(() => activeConv.customWallpaper = newWp);
                    },
                  )
                : _buildEmptyChatPlaceholder(),
          ),
        ],
      );
    }

    final conv = _activeConversation;
    if (conv != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_isMultiSelectMode) {
            setState(() {
              _isMultiSelectMode = false;
              _selectedMessageIds.clear();
            });
            return;
          }
          _selectConversation(null);
        },
        child: IndividualChatScreen(
          conversation: conv,
          defaultWallpaper: _defaultWallpaper,
          allConversations: _conversations,
          isEmbedded: widget.isEmbedded,
          onBack: () => _selectConversation(null),
          onWallpaperUpdated: (newWp) {
            setState(() => conv.customWallpaper = newWp);
          },
        ),
      );
    }

    return _buildConversationList();
  }

  Widget _buildEmptyChatPlaceholder() {
    return Container(
      color: const Color(0xFF07080A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(LucideIcons.messageSquare, size: 36, color: Color(0xFF54C5F8)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a conversation',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a teammate from the left to start chatting',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  void _onContactTapped(ChatConversation c) {
    c.unreadCount = 0;
    _selectConversation(c.id);
  }

  // ── Conversation List View (Contacts with Custom Wallpaper) ─────────────────
  Widget _buildConversationList() {
    final filtered = _conversations.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Out-chat contacts wallpaper
        buildWallpaperBackground(_contactsWallpaper),
        SafeArea(
          top: !widget.isEmbedded,
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildSearchBar(),
              ),
              _buildOnlineTeammates(),
              const Divider(color: Color(0x1AFFFFFF), height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    return _buildConversationItem(c);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Icon(LucideIcons.messageSquare, color: Color(0xFF54C5F8), size: 20),
          const SizedBox(width: 10),
          Text(
            'Developer Chat',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          // 1. Expand button beside 3-dots (only on desktop/tablet >= 768px, hidden on mobile)
          if (MediaQuery.of(context).size.width >= 768) ...[
            SpringButton(
              onTap: _toggleExpand,
              child: Container(
                padding: const EdgeInsets.all(7.5),
                decoration: BoxDecoration(
                  color: _isExpanded ? const Color(0xFF54C5F8).withOpacity(0.18) : Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isExpanded ? const Color(0xFF54C5F8).withOpacity(0.6) : Colors.white.withOpacity(0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isExpanded ? const Color(0xFF54C5F8).withOpacity(0.25) : Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _isExpanded ? LucideIcons.minimize2 : LucideIcons.maximize2,
                  color: _isExpanded ? const Color(0xFF54C5F8) : Colors.white,
                  size: 17,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 2. 3-dots button (Settings, Wallpaper for contacts, Clear chats)
          SpringButton(
            onTap: _openContactsMenu,
            child: Container(
              padding: const EdgeInsets.all(7.5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(LucideIcons.moreVertical, color: Colors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  void _openContactsMenu() {
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
              _buildSheetMenuTile(LucideIcons.image, 'Wallpaper', 'Change background for contacts list', () {
                Navigator.pop(ctx);
                _openContactsWallpaperPicker();
              }),
              _buildSheetMenuTile(LucideIcons.settings, 'Settings', 'Preferences, notifications, storage', () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatSettingsScreen(
                      onOpenWallpaperPicker: () {
                        _openContactsWallpaperPicker();
                      },
                      onClearAllChats: () {
                        setState(() {
                          for (final c in _conversations) {
                            c.messages.clear();
                          }
                        });
                      },
                    ),
                  ),
                );
              }),
              _buildSheetMenuTile(LucideIcons.trash2, 'Clear All Chats', 'Delete all conversation messages', () {
                Navigator.pop(ctx);
                setState(() {
                  for (final c in _conversations) {
                    c.messages.clear();
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All chat messages cleared')),
                );
              }, isDestructive: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false}) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDestructive ? const Color(0xFFFF5252).withOpacity(0.08) : Colors.white.withOpacity(0.04),
          border: Border.all(color: isDestructive ? const Color(0xFFFF5252).withOpacity(0.2) : Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? const Color(0xFFFF5252).withOpacity(0.15) : const Color(0xFF54C5F8).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: isDestructive ? const Color(0xFFFF5252) : const Color(0xFF54C5F8)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? const Color(0xFFFF5252) : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: Colors.white.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  void _openContactsWallpaperPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (pickerCtx) {
        return _buildContactsWallpaperPickerSheet(pickerCtx);
      },
    );
  }

  Widget _buildContactsWallpaperPickerSheet(BuildContext pickerCtx) {
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contacts Wallpaper',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Shows behind contacts list (out-chat)',
                        style: TextStyle(color: Color(0xFF54C5F8), fontSize: 12),
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

              // 1. Choose from Device Gallery
              SpringButton(
                onTap: () async {
                  try {
                    final result = await getStoragePicker().pickImage();
                    if (result != null) {
                      Navigator.pop(pickerCtx);
                      _openAdjustSheetForContacts(
                        ChatWallpaperConfig(
                          id: 'contacts_custom_${DateTime.now().millisecondsSinceEpoch}',
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
                              'Pick local photo for contacts background',
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

              const SizedBox(height: 10),
              SpringButton(
                onTap: () {
                  setState(() {
                    _contactsWallpaper = const ChatWallpaperConfig(
                      id: 'contacts_obsidian',
                      name: 'Obsidian Void',
                      type: 'solid',
                      solidColor: Color(0xFF07080A),
                    );
                  });
                  Navigator.pop(pickerCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contacts wallpaper reset to default')),
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
                      Text('Reset Contacts Wallpaper to Default', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.5)),
                    ],
                  ),
                ),
              ),

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
                      _openAdjustSheetForContacts(
                        ChatWallpaperConfig(
                          id: 'contacts_curated_$i',
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
                      _openAdjustSheetForContacts(
                        ChatWallpaperConfig(
                          id: 'contacts_grad_$i',
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
                      _openAdjustSheetForContacts(
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

  void _openAdjustSheetForContacts(ChatWallpaperConfig config) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (adjustCtx) {
        return WallpaperAdjustSheet(
          wallpaper: config,
          isForContacts: true,
          onApply: (appliedConfig, _) {
            setState(() {
              _contactsWallpaper = appliedConfig;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contacts wallpaper updated!')),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: 'Search teammates, repos, topics...',
          hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.45), fontSize: 12),
          prefixIcon: const Icon(LucideIcons.search, size: 16, color: Colors.white60),
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildOnlineTeammates() {
    final online = _conversations.where((c) => c.isOnline).toList();
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: online.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = online[i];
          return SpringButton(
            onTap: () => _onContactTapped(c),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(c.avatarUrl),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF09090B), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  c.name.split(' ').first,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationItem(ChatConversation c) {
    final isSelectedInSplit = _isExpanded && _selectedConversationId == c.id;

    return SpringButton(
      onTap: () => _onContactTapped(c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelectedInSplit ? const Color(0xFF54C5F8).withOpacity(0.14) : const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelectedInSplit ? const Color(0xFF54C5F8).withOpacity(0.65) : const Color(0x1AFFFFFF),
            width: isSelectedInSplit ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(c.avatarUrl),
                ),
                if (c.isAiAssistant)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0F18),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                      ),
                      child: const Icon(LucideIcons.terminal, size: 9, color: Color(0xFFFFD700)),
                    ),
                  ),
                if (c.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF09090B), width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (c.isAiAssistant) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.55), width: 0.8),
                                ),
                                child: const Text(
                                  'SERVER AI',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.time,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF666677),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: c.unreadCount > 0 ? const Color(0xFFDDDDFF) : const Color(0xFF888899),
                            fontSize: 12,
                            fontWeight: c.unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (c.unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF54C5F8),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${c.unreadCount}',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Conversation Detail Screen (Exact Image Theme) ─────────────────────────
  Widget _buildConversationDetail(ChatConversation c) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Live Wallpaper Background for this specific chat
        _buildWallpaperBackground(c),

        SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Bar: Switches between Normal Sleek Glass Bar and Multi-Select Bar
              if (_isMultiSelectMode)
                _buildMultiSelectTopBar(c)
              else
                _buildNormalTopBar(c),

              // 2. Message Stream with "Today" pill
              Expanded(
                child: ListView.builder(
                  controller: _messagesScrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  itemCount: c.messages.length + 1,
                  itemBuilder: (context, index) {
                    // Render "Today" capsule divider in the middle
                    if (index == 5) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.10),
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
                            ),
                          ),
                        ),
                      );
                    }

                    final msgIndex = index > 5 ? index - 1 : index;
                    final msg = c.messages[msgIndex];

                    return _buildMessageBubbleRow(msg);
                  },
                ),
              ),

              // Replying banner preview (if active)
              if (_replyingToMessage != null) _buildReplyingBanner(),

              // 3. Sleek Bottom Input Pill (from Image Theme)
              _buildBottomInputBar(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWallpaperBackground(ChatConversation c) {
    final wallpaper = c.customWallpaper ?? _defaultWallpaper;

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

  // Normal Floating Liquid Glass App Bar
  Widget _buildNormalTopBar(ChatConversation c) {
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
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SpringButton(
                  onTap: () => _selectConversation(null),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(LucideIcons.chevronLeft, size: 22, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: SpringButton(
                    onTap: () => _navigateToContactInfo(c),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search active')),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(LucideIcons.search, size: 19, color: Colors.white),
                  ),
                ),
                SpringButton(
                  onTap: () => _openThreeDotsMenu(c),
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

  // Multi-Select Action Top Bar (Liquid Glass Glow)
  Widget _buildMultiSelectTopBar(ChatConversation c) {
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
              onTap: count > 0 ? () => _starSelectedMessages() : null,
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
              onTap: count > 0 ? () => _copySelectedMessages() : null,
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
              onTap: count > 0 ? () => _forwardSelectedMessages() : null,
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
              onTap: count > 0 ? () => _deleteSelectedMessagesPrompt() : null,
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
                    msg.isMe ? 'You' : 'Teammate',
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

  // ── Message Bubble Row with Dismissible Swipe Left (Reply) & Right (Delete) ─
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
                        color: isSelected ? const Color(0xFF54C5F8) : Colors.white38,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF54C5F8).withOpacity(0.4),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(LucideIcons.check, size: 14, color: Colors.black),
                          )
                        : null,
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

        return Align(
          alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Dismissible(
            key: ValueKey('msg_${msg.id}'),
            direction: DismissDirection.horizontal,
            // Swipe Right (startToEnd) -> Delete
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 12, bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5252).withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFFF5252)),
              ),
            ),
            // Swipe Left (endToStart) -> Reply
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 12, bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF54C5F8).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF54C5F8).withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.reply, size: 18, color: Color(0xFF54C5F8)),
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // Swiped Right -> Delete Option Sheet
                HapticFeedback.mediumImpact();
                _promptDeleteMessage(msg);
                return false;
              } else if (direction == DismissDirection.endToStart) {
                // Swiped Left -> Reply Option
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

  // Message Bubble Appearance with Media & Upload Animation
  Widget _buildBubbleContent(ChatMessage msg) {
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(msg.isMe ? 18 : 4),
      bottomRight: Radius.circular(msg.isMe ? 4 : 18),
    );

    return Column(
      crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            // Sent: Crystal clear liquid glass white shade (exact match to preview)
            // Received: Subtle translucent liquid glass white shade (exact match to preview)
            gradient: msg.isMe
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.26),
                      Colors.white.withOpacity(0.14),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.14),
                      Colors.white.withOpacity(0.07),
                    ],
                  ),
            borderRadius: bubbleRadius,
            border: Border.all(
              color: msg.isMe
                  ? Colors.white.withOpacity(0.30)
                  : Colors.white.withOpacity(0.18),
              width: 1.1,
            ),
            boxShadow: [
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
                      const Text(
                        'Replied to',
                        style: TextStyle(
                          color: Color(0xFF54C5F8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        msg.replyingTo!.mediaCaption?.isNotEmpty == true
                            ? msg.replyingTo!.mediaCaption!
                            : (msg.replyingTo!.text.isNotEmpty
                                ? msg.replyingTo!.text
                                : 'Media attachment'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Media Preview Card (Image, Video, Document) with Upload Progress ─
              if (msg.mediaUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (msg.mediaType == 'document')
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF54C5F8).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.fileText, color: Color(0xFF54C5F8), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.mediaCaption?.isNotEmpty == true ? msg.mediaCaption! : 'Project_Doc.pdf',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '2.4 MB · PDF Document',
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.download, color: Colors.white70, size: 18),
                            ],
                          ),
                        )
                      else if (msg.mediaUrl!.startsWith('data:image'))
                        Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          width: double.infinity,
                          child: Image.memory(
                            base64Decode(msg.mediaUrl!.split(',').last),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 140,
                              color: Colors.white10,
                              child: const Center(
                                child: Icon(LucideIcons.image, color: Colors.white38, size: 36),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          width: double.infinity,
                          child: Image.network(
                            msg.mediaUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                height: 160,
                                color: Colors.black26,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF54C5F8))),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              height: 140,
                              color: Colors.white10,
                              child: const Center(
                                child: Icon(LucideIcons.image, color: Colors.white38, size: 36),
                              ),
                            ),
                          ),
                        ),

                      // Video Play button overlay
                      if (msg.mediaType == 'video' && !msg.isUploading)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.4)),
                          ),
                          child: const Icon(LucideIcons.play, color: Colors.white, size: 24),
                        ),

                      // Video duration chip
                      if (msg.mediaType == 'video' && !msg.isUploading)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('0:18', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ),

                      // Uploading Animation Overlay with percentage
                      if (msg.isUploading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.65),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: CircularProgressIndicator(
                                            value: msg.uploadProgress,
                                            strokeWidth: 3.5,
                                            backgroundColor: Colors.white24,
                                            valueColor: const AlwaysStoppedAnimation(Color(0xFF54C5F8)),
                                          ),
                                        ),
                                        Text(
                                          '${(msg.uploadProgress * 100).toInt()}%',
                                          style: const TextStyle(
                                            color: Color(0xFF54C5F8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Uploading media...',
                                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (msg.mediaCaption != null && msg.mediaCaption!.isNotEmpty && msg.mediaType != 'document') ...[
                  const SizedBox(height: 6),
                  Text(
                    msg.mediaCaption!,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5, height: 1.3),
                  ),
                ],
                const SizedBox(height: 4),
              ],

              // Message Body Text (if not redundant with caption)
              if (msg.text.isNotEmpty && msg.text != msg.mediaCaption && msg.mediaType != 'document') ...[
                Text(
                  msg.text,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],

              // Code Snippet (if any)
              if (msg.codeSnippet != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09090B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Text(
                    msg.codeSnippet!,
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF98C379),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),

              // Timestamp & Status (Spinner / Checkmark)
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (msg.isStarred)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(LucideIcons.star, size: 11, color: Color(0xFFFFD700)),
                    ),
                  if (msg.isPinned)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(LucideIcons.pin, size: 11, color: Color(0xFF54C5F8)),
                    ),
                  Text(
                    msg.time,
                    style: TextStyle(
                      color: Colors.white.withOpacity(msg.isMe ? 0.65 : 0.45),
                      fontSize: 10.5,
                    ),
                  ),
                  if (msg.isMe) ...[
                    const SizedBox(width: 4),
                    if (msg.isUploading)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF54C5F8)),
                        ),
                      )
                    else
                      Text(
                        '...',
                        style: TextStyle(
                          color: msg.isDelivered ? const Color(0xFF54C5F8) : Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Reaction Badge (if any)
        if (msg.reactions.isNotEmpty)
          Transform.translate(
            offset: const Offset(0, -6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.28)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(msg.reactions.join(' '), style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${msg.reactions.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Bottom Message Input Bar (Liquid Glass Capsule & Mic) ───────────────────
  Widget _buildBottomInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
        child: Row(
          children: [
            // Main Glass Capsule Container
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
                    // Attachment paperclip
                    SpringButton(
                      onTap: () {
                        _showAttachmentOptions();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(LucideIcons.paperclip, size: 20, color: Colors.white.withOpacity(0.85)),
                      ),
                    ),
                    // Emoji icon
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
                    // Text input
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
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.18),
                  const Color(0xFF1E283C).withOpacity(0.70),
                  const Color(0xFF101420).withOpacity(0.85),
                ],
              ),
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
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF54C5F8).withOpacity(0.12),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF54C5F8)),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Native Internal Device Storage Picker (Camera / Gallery / Video / Docs) ──
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

  // ── Open Media Preview & Editor Sheet ─────────────────────────────────────
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
        return _MediaEditorSheet(
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
}

/// ─── Interactive Liquid Glass Media Editor Sheet ───────────────────────────
class _MediaEditorSheet extends StatefulWidget {
  final String mediaType;
  final String mediaUrl;
  final String mediaTitle;
  final String? initialCaption;
  final Function(String type, String url, String? caption, String filterName) onSend;

  const _MediaEditorSheet({
    required this.mediaType,
    required this.mediaUrl,
    required this.mediaTitle,
    this.initialCaption,
    required this.onSend,
  });

  @override
  State<_MediaEditorSheet> createState() => _MediaEditorSheetState();
}

class _MediaEditorSheetState extends State<_MediaEditorSheet> {
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

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0E17).withOpacity(0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 32,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Drag Handle & Title Bar
            Row(
              children: [
                SpringButton(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: const Icon(LucideIcons.x, size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.mediaTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF54C5F8).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.35)),
                  ),
                  child: Text(
                    widget.mediaType.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF54C5F8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live Media Preview Frame
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    if (widget.mediaType == 'document')
                      Container(
                        color: Colors.white.withOpacity(0.06),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF54C5F8).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.3)),
                                ),
                                child: const Icon(LucideIcons.fileText, color: Color(0xFF54C5F8), size: 48),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                widget.mediaTitle,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '2.4 MB · Project Document',
                                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ColorFiltered(
                        colorFilter: _filters[_selectedFilter] ??
                            const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                        child: widget.mediaUrl.startsWith('data:image')
                            ? Image.memory(
                                base64Decode(widget.mediaUrl.split(',').last),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.black26,
                                  child: const Center(child: Icon(LucideIcons.image, size: 48, color: Colors.white38)),
                                ),
                              )
                            : Image.network(
                                widget.mediaUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.black26,
                                  child: const Center(child: Icon(LucideIcons.image, size: 48, color: Colors.white38)),
                                ),
                              ),
                      ),

                    // Video Play Badge
                    if (widget.mediaType == 'video')
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(LucideIcons.play, color: Colors.white, size: 32),
                      ),

                    // Sticker / Badge Overlay
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
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF54C5F8).withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            _selectedBadge!,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips (Only for images/videos)
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
                              width: 1.2,
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
                      onTap: () {
                        setState(() {
                          _selectedBadge = isSelected ? null : bName;
                        });
                      },
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

            // Bottom Caption Input & Send Pill
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
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13.5),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SpringButton(
                  onTap: () {
                    final caption = _captionCtrl.text.trim();
                    Navigator.pop(context);
                    widget.onSend(
                      widget.mediaType,
                      widget.mediaUrl,
                      caption.isNotEmpty ? caption : null,
                      _selectedFilter,
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF54C5F8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF54C5F8).withOpacity(0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.send, size: 20, color: Colors.black),
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
}

/// ─── Interactive Wallpaper Adjust & Preview Sheet ───────────────────────────
class _WallpaperAdjustSheet extends StatefulWidget {
  final ChatConversation conv;
  final ChatWallpaperConfig wallpaper;
  final Function(ChatWallpaperConfig config, bool forAllChats) onApply;

  const _WallpaperAdjustSheet({
    required this.conv,
    required this.wallpaper,
    required this.onApply,
  });

  @override
  State<_WallpaperAdjustSheet> createState() => _WallpaperAdjustSheetState();
}

class _WallpaperAdjustSheetState extends State<_WallpaperAdjustSheet> {
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

  void _resetPlacement() {
    setState(() {
      _scale = 1.0;
      _alignmentX = 0.0;
      _alignmentY = 0.0;
    });
  }

  void _nudge({double dx = 0.0, double dy = 0.0}) {
    setState(() {
      _alignmentX = (_alignmentX + dx).clamp(-1.8, 1.8);
      _alignmentY = (_alignmentY + dy).clamp(-1.8, 1.8);
    });
  }

  Widget _buildPreviewBackground() {
    final wp = widget.wallpaper;
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
              final dx = _alignmentX * (w * 0.5);
              final dy = _alignmentY * (h * 0.5);
              return ClipRect(
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.scale(
                    scale: _scale,
                    alignment: Alignment.center,
                    child: SizedBox.expand(child: imageWidget),
                  ),
                ),
              );
            },
          ),
          if (_blur > 0.1)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
              child: const SizedBox.expand(),
            ),
          Container(
            color: Colors.black.withOpacity((1.0 - _opacity).clamp(0.0, 0.95)),
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
      return Container(color: wp.solidColor ?? const Color(0xFF07080A));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImageType = widget.wallpaper.type == 'image';
    final screenH = MediaQuery.of(context).size.height;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        constraints: BoxConstraints(maxHeight: screenH * 0.88),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0D14).withOpacity(0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adjust Wallpaper',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Target chat: ${widget.conv.name}',
                          style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 12),
                        ),
                      ],
                    ),
                    SpringButton(
                      onTap: () => Navigator.pop(context),
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
                const SizedBox(height: 12),

                // Live Preview Frame with Sample Chat Bubbles + Pan Drag Reposition
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 195,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Interactive Drag Pan Layer
                        GestureDetector(
                          onPanUpdate: isImageType
                              ? (details) {
                                  setState(() {
                                    _alignmentX = (_alignmentX + details.delta.dx / 100.0).clamp(-1.8, 1.8);
                                    _alignmentY = (_alignmentY + details.delta.dy / 85.0).clamp(-1.8, 1.8);
                                  });
                                }
                              : null,
                          child: _buildPreviewBackground(),
                        ),

                        // Sample Chat Bubbles (Non-interactive preview)
                        IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Partner Bubble (Received)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                    constraints: const BoxConstraints(maxWidth: 240),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.14),
                                          Colors.white.withOpacity(0.07),
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                                    ),
                                    child: const Text(
                                      'How does the new wallpaper look behind our code chat?',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // My Bubble (Sent)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                    constraints: const BoxConstraints(maxWidth: 240),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.26),
                                          Colors.white.withOpacity(0.14),
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: const Text(
                                      'Crystal clear! The liquid glass shade is perfect 🔥',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Helpful floating drag tip pill
                        if (isImageType)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withOpacity(0.15)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.move, size: 11, color: Colors.white.withOpacity(0.85)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Drag to Pan',
                                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                if (isImageType) ...[
                  const SizedBox(height: 14),

                  // Tab switcher between "Size & Position" and "Effects & Dim"
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SpringButton(
                            onTap: () => setState(() => _activeTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _activeTab == 0 ? const Color(0xFF54C5F8) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.move,
                                    size: 14,
                                    color: _activeTab == 0 ? Colors.black : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Size & Placement',
                                    style: TextStyle(
                                      color: _activeTab == 0 ? Colors.black : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SpringButton(
                            onTap: () => setState(() => _activeTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _activeTab == 1 ? const Color(0xFF54C5F8) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.sliders,
                                    size: 14,
                                    color: _activeTab == 1 ? Colors.black : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Dimming & Blur',
                                    style: TextStyle(
                                      color: _activeTab == 1 ? Colors.black : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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

                  const SizedBox(height: 12),

                  // TAB 0: Size & Placement (Left, Right, Top, Down, Zoom)
                  if (_activeTab == 0) ...[
                    // 1. Zoom / Size Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.zoomIn, size: 15, color: Color(0xFF54C5F8)),
                            const SizedBox(width: 8),
                            const Text('Wallpaper Size (Zoom)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(
                          '${(_scale * 100).toInt()}%',
                          style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF54C5F8),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: Colors.white,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _scale,
                        min: 0.5,
                        max: 3.0,
                        onChanged: (val) => setState(() => _scale = val),
                      ),
                    ),

                    // Quick zoom presets
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [0.75, 1.0, 1.4, 1.8, 2.4].map((preset) {
                        final isSel = (_scale - preset).abs() < 0.08;
                        return SpringButton(
                          onTap: () => setState(() => _scale = preset),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF54C5F8).withOpacity(0.2) : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSel ? const Color(0xFF54C5F8) : Colors.white12),
                            ),
                            child: Text(
                              preset == 0.75 ? 'Fit' : '${(preset * 100).toInt()}%',
                              style: TextStyle(
                                color: isSel ? const Color(0xFF54C5F8) : Colors.white70,
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // 2. Horizontal Placement (Left / Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.arrowLeft, size: 14, color: Color(0xFF54C5F8)),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.arrowRight, size: 14, color: Color(0xFF54C5F8)),
                            const SizedBox(width: 8),
                            const Text('Horizontal (Left / Right)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(
                          _alignmentX.abs() < 0.04
                              ? 'Center'
                              : _alignmentX < 0
                                  ? '${(-_alignmentX * 100).toInt()}% Left'
                                  : '${(_alignmentX * 100).toInt()}% Right',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF54C5F8),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: Colors.white,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _alignmentX,
                        min: -1.5,
                        max: 1.5,
                        onChanged: (val) => setState(() => _alignmentX = val),
                      ),
                    ),

                    // 3. Vertical Placement (Top / Down)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.arrowUp, size: 14, color: Color(0xFF54C5F8)),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.arrowDown, size: 14, color: Color(0xFF54C5F8)),
                            const SizedBox(width: 8),
                            const Text('Vertical (Top / Down)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(
                          _alignmentY.abs() < 0.04
                              ? 'Center'
                              : _alignmentY < 0
                                  ? '${(-_alignmentY * 100).toInt()}% Top'
                                  : '${(_alignmentY * 100).toInt()}% Down',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF54C5F8),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: Colors.white,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _alignmentY,
                        min: -1.5,
                        max: 1.5,
                        onChanged: (val) => setState(() => _alignmentY = val),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 4. Directional Nudge Pad & Center Reset
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quick Nudge & Reset',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              _buildNudgeBtn(LucideIcons.arrowLeft, () => _nudge(dx: -0.1)),
                              const SizedBox(width: 6),
                              _buildNudgeBtn(LucideIcons.arrowUp, () => _nudge(dy: -0.1)),
                              const SizedBox(width: 6),
                              _buildNudgeBtn(LucideIcons.arrowDown, () => _nudge(dy: 0.1)),
                              const SizedBox(width: 6),
                              _buildNudgeBtn(LucideIcons.arrowRight, () => _nudge(dx: 0.1)),
                              const SizedBox(width: 10),
                              SpringButton(
                                onTap: _resetPlacement,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.rotateCcw, size: 12, color: Colors.white.withOpacity(0.9)),
                                      const SizedBox(width: 4),
                                      Text('Reset', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // TAB 1: Dimming & Blur
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.sunMedium, size: 16, color: Color(0xFF54C5F8)),
                            const SizedBox(width: 8),
                            const Text('Background Dimming', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(
                          '${((1.0 - _opacity) * 100).toInt()}% Dark',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF54C5F8),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: Colors.white,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _opacity,
                        min: 0.20,
                        max: 1.0,
                        onChanged: (val) => setState(() => _opacity = val),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Blur Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.droplets, size: 16, color: Color(0xFF54C5F8)),
                            const SizedBox(width: 8),
                            const Text('Frosted Glass Blur', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(
                          '${_blur.toStringAsFixed(1)} px',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF54C5F8),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: Colors.white,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _blur,
                        min: 0.0,
                        max: 18.0,
                        onChanged: (val) => setState(() => _blur = val),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 16),
                // Action Buttons
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
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF54C5F8).withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Apply to ${widget.conv.name}',
                        style: const TextStyle(color: Colors.black, fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SpringButton(
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
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: const Center(
                            child: Text(
                              'Set for all chats',
                              style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNudgeBtn(IconData icon, VoidCallback onTap) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Center(
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}
