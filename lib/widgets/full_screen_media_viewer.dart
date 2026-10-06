import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/theme_provider.dart';
import '../screens/chat_screen.dart';
import 'morphing_capsule.dart';
import 'spring_button.dart';

class FullScreenMediaViewer extends StatefulWidget {
  final ChatMessage message;
  final String senderName;
  final String senderAvatar;
  final VoidCallback? onShowInChat;
  final VoidCallback? onShare;

  const FullScreenMediaViewer({
    super.key,
    required this.message,
    required this.senderName,
    required this.senderAvatar,
    this.onShowInChat,
    this.onShare,
  });

  static void show(
    BuildContext context, {
    required ChatMessage message,
    required String senderName,
    required String senderAvatar,
    VoidCallback? onShowInChat,
    VoidCallback? onShare,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.92),
        pageBuilder: (context, animation, secondaryAnimation) => FullScreenMediaViewer(
          message: message,
          senderName: senderName,
          senderAvatar: senderAvatar,
          onShowInChat: onShowInChat,
          onShare: onShare,
        ),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  final TransformationController _transformController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _controlsVisible = true;
  bool _isPlayingVideo = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformController.value != Matrix4.identity()) {
      _transformController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      _transformController.value = Matrix4.identity()
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        ..scale(2.5);
    }
  }

  void _downloadMedia() {
    MorphingCapsule.show(
      context,
      icon: LucideIcons.download,
      label: 'Saved to device gallery',
      color: ThemeProvider.primaryGold,
    );
  }

  void _copyMediaInfo() {
    final caption = widget.message.mediaCaption ?? widget.message.text;
    Clipboard.setData(ClipboardData(text: caption.isNotEmpty ? caption : widget.message.mediaUrl ?? ''));
    MorphingCapsule.show(
      context,
      icon: LucideIcons.copy,
      label: 'Copied to clipboard',
      color: const Color(0xFF54C5F8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isVideo = msg.mediaType == 'video';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Backdrop Filter
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: Colors.black.withOpacity(0.85)),
          ),

          // Interactive Zoomable / Pannable Media Canvas at original size
          GestureDetector(
            onTap: () => setState(() => _controlsVisible = !_controlsVisible),
            onDoubleTapDown: (details) => _doubleTapDetails = details,
            onDoubleTap: _handleDoubleTap,
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.8,
                maxScale: 4.5,
                child: _buildMediaContent(msg, isVideo),
              ),
            ),
          ),

          // Top Header Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            top: _controlsVisible ? 0 : -100,
            left: 0,
            right: 0,
            child: _buildTopHeaderBar(msg),
          ),

          // Bottom Caption Bar
          if ((msg.mediaCaption?.isNotEmpty == true || msg.text.isNotEmpty) && _controlsVisible)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildBottomCaptionPill(msg),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(ChatMessage msg, bool isVideo) {
    final url = msg.mediaUrl ?? '';

    if (isVideo) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              url.isNotEmpty ? url : 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 320,
                height: 220,
                color: const Color(0xFF1E2028),
                child: const Center(
                  child: Icon(LucideIcons.video, size: 54, color: Colors.white30),
                ),
              ),
            ),
          ),
          SpringButton(
            onTap: () => setState(() => _isPlayingVideo = !_isPlayingVideo),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.8), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Icon(
                _isPlayingVideo ? LucideIcons.pause : LucideIcons.play,
                color: const Color(0xFFFFD700),
                size: 32,
              ),
            ),
          ),
        ],
      );
    }

    // Image Message
    if (url.startsWith('data:image')) {
      return Image.memory(
        base64Decode(url.split(',').last),
        fit: BoxFit.contain,
      );
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.imageOff, size: 48, color: Colors.white38),
            SizedBox(height: 12),
            Text(
              'Could not load original image',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeaderBar(ChatMessage msg) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, MediaQuery.of(context).padding.top + 8, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.black.withOpacity(0.4),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Close button: X mark on top to cancel full screen
          SpringButton(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.24)),
              ),
              child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),

          // Sender Info & Time
          CircleAvatar(
            radius: 17,
            backgroundImage: NetworkImage(widget.senderAvatar),
            backgroundColor: Colors.white12,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.senderName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Sent at ${msg.time}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Action 1: Show in Chat
          if (widget.onShowInChat != null)
            _buildTopActionButton(
              icon: LucideIcons.messageSquare,
              tooltip: 'Show in chat',
              color: const Color(0xFF54C5F8),
              onTap: () {
                Navigator.pop(context);
                widget.onShowInChat?.call();
              },
            ),

          // Action 2: Download Option
          _buildTopActionButton(
            icon: LucideIcons.download,
            tooltip: 'Download media',
            color: const Color(0xFFFFD700),
            onTap: _downloadMedia,
          ),

          // Action 3: Share / Forward
          _buildTopActionButton(
            icon: LucideIcons.share2,
            tooltip: 'Share',
            onTap: () {
              if (widget.onShare != null) {
                Navigator.pop(context);
                widget.onShare?.call();
              } else {
                _copyMediaInfo();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionButton({
    required IconData icon,
    required String tooltip,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildBottomCaptionPill(ChatMessage msg) {
    final text = msg.mediaCaption?.isNotEmpty == true ? msg.mediaCaption! : msg.text;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
