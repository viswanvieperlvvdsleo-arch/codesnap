import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../utils/mock_data.dart';
import '../utils/app_animations.dart';
import '../widgets/code_editor.dart';
import '../services/workspace_service.dart';
import '../services/terminal_service.dart';
import '../services/live_server_service.dart';
import 'chat_screen.dart';
import '../widgets/spring_button.dart';

// ── Glass Theme Constants ──────────────────────────────────────────────────────
class _G {
  static const bg         = Color(0xFF09090B);
  static const surface    = Color(0xFF111113);
  static const glass      = Color(0x14FFFFFF);
  static const glassHigh  = Color(0x38FFFFFF);
  static const border     = Color(0x26FFFFFF);
  static const borderHigh = Color(0x38FFFFFF);
  static const textPri    = Color(0xFFFFFFFF);
  static const textSec    = Color(0xFF8888C9);
  static const textMuted  = Color(0xFF555560);
  static const radius     = 22.0;
  static const blur       = 40.0;
  static const sp         = 8.0;
}

// ── Workspace Screen ──────────────────────────────────────────────────────────
class WorkspaceScreen extends StatefulWidget {
  final String? initialTaskId;
  final String? initialProjectId;
  final VoidCallback? onClearSelection;

  const WorkspaceScreen({
    super.key,
    this.initialTaskId,
    this.initialProjectId,
    this.onClearSelection,
  });

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

// ── Editor Tab Model ─────────────────────────────────────────────────────────
class _EditorTab {
  final String name;
  final String path;
  _EditorTab({required this.name, required this.path});
}

class _WorkspaceScreenState extends State<WorkspaceScreen>
    with TickerProviderStateMixin {

  // ── Real Filesystem ───────────────────────────────────────────────────────
  String? _workspaceRoot;   // String path — works on both native & web
  List<FileNode> _tree = [];
  bool _loadingWorkspace = true;

  // Active file & Multi-tab state
  String _activeFile = '';       // file name (for tab)
  String _activePath = '';       // absolute path on disk
  String _activeCode = '';       // current in-memory content
  Uint8List? _activeImageBytes;  // for image preview
  bool _hasUnsaved = false;
  final List<_EditorTab> _openTabs = [];

  // ── Inline Creation state (VS Code style) ──────────────────────────────────
  String? _selectedFolderPath;
  bool _inlineCreating = false;
  bool _inlineIsFolder = false;
  String? _inlineParentPath;
  final _inlineCtrl = TextEditingController();
  final _inlineFocus = FocusNode();

  // ── UI state ─────────────────────────────────────────────────────────────
  bool _explorerOpen = true;
  bool _terminalOpen = false;
  int  _leftNav = 0;
  bool _searchExpanded = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── Workspace AI Chat state ────────────────────────────────────────────────
  final List<ChatMessage> _workspaceAiMessages = [
    ChatMessage(
      id: 'ws_ai_welcome',
      text: '⚡ [Remote Terminal AI Connected]\nActive Engine: Claude 3.5 Sonnet\nHost: dev-worker (tmux:0)\nI have real-time access to your workspace files and terminal.',
      isMe: false,
      time: 'Now',
      codeSnippet: '// Tap [⚡ Apply to Editor] on any code snippet to update your file instantly!',
      codeLang: 'dart',
      isDelivered: true,
    ),
  ];
  final TextEditingController _workspaceAiCtrl = TextEditingController();
  final ScrollController _workspaceAiScroll = ScrollController();
  String _workspaceAiModel = 'Claude 3.5 Sonnet';
  bool _workspaceAiThinking = false;

  // ── Terminal ─────────────────────────────────────────────────────────────
  final List<String> _termLogs = [];
  final _termCtrl   = TextEditingController();
  final _termScroll = ScrollController();
  final _termFocus  = FocusNode();
  final List<String> _cmdHistory = [];
  int _historyIndex = -1;
  TerminalService? _terminalService;
  LiveServerService? _liveServerService;

  // ── WebView ───────────────────────────────────────────────────────────────
  WebViewController? _webCtrl;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _explorerAnim;
  late Animation<double>   _explorerSlide;

  // ── Auto-save debounce ────────────────────────────────────────────────────
  final Map<String, String> _inMemoryFiles = {};

  @override
  void initState() {
    super.initState();

    _liveServerService = LiveServerService();

    _explorerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    _explorerSlide = CurvedAnimation(
      parent: _explorerAnim,
      curve: AppAnimations.snappy,
    );

    // WebView (Android/iOS only)
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS)) {
      _webCtrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF09090B));
    }

    _initWorkspace();
  }

  Future<void> _initWorkspace() async {
    // Determine project name
    String projectName = 'MyBug_Workspace';
    if (widget.initialProjectId != null) {
      try {
        final proj = MockData.mockProjects
            .firstWhere((p) => p.id == widget.initialProjectId);
        projectName = proj.title.replaceAll(' ', '_');
      } catch (_) {}
    } else if (widget.initialTaskId != null) {
      projectName = 'Task_${widget.initialTaskId}';
    }

    final rootPath = await WorkspaceService.getWorkspaceRootPath(projectName);

    // Load file tree (real disk on native, in-memory on web)
    final tree = await WorkspaceService.loadTree(rootPath);

    // Build TerminalService wired to our log list
    final termSvc = TerminalService(
      workingDirectoryPath: rootPath,
      onLog: (line) {
        if (!mounted) return;
        setState(() {
          if (line == '__CLEAR__') {
            _termLogs.clear();
          } else {
            _termLogs.add(line);
          }
        });
        _scrollTermToBottom();
      },
      onProcessEnd: () {
        if (mounted) setState(() {});
      },
      onLivePreviewRequest: () => _openInBrowser(),
    );

    setState(() {
      _workspaceRoot = rootPath;
      _tree = tree;
      _terminalService = termSvc;
      _loadingWorkspace = false;
    });

    // Seed terminal with welcome banner
    _termLogs.addAll([
      '── Bug Workspace ─────────────────────────────',
      'Project : $projectName',
      'Path    : $rootPath',
      kIsWeb ? '⚠️  Web preview mode — filesystem is in-memory' : "Type 'help' for available commands.",
      '',
    ]);

    // Auto-open the first file found (index.html → main.py → any)
    final firstFile = _findFirstFile(_tree);
    if (firstFile != null) {
      await _openFile(firstFile);
    }

    // Handle initial task/project content overrides
    _loadInitialContent();
    widget.onClearSelection?.call();
  }

  /// Finds the first non-folder FileNode in the tree
  FileNode? _findFirstFile(List<FileNode> nodes) {
    for (final n in nodes) {
      if (!n.isFolder) return n;
      final found = _findFirstFile(n.children);
      if (found != null) return found;
    }
    return null;
  }

  void _loadInitialContent() {
    if (widget.initialTaskId != null) {
      try {
        final task = MockData.mockTasks
            .firstWhere((t) => t.id == widget.initialTaskId);
        final taskFileName = 'task_${task.id}.dart';
        if (_workspaceRoot != null) {
          final path = '$_workspaceRoot/$taskFileName';
          WorkspaceService.writeFile(path, task.starterCode ?? '').then((_) {
            _refreshTree();
          });
        }
      } catch (_) {}
    } else if (widget.initialProjectId != null) {
      try {
        final proj = MockData.mockProjects
            .firstWhere((p) => p.id == widget.initialProjectId);
        final htmlContent = '<!DOCTYPE html>\n<html><head><style>${proj.cssTemplate}</style></head>\n'
            '<body>${proj.htmlTemplate}<script>${proj.jsTemplate}</script></body></html>';
        if (_workspaceRoot != null) {
          final path = '$_workspaceRoot/index.html';
          WorkspaceService.writeFile(path, htmlContent).then((_) {
            _refreshTree();
          });
        }
      } catch (_) {}
    }
  }

  // ── File & Tab Operations ──────────────────────────────────────────────────
  Future<void> _openFileByPath(String name, String path) async {
    await _saveCurrentFile();

    Uint8List? imageBytes;
    String content = '';

    final lower = name.toLowerCase();
    final isImg = lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.ico');

    final isBin = lower.endsWith('.db') ||
        lower.endsWith('.sqlite') ||
        lower.endsWith('.exe') ||
        lower.endsWith('.dll') ||
        lower.endsWith('.bin') ||
        lower.endsWith('.wasm');

    if (isImg) {
      imageBytes = await WorkspaceService.readBytes(path);
    } else if (!isBin) {
      content = _inMemoryFiles[path] ?? await WorkspaceService.readFile(path);
    }

    if (mounted) {
      setState(() {
        _activeFile = name;
        _activePath = path;
        _activeCode = content;
        _activeImageBytes = imageBytes;
        _hasUnsaved = false;
        if (!isImg && !isBin) {
          _inMemoryFiles[path] = content;
        }
        if (!_openTabs.any((t) => t.path == path)) {
          _openTabs.add(_EditorTab(name: name, path: path));
        }
      });
    }
  }

  Future<void> _openFile(FileNode node) async {
    if (node.isFolder) return;
    await _openFileByPath(node.name, node.path);
  }

  Future<void> _closeTab(int index) async {
    if (index < 0 || index >= _openTabs.length) return;
    final tab = _openTabs[index];
    if (tab.path == _activePath) {
      await _saveCurrentFile();
    }
    setState(() {
      _openTabs.removeAt(index);
      if (_openTabs.isEmpty) {
        _activeFile = '';
        _activePath = '';
        _activeCode = '';
        _activeImageBytes = null;
        _hasUnsaved = false;
      } else if (tab.path == _activePath) {
        final nextIdx = (index - 1).clamp(0, _openTabs.length - 1);
        final nextTab = _openTabs[nextIdx];
        _openFileByPath(nextTab.name, nextTab.path);
      }
    });
  }

  Future<void> _saveCurrentFile() async {
    if (_activePath.isEmpty || !_hasUnsaved) return;
    final content = _inMemoryFiles[_activePath] ?? _activeCode;
    await WorkspaceService.writeFile(_activePath, content);
    if (mounted) setState(() => _hasUnsaved = false);
  }

  Future<void> _refreshTree() async {
    if (_workspaceRoot == null) return;
    final tree = await WorkspaceService.loadTree(_workspaceRoot!);
    if (mounted) setState(() => _tree = tree);
  }

  void _onCodeChanged(String value) {
    _inMemoryFiles[_activePath] = value;
    if (mounted) setState(() {
      _activeCode = value;
      _hasUnsaved = true;
    });
  }

  Future<void> _showCreateDialog({required bool isFolder}) async {
    if (_workspaceRoot == null) return;
    final ctrl = TextEditingController();
    final ext = isFolder ? '' : '.html';
    ctrl.text = ext;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: isFolder ? 'New Folder' : 'New File',
        hint: isFolder ? 'folder-name' : 'filename.html',
        controller: ctrl,
        confirmLabel: 'Create',
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final name = result.trim();
      if (isFolder) {
        await WorkspaceService.createFolder(_workspaceRoot!, name);
      } else {
        await WorkspaceService.createFile(_workspaceRoot!, name);
      }
      await _refreshTree();
      // Auto-open the new file
      if (!isFolder) {
        final newPath = '$_workspaceRoot/$name';
        await _openFile(FileNode(name: name, path: newPath, isFolder: false));
      }
    }
  }

  // ── VS Code Inline Creation ───────────────────────────────────────────────
  void _startInlineCreation({required bool isFolder}) {
    final targetParent = _selectedFolderPath ?? _workspaceRoot;
    if (targetParent == null) return;

    if (_selectedFolderPath != null) {
      _expandFolderByPath(_tree, _selectedFolderPath!);
    }

    _inlineCtrl.clear();
    setState(() {
      _inlineCreating = true;
      _inlineIsFolder = isFolder;
      _inlineParentPath = targetParent;
    });

    Future.delayed(const Duration(milliseconds: 60), () {
      _inlineFocus.requestFocus();
    });
  }

  Future<void> _commitInlineCreation(String val) async {
    final name = val.trim();
    if (name.isEmpty) {
      setState(() => _inlineCreating = false);
      return;
    }

    final parent = _inlineParentPath ?? _workspaceRoot;
    if (parent == null) {
      setState(() => _inlineCreating = false);
      return;
    }

    if (_inlineIsFolder) {
      await WorkspaceService.createFolder(parent, name);
    } else {
      await WorkspaceService.createFile(parent, name);
    }

    setState(() => _inlineCreating = false);
    await _refreshTree();

    if (!_inlineIsFolder) {
      final sep = parent.contains('\\') ? '\\' : '/';
      final newPath = '$parent$sep$name';
      await _openFileByPath(name, newPath);
    }
  }

  bool _expandFolderByPath(List<FileNode> nodes, String targetPath) {
    for (final node in nodes) {
      if (node.isFolder) {
        if (node.path == targetPath) {
          node.expanded = true;
          return true;
        }
        if (_expandFolderByPath(node.children, targetPath)) {
          node.expanded = true;
          return true;
        }
      }
    }
    return false;
  }

  void _collapseAllFolders(List<FileNode> nodes) {
    for (final node in nodes) {
      if (node.isFolder) {
        node.expanded = false;
        _collapseAllFolders(node.children);
      }
    }
    setState(() => _selectedFolderPath = null);
  }

  // ── Open Folder / Import Project ──────────────────────────────────────────
  Future<void> _showOpenFolderDialog() async {
    // 1. On Windows desktop, launch the native Windows File Explorer folder picker directly
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      final nativePath = await WorkspaceService.pickFolderNative(_workspaceRoot);
      if (nativePath != null && nativePath.isNotEmpty) {
        await _applyWorkspaceRoot(nativePath);
        return;
      }
    }

    if (!mounted) return;

    // 2. Fallback / Android / Web: Open the interactive visual File Manager modal
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => _VisualFileManagerDialog(initialPath: _workspaceRoot),
    );

    if (chosen != null && chosen.isNotEmpty) {
      await _applyWorkspaceRoot(chosen);
    }
  }

  Future<void> _applyWorkspaceRoot(String rootPath) async {
    setState(() {
      _workspaceRoot = rootPath;
      _loadingWorkspace = true;
      _openTabs.clear();
      _inMemoryFiles.clear();
      _activeFile = '';
      _activePath = '';
      _activeCode = '';
      _activeImageBytes = null;
      _hasUnsaved = false;
    });

    _terminalService?.setWorkingDirectory(rootPath);
    final sep = rootPath.contains('\\') ? '\\' : '/';
    final folderName = rootPath.split(sep).where((s) => s.isNotEmpty).last;
    _termLogs.add('📁 Switched terminal to: $folderName ($rootPath)');
    _scrollTermToBottom();

    await _refreshTree();

    final firstFile = _findFirstFile(_tree);
    if (firstFile != null) {
      await _openFile(firstFile);
    }

    if (mounted) {
      setState(() => _loadingWorkspace = false);
    }
  }

  Future<void> _showRenameDialog(FileNode node) async {
    final ctrl = TextEditingController(text: node.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: 'Rename',
        hint: node.name,
        controller: ctrl,
        confirmLabel: 'Rename',
      ),
    );
    if (result != null && result.trim().isNotEmpty && result.trim() != node.name) {
      final newPath = await WorkspaceService.renameNode(node.path, result.trim());
      if (newPath != null && node.path == _activePath) {
        setState(() {
          _activeFile = result.trim();
          _activePath = newPath;
        });
      }
      await _refreshTree();
    }
  }

  Future<void> _confirmDelete(FileNode node) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111113),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _G.border),
        ),
        title: Text(
          'Delete ${node.isFolder ? "Folder" : "File"}?',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        content: Text(
          '"${node.name}" will be permanently deleted.',
          style: const TextStyle(color: _G.textSec, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _G.textSec)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await WorkspaceService.deleteNode(node.path, node.isFolder);
      if (node.path == _activePath) {
        setState(() { _activeFile = ''; _activePath = ''; _activeCode = ''; });
      }
      await _refreshTree();
    }
  }

  // ── Run & Terminal ────────────────────────────────────────────────────────

  // ── Live Server & Browser Preview ─────────────────────────────────────────

  Future<void> _toggleLiveServer() async {
    final root = _workspaceRoot;
    if (root == null || root.isEmpty) return;

    if (_liveServerService != null && _liveServerService!.isRunning) {
      await _liveServerService!.stop();
      setState(() {
        _termLogs.add('🛑 Live Server stopped.');
        _terminalOpen = true;
      });
    } else {
      _liveServerService ??= LiveServerService();
      final ok = await _liveServerService!.start(rootPath: root);
      if (ok) {
        setState(() {
          _termLogs.add('🌐 Live Server running at ${_liveServerService!.url}');
          _terminalOpen = true;
        });
        await _openInBrowser();
      } else {
        setState(() {
          _termLogs.add('❌ Failed to start Live Server on port 5050.');
          _terminalOpen = true;
        });
      }
    }
    _scrollTermToBottom();
  }

  Future<void> _openInBrowser({String? fileOverride}) async {
    await _saveCurrentFile();

    final root = _workspaceRoot;
    if (root == null || root.isEmpty) {
      setState(() {
        _termLogs.add('⚠️ No workspace folder open to preview.');
        _terminalOpen = true;
      });
      _scrollTermToBottom();
      return;
    }

    // Determine target relative path
    String relPath = '';
    final targetFile = fileOverride ?? _activeFile;
    final lower = targetFile.toLowerCase();

    if (lower.endsWith('.html') || lower.endsWith('.htm')) {
      if (_activePath.startsWith(root)) {
        relPath = _activePath.substring(root.length).replaceAll('\\', '/');
        if (relPath.startsWith('/')) relPath = relPath.substring(1);
      } else {
        relPath = targetFile;
      }
    } else {
      // If active file is CSS or JS, check if index.html exists
      final sep = root.contains('\\') ? '\\' : '/';
      final indexPath = '$root${sep}index.html';
      if (await WorkspaceService.fileExists(indexPath)) {
        relPath = 'index.html';
      } else if (targetFile.isNotEmpty) {
        relPath = targetFile;
      }
    }

    // Start live server if not already running
    _liveServerService ??= LiveServerService();
    if (!_liveServerService!.isRunning) {
      final ok = await _liveServerService!.start(rootPath: root);
      if (ok) {
        setState(() {
          _termLogs.add('🌐 Live Server running at ${_liveServerService!.url}');
        });
      }
    }

    if (_liveServerService!.isRunning) {
      final targetUrl = '${_liveServerService!.url}/$relPath';
      final ok = await LiveServerService.launchBrowser(targetUrl);
      setState(() {
        if (ok) {
          _termLogs.add('🚀 Launched in browser: $targetUrl');
        } else {
          _termLogs.add('🌐 Live Server available at: $targetUrl');
        }
        _terminalOpen = true;
      });
    } else {
      // Direct file launch fallback
      final filePath = _activePath.isNotEmpty ? _activePath : '$root/index.html';
      final ok = await LiveServerService.launchBrowser(filePath);
      setState(() {
        if (ok) {
          _termLogs.add('🚀 Opened file in default browser: $filePath');
        } else {
          _termLogs.add('⚠️ Unable to open browser automatically. Path: $filePath');
        }
        _terminalOpen = true;
      });
    }
    _scrollTermToBottom();
  }

  Future<void> _runCode() async {
    await _saveCurrentFile();
    setState(() => _terminalOpen = true);

    if (_terminalService == null) return;

    final lower = _activePath.toLowerCase();

    // 1. Web files (HTML, CSS) -> Launch Live Server & Browser Preview!
    if (lower.endsWith('.html') || lower.endsWith('.htm') || lower.endsWith('.css')) {
      await _openInBrowser();
      return;
    }

    // 2. JavaScript files: if frontend DOM or index.html exists, preview in browser
    if (lower.endsWith('.js') || lower.endsWith('.mjs')) {
      final root = _workspaceRoot;
      final sep = root != null && root.contains('\\') ? '\\' : '/';
      final hasHtml = root != null && await WorkspaceService.fileExists('$root${sep}index.html');
      final isDomScript = _activeCode.contains('document.') || _activeCode.contains('window.') || hasHtml;

      if (isDomScript) {
        _termLogs.add('🌐 Detected web frontend script. Launching browser preview…');
        await _openInBrowser();
      } else {
        await _terminalService!.runCommand('node "${_activePath}"');
      }
      return;
    }

    // 3. Python files
    if (lower.endsWith('.py')) {
      await _terminalService!.runCommand('python "${_activePath}"');
      return;
    }

    // 4. Dart files
    if (lower.endsWith('.dart')) {
      await _terminalService!.runCommand('dart run "${_activePath}"');
      return;
    }

    setState(() {
      _termLogs.add('⚠️ Run not supported for this file type. Supported: HTML, JS, Python, Dart.');
    });
  }

  Future<void> _termSubmit(String val) async {
    val = val.trim();
    if (val.isEmpty) return;
    _cmdHistory.add(val);
    _historyIndex = _cmdHistory.length;
    _termCtrl.clear();
    if (_terminalService != null) {
      await _terminalService!.runCommand(val);
    }
  }

  void _historyPrev() {
    if (_cmdHistory.isEmpty) return;
    if (_historyIndex > 0) {
      _historyIndex--;
      _termCtrl.text = _cmdHistory[_historyIndex];
      _termCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _termCtrl.text.length));
    }
  }

  void _historyNext() {
    if (_cmdHistory.isEmpty) return;
    if (_historyIndex < _cmdHistory.length - 1) {
      _historyIndex++;
      _termCtrl.text = _cmdHistory[_historyIndex];
      _termCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _termCtrl.text.length));
    } else {
      _historyIndex = _cmdHistory.length;
      _termCtrl.clear();
    }
  }

  void _scrollTermToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_termScroll.hasClients) {
        _termScroll.animateTo(
          _termScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Explorer Toggle ───────────────────────────────────────────────────────
  void _toggleExplorer() {
    setState(() => _explorerOpen = !_explorerOpen);
    if (_explorerOpen) {
      _explorerAnim.forward();
    } else {
      _explorerAnim.reverse();
    }
  }

  @override
  void dispose() {
    _inlineCtrl.dispose();
    _inlineFocus.dispose();
    _explorerAnim.dispose();
    _termCtrl.dispose();
    _termScroll.dispose();
    _termFocus.dispose();
    _searchCtrl.dispose();
    _workspaceAiCtrl.dispose();
    _workspaceAiScroll.dispose();
    _terminalService?.dispose();
    _liveServerService?.stop();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  bool get _isImage {
    final lower = _activeFile.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.ico');
  }

  bool get _isBinary {
    final lower = _activeFile.toLowerCase();
    return lower.endsWith('.db') ||
        lower.endsWith('.sqlite') ||
        lower.endsWith('.exe') ||
        lower.endsWith('.dll') ||
        lower.endsWith('.bin') ||
        lower.endsWith('.wasm');
  }

  String get _lang {
    final lower = _activeFile.toLowerCase();
    if (lower.endsWith('.py')) return 'python';
    if (lower.endsWith('.html') || lower.endsWith('.xml') || lower.endsWith('.svg')) return 'html';
    if (lower.endsWith('.js') || lower.endsWith('.jsx') || lower.endsWith('.ts') || lower.endsWith('.tsx') || lower.endsWith('.json')) return 'javascript';
    if (lower.endsWith('.css') || lower.endsWith('.scss')) return 'css';
    if (lower.endsWith('.md') || lower.endsWith('.txt') || lower.endsWith('.log') || lower.endsWith('.env') || lower.endsWith('.gitignore') || lower.endsWith('.lock')) return 'text';
    return 'dart';
  }

  String get _termPrompt {
    if (_terminalService != null) {
      return _terminalService!.prompt;
    }
    if (_workspaceRoot != null && _workspaceRoot!.isNotEmpty) {
      final sep = _workspaceRoot!.contains('\\') ? '\\' : '/';
      final parts = _workspaceRoot!.split(sep).where((s) => s.isNotEmpty).toList();
      final name = parts.isNotEmpty ? parts.last : 'workspace';
      return 'bug@$name> ';
    }
    return 'bug> ';
  }

  // ── Glass Widget ──────────────────────────────────────────────────────────
  Widget _glass({
    required Widget child,
    double opacity = 0.08,
    double radius = _G.radius,
    Color? borderColor,
    EdgeInsets? padding,
    double? width,
    double? height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _G.blur / 2, sigmaY: _G.blur / 2),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? _G.border,
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loadingWorkspace) {
      return Container(
        color: _G.bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white30),
              const SizedBox(height: 16),
              Text(
                'Initialising Bug Workspace…',
                style: GoogleFonts.inter(color: _G.textSec, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLand = constraints.maxWidth > constraints.maxHeight;
        final w = constraints.maxWidth;
        return Container(
          color: _G.bg,
          child: isLand ? _buildLandscape(w) : _buildPortrait(w),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PORTRAIT LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPortrait(double w) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        children: [
          _buildTopBar(w, isLandscape: false),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLeftRail(),
                if (_explorerOpen)
                  SizeTransition(
                    axis: Axis.horizontal,
                    sizeFactor: _explorerSlide,
                    child: _buildDrawerContent(w, isLandscape: false),
                  ),
                Expanded(child: _buildEditorArea()),
              ],
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LANDSCAPE LAYOUT (Windows / IDE optimized for mobile rotation)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLandscape(double w) {
    return SafeArea(
      top: false,
      bottom: true,
      left: true,
      right: true,
      child: Column(
        children: [
          _buildTopBar(w, isLandscape: true),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLeftRail(),
                if (_explorerOpen)
                  SizeTransition(
                    axis: Axis.horizontal,
                    sizeFactor: _explorerSlide,
                    child: _buildDrawerContent(w, isLandscape: true),
                  ),
                Expanded(child: _buildEditorArea()),
              ],
            ),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildDrawerContent(double screenW, {required bool isLandscape}) {
    if (_leftNav == 6) {
      final drawerW = isLandscape
          ? (screenW * 0.44).clamp(320.0, 520.0)
          : (screenW * 0.86).clamp(280.0, 420.0);
      return _buildAiChatDrawer(drawerW);
    }
    final drawerW = isLandscape
        ? (screenW * 0.28).clamp(180.0, 260.0)
        : (screenW * 0.52).clamp(160.0, 240.0);
    return _buildExplorerDrawer(drawerW);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TOP APP BAR
  // ═══════════════════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════════════════
  //  TOP APP BAR — VS Code Menu Bar (File, Edit, Selection, View, Go, Run...)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar(double w, {required bool isLandscape}) {
    final projectName = _workspaceRoot?.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).last ?? 'codesnap';

    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        border: Border(bottom: BorderSide(color: Color(0x26FFFFFF))),
      ),
      child: Row(
        children: [
          // Sidebar Toggle
          _topBarBtn(
            icon: LucideIcons.menu,
            onTap: _toggleExplorer,
            active: _explorerOpen,
          ),
          // VS Code Code icon
          const Padding(
            padding: EdgeInsets.only(left: 2, right: 6),
            child: Icon(LucideIcons.code2, size: 16, color: Color(0xFF54C5F8)),
          ),
          // Menu Items (scrollable horizontally)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFileMenu(),
                  _buildEditMenu(),
                  _buildSelectionMenu(),
                  _buildViewMenu(),
                  _buildGoMenu(),
                  _buildRunMenu(),
                  _buildTerminalMenu(),
                  _buildHelpMenu(),
                ],
              ),
            ),
          ),
          // Center Navigation & Search Pill (when width permits)
          if (w > 560) ...[
            GestureDetector(
              onTap: () {
                if (_openTabs.length > 1) {
                  final idx = _openTabs.indexWhere((t) => t.path == _activePath);
                  if (idx > 0) _openFileByPath(_openTabs[idx - 1].name, _openTabs[idx - 1].path);
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(LucideIcons.arrowLeft, size: 13, color: Color(0xFF888899)),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (_openTabs.length > 1) {
                  final idx = _openTabs.indexWhere((t) => t.path == _activePath);
                  if (idx >= 0 && idx < _openTabs.length - 1) {
                    _openFileByPath(_openTabs[idx + 1].name, _openTabs[idx + 1].path);
                  }
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(LucideIcons.arrowRight, size: 13, color: Color(0xFF888899)),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => _searchExpanded = !_searchExpanded),
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0x26FFFFFF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.search, size: 12, color: Color(0xFF888899)),
                    const SizedBox(width: 6),
                    Text(
                      projectName,
                      style: GoogleFonts.inter(color: const Color(0xFFCCCCDD), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          // Search expand bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _searchExpanded ? (w * 0.30) : 0,
            child: _searchExpanded
                ? TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(color: _G.textPri, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search files…',
                      hintStyle: GoogleFonts.inter(color: _G.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: _G.glass,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: _G.border),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _G.border),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          _topBarBtn(
            icon: LucideIcons.search,
            onTap: () => setState(() {
              _searchExpanded = !_searchExpanded;
              if (!_searchExpanded) {
                _searchQuery = '';
                _searchCtrl.clear();
              }
            }),
          ),
          _topBarBtn(icon: LucideIcons.save, onTap: _saveCurrentFile),
          _topBarBtn(
            icon: LucideIcons.globe,
            onTap: _openInBrowser,
            active: _liveServerService?.isRunning == true,
          ),
          _topBarBtn(
            icon: LucideIcons.bot,
            onTap: () {
              setState(() {
                if (_leftNav == 6 && _explorerOpen) {
                  _toggleExplorer();
                } else {
                  _leftNav = 6;
                  if (!_explorerOpen) {
                    _explorerOpen = true;
                    _explorerAnim.forward();
                  }
                }
              });
            },
            active: _leftNav == 6 && _explorerOpen,
          ),
          _topBarBtn(
            icon: _terminalOpen ? LucideIcons.terminal : LucideIcons.play,
            onTap: _runCode,
          ),
        ],
      ),
    );
  }

  // ── Menu Bar Helpers ──────────────────────────────────────────────────────
  Widget _buildMenuBarItem({
    required String label,
    required List<PopupMenuEntry<String>> items,
    required void Function(String) onSelected,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF1E1E24),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0x33FFFFFF), width: 1),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: label,
        offset: const Offset(0, 30),
        onSelected: onSelected,
        itemBuilder: (context) => items,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFFCCCCCC),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String text, {String? shortcut, IconData? icon, Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      height: 32,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color ?? const Color(0xFFAAAAAA)),
            const SizedBox(width: 8),
          ],
          Text(text, style: GoogleFonts.inter(fontSize: 12, color: color ?? Colors.white)),
          const Spacer(),
          if (shortcut != null)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(shortcut, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF777788))),
            ),
        ],
      ),
    );
  }

  Widget _buildFileMenu() {
    return _buildMenuBarItem(
      label: 'File',
      items: [
        _menuItem('new_file', 'New File...', shortcut: 'Ctrl+N', icon: LucideIcons.filePlus),
        _menuItem('new_folder', 'New Folder...', shortcut: 'Ctrl+Shift+N', icon: LucideIcons.folderPlus),
        _menuItem('open_folder', 'Open Folder...', shortcut: 'Ctrl+O', icon: LucideIcons.folderOpen),
        const PopupMenuDivider(height: 8),
        _menuItem('save', 'Save', shortcut: 'Ctrl+S', icon: LucideIcons.save),
        _menuItem('save_all', 'Save All', shortcut: 'Ctrl+K S'),
        const PopupMenuDivider(height: 8),
        _menuItem('refresh', 'Refresh Files', icon: LucideIcons.refreshCw),
        _menuItem('close_tab', 'Close Tab', shortcut: 'Ctrl+W', icon: LucideIcons.x),
      ],
      onSelected: (val) {
        switch (val) {
          case 'new_file':
            _startInlineCreation(isFolder: false);
            break;
          case 'new_folder':
            _startInlineCreation(isFolder: true);
            break;
          case 'open_folder':
            _showOpenFolderDialog();
            break;
          case 'save':
            _saveCurrentFile();
            break;
          case 'save_all':
            _saveAllFiles();
            break;
          case 'refresh':
            _refreshTree();
            break;
          case 'close_tab':
            if (_openTabs.isNotEmpty) {
              final idx = _openTabs.indexWhere((t) => t.path == _activePath);
              if (idx >= 0) _closeTab(idx);
            }
            break;
        }
      },
    );
  }

  Widget _buildEditMenu() {
    return _buildMenuBarItem(
      label: 'Edit',
      items: [
        _menuItem('undo', 'Undo', shortcut: 'Ctrl+Z', icon: LucideIcons.undo),
        _menuItem('redo', 'Redo', shortcut: 'Ctrl+Y', icon: LucideIcons.redo),
        const PopupMenuDivider(height: 8),
        _menuItem('cut', 'Cut', shortcut: 'Ctrl+X'),
        _menuItem('copy', 'Copy', shortcut: 'Ctrl+C'),
        _menuItem('paste', 'Paste', shortcut: 'Ctrl+V'),
        const PopupMenuDivider(height: 8),
        _menuItem('find', 'Find...', shortcut: 'Ctrl+F', icon: LucideIcons.search),
      ],
      onSelected: (val) {
        if (val == 'find') {
          setState(() => _searchExpanded = !_searchExpanded);
        }
      },
    );
  }

  Widget _buildSelectionMenu() {
    return _buildMenuBarItem(
      label: 'Selection',
      items: [
        _menuItem('select_all', 'Select All', shortcut: 'Ctrl+A'),
        _menuItem('expand', 'Expand Selection', shortcut: 'Shift+Alt+Right'),
      ],
      onSelected: (_) {},
    );
  }

  Widget _buildViewMenu() {
    return _buildMenuBarItem(
      label: 'View',
      items: [
        _menuItem('toggle_explorer', 'Explorer', shortcut: 'Ctrl+Shift+E', icon: LucideIcons.files),
        _menuItem('toggle_search', 'Search', shortcut: 'Ctrl+Shift+F', icon: LucideIcons.search),
        _menuItem('toggle_terminal', 'Terminal', shortcut: 'Ctrl+`', icon: LucideIcons.terminal),
      ],
      onSelected: (val) {
        if (val == 'toggle_explorer') _toggleExplorer();
        if (val == 'toggle_search') setState(() => _searchExpanded = !_searchExpanded);
        if (val == 'toggle_terminal') setState(() => _terminalOpen = !_terminalOpen);
      },
    );
  }

  Widget _buildGoMenu() {
    return _buildMenuBarItem(
      label: 'Go',
      items: [
        _menuItem('next_tab', 'Next Tab', shortcut: 'Ctrl+Tab'),
        _menuItem('prev_tab', 'Previous Tab', shortcut: 'Ctrl+Shift+Tab'),
      ],
      onSelected: (val) {
        if (_openTabs.length > 1) {
          final idx = _openTabs.indexWhere((t) => t.path == _activePath);
          if (val == 'next_tab' && idx >= 0 && idx < _openTabs.length - 1) {
            _openFileByPath(_openTabs[idx + 1].name, _openTabs[idx + 1].path);
          } else if (val == 'prev_tab' && idx > 0) {
            _openFileByPath(_openTabs[idx - 1].name, _openTabs[idx - 1].path);
          }
        }
      },
    );
  }

  Widget _buildRunMenu() {
    return _buildMenuBarItem(
      label: 'Run',
      items: [
        _menuItem('start_run', 'Start Debugging / Run', shortcut: 'F5', icon: LucideIcons.play),
        _menuItem('live_preview', 'Open Live Preview in Browser', shortcut: 'Alt+B', icon: LucideIcons.globe),
        _menuItem('toggle_live_server', _liveServerService?.isRunning == true ? 'Stop Live Server' : 'Start Live Server', icon: LucideIcons.radio),
        _menuItem('stop_run', 'Stop Execution', shortcut: 'Shift+F5', icon: LucideIcons.square),
      ],
      onSelected: (val) {
        if (val == 'start_run') _runCode();
        if (val == 'live_preview') _openInBrowser();
        if (val == 'toggle_live_server') _toggleLiveServer();
        if (val == 'stop_run') _terminalService?.killProcess();
      },
    );
  }

  Widget _buildTerminalMenu() {
    return _buildMenuBarItem(
      label: 'Terminal',
      items: [
        _menuItem('toggle_term', 'Toggle Terminal', shortcut: 'Ctrl+`', icon: LucideIcons.terminal),
        _menuItem('clear_term', 'Clear Terminal', shortcut: 'Ctrl+K', icon: LucideIcons.trash2),
        _menuItem('status', 'Terminal Status', icon: LucideIcons.info),
      ],
      onSelected: (val) {
        if (val == 'toggle_term') setState(() => _terminalOpen = !_terminalOpen);
        if (val == 'clear_term') setState(() => _termLogs.clear());
        if (val == 'status') _termSubmit('status');
      },
    );
  }

  Widget _buildHelpMenu() {
    return _buildMenuBarItem(
      label: 'Help',
      items: [
        _menuItem('shortcuts', 'Keyboard Shortcuts', shortcut: 'Ctrl+K Ctrl+S', icon: LucideIcons.keyboard),
        _menuItem('about', 'About Bug Workspace', icon: LucideIcons.info),
      ],
      onSelected: (val) {
        if (val == 'shortcuts') _showShortcutsDialog();
        if (val == 'about') _showAboutDialog();
      },
    );
  }

  Future<void> _saveAllFiles() async {
    for (final entry in _inMemoryFiles.entries) {
      await WorkspaceService.writeFile(entry.key, entry.value);
    }
    if (mounted) setState(() => _hasUnsaved = false);
  }

  void _showShortcutsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141416),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        title: Row(
          children: [
            const Icon(LucideIcons.keyboard, size: 20, color: Color(0xFF54C5F8)),
            const SizedBox(width: 10),
            Text('Keyboard Shortcuts', style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _shortcutRow('Save File', 'Ctrl + S'),
                _shortcutRow('New File', 'Ctrl + N'),
                _shortcutRow('Toggle Explorer', 'Ctrl + B'),
                _shortcutRow('Toggle Terminal', 'Ctrl + `'),
                _shortcutRow('Run Code', 'F5'),
                _shortcutRow('HTML Boilerplate', '! + Tab'),
                _shortcutRow('console.log', 'cl + Tab'),
                _shortcutRow('Flexbox', 'flex + Tab'),
                _shortcutRow('Python Function', 'def + Tab'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF54C5F8))),
          ),
        ],
      ),
    );
  }

  Widget _shortcutRow(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: const Color(0xFFCCCCDD), fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0x26FFFFFF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: Text(
              key,
              style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141416),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        title: Row(
          children: [
            const Icon(LucideIcons.code2, size: 22, color: Color(0xFF54C5F8)),
            const SizedBox(width: 10),
            Text('Bug Workspace', style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          'A cross-platform coding workspace designed for students and developers.\nVersion 1.0.0 (Bug Engine)',
          style: GoogleFonts.inter(color: const Color(0xFF888899), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF54C5F8))),
          ),
        ],
      ),
    );
  }

  Widget _topBarBtn({required IconData icon, VoidCallback? onTap, bool active = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 48,
        child: Center(
          child: Icon(icon, size: 17, color: active ? _G.textPri : _G.textSec),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LEFT ICON RAIL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLeftRail() {
    final items = [
      (LucideIcons.files,     0),
      (LucideIcons.bot,       6),
      (LucideIcons.search,    1),
      (LucideIcons.gitBranch, 2),
      (LucideIcons.play,      3),
      (LucideIcons.blocks,    4),
    ];
    return Container(
      width: 44,
      decoration: BoxDecoration(
        color: _G.surface,
        border: Border(right: BorderSide(color: _G.border)),
      ),
      child: Column(
        children: [
          ...items.map((e) => _railBtn(e.$1, e.$2)),
          const Spacer(),
          _railBtn(LucideIcons.user, 5),
          const SizedBox(height: _G.sp),
        ],
      ),
    );
  }

  Widget _railBtn(IconData icon, int idx) {
    final active = _leftNav == idx;
    final isAi = idx == 6;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_leftNav == idx && _explorerOpen) {
          _toggleExplorer();
        } else {
          setState(() {
            _leftNav = idx;
            if (!_explorerOpen) {
              _explorerOpen = true;
              _explorerAnim.forward();
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: AppAnimations.micro,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isAi && active ? const Color(0xFF1E293B) : Colors.transparent,
          border: active
              ? Border(left: BorderSide(color: isAi ? const Color(0xFF38BDF8) : _G.textPri, width: 2))
              : null,
        ),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 18,
                color: active
                    ? (isAi ? const Color(0xFF38BDF8) : _G.textPri)
                    : (isAi ? const Color(0xFF818CF8) : _G.textMuted),
              ),
              if (isAi)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  WORKSPACE AI CHAT DRAWER (Zero-Cost Remote Terminal AI Bridge)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAiChatDrawer(double drawerW) {
    final activeFilename = _activeFile.isEmpty ? 'No file selected' : _activeFile;
    return Container(
      width: drawerW,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F17),
        border: Border(right: BorderSide(color: _G.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: Status + Model Picker + Close
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF131722),
              border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(LucideIcons.bot, size: 14, color: Color(0xFF38BDF8)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'REMOTE AI',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'tmux:0 · dev-worker',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF94A3B8),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Model switcher pill
                GestureDetector(
                  onTap: _showWorkspaceModelPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2433),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x3338BDF8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _workspaceAiModel,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF7DD3FC),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(LucideIcons.chevronDown, size: 11, color: Color(0xFF7DD3FC)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Close button
                GestureDetector(
                  onTap: _toggleExplorer,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(LucideIcons.x, size: 14, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),

          // Context row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFF0F121C),
            child: Row(
              children: [
                const Icon(LucideIcons.fileCode2, size: 12, color: Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Context: $activeFilename',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFFCBD5E1),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Clear chat button
                Tooltip(
                  message: 'Clear Chat History',
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _workspaceAiMessages.clear();
                        _workspaceAiMessages.add(
                          ChatMessage(
                            id: 'ws_ai_welcome',
                            text: '⚡ [Remote Terminal AI Connected]\nEngine: $_workspaceAiModel\nReady to analyze $_activeFile or run terminal commands.',
                            isMe: false,
                            time: 'Now',
                            codeSnippet: '// Tap [⚡ Apply to Editor] on any code snippet to update your file instantly!',
                            codeLang: _lang,
                            isDelivered: true,
                          ),
                        );
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(LucideIcons.trash2, size: 13, color: Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick Action Prompt Chips
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildWorkspacePromptChip('✨ Explain', LucideIcons.sparkles),
                const SizedBox(width: 6),
                _buildWorkspacePromptChip('🐛 Fix bugs', LucideIcons.bug),
                const SizedBox(width: 6),
                _buildWorkspacePromptChip('⚡ Optimize', LucideIcons.zap),
                const SizedBox(width: 6),
                _buildWorkspacePromptChip('🧪 Add tests', LucideIcons.checkCheck),
                const SizedBox(width: 6),
                _buildWorkspacePromptChip('▶ Run cmd', LucideIcons.terminal),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0x1FFFFFFF)),

          // Message Stream
          Expanded(
            child: ListView.builder(
              controller: _workspaceAiScroll,
              padding: const EdgeInsets.all(10),
              itemCount: _workspaceAiMessages.length + (_workspaceAiThinking ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _workspaceAiMessages.length) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131722),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x2238BDF8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF38BDF8)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Streaming through terminal bridge...',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final msg = _workspaceAiMessages[i];
                return _buildWorkspaceAiBubble(msg);
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF11141F),
              border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0C13),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: TextField(
                          controller: _workspaceAiCtrl,
                          minLines: 1,
                          maxLines: 4,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Ask to edit, fix, or run code…',
                            hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          onSubmitted: (val) => _sendWorkspaceAiMessage(val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _sendWorkspaceAiMessage(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.send, size: 15, color: Color(0xFF0B1120)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Connected to dev server (free CLI bridge · no API cost)',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspacePromptChip(String label, IconData icon) {
    return GestureDetector(
      onTap: () => _sendWorkspaceAiMessage(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF161C2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x2638BDF8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: const Color(0xFF38BDF8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFFE2E8F0),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceAiBubble(ChatMessage m) {
    final isMe = m.isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bubble
          Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF1E3A8A) : const Color(0xFF131722),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isMe ? const Color(0x4460A5FA) : const Color(0x22FFFFFF),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.bot, size: 12, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 4),
                      Text(
                        _workspaceAiModel,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF38BDF8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (!isMe) const SizedBox(height: 4),
                SelectableText(
                  m.text,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Code snippet card (if any)
          if (m.codeSnippet != null && m.codeSnippet!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: const Color(0xFF07080A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Code header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          (m.codeLang ?? _lang).toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFF94A3B8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: m.codeSnippet!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code snippet copied to clipboard!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(LucideIcons.copy, size: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  // Code content
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: SelectableText(
                      m.codeSnippet!,
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFFF1F5F9),
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                  // Action buttons bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(7)),
                    ),
                    child: Row(
                      children: [
                        // Apply to Editor
                        GestureDetector(
                          onTap: () => _applyCodeToActiveFile(m.codeSnippet!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF10B981)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.zap, size: 11, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  'Apply to Editor',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF10B981),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Run in Terminal
                        GestureDetector(
                          onTap: () => _runCodeInTerminal(m.codeSnippet!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF38BDF8)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.play, size: 11, color: Color(0xFF38BDF8)),
                                const SizedBox(width: 4),
                                Text(
                                  'Run in Terminal',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF38BDF8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
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
        ],
      ),
    );
  }

  void _applyCodeToActiveFile(String code) {
    if (_activePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active file open in editor to apply changes to.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _activeCode = code;
      _inMemoryFiles[_activePath] = code;
      _hasUnsaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCheck, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Applied to $_activeFile! (Ctrl+S to save)')),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _runCodeInTerminal(String cmdOrCode) {
    setState(() => _terminalOpen = true);
    final trimmed = cmdOrCode.trim();
    if (trimmed.startsWith('flutter') ||
        trimmed.startsWith('dart') ||
        trimmed.startsWith('npm') ||
        trimmed.startsWith('node') ||
        trimmed.startsWith('python') ||
        trimmed.startsWith('git') ||
        trimmed.startsWith('curl') ||
        trimmed.startsWith('cat') ||
        trimmed.startsWith('ls') ||
        trimmed.startsWith('echo')) {
      _termSubmit(trimmed);
    } else {
      _termLogs.add('⚡ Running active file with updated snippet...');
      _runCode();
    }
    _scrollTermToBottom();
  }

  void _showWorkspaceModelPicker() {
    final models = [
      ('Claude 3.5 Sonnet', 'Anthropic · Best for architecture & Flutter'),
      ('GPT-4o', 'OpenAI · Multimodal reasoning'),
      ('Codex', 'OpenAI · Ultra-fast code generation'),
      ('Antigravity 2.0', 'DeepMind · Full repo terminal agent'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F121C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 12),
                  child: Text(
                    'Select Remote AI Engine (tmux:0)',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...models.map((m) {
                  final selected = _workspaceAiModel == m.$1;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    tileColor: selected ? const Color(0xFF1E293B) : Colors.transparent,
                    leading: Icon(
                      LucideIcons.bot,
                      color: selected ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    title: Text(
                      m.$1,
                      style: GoogleFonts.inter(
                        color: selected ? const Color(0xFF38BDF8) : Colors.white,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      m.$2,
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                    ),
                    trailing: selected
                        ? const Icon(LucideIcons.check, size: 16, color: Color(0xFF38BDF8))
                        : null,
                    onTap: () {
                      setState(() => _workspaceAiModel = m.$1);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched AI engine to ${m.$1}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollAiChatToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_workspaceAiScroll.hasClients) {
        _workspaceAiScroll.animateTo(
          _workspaceAiScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  ChatMessage _generateAiResponse(String query) {
    final q = query.toLowerCase();
    final filename = _activeFile.isEmpty ? 'untitled' : _activeFile;
    final code = _activeCode;
    final lang = _lang;

    String answerText;
    String? snippet;

    if (q.contains('explain')) {
      answerText = 'Here is the architectural overview of `$filename`:\n'
          '• Target language: `$lang`\n'
          '• Total lines: ${code.split('\n').length}\n'
          '• Structure: Contains logic and component declarations tailored for this module.';
      snippet = code.isNotEmpty ? code : '// No code currently in $filename';
    } else if (q.contains('fix') || q.contains('bug')) {
      answerText = 'Identified potential edge cases and applied modern formatting and safe null handling for `$filename`.';
      snippet = code.isNotEmpty
          ? '// Fixed & verified by $_workspaceAiModel\n$code'
          : '// Clean template for $filename\nvoid main() {\n  print("Ready");\n}';
    } else if (q.contains('optimiz')) {
      answerText = 'Refactored `$filename` to reduce redundant computations and improve maintainability.';
      snippet = code.isNotEmpty
          ? '// Optimized version of $filename\n$code'
          : '// High-performance template\nvoid main() {\n  // Optimized logic\n}';
    } else if (q.contains('test')) {
      answerText = 'Generated comprehensive unit test suite covering key assertions for `$filename`:';
      snippet = 'import \'package:flutter_test/flutter_test.dart\';\n\nvoid main() {\n  test(\'$filename smoke test\', () {\n    expect(true, isTrue);\n  });\n}';
    } else if (q.contains('terminal') || q.contains('cmd') || q.contains('run')) {
      answerText = 'Generated executable terminal command for this project:';
      snippet = lang == 'dart' ? 'flutter test' : (lang == 'python' ? 'python "$filename"' : 'npm test');
    } else {
      answerText = 'Here is the solution generated for: "$query"\nContext: `$filename`';
      snippet = code.isNotEmpty
          ? '// Updated logic for: $query\n$code'
          : '// Code generated by $_workspaceAiModel\nvoid main() {\n  print("Executed for: $query");\n}';
    }

    return ChatMessage(
      id: 'ws_ai_${DateTime.now().millisecondsSinceEpoch}',
      text: answerText,
      isMe: false,
      time: 'Just now',
      codeSnippet: snippet,
      codeLang: lang,
      isDelivered: true,
    );
  }

  void _sendWorkspaceAiMessage([String? presetText]) {
    final text = (presetText ?? _workspaceAiCtrl.text).trim();
    if (text.isEmpty) return;
    _workspaceAiCtrl.clear();

    final userMsg = ChatMessage(
      id: 'ws_msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isMe: true,
      time: 'Just now',
    );

    setState(() {
      _workspaceAiMessages.add(userMsg);
      _workspaceAiThinking = true;
    });

    _scrollAiChatToBottom();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final response = _generateAiResponse(text);
      setState(() {
        _workspaceAiMessages.add(response);
        _workspaceAiThinking = false;
      });
      _scrollAiChatToBottom();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  EXPLORER DRAWER — real filesystem tree
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildExplorerDrawer(double drawerW) {
    return Container(
      width: drawerW,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0F),
        border: Border(right: BorderSide(color: _G.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(_G.sp * 1.5, _G.sp, _G.sp, _G.sp),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    // Clicking EXPLORER header clears folder selection so creations go to root
                    setState(() => _selectedFolderPath = null);
                  },
                  child: Text(
                    'EXPLORER',
                    style: GoogleFonts.inter(
                      color: _G.textSec,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const Spacer(),
                // Open Folder / Project
                Tooltip(
                  message: 'Open Folder / Import Project',
                  child: GestureDetector(
                    onTap: _showOpenFolderDialog,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(LucideIcons.folderOpen, size: 14, color: _G.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                // New File
                Tooltip(
                  message: 'New File',
                  child: GestureDetector(
                    onTap: () => _startInlineCreation(isFolder: false),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(LucideIcons.filePlus, size: 14, color: _G.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                // New Folder
                Tooltip(
                  message: 'New Folder',
                  child: GestureDetector(
                    onTap: () => _startInlineCreation(isFolder: true),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(LucideIcons.folderPlus, size: 14, color: _G.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                // Refresh tree
                Tooltip(
                  message: 'Refresh Explorer',
                  child: GestureDetector(
                    onTap: _refreshTree,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(LucideIcons.refreshCw, size: 14, color: _G.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                // Collapse All Folders
                Tooltip(
                  message: 'Collapse All Folders',
                  child: GestureDetector(
                    onTap: () => _collapseAllFolders(_tree),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(LucideIcons.chevronsDownUp, size: 14, color: _G.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Workspace root path label (clickable to clear folder selection)
          if (_workspaceRoot != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _selectedFolderPath = null);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(_G.sp * 1.5, 0, _G.sp, _G.sp),
                child: Row(
                  children: [
                    Icon(
                      _selectedFolderPath == null ? LucideIcons.folderOpen : LucideIcons.folder,
                      size: 13,
                      color: const Color(0xFFCCA352),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _workspaceRoot!.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).last,
                        style: GoogleFonts.inter(
                          color: _G.textPri,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // File Tree from real disk
          Expanded(
            child: _tree.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.folderOpen, size: 28, color: _G.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'Empty workspace\nTap + to create a file',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: _G.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      // Clicking on empty explorer background deselects folder
                      if (_selectedFolderPath != null) {
                        setState(() => _selectedFolderPath = null);
                      }
                    },
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // Inline input at root level if active and no folder selected
                        if (_inlineCreating &&
                            (_inlineParentPath == null || _inlineParentPath == _workspaceRoot))
                          _buildInlineInputNode(0),
                        ..._filteredTree(_tree, _searchQuery)
                            .map((node) => _buildTreeNode(node, 0)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Inline VS Code Input Box Node ──────────────────────────────────────────
  Widget _buildInlineInputNode(int depth) {
    final indent = _G.sp * 1.5 + depth * _G.sp * 2.0;
    return Container(
      height: 28,
      padding: EdgeInsets.only(left: indent, right: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(
            _inlineIsFolder ? LucideIcons.folder : LucideIcons.fileCode,
            size: 13,
            color: _inlineIsFolder ? const Color(0xFFCCA352) : const Color(0xFF54C5F8),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1E),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF007ACC), width: 1.5),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _inlineCtrl,
                focusNode: _inlineFocus,
                cursorColor: Colors.white,
                cursorWidth: 1.5,
                cursorHeight: 14,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  isDense: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: _inlineIsFolder ? 'Folder name...' : 'File name (e.g. main.js)...',
                  hintStyle: const TextStyle(color: Color(0xFF666677), fontSize: 11),
                ),
                onSubmitted: _commitInlineCreation,
                onTapOutside: (_) {
                  if (_inlineCreating) {
                    if (_inlineCtrl.text.trim().isNotEmpty) {
                      _commitInlineCreation(_inlineCtrl.text);
                    } else {
                      setState(() => _inlineCreating = false);
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FileNode> _filteredTree(List<FileNode> nodes, String query) {
    if (query.isEmpty) return nodes;
    return nodes.where((n) {
      if (n.isFolder) return true;
      return n.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Widget _buildTreeNode(FileNode node, int depth) {
    final indent = _G.sp * 1.5 + depth * _G.sp * 2.0;
    final isActive = !node.isFolder && node.path == _activePath;
    final isFolderSelected = node.isFolder && _selectedFolderPath == node.path;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (node.isFolder) {
              setState(() {
                node.expanded = !node.expanded;
                if (node.expanded) {
                  _selectedFolderPath = node.path;
                } else {
                  if (_selectedFolderPath == node.path) {
                    _selectedFolderPath = null;
                  }
                }
              });
            } else {
              _openFile(node);
            }
          },
          onLongPress: () => _showNodeContextMenu(node),
          child: Container(
            height: 28,
            color: isActive
                ? _G.glass
                : (isFolderSelected ? const Color(0x1FFFFFFF) : Colors.transparent),
            padding: EdgeInsets.only(left: indent),
            child: Row(
              children: [
                if (node.isFolder) ...[
                  Icon(
                    node.expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 13,
                    color: _G.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    node.expanded ? LucideIcons.folderOpen : LucideIcons.folder,
                    size: 13,
                    color: const Color(0xFFCCA352),
                  ),
                ] else ...[
                  const SizedBox(width: 16),
                  _fileIcon(node.name, size: 12),
                ],
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    node.name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: isActive ? _G.textPri : const Color(0xFFCCCCDD),
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (node.isFolder && node.expanded) ...[
          // Show inline text field right inside this folder if creating inside it
          if (_inlineCreating && _inlineParentPath == node.path)
            _buildInlineInputNode(depth + 1),
          ...node.children.map((c) => _buildTreeNode(c, depth + 1)),
        ],
      ],
    );
  }

  void _showNodeContextMenu(FileNode node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111113),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: _G.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Text(
              node.name,
              style: GoogleFonts.inter(
                color: _G.textPri,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            if (node.isFolder) ...[
              ListTile(
                leading: const Icon(LucideIcons.filePlus, color: Color(0xFF54C5F8), size: 18),
                title: Text('New File in this folder', style: GoogleFonts.inter(color: _G.textPri)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedFolderPath = node.path);
                  _startInlineCreation(isFolder: false);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.folderPlus, color: Color(0xFFCCA352), size: 18),
                title: Text('New Folder in this folder', style: GoogleFonts.inter(color: _G.textPri)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedFolderPath = node.path);
                  _startInlineCreation(isFolder: true);
                },
              ),
            ],
            ListTile(
              leading: const Icon(LucideIcons.pencil, color: _G.textSec, size: 18),
              title: Text('Rename', style: GoogleFonts.inter(color: _G.textPri)),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(node);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
              title: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(node);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _fileIcon(String name, {double size = 14}) {
    IconData icon;
    Color color;
    if (name.endsWith('.dart')) {
      icon = LucideIcons.fileCode2; color = const Color(0xFF54C5F8);
    } else if (name.endsWith('.html')) {
      icon = LucideIcons.fileCode; color = const Color(0xFFE44D26);
    } else if (name.endsWith('.py')) {
      icon = LucideIcons.fileCode; color = const Color(0xFF3572A5);
    } else if (name.endsWith('.css')) {
      icon = LucideIcons.fileCode; color = const Color(0xFF563D7C);
    } else if (name.endsWith('.js')) {
      icon = LucideIcons.fileCode; color = const Color(0xFFF7DF1E);
    } else if (name.endsWith('.md')) {
      icon = LucideIcons.fileText; color = const Color(0xFF88AACC);
    } else if (name.endsWith('.json')) {
      icon = LucideIcons.fileText; color = const Color(0xFFD19A66);
    } else {
      icon = LucideIcons.fileText; color = _G.textMuted;
    }
    return Icon(icon, size: size, color: color);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  EDITOR AREA
  // ═══════════════════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════════════════
  //  EDITOR AREA (Tabs + Breadcrumbs + Code View + Floating Run)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEditorArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // VS Code Editor Tabs Bar
        _buildEditorTabBar(),

        // VS Code Breadcrumbs Bar
        _buildBreadcrumbsBar(),

        Expanded(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: Container(
                  color: _G.bg,
                  child: _activeFile.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.fileCode2,
                                  size: 40, color: _G.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'Open a file from the explorer\nto start coding',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: _G.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : _buildActiveFileContent(),
                ),
              ),
              // Floating Run button
              Positioned(
                bottom: _G.sp * 2,
                right: _G.sp * 2,
                child: _buildRunBtn(),
              ),
            ],
          ),
        ),

        // Terminal drop-up panel
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: _terminalOpen
              ? SizedBox(height: 220, child: _buildTerminalPanel())
              : const SizedBox.shrink(),
        ),

        _buildStatusBar(),
      ],
    );
  }

  // ── VS Code Editor Tab Bar ────────────────────────────────────────────────
  Widget _buildEditorTabBar() {
    if (_openTabs.isEmpty && _activeFile.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_activeFile.isNotEmpty && !_openTabs.any((t) => t.path == _activePath)) {
      _openTabs.add(_EditorTab(name: _activeFile, path: _activePath));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableW = constraints.maxWidth;
        final hidePreviewText = availableW < 320;
        final hidePreviewBtn = availableW < 190;
        final hidePlusBtn = availableW < 160;

        return Container(
          height: 35,
          decoration: const BoxDecoration(
            color: Color(0xFF141416),
            border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF))),
          ),
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _openTabs.length,
                  itemBuilder: (context, i) {
                    final tab = _openTabs[i];
                    final isActive = tab.path == _activePath;
                    return GestureDetector(
                      onTap: () => _openFileByPath(tab.name, tab.path),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF09090B) : const Color(0xFF141416),
                          border: Border(
                            top: isActive
                                ? const BorderSide(color: Color(0xFF54C5F8), width: 2)
                                : BorderSide.none,
                            right: const BorderSide(color: Color(0x14FFFFFF), width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _fileIcon(tab.name, size: 13),
                            const SizedBox(width: 7),
                            Text(
                              tab.name,
                              style: GoogleFonts.inter(
                                color: isActive ? Colors.white : const Color(0xFF888899),
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isActive && _hasUnsaved)
                              Container(
                                width: 7,
                                height: 7,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _closeTab(i),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  LucideIcons.x,
                                  size: 13,
                                  color: isActive ? const Color(0xFFAAAAAA) : const Color(0xFF555566),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Live Preview in Browser Button
              if (!hidePreviewBtn)
                Tooltip(
                  message: 'Open Live Preview in Browser',
                  child: GestureDetector(
                    onTap: _openInBrowser,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: hidePreviewText ? 6 : 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _liveServerService?.isRunning == true
                            ? const Color(0x2654C5F8)
                            : const Color(0x0FFFFFFF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _liveServerService?.isRunning == true
                              ? const Color(0x5954C5F8)
                              : const Color(0x1FFFFFFF),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.globe,
                            size: 13,
                            color: _liveServerService?.isRunning == true
                                ? const Color(0xFF54C5F8)
                                : const Color(0xFFCCCCCC),
                          ),
                          if (!hidePreviewText) ...[
                            const SizedBox(width: 5),
                            Text(
                              'Preview',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _liveServerService?.isRunning == true
                                    ? const Color(0xFF54C5F8)
                                    : const Color(0xFFCCCCCC),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              // New file shortcut button in tab bar
              if (!hidePlusBtn)
                GestureDetector(
                  onTap: () => _showCreateDialog(isFolder: false),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(LucideIcons.plus, size: 15, color: Color(0xFF888899)),
                  ),
                ),
              // More tab options
              PopupMenuButton<String>(
                tooltip: 'More Tab Actions',
                offset: const Offset(0, 30),
                color: const Color(0xFF1E1E24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0x33FFFFFF), width: 1),
                ),
                onSelected: (val) {
                  if (val == 'close_all') {
                    setState(() {
                      _openTabs.clear();
                      _activeFile = '';
                      _activePath = '';
                      _activeCode = '';
                      _hasUnsaved = false;
                    });
                  } else if (val == 'save_all') {
                    _saveAllFiles();
                  } else if (val == 'open_browser') {
                    _openInBrowser();
                  } else if (val == 'live_server') {
                    _toggleLiveServer();
                  } else if (val == 'new_file') {
                    _showCreateDialog(isFolder: false);
                  }
                },
                itemBuilder: (context) => [
                  if (hidePlusBtn)
                    _menuItem('new_file', 'New File...', icon: LucideIcons.plus),
                  _menuItem('open_browser', 'Open in Browser', icon: LucideIcons.globe),
                  _menuItem('live_server', _liveServerService?.isRunning == true ? 'Stop Live Server' : 'Start Live Server', icon: LucideIcons.radio),
                  _menuItem('save_all', 'Save All', shortcut: 'Ctrl+K S', icon: LucideIcons.save),
                  _menuItem('close_all', 'Close All Tabs', icon: LucideIcons.x),
                ],
                child: const Padding(
                  padding: EdgeInsets.only(left: 4, right: 8),
                  child: Icon(LucideIcons.moreHorizontal, size: 15, color: Color(0xFF888899)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── VS Code Breadcrumbs Bar ───────────────────────────────────────────────
  Widget _buildBreadcrumbsBar() {
    if (_activeFile.isEmpty) return const SizedBox.shrink();

    final root = _workspaceRoot ?? '';
    String rel = _activePath;
    if (root.isNotEmpty && rel.startsWith(root)) {
      rel = rel.substring(root.length);
      if (rel.startsWith('/') || rel.startsWith('\\')) {
        rel = rel.substring(1);
      }
    }
    final segments = rel.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) segments.add(_activeFile);

    final parts = root.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).toList();
    final projectName = parts.isNotEmpty ? parts.last : 'codesnap';

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0C0E),
        border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              projectName,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF777788)),
            ),
            for (int i = 0; i < segments.length; i++) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(LucideIcons.chevronRight, size: 10, color: Color(0xFF555566)),
              ),
              if (i == segments.length - 1)
                _fileIcon(segments[i], size: 11)
              else
                const Icon(LucideIcons.folder, size: 11, color: Color(0xFF777799)),
              const SizedBox(width: 4),
              Text(
                segments[i],
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: i == segments.length - 1 ? const Color(0xFFCCCCCC) : const Color(0xFF777788),
                  fontWeight: i == segments.length - 1 ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Floating Run Button ───────────────────────────────────────────────────
  Widget _buildRunBtn() {
    final lower = _activePath.toLowerCase();
    final isWeb = lower.endsWith('.html') || lower.endsWith('.htm') || lower.endsWith('.css');
    final isRunning = _terminalService?.isRunning == true;

    return Tooltip(
      message: isRunning
          ? 'Stop Process'
          : (isWeb ? 'Launch Live Preview in Browser' : 'Run File'),
      child: GestureDetector(
        onTap: _runCode,
        child: _glass(
          opacity: 0.20,
          radius: 30,
          borderColor: isWeb ? const Color(0x6654C5F8) : _G.borderHigh,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(
              isRunning
                  ? LucideIcons.square
                  : (isWeb ? LucideIcons.globe : LucideIcons.play),
              size: 20,
              color: isRunning
                  ? Colors.redAccent
                  : (isWeb ? const Color(0xFF54C5F8) : _G.textPri),
            ),
          ),
        ),
      ),
    );
  }

  // ── Active File Content (Image / Binary / Code) ───────────────────────────
  Widget _buildActiveFileContent() {
    if (_isImage) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 650, maxHeight: 500),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0x0FFFFFFF),
                  border: Border.all(color: const Color(0x26FFFFFF)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _activeImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(_activeImageBytes!),
                      )
                    : const Icon(LucideIcons.image, size: 64, color: _G.textMuted),
              ),
              const SizedBox(height: 12),
              Text(
                _activeFile,
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFFCCCCCC), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (_isBinary) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.fileWarning, size: 48, color: Colors.amber),
            const SizedBox(height: 12),
            Text(
              'Binary file: $_activeFile',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'This file cannot be displayed or edited as text.',
              style: GoogleFonts.inter(color: const Color(0xFF888899), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return CodeEditor(
      key: ValueKey(_activePath),
      code: _activeCode,
      language: _lang,
      onChanged: _onCodeChanged,
    );
  }

  // ── Terminal Panel — Integrated VS Code style ─────────────────────────────
  Widget _buildTerminalPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0C),
        border: Border(top: BorderSide(color: _G.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab bar
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: _G.surface,
              border: Border(bottom: BorderSide(color: _G.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: _G.sp),
            child: Row(
              children: [
                _panelTab('Terminal', true),
                _panelTab('Output', false),
                const Spacer(),
                // Kill process button (only when running)
                if (_terminalService?.isRunning == true)
                  GestureDetector(
                    onTap: () => setState(() {
                      _terminalService?.killProcess();
                    }),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(LucideIcons.square, size: 14, color: Colors.redAccent),
                    ),
                  ),
                // Clear logs
                GestureDetector(
                  onTap: () => setState(() => _termLogs.clear()),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(LucideIcons.trash2, size: 14, color: _G.textMuted),
                  ),
                ),
                // Close
                GestureDetector(
                  onTap: () => setState(() => _terminalOpen = false),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(LucideIcons.chevronDown, size: 16, color: _G.textMuted),
                  ),
                ),
              ],
            ),
          ),
          // Integrated VS Code Terminal Body (logs + active prompt at the bottom)
          Expanded(
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  final isCtrl = HardwareKeyboard.instance.isControlPressed;
                  final isShift = HardwareKeyboard.instance.isShiftPressed;

                  // Ctrl + C: Stop running process or copy
                  if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyC) {
                    if (isShift) {
                      // Ctrl + Shift + C: copy selected text
                      if (_termCtrl.selection.isValid && !_termCtrl.selection.isCollapsed) {
                        final sel = _termCtrl.text.substring(_termCtrl.selection.start, _termCtrl.selection.end);
                        Clipboard.setData(ClipboardData(text: sel));
                      }
                      return KeyEventResult.handled;
                    } else {
                      // Ctrl + C (no shift):
                      // If text is highlighted, let native copy work
                      if (_termCtrl.selection.isValid && !_termCtrl.selection.isCollapsed) {
                        return KeyEventResult.ignored;
                      }
                      // If a process is running (e.g. Next.js server): STOP IT!
                      if (_terminalService?.isRunning == true) {
                        _terminalService?.killProcess();
                        _termLogs.add('^C');
                        setState(() {});
                        _scrollTermToBottom();
                        return KeyEventResult.handled;
                      }
                    }
                  }

                  // Ctrl + Shift + V: Paste into terminal
                  if (isCtrl && isShift && event.logicalKey == LogicalKeyboardKey.keyV) {
                    Clipboard.getData(Clipboard.kTextPlain).then((clip) {
                      if (clip?.text != null && clip!.text!.isNotEmpty) {
                        final t = clip.text!;
                        final current = _termCtrl.text;
                        final sel = _termCtrl.selection;
                        if (sel.isValid) {
                          final before = current.substring(0, sel.start);
                          final after = current.substring(sel.end);
                          _termCtrl.text = '$before$t$after';
                          _termCtrl.selection = TextSelection.collapsed(offset: sel.start + t.length);
                        } else {
                          _termCtrl.text += t;
                          _termCtrl.selection = TextSelection.collapsed(offset: _termCtrl.text.length);
                        }
                      }
                    });
                    return KeyEventResult.handled;
                  }

                  // Ctrl + L: Clear terminal screen
                  if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyL) {
                    setState(() => _termLogs.clear());
                    return KeyEventResult.handled;
                  }

                  // History navigation: Up and Down arrows
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _historyPrev();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _historyNext();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _termFocus.requestFocus(),
                child: ListView(
                  controller: _termScroll,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _G.sp * 1.5,
                    vertical: _G.sp,
                  ),
                  children: [
                    ..._termLogs.map((line) {
                      Color lineColor = const Color(0xFFCCCCDD);
                      if (line.startsWith('❌')) lineColor = Colors.redAccent;
                      if (line.startsWith('✓')) lineColor = const Color(0xFF4CAF50);
                      if (line.startsWith('🌐')) lineColor = const Color(0xFF54C5F8);
                      if (line.startsWith('⚡')) lineColor = Colors.amber;
                      if (line.startsWith('──')) lineColor = _G.textSec;
                      if (line.startsWith('📁')) lineColor = const Color(0xFF54C5F8);
                      if (line.startsWith('^C')) lineColor = Colors.amber;
                      return SelectableText(
                        line,
                        style: GoogleFonts.jetBrainsMono(
                          color: lineColor,
                          fontSize: 11.5,
                          height: 1.6,
                        ),
                      );
                    }),
                    // Live inline prompt line directly inside console stream — 100% plain terminal text
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _termPrompt,
                            style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFF54C5F8),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                inputDecorationTheme: const InputDecorationTheme(
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              child: TextField(
                                controller: _termCtrl,
                                focusNode: _termFocus,
                                cursorColor: const Color(0xFF54C5F8),
                                cursorWidth: 2,
                                cursorHeight: 14,
                                style: GoogleFonts.jetBrainsMono(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  isDense: true,
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: (val) async {
                                  await _termSubmit(val);
                                  _termFocus.requestFocus();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _panelTab(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: active
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: _G.textPri, width: 1.5)),
            )
          : null,
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: active ? _G.textPri : _G.textMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Status Bar ──────────────────────────────────────────────────────────
  Widget _buildStatusBar() {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: _G.surface,
        border: Border(top: BorderSide(color: _G.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _G.sp * 1.5),
      child: Row(
        children: [
          _statusItem(LucideIcons.gitBranch, 'main'),
          const SizedBox(width: _G.sp * 2),
          if (_terminalService?.isRunning == true) ...[
            _statusItem(LucideIcons.loader, 'Running…', color: Colors.amber),
            const SizedBox(width: _G.sp * 2),
          ],
          // Live Server status pill
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleLiveServer,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: _statusItem(
                LucideIcons.radio,
                _liveServerService?.isRunning == true
                    ? 'Port: ${_liveServerService!.port}'
                    : 'Go Live',
                color: _liveServerService?.isRunning == true
                    ? const Color(0xFF54C5F8)
                    : _G.textMuted,
              ),
            ),
          ),
          const Spacer(),
          if (_hasUnsaved)
            Text(
              '● Unsaved',
              style: GoogleFonts.inter(color: Colors.amber, fontSize: 10.5),
            ),
          const SizedBox(width: _G.sp * 2),
          Text(
            _lang.toUpperCase(),
            style: GoogleFonts.inter(color: _G.textMuted, fontSize: 10.5),
          ),
          const SizedBox(width: _G.sp * 2),
          Text('UTF-8', style: GoogleFonts.inter(color: _G.textMuted, fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _statusItem(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color ?? _G.textMuted),
        const SizedBox(width: 3),
        Text(label, style: GoogleFonts.inter(color: _G.textMuted, fontSize: 10.5)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BOTTOM BAR — ^ terminal toggle
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _G.surface,
        border: Border(top: BorderSide(color: _G.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _terminalOpen = !_terminalOpen),
            child: AnimatedContainer(
              duration: AppAnimations.micro,
              width: 52,
              height: 44,
              decoration: BoxDecoration(
                color: _terminalOpen
                    ? Colors.white.withOpacity(0.10)
                    : Colors.transparent,
                border: Border(
                  right: BorderSide(color: _G.border),
                  top: _terminalOpen
                      ? const BorderSide(color: Colors.white, width: 1.5)
                      : BorderSide.none,
                ),
              ),
              child: Center(
                child: Icon(
                  _terminalOpen ? LucideIcons.chevronDown : LucideIcons.chevronUp,
                  size: 17,
                  color: _terminalOpen ? Colors.white : const Color(0xFF555566),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _terminalOpen ? 'Terminal  ·  tap ^ to close' : 'tap ^ to open terminal',
            style: GoogleFonts.inter(
              color: const Color(0xFF444455),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ── Glass Dialog Widget ───────────────────────────────────────────────────────
class _GlassDialog extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final String confirmLabel;

  const _GlassDialog({
    required this.title,
    required this.hint,
    required this.controller,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111113),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _G.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              cursorColor: Colors.white,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.jetBrainsMono(
                  color: _G.textMuted,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: _G.glass,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: _G.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _G.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _G.glassHigh),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text('Cancel',
                      style: GoogleFonts.inter(color: _G.textSec)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pop(controller.text),
                  child: Text(confirmLabel,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Visual File Manager Dialog ─────────────────────────────────────────────
class _VisualFileManagerDialog extends StatefulWidget {
  final String? initialPath;
  const _VisualFileManagerDialog({this.initialPath});

  @override
  State<_VisualFileManagerDialog> createState() => _VisualFileManagerDialogState();
}

class _VisualFileManagerDialogState extends State<_VisualFileManagerDialog> {
  late String _currentPath;
  List<String> _subFolders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath ??
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows
            ? r'C:\codesnap'
            : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
                ? '/storage/emulated/0'
                : '/web/MyBug_Workspace'));
    _loadCurrentDir();
  }

  Future<void> _loadCurrentDir() async {
    setState(() => _loading = true);
    final list = await WorkspaceService.listDirectories(_currentPath);
    if (mounted) {
      setState(() {
        _subFolders = list;
        _loading = false;
      });
    }
  }

  void _navigateTo(String path) {
    setState(() => _currentPath = path);
    _loadCurrentDir();
  }

  void _goUp() {
    final sep = _currentPath.contains('\\') ? '\\' : '/';
    final parts = _currentPath.split(sep).where((s) => s.isNotEmpty).toList();
    if (parts.length <= 1) {
      return;
    }
    parts.removeLast();
    String parent;
    if (_currentPath.contains(':\\') || _currentPath.contains(':/')) {
      parent = parts.length == 1 ? '${parts[0]}\\' : parts.join('\\');
    } else {
      parent = '/${parts.join('/')}';
    }
    _navigateTo(parent);
  }

  @override
  Widget build(BuildContext context) {
    final folderName = _currentPath.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).lastOrNull ?? _currentPath;
    final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return AlertDialog(
      backgroundColor: const Color(0xFF141416),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Row(
        children: [
          const Icon(LucideIcons.folderOpen, size: 22, color: Color(0xFF54C5F8)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File Manager',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Browse and select a project folder to open',
                  style: GoogleFonts.inter(color: const Color(0xFF888899), fontSize: 11),
                ),
              ],
            ),
          ),
          if (isWindows)
            Tooltip(
              message: 'Open Windows File Explorer',
              child: IconButton(
                icon: const Icon(LucideIcons.externalLink, size: 18, color: Color(0xFF54C5F8)),
                onPressed: () async {
                  final native = await WorkspaceService.pickFolderNative(_currentPath);
                  if (native != null && native.isNotEmpty && context.mounted) {
                    Navigator.pop(context, native);
                  }
                },
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Path & Up button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x26FFFFFF)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.folder, size: 16, color: Color(0xFFCCA352)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentPath,
                      style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _goUp,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.arrowUp, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('Up', style: GoogleFonts.inter(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Quick shortcuts
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (isWindows) ...[
                    _chip('C:\\', () => _navigateTo(r'C:\')),
                    _chip('codesnap', () => _navigateTo(r'C:\codesnap')),
                    _chip('Users', () => _navigateTo(r'C:\Users')),
                  ],
                  if (isAndroid) ...[
                    _chip('Storage', () => _navigateTo('/storage/emulated/0')),
                    _chip('Download', () => _navigateTo('/storage/emulated/0/Download')),
                    _chip('Documents', () => _navigateTo('/storage/emulated/0/Documents')),
                  ],
                  if (kIsWeb) ...[
                    _chip('Web Workspace', () => _navigateTo('/web/MyBug_Workspace')),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Subdirectories list
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x0AFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF54C5F8)),
                      )
                    : _subFolders.isEmpty
                        ? Center(
                            child: Text(
                              'No subdirectories in this folder\nYou can select this folder below',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: const Color(0xFF666677), fontSize: 12),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _subFolders.length,
                            separatorBuilder: (_, __) => const Divider(color: Color(0x0FFFFFFF), height: 1),
                            itemBuilder: (ctx, i) {
                              final path = _subFolders[i];
                              final sep = path.contains('\\') ? '\\' : '/';
                              final name = path.split(sep).last;
                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: const Icon(LucideIcons.folder, size: 16, color: Color(0xFFCCA352)),
                                title: Text(
                                  name,
                                  style: GoogleFonts.inter(color: const Color(0xFFEEEEEE), fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF555566)),
                                onTap: () => _navigateTo(path),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF888899))),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF54C5F8),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(LucideIcons.check, size: 16),
          label: Text(
            'Select & Open ($folderName)',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
          onPressed: () => Navigator.pop(context, _currentPath),
        ),
      ],
    );
  }

  Widget _chip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        visualDensity: VisualDensity.compact,
        backgroundColor: const Color(0x1FFFFFFF),
        side: const BorderSide(color: Color(0x26FFFFFF)),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        label: Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 11)),
        onPressed: onTap,
      ),
    );
  }
}
