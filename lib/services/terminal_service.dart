import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'dart:io' if (dart.library.html) '../utils/web_io_stub.dart';

/// ─── TerminalService ─────────────────────────────────────────────────────────
/// • Android / Windows  → real OS shell via dart:io Process
/// • Web Chrome         → simulated responses (kIsWeb guard)
class TerminalService {
  Process? _activeProcess;
  String _workingDirectoryPath;
  final void Function(String) onLog;
  final void Function()? onProcessEnd;
  final void Function()? onLivePreviewRequest;

  TerminalService({
    required String workingDirectoryPath,
    required this.onLog,
    this.onProcessEnd,
    this.onLivePreviewRequest,
  }) : _workingDirectoryPath = workingDirectoryPath;

  bool get isRunning => _activeProcess != null;
  String get workingDirectory => _workingDirectoryPath;

  void setWorkingDirectory(String newPath) {
    _workingDirectoryPath = newPath;
  }

  String get prompt {
    if (kIsWeb) return 'bug-web> ';
    try {
      final sep   = _workingDirectoryPath.contains('\\') ? '\\' : '/';
      final parts = _workingDirectoryPath.split(sep).where((s) => s.isNotEmpty).toList();
      return 'bug@${parts.last}> ';
    } catch (_) {
      return 'bug> ';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  Future<void> runCommand(String commandLine) async {
    final cmd = commandLine.trim();
    if (cmd.isEmpty) return;

    onLog('$prompt$cmd');

    // ── Built-in commands (all platforms) ─────────────────────────────────
    switch (cmd) {
      case 'clear':
        onLog('__CLEAR__');
        return;
      case 'live':
      case 'serve':
      case 'preview':
        onLog('🌐 Launching Live Server & browser preview…');
        onLivePreviewRequest?.call();
        return;
      case 'help':
        onLog('── Bug Terminal Help ─────────────────');
        if (kIsWeb) {
          onLog('⚠️  Web mode — real execution needs Android/Windows app.');
          onLog('  ls      list workspace files');
          onLog('  status  show workspace info');
          onLog('  clear   clear terminal');
        } else {
          onLog('  live / serve    start Live Server & preview in browser');
          onLog('  python <file>   run Python script');
          onLog('  node <file>     run JavaScript');
          onLog('  ls / dir        list files');
          onLog('  clear           clear terminal');
          onLog('  status          workspace info');
        }
        return;
      case 'status':
        onLog('── Workspace Status ──────────────────');
        onLog('Path     : $_workingDirectoryPath');
        onLog('Platform : ${kIsWeb ? "Web (Chrome)" : _nativePlatformName()}');
        onLog('Mode     : ${kIsWeb ? "In-memory preview" : "Real filesystem"}');
        return;
    }

    // ── Web: friendly simulation ──────────────────────────────────────────
    if (kIsWeb) {
      _simulateWeb(cmd);
      return;
    }

    // ── Native: real process ──────────────────────────────────────────────
    if (_activeProcess != null) {
      onLog('⚠️  A process is already running. Stop it first (■ button).');
      return;
    }

    try {
      final parts = _split(cmd);
      final exec  = parts.first;
      final args  = parts.length > 1 ? parts.sublist(1) : <String>[];

      onLog('⚡ Starting $exec…');

      _activeProcess = await Process.start(
        exec,
        args,
        workingDirectory: _workingDirectoryPath,
        runInShell: true,
      );

      _activeProcess!.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen((l) => onLog(sanitizeTerminalLine(l)));

      _activeProcess!.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen((l) => onLog('❌ ${sanitizeTerminalLine(l)}'));

      final code = await _activeProcess!.exitCode;
      _activeProcess = null;
      onLog('✓ Done  (exit $code)');
      onProcessEnd?.call();
    } catch (e) {
      _activeProcess = null;
      onLog('❌ Error: $e');
      onProcessEnd?.call();
    }
  }

  static final _ansiRegex = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');

  static String sanitizeTerminalLine(String raw) {
    var line = raw.replaceAll(_ansiRegex, '');
    line = line.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    
    // Clean unpaired UTF-16 surrogates safely across all Dart versions
    final buffer = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final codeUnit = line.codeUnitAt(i);
      if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
        // High surrogate - check next code unit
        if (i + 1 < line.length) {
          final nextUnit = line.codeUnitAt(i + 1);
          if (nextUnit >= 0xDC00 && nextUnit <= 0xDFFF) {
            // Valid surrogate pair
            buffer.writeCharCode(codeUnit);
            buffer.writeCharCode(nextUnit);
            i++;
            continue;
          }
        }
        // Unpaired high surrogate -> replace with standard replacement character
        buffer.write('\uFFFD');
      } else if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
        // Unpaired low surrogate
        buffer.write('\uFFFD');
      } else {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  // ── Web simulation ────────────────────────────────────────────────────────
  void _simulateWeb(String cmd) {
    final lo = cmd.toLowerCase();
    if (lo.startsWith('python') || lo.startsWith('py ')) {
      onLog('⚠️  Python needs the Android or Windows app.');
    } else if (lo.startsWith('node')) {
      onLog('⚠️  Node.js not available in web preview.');
    } else if (lo == 'ls' || lo == 'dir') {
      onLog('index.html    style.css    script.js');
      onLog('main.py       README.md    src/');
    } else if (lo == 'pwd') {
      onLog(_workingDirectoryPath);
    } else {
      onLog('⚠️  "$cmd" — shell commands run on Android/Windows only.');
    }
    onProcessEnd?.call();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _nativePlatformName() {
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isLinux)   return 'Linux';
      if (Platform.isMacOS)   return 'macOS';
      if (Platform.isIOS)     return 'iOS';
    } catch (_) {}
    return 'Native';
  }

  void sendInput(String input) {
    if (kIsWeb || _activeProcess == null) {
      onLog('⚠️  No running process.');
      return;
    }
    _activeProcess!.stdin.writeln(input);
  }

  void killProcess() {
    if (!kIsWeb && _activeProcess != null) {
      final pid = _activeProcess!.pid;
      if (Platform.isWindows) {
        Process.run('taskkill', ['/F', '/T', '/PID', pid.toString()]);
      }
      _activeProcess!.kill();
      _activeProcess = null;
      onLog('🛑 Process terminated.');
      onProcessEnd?.call();
    }
  }

  void dispose() => killProcess();

  List<String> _split(String input) {
    final result = <String>[];
    bool inQ = false;
    final buf = StringBuffer();
    for (final ch in input.split('')) {
      if (ch == '"' || ch == "'") { inQ = !inQ; }
      else if (ch == ' ' && !inQ) { if (buf.isNotEmpty) { result.add(buf.toString()); buf.clear(); } }
      else { buf.write(ch); }
    }
    if (buf.isNotEmpty) result.add(buf.toString());
    return result;
  }
}
