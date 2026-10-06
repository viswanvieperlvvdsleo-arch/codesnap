import 'dart:async';
import 'package:flutter/foundation.dart';

// Conditional import: dart:io on native, stub on web
import 'dart:io' if (dart.library.html) '../utils/web_io_stub.dart';

/// ─── LiveServerService ────────────────────────────────────────────────────────
/// High-performance built-in HTTP static server for local web projects.
/// Automatically serves HTML, CSS, JS, images, fonts, and assets from the workspace folder.
/// Works natively on Windows, macOS, and Linux without requiring external dependencies (like Node or Python).
class LiveServerService {
  HttpServer? _server;
  StreamSubscription<HttpRequest>? _sub;
  String? _rootPath;
  int _port = 5050;

  bool get isRunning => _server != null;
  int get port => _port;
  String? get rootPath => _rootPath;
  String get url => 'http://localhost:$_port';

  /// Starts the local HTTP static file server
  Future<bool> start({required String rootPath, int initialPort = 5050}) async {
    if (kIsWeb) return false;
    _rootPath = rootPath;

    // If already running on this path, keep it
    if (_server != null) {
      await stop();
    }

    // Try starting on initialPort or subsequent ports if in use
    int attemptPort = initialPort;
    for (int i = 0; i < 5; i++) {
      try {
        _server = await HttpServer.bind(InternetAddress.loopbackIPv4, attemptPort);
        _port = _server!.port;
        break;
      } catch (_) {
        attemptPort++;
      }
    }

    // Fallback to random available OS port if all attempts were busy
    if (_server == null) {
      try {
        _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        _port = _server!.port;
      } catch (e) {
        debugPrint('Failed to start Live Server: $e');
        return false;
      }
    }

    _sub = _server!.listen(_handleRequest);
    return true;
  }

  /// Stops the local HTTP server
  Future<void> stop() async {
    try {
      await _sub?.cancel();
      _sub = null;
      await _server?.close(force: true);
      _server = null;
    } catch (_) {}
  }

  ContentType _getContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.html') || lower.endsWith('.htm')) return ContentType.html;
    if (lower.endsWith('.css')) return ContentType('text', 'css', charset: 'utf-8');
    if (lower.endsWith('.js') || lower.endsWith('.mjs')) return ContentType('application', 'javascript', charset: 'utf-8');
    if (lower.endsWith('.json')) return ContentType.json;
    if (lower.endsWith('.svg')) return ContentType('image', 'svg+xml');
    if (lower.endsWith('.png')) return ContentType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return ContentType('image', 'jpeg');
    if (lower.endsWith('.gif')) return ContentType('image', 'gif');
    if (lower.endsWith('.webp')) return ContentType('image', 'webp');
    if (lower.endsWith('.ico')) return ContentType('image', 'x-icon');
    if (lower.endsWith('.woff')) return ContentType('font', 'woff');
    if (lower.endsWith('.woff2')) return ContentType('font', 'woff2');
    if (lower.endsWith('.ttf')) return ContentType('font', 'ttf');
    return ContentType.binary;
  }

  Future<void> _handleRequest(HttpRequest req) async {
    try {
      // CORS headers for seamless preview
      req.response.headers.add('Access-Control-Allow-Origin', '*');
      req.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      req.response.headers.add('Access-Control-Allow-Headers', '*');

      if (req.method == 'OPTIONS') {
        req.response.statusCode = HttpStatus.ok;
        await req.response.close();
        return;
      }

      String reqPath = req.uri.path;
      if (reqPath.isEmpty || reqPath == '/' || reqPath.endsWith('/')) {
        reqPath = '${reqPath}index.html';
      }

      // Sanitize against directory traversal attacks
      if (reqPath.startsWith('/')) reqPath = reqPath.substring(1);
      final parts = reqPath.split('/').where((s) => s.isNotEmpty && s != '..').toList();
      final cleanSubPath = parts.join('/');

      final root = _rootPath ?? '';
      final sep = root.contains('\\') ? '\\' : '/';
      final fullPath = cleanSubPath.isEmpty ? root : '$root$sep${cleanSubPath.replaceAll('/', sep)}';

      final file = File(fullPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        req.response.headers.contentType = _getContentType(fullPath);
        req.response.statusCode = HttpStatus.ok;
        req.response.add(bytes);
        await req.response.close();
      } else {
        req.response.statusCode = HttpStatus.notFound;
        req.response.headers.contentType = ContentType.html;
        req.response.write('''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>404 Not Found — CodeSnap Live Server</title>
  <style>
    body { background: #09090b; color: #f4f4f5; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
    .card { background: #18181b; border: 1px solid rgba(255,255,255,0.1); border-radius: 16px; padding: 32px; max-width: 480px; text-align: center; }
    h1 { font-size: 24px; color: #f87171; margin-bottom: 8px; }
    p { color: #a1a1aa; font-size: 14px; line-height: 1.5; }
    code { background: rgba(255,255,255,0.06); padding: 2px 6px; border-radius: 4px; color: #38bdf8; font-family: monospace; }
  </style>
</head>
<body>
  <div class="card">
    <h1>404 Not Found</h1>
    <p>The requested file <code>$reqPath</code> does not exist in this workspace folder.</p>
  </div>
</body>
</html>''');
        await req.response.close();
      }
    } catch (e) {
      try {
        req.response.statusCode = HttpStatus.internalServerError;
        req.response.write('Internal Server Error: $e');
        await req.response.close();
      } catch (_) {}
    }
  }

  /// Launch default web browser to a URL or file path on Windows/Mac/Linux
  static Future<bool> launchBrowser(String target) async {
    if (kIsWeb) return false;
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', target]);
        return true;
      } else if (Platform.isMacOS) {
        await Process.run('open', [target]);
        return true;
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [target]);
        return true;
      }
    } catch (e) {
      debugPrint('Error launching browser: $e');
    }
    return false;
  }
}
