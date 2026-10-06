import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/spring_button.dart';
import 'saved_posts_screen.dart';

class ChatSettingsScreen extends StatefulWidget {
  final VoidCallback? onOpenWallpaperPicker;
  final VoidCallback? onClearAllChats;

  const ChatSettingsScreen({
    super.key,
    this.onOpenWallpaperPicker,
    this.onClearAllChats,
  });

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  String _userHandle = 'viswanvieperlvvdsleo-arch';
  String _userName = 'Viswan Vieper';
  String _userBio = 'Building next-gen distributed mobile developer tools & AI 🚀';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // Settings states
  bool _readReceipts = true;
  String _disappearingMessages = 'Off';
  bool _appLock = false;
  bool _enterIsSend = true;
  String _accentColorName = 'Cyber Cyan';
  Color _accentColor = const Color(0xFF54C5F8);
  bool _glassBlurEnabled = true;
  bool _amoledMode = true;
  bool _bugAiAutoDetect = true;
  String _codeTheme = 'Cyberpunk Neon';
  String _defaultCodeLang = 'Dart';
  bool _notificationsEnabled = true;
  bool _notificationSounds = true;
  bool _previewInNotification = true;
  double _cachedMediaMB = 65.3;
  bool _autoDownloadWifi = true;
  bool _aiSafeFilter = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openQrCodeModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0E17).withOpacity(0.95),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.25),
                    blurRadius: 36,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Developer QR Code',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SpringButton(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: const Icon(LucideIcons.x, size: 18, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // QR Code Box with Cyber Glow
                  Container(
                    width: 220,
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Stylized QR pattern
                        CustomPaint(
                          size: const Size(190, 190),
                          painter: _StylizedQrPainter(color: Colors.black87),
                        ),
                        // Center Developer Badge
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C0E17),
                            shape: BoxShape.circle,
                            border: Border.all(color: _accentColor, width: 2),
                          ),
                          child: Icon(LucideIcons.code, color: _accentColor, size: 22),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text(
                    _userName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@$_userHandle',
                    style: TextStyle(color: _accentColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: SpringButton(
                          onTap: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Profile link copied: codesnap.dev/@$_userHandle')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _accentColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Text(
                                'Copy Handle',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SpringButton(
                        onTap: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('QR code saved to gallery')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: const Icon(LucideIcons.download, color: Colors.white, size: 19),
                        ),
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

  void _openEditProfileModal() {
    final nameCtrl = TextEditingController(text: _userName);
    final handleCtrl = TextEditingController(text: _userHandle);
    final bioCtrl = TextEditingController(text: _userBio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0E17).withOpacity(0.97),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Developer Profile',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        SpringButton(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildTextInputField('Display Name', nameCtrl, LucideIcons.user),
                    const SizedBox(height: 14),
                    _buildTextInputField('Developer Handle (@)', handleCtrl, LucideIcons.atSign),
                    const SizedBox(height: 14),
                    _buildTextInputField('Bio / Status', bioCtrl, LucideIcons.quote, maxLines: 2),
                    const SizedBox(height: 22),
                    SpringButton(
                      onTap: () {
                        setState(() {
                          _userName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _userName;
                          _userHandle = handleCtrl.text.trim().isNotEmpty ? handleCtrl.text.trim() : _userHandle;
                          _userBio = bioCtrl.text.trim().isNotEmpty ? bioCtrl.text.trim() : _userBio;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated successfully')),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Save Changes',
                            style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
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

  Widget _buildTextInputField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Row(
            crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 10 : 0),
                child: Icon(icon, size: 16, color: _accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  maxLines: maxLines,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  cursorColor: _accentColor,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Account Dialog ────────────────────────────────────────────────────────
  void _openAccountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E17).withOpacity(0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSheetHeader('Account & Security', LucideIcons.keyRound),
                  const SizedBox(height: 16),
                  _buildDetailTile(
                    title: 'Security Notifications',
                    subtitle: 'Show alerts when security keys change',
                    trailing: const Icon(LucideIcons.checkCircle2, color: Color(0xFF4ADE80), size: 18),
                  ),
                  _buildDetailTile(
                    title: 'Passkeys & Biometrics',
                    subtitle: 'Fingerprint / Windows Hello enabled',
                    trailing: Switch(
                      value: _appLock,
                      activeColor: _accentColor,
                      onChanged: (val) {
                        setState(() => _appLock = val);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  _buildDetailTile(
                    title: 'Linked GitHub Account',
                    subtitle: 'viswanvieperlvvdsleo-arch (Authenticated)',
                    trailing: const Icon(LucideIcons.externalLink, color: Colors.white54, size: 16),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('GitHub OAuth token active')),
                      );
                    },
                  ),
                  _buildDetailTile(
                    title: 'Delete Account',
                    subtitle: 'Erase all personal keys, chats & snippets',
                    titleColor: const Color(0xFFFF5252),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmAction('Delete Account', 'Are you sure? This action is irreversible.');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Privacy Modal ─────────────────────────────────────────────────────────
  void _openPrivacySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E17).withOpacity(0.96),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSheetHeader('Privacy Settings', LucideIcons.lock),
                      const SizedBox(height: 16),
                      _buildDetailTile(
                        title: 'Disappearing Messages',
                        subtitle: 'Default timer for new chats: $_disappearingMessages',
                        onTap: () {
                          _showOptionPicker(
                            title: 'Disappearing Messages',
                            options: ['Off', '24 Hours', '7 Days', '90 Days'],
                            selected: _disappearingMessages,
                            onSelect: (val) {
                              setState(() => _disappearingMessages = val);
                              setModalState(() {});
                            },
                          );
                        },
                      ),
                      _buildDetailTile(
                        title: 'Read Receipts',
                        subtitle: 'Show blue checkmarks when messages are read',
                        trailing: Switch(
                          value: _readReceipts,
                          activeColor: _accentColor,
                          onChanged: (val) {
                            setState(() => _readReceipts = val);
                            setModalState(() {});
                          },
                        ),
                      ),
                      _buildDetailTile(
                        title: 'Blocked Contacts',
                        subtitle: '2 blocked users',
                        trailing: const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 18),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showBlockedListDialog();
                        },
                      ),
                      _buildDetailTile(
                        title: 'App Lock on Idle',
                        subtitle: 'Require biometric scan after 1 minute',
                        trailing: Switch(
                          value: _appLock,
                          activeColor: _accentColor,
                          onChanged: (val) {
                            setState(() => _appLock = val);
                            setModalState(() {});
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

  // ── Appearance & UI Modal ──────────────────────────────────────────────────
  void _openAppearanceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E17).withOpacity(0.96),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSheetHeader('Appearance & Liquid Glass', LucideIcons.palette),
                      const SizedBox(height: 16),
                      Text(
                        'Accent Glow Theme',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAccentPill('Cyber Cyan', const Color(0xFF54C5F8), setModalState),
                          _buildAccentPill('Neon Violet', const Color(0xFFA855F7), setModalState),
                          _buildAccentPill('Matrix Green', const Color(0xFF10B981), setModalState),
                          _buildAccentPill('Amber Gold', const Color(0xFFFFB020), setModalState),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailTile(
                        title: 'Liquid Glass Gaussian Blur',
                        subtitle: 'Backdrop blur on message capsules and top bar',
                        trailing: Switch(
                          value: _glassBlurEnabled,
                          activeColor: _accentColor,
                          onChanged: (val) {
                            setState(() => _glassBlurEnabled = val);
                            setModalState(() {});
                          },
                        ),
                      ),
                      _buildDetailTile(
                        title: 'AMOLED Pure Pitch Black',
                        subtitle: 'Deep contrast background for OLED panels',
                        trailing: Switch(
                          value: _amoledMode,
                          activeColor: _accentColor,
                          onChanged: (val) {
                            setState(() => _amoledMode = val);
                            setModalState(() {});
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

  Widget _buildAccentPill(String name, Color col, StateSetter setModalState) {
    final isSel = _accentColorName == name;
    return SpringButton(
      onTap: () {
        setState(() {
          _accentColorName = name;
          _accentColor = col;
        });
        setModalState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: col.withOpacity(isSel ? 0.25 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? col : col.withOpacity(0.3), width: isSel ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              name.split(' ').first,
              style: TextStyle(color: isSel ? col : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ── Developer & AI Tools Modal (Special for CodeSnap) ─────────────────────
  void _openDevToolsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E17).withOpacity(0.96),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSheetHeader('Developer & Bug AI Tools', LucideIcons.bot),
                      const SizedBox(height: 16),
                      _buildDetailTile(
                        title: 'Bug AI Auto-Inspector',
                        subtitle: 'Automatically analyze code snippets in chat for defects',
                        trailing: Switch(
                          value: _bugAiAutoDetect,
                          activeColor: _accentColor,
                          onChanged: (val) {
                            setState(() => _bugAiAutoDetect = val);
                            setModalState(() {});
                          },
                        ),
                      ),
                      _buildDetailTile(
                        title: 'Syntax Highlight Theme',
                        subtitle: _codeTheme,
                        onTap: () {
                          _showOptionPicker(
                            title: 'Code Snippet Theme',
                            options: ['Cyberpunk Neon', 'Dracula Pro', 'GitHub Dark Dimmed', 'Monokai Pro'],
                            selected: _codeTheme,
                            onSelect: (val) {
                              setState(() => _codeTheme = val);
                              setModalState(() {});
                            },
                          );
                        },
                      ),
                      _buildDetailTile(
                        title: 'Default Snippet Language',
                        subtitle: _defaultCodeLang,
                        onTap: () {
                          _showOptionPicker(
                            title: 'Default Language',
                            options: ['Dart', 'Python', 'TypeScript', 'Rust', 'Go', 'JSON'],
                            selected: _defaultCodeLang,
                            onSelect: (val) {
                              setState(() => _defaultCodeLang = val);
                              setModalState(() {});
                            },
                          );
                        },
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

  // ── Storage & Data Modal ─────────────────────────────────────────────────
  void _openStorageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E17).withOpacity(0.96),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSheetHeader('Storage & Network Data', LucideIcons.hardDrive),
                      const SizedBox(height: 16),
                      _buildDetailTile(
                        title: 'Cached Media Size',
                        subtitle: '${_cachedMediaMB.toStringAsFixed(1)} MB stored locally',
                        trailing: SpringButton(
                          onTap: () {
                            setState(() => _cachedMediaMB = 0.0);
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Media cache cleared! 0 MB stored.')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5252).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.35)),
                            ),
                            child: const Text('Clear Cache', style: TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      _buildDetailTile(
                        title: 'Auto-Download over Wi-Fi',
                        subtitle: 'Automatically cache pictures & small videos',
                        trailing: Switch(
                          value: _autoDownloadWifi,
                          activeColor: _accentColor,
                          onChanged: (val) {
                            setState(() => _autoDownloadWifi = val);
                            setModalState(() {});
                          },
                        ),
                      ),
                      _buildDetailTile(
                        title: 'Data Usage Statistics',
                        subtitle: 'Sent: 14.2 MB · Received: 58.9 MB',
                        trailing: const Icon(LucideIcons.activity, color: Colors.white54, size: 16),
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

  // ── Blocked List Dialog ───────────────────────────────────────────────────
  void _showBlockedListDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0E17).withOpacity(0.96),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Blocked Contacts', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  _buildBlockedUserRow('Spam Bot #4910', 'bot@devspam.io'),
                  _buildBlockedUserRow('Anonymous Telemetry', 'telemetry@tracker.com'),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Done', style: TextStyle(color: Color(0xFF54C5F8), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockedUserRow(String name, String email) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(email, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            ],
          ),
          SpringButton(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unblocked $name')));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Unblock', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Option Picker Bottom Sheet ────────────────────────────────────────────
  void _showOptionPicker({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E17).withOpacity(0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  ...options.map((opt) {
                    final isSel = opt == selected;
                    return SpringButton(
                      onTap: () {
                        onSelect(opt);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              opt,
                              style: TextStyle(
                                color: isSel ? _accentColor : Colors.white,
                                fontSize: 14,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (isSel) Icon(LucideIcons.check, size: 18, color: _accentColor),
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
      },
    );
  }

  void _confirmAction(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E17).withOpacity(0.96),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(message, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                const SizedBox(height: 18),
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
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title completed.')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5252).withOpacity(0.2),
                        foregroundColor: const Color(0xFFFF5252),
                        side: BorderSide(color: const Color(0xFFFF5252).withOpacity(0.4)),
                      ),
                      child: const Text('Proceed', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildSheetHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: _accentColor),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailTile({
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _getSettingsList().where((item) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return item.title.toLowerCase().contains(query) || item.subtitle.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF07080A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar (Matching Image 2 Header) ─────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Row(
                children: [
                  SpringButton(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(LucideIcons.arrowLeft, size: 22, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),

                  if (_isSearching)
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        cursorColor: _accentColor,
                        decoration: InputDecoration(
                          hintText: 'Search settings...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    )
                  else
                    Expanded(
                      child: SpringButton(
                        onTap: _openEditProfileModal,
                        child: Text(
                          _userHandle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),

                  // Search toggle
                  SpringButton(
                    onTap: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchQuery = '';
                          _searchCtrl.clear();
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        _isSearching ? LucideIcons.x : LucideIcons.search,
                        size: 20,
                        color: Colors.white70,
                      ),
                    ),
                  ),

                  // QR Code Icon
                  SpringButton(
                    onTap: _openQrCodeModal,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(LucideIcons.qrCode, size: 20, color: Colors.white70),
                    ),
                  ),

                  // Edit Profile Icon
                  SpringButton(
                    onTap: _openEditProfileModal,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(LucideIcons.pencil, size: 19, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            // ── Settings List & Profile Banner ──────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // User Profile Capsule Card
                  if (!_isSearching)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: SpringButton(
                        onTap: _openEditProfileModal,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.08),
                                Colors.white.withOpacity(0.03),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: _accentColor.withOpacity(0.2),
                                    backgroundImage: const NetworkImage(
                                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4ADE80),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF0C0E17), width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userName,
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _userBio,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(LucideIcons.chevronRight, size: 18, color: Colors.white.withOpacity(0.4)),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Settings items (matching Image 2 layout + dev items)
                  ...filteredCategories.map((item) => _buildSettingTile(item)),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'CodeSnap Developer Suite · v2.4.0 (Build 42)',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(_SettingItem item) {
    return SpringButton(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: item.iconColor.withOpacity(0.20)),
              ),
              child: Center(
                child: Icon(item.icon, size: 19, color: item.iconColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 17, color: Colors.white.withOpacity(0.25)),
          ],
        ),
      ),
    );
  }

  List<_SettingItem> _getSettingsList() {
    return [
      _SettingItem(
        icon: LucideIcons.keyRound,
        iconColor: const Color(0xFF54C5F8),
        title: 'Account',
        subtitle: 'Security notifications, passkeys, change handle',
        onTap: _openAccountSheet,
      ),
      _SettingItem(
        icon: LucideIcons.lock,
        iconColor: const Color(0xFFA855F7),
        title: 'Privacy',
        subtitle: 'Blocked accounts, disappearing messages, read receipts',
        onTap: _openPrivacySheet,
      ),
      _SettingItem(
        icon: LucideIcons.messageSquare,
        iconColor: const Color(0xFF38BDF8),
        title: 'Chats',
        subtitle: 'Wallpaper, theme, chat history, export & backup',
        onTap: () {
          _openChatsMenu();
        },
      ),
      _SettingItem(
        icon: LucideIcons.palette,
        iconColor: const Color(0xFFEC4899),
        title: 'Appearance',
        subtitle: 'Chat theme, liquid glass blur, accent color',
        onTap: _openAppearanceSheet,
      ),
      _SettingItem(
        icon: LucideIcons.bookmark,
        iconColor: const Color(0xFFF59E0B),
        title: 'Saved List',
        subtitle: 'View all saved posts, reels, and tutorials from the feed',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
          );
        },
      ),
      _SettingItem(
        icon: LucideIcons.bot,
        iconColor: const Color(0xFF10B981),
        title: 'Developer & AI Tools',
        subtitle: 'Bug AI auto-detect, syntax theme, default language',
        onTap: _openDevToolsSheet,
      ),
      _SettingItem(
        icon: LucideIcons.bell,
        iconColor: const Color(0xFFF59E0B),
        title: 'Notifications',
        subtitle: 'Message, mention alerts, sound & haptic tones',
        onTap: () {
          _openNotificationsSheet();
        },
      ),
      _SettingItem(
        icon: LucideIcons.hardDrive,
        iconColor: const Color(0xFF6366F1),
        title: 'Storage and data',
        subtitle: 'Network usage, auto-download, cache cleaner',
        onTap: _openStorageSheet,
      ),
      _SettingItem(
        icon: LucideIcons.shieldCheck,
        iconColor: const Color(0xFF14B8A6),
        title: 'Safety & Content Filter',
        subtitle: 'Malicious URL protection, sensitive code filters',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI Content & Safety Filter is Active.')),
          );
        },
      ),
      _SettingItem(
        icon: LucideIcons.helpCircle,
        iconColor: Colors.white70,
        title: 'Help & About',
        subtitle: 'Help center, release notes, license, terms',
        onTap: () {
          _showAboutDialog();
        },
      ),
    ];
  }

  void _openChatsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E17).withOpacity(0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSheetHeader('Chats & Wallpapers', LucideIcons.messageSquare),
                  const SizedBox(height: 16),
                  _buildDetailTile(
                    title: 'Chat Wallpaper',
                    subtitle: 'Set custom photo, blur, and opacity for chats',
                    trailing: const Icon(LucideIcons.image, color: Color(0xFF54C5F8), size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context); // back to chat
                      widget.onOpenWallpaperPicker?.call();
                    },
                  ),
                  _buildDetailTile(
                    title: 'Enter is Send',
                    subtitle: 'Pressing Enter will send your message',
                    trailing: Switch(
                      value: _enterIsSend,
                      activeColor: _accentColor,
                      onChanged: (val) => setState(() => _enterIsSend = val),
                    ),
                  ),
                  _buildDetailTile(
                    title: 'Export Chat History',
                    subtitle: 'Save conversations and snippets to JSON / Gist',
                    trailing: const Icon(LucideIcons.downloadCloud, color: Colors.white54, size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat history exported to downloads folder')),
                      );
                    },
                  ),
                  _buildDetailTile(
                    title: 'Clear All Chats',
                    subtitle: 'Delete all active conversations and message logs',
                    titleColor: const Color(0xFFFF5252),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmAction('Clear All Chats', 'Delete all messages across conversations?');
                      widget.onClearAllChats?.call();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E17).withOpacity(0.96),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSheetHeader('Notification Preferences', LucideIcons.bell),
                      const SizedBox(height: 16),
                      _buildDetailTile(
                        title: 'Push Notifications',
                        subtitle: 'Receive alerts when messages arrive',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          activeColor: _accentColor,
                          onChanged: (val) {
                            setState(() => _notificationsEnabled = val);
                            setModalState(() {});
                          },
                        ),
                      ),
                      _buildDetailTile(
                        title: 'Sound & Haptics',
                        subtitle: 'Play gentle cyber tone on new message',
                        trailing: Switch(
                          value: _notificationSounds,
                          activeColor: _accentColor,
                          onChanged: (val) {
                            setState(() => _notificationSounds = val);
                            setModalState(() {});
                          },
                        ),
                      ),
                      _buildDetailTile(
                        title: 'Message Preview in Banner',
                        subtitle: 'Show snippet content on notification popup',
                        trailing: Switch(
                          value: _previewInNotification,
                          activeColor: _accentColor,
                          onChanged: (val) {
                            setState(() => _previewInNotification = val);
                            setModalState(() {});
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E17).withOpacity(0.96),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _accentColor.withOpacity(0.3)),
                  ),
                  child: Icon(LucideIcons.terminal, size: 28, color: _accentColor),
                ),
                const SizedBox(height: 14),
                const Text('CodeSnap Developer Suite', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Version 2.4.0 (Build 42)', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                const SizedBox(height: 12),
                Text(
                  'Ultra-fast real-time developer messenger with liquid glass aesthetics, multi-language code snippets, Bug AI analysis, and customizable wallpapers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _StylizedQrPainter extends CustomPainter {
  final Color color;
  _StylizedQrPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Corner targeting squares
    _drawTargetSquare(canvas, paint, 0, 0, 48);
    _drawTargetSquare(canvas, paint, size.width - 48, 0, 48);
    _drawTargetSquare(canvas, paint, 0, size.height - 48, 48);

    // Decorative QR data modules
    final step = size.width / 12;
    for (int i = 2; i < 10; i++) {
      for (int j = 2; j < 10; j++) {
        if ((i + j) % 3 == 0 || (i * j) % 5 == 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(i * step + 2, j * step + 2, step - 4, step - 4),
              const Radius.circular(2),
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawTargetSquare(Canvas canvas, Paint paint, double x, double y, double s) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, s, s), const Radius.circular(10)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + 7, y + 7, s - 14, s - 14), const Radius.circular(6)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + 13, y + 13, s - 26, s - 26), const Radius.circular(4)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
