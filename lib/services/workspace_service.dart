import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Conditional import: dart:io on native, our stub on web
import 'dart:io' if (dart.library.html) '../utils/web_io_stub.dart';

/// ─── FileNode ─────────────────────────────────────────────────────────────────
class FileNode {
  final String name;
  final String path;
  final bool isFolder;
  final List<FileNode> children;
  bool expanded;

  FileNode({
    required this.name,
    required this.path,
    this.isFolder = false,
    this.children = const [],
    this.expanded = false,
  });
}

/// ─── WorkspaceService ─────────────────────────────────────────────────────────
/// • Android / Windows  → real dart:io filesystem
/// • Web (Chrome)       → in-memory Map<String,String> (no filesystem access)
class WorkspaceService {
  WorkspaceService._();

  // ── In-memory store for Web ───────────────────────────────────────────────
  static final Map<String, String> _webFiles = {};
  static String _webRoot = '/web/MyBug_Workspace';

  // ── Starter templates ─────────────────────────────────────────────────────
  static String _html(String t) => '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$t</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <div class="container">
    <h1>🚀 $t</h1>
    <p>Bug Workspace — edit me!</p>
    <button id="btn">Click Me</button>
    <p id="out"></p>
  </div>
  <script src="script.js"></script>
</body>
</html>''';

  static const _css = '''body {
  margin: 0; padding: 40px;
  background: #09090b; color: #fff;
  font-family: system-ui, sans-serif;
  display: flex; justify-content: center; align-items: center;
  min-height: 100vh;
}
.container {
  background: rgba(255,255,255,.08);
  padding: 32px; border-radius: 24px;
  border: 1px solid rgba(255,255,255,.2);
  text-align: center; max-width: 400px;
}
h1 { background: linear-gradient(135deg,#a855f7,#ec4899);
     -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
button {
  background: #fff; color: #000; border: none;
  padding: 12px 24px; border-radius: 99px;
  font-weight: bold; cursor: pointer; margin-top: 16px;
  transition: transform .2s;
}
button:hover { transform: translateY(-2px); }''';

  static const _js = '''document.getElementById('btn').addEventListener('click', () => {
  const out = document.getElementById('out');
  out.textContent = '✨ Running in Bug Workspace!';
  out.style.color = '#4ade80';
  out.style.fontWeight = 'bold';
});''';

  static const _py = '''# Bug Python Workspace
import sys

def main():
    print("🐍 Python ready!")
    print(f"Version: {sys.version}")
    numbers = [10, 20, 30, 40, 50]
    total   = sum(numbers)
    print(f"Sum: {total}  Average: {total/len(numbers)}")

if __name__ == "__main__":
    main()''';

  static String _readme(String t) => '# $t\nCreated in **Bug Workspace**.\n\n'
      '- `index.html` — HTML page\n- `style.css` — Styles\n'
      '- `script.js` — JavaScript\n- `main.py` — Python\n';

  // ─────────────────────────────────────────────────────────────────────────
  //  getWorkspaceRootPath
  // ─────────────────────────────────────────────────────────────────────────
  static Future<String> getWorkspaceRootPath(String projectName) async {
    final clean = projectName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

    if (kIsWeb) {
      _webRoot = '/web/$clean';
      if (_webFiles.isEmpty) _seedWeb(clean, projectName);
      return _webRoot;
    }

    // ── Native ───────────────────────────────────────────────────────────
    Directory baseDir;
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['USERPROFILE'] ??
            Platform.environment['HOME'] ??
            Directory.current.path;
        baseDir = Directory('$home/MyBugWorkspaces');
      } else {
        baseDir = Directory('${Directory.systemTemp.path}/MyBugWorkspaces');
      }
    } catch (_) {
      baseDir = Directory('${Directory.systemTemp.path}/MyBugWorkspaces');
    }

    if (!await baseDir.exists()) await baseDir.create(recursive: true);

    final projectDir = Directory('${baseDir.path}/$clean');
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
      await _seedNative(projectDir, projectName);
    }
    return projectDir.path;
  }

  // ── Seed helpers ──────────────────────────────────────────────────────────
  static void _seedWeb(String clean, String title) {
    final r = '/web/$clean';
    _webFiles['$r/index.html'] = _html(title);
    _webFiles['$r/style.css']  = _css;
    _webFiles['$r/script.js']  = _js;
    _webFiles['$r/main.py']    = _py;
    _webFiles['$r/README.md']  = _readme(title);
  }

  static Future<void> _seedNative(Directory root, String title) async {
    await File('${root.path}/index.html').writeAsString(_html(title));
    await File('${root.path}/style.css').writeAsString(_css);
    await File('${root.path}/script.js').writeAsString(_js);
    await File('${root.path}/main.py').writeAsString(_py);
    await File('${root.path}/README.md').writeAsString(_readme(title));
    await Directory('${root.path}/src').create();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  loadTree
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<FileNode>> loadTree(String rootPath) async {
    if (kIsWeb) return _webTree(rootPath);
    return _nativeTree(Directory(rootPath));
  }

  static List<FileNode> _webTree(String root) {
    final Map<String, List<FileNode>> folders = {};
    final List<FileNode> rootFiles = [];
    final Set<String> seen = {};

    for (final p in _webFiles.keys) {
      if (!p.startsWith('$root/')) continue;
      final rel   = p.substring(root.length + 1);
      final parts = rel.split('/');

      if (parts.length == 1) {
        if (!seen.contains(p)) { seen.add(p); rootFiles.add(FileNode(name: parts[0], path: p)); }
      } else {
        final folder = parts[0];
        folders.putIfAbsent(folder, () => []);
        final fp = '$root/$folder/${parts.last}';
        if (!seen.contains(fp)) {
          seen.add(fp);
          folders[folder]!.add(FileNode(name: parts.last, path: fp));
        }
      }
    }

    final result = <FileNode>[
      ...folders.entries.map((e) => FileNode(
        name: e.key, path: '$root/${e.key}', isFolder: true, children: e.value,
      )),
      ...rootFiles,
    ];
    result.sort((a, b) {
      if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  static Future<List<FileNode>> _nativeTree(Directory dir) async {
    if (!await dir.exists()) return [];
    try {
      final list = await dir.list(recursive: false, followLinks: false).toList();
      final folders = <FileNode>[];
      final files   = <FileNode>[];
      for (final e in list) {
        final name = e.path.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).last;
        if (name.startsWith('.')) continue;
        if (e is Directory) {
          folders.add(FileNode(name: name, path: e.path, isFolder: true,
              children: await _nativeTree(Directory(e.path))));
        } else if (e is File) {
          files.add(FileNode(name: name, path: e.path));
        }
      }
      folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return [...folders, ...files];
    } catch (ex) { return []; }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Read / Write
  // ─────────────────────────────────────────────────────────────────────────
  static Future<String> readFile(String path) async {
    if (kIsWeb) return _webFiles[path] ?? '';
    try {
      final f = File(path);
      if (!await f.exists()) return '';
      try {
        return await f.readAsString(encoding: utf8);
      } catch (_) {
        try {
          return await f.readAsString(encoding: latin1);
        } catch (_) {
          return '';
        }
      }
    } catch (_) { return ''; }
  }

  static Future<Uint8List?> readBytes(String path) async {
    if (kIsWeb) return null;
    try {
      final f = File(path);
      if (await f.exists()) {
        final bytes = await f.readAsBytes();
        return Uint8List.fromList(bytes);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> fileExists(String path) async {
    if (kIsWeb) return _webFiles.containsKey(path);
    try {
      return await File(path).exists();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> writeFile(String path, String content) async {
    if (kIsWeb) { _webFiles[path] = content; return true; }
    try {
      final f = File(path);
      if (!await f.exists()) await f.create(recursive: true);
      await f.writeAsString(content, encoding: utf8, flush: true);
      return true;
    } catch (_) { return false; }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Create
  // ─────────────────────────────────────────────────────────────────────────
  static Future<bool> createFile(String parent, String name, [String init = '']) async {
    final full = '$parent/$name';
    if (kIsWeb) { _webFiles[full] = init; return true; }
    try {
      final f = File(full);
      if (!await f.exists()) await f.create(recursive: true);
      if (init.isNotEmpty) await f.writeAsString(init, encoding: utf8);
      return true;
    } catch (_) { return false; }
  }

  static Future<bool> createFolder(String parent, String name) async {
    if (kIsWeb) { _webFiles['$parent/$name/.keep'] = ''; return true; }
    try {
      final d = Directory('$parent/$name');
      if (!await d.exists()) await d.create(recursive: true);
      return true;
    } catch (_) { return false; }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Delete
  // ─────────────────────────────────────────────────────────────────────────
  static Future<bool> deleteNode(String path, bool isFolder) async {
    if (kIsWeb) { _webFiles.removeWhere((k, _) => k.startsWith(path)); return true; }
    try {
      if (isFolder) {
        final d = Directory(path);
        if (await d.exists()) { await d.delete(recursive: true); return true; }
      } else {
        final f = File(path);
        if (await f.exists()) { await f.delete(); return true; }
      }
    } catch (_) {}
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Rename
  // ─────────────────────────────────────────────────────────────────────────
  static Future<String?> renameNode(String oldPath, String newName) async {
    final sep     = oldPath.contains('\\') ? '\\' : '/';
    final parts   = oldPath.split(sep);
    parts.last    = newName;
    final newPath = parts.join(sep);

    if (kIsWeb) {
      for (final key in Map.of(_webFiles).keys) {
        if (key.startsWith(oldPath)) {
          _webFiles[key.replaceFirst(oldPath, newPath)] = _webFiles.remove(key)!;
        }
      }
      return newPath;
    }
    try {
      if (await FileSystemEntity.isDirectory(oldPath)) {
        await Directory(oldPath).rename(newPath);
      } else {
        await File(oldPath).rename(newPath);
      }
      return newPath;
    } catch (_) { return null; }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Native & Visual Folder Picker
  // ─────────────────────────────────────────────────────────────────────────
  static Future<String?> pickFolderNative([String? initialPath]) async {
    if (kIsWeb) return null;
    if (Platform.isWindows) {
      try {
        final init = (initialPath != null && initialPath.isNotEmpty)
            ? initialPath.replaceAll("'", "''")
            : '';
        final script = '''
Add-Type -AssemblyName System.Windows.Forms;
\$f = New-Object System.Windows.Forms.FolderBrowserDialog;
\$f.Description = 'Select Project Folder to open in Bug Workspace';
\$f.ShowNewFolderButton = \$true;
\$f.AutoUpgradeEnabled = \$true;
if ('$init' -ne '' -and (Test-Path '$init')) { \$f.SelectedPath = '$init' }
\$top = New-Object System.Windows.Forms.Form;
\$top.TopMost = \$true;
if (\$f.ShowDialog(\$top) -eq [System.Windows.Forms.DialogResult]::OK) {
    [Console]::Out.Write(\$f.SelectedPath)
}
''';
        final res = await Process.run('powershell', [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          script,
        ]);
        if (res.exitCode == 0) {
          final path = res.stdout.toString().trim();
          if (path.isNotEmpty && await Directory(path).exists()) {
            return path;
          }
        }
      } catch (e) {
        debugPrint('Native folder picker error: $e');
      }
    }
    return null;
  }

  static Future<List<String>> listDirectories(String currentPath) async {
    if (kIsWeb) {
      return [
        '$currentPath/src',
        '$currentPath/components',
        '$currentPath/public',
        '$currentPath/utils',
      ];
    }
    try {
      final dir = Directory(currentPath);
      if (!await dir.exists()) return [];
      final List<String> list = [];
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory) {
          final sep = entity.path.contains('\\') ? '\\' : '/';
          final name = entity.path.split(sep).last;
          if (!name.startsWith('.') && name != 'node_modules' && name != 'build') {
            list.add(entity.path);
          }
        }
      }
      list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return list;
    } catch (_) {
      return [];
    }
  }
}
