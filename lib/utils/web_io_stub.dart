// ── web_io_stub.dart ──────────────────────────────────────────────────────────
// Stub implementations of dart:io types for Flutter Web builds.
// Used via conditional import:
//   import 'dart:io' if (dart.library.html) '../utils/web_io_stub.dart';
//
// On web, dart.library.html is present, so this file replaces dart:io.
// All methods are no-ops / return safe defaults — the real kIsWeb guards in
// WorkspaceService and TerminalService ensure they are never actually called.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:typed_data';

class Platform {
  static bool get isWindows => false;
  static bool get isLinux   => false;
  static bool get isMacOS   => false;
  static bool get isAndroid => false;
  static bool get isIOS     => false;
  static String get operatingSystem        => 'web';
  static String get operatingSystemVersion => 'Web';
  static Map<String, String> get environment => const {};
}

abstract class FileSystemEntity {
  final String path;
  FileSystemEntity(this.path);

  static Future<bool> isDirectory(String path) async => false;
  static Future<bool> isFile(String path)      async => false;

  Future<FileSystemEntity> delete({bool recursive = false}) async => this;
}

class Directory extends FileSystemEntity {
  Directory(super.path);

  static Directory get current  => Directory('/');
  static Directory get systemTemp => Directory('/tmp');

  Directory get parent => Directory('/');

  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
  Future<Directory> rename(String newPath) async => Directory(newPath);
  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async => this;
  Stream<FileSystemEntity> list({
    bool recursive   = false,
    bool followLinks = true,
  }) => const Stream.empty();
}

class File extends FileSystemEntity {
  File(super.path);

  Future<bool>   exists() async => false;
  Future<File>   create({bool recursive = false}) async => this;
  Future<String> readAsString({dynamic encoding}) async => '';
  Future<Uint8List> readAsBytes() async => Uint8List(0);
  Future<File>   writeAsString(
    String contents, {
    dynamic encoding,
    dynamic mode,
    bool flush = false,
  }) async => this;
  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async => this;
  Future<File>   rename(String newPath) async => File(newPath);
}

// ── Process stubs ─────────────────────────────────────────────────────────────

class _StubSink {
  void writeln([Object? obj = '']) {}
  void write(Object? obj) {}
  Future<void> close() async {}
}

class ProcessResult {
  final int pid;
  final int exitCode;
  final dynamic stdout;
  final dynamic stderr;
  ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}

class Process {
  final int pid = 0;
  final Stream<List<int>> stdout = const Stream.empty();
  final Stream<List<int>> stderr = const Stream.empty();
  final _StubSink stdin = _StubSink();

  Future<int> get exitCode async => 0;
  bool kill([dynamic signal]) => false;

  static Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = false,
    Map<String, String>? environment,
  }) async => Process._();

  static Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    dynamic stdoutEncoding,
    dynamic stderrEncoding,
  }) async => ProcessResult(0, 0, '', '');

  Process._();
}

// ── ProcessSignal stub ────────────────────────────────────────────────────────
class ProcessSignal {
  static final sigterm = ProcessSignal._('SIGTERM');
  final String _name;
  ProcessSignal._(this._name);
  @override String toString() => _name;
}

// ── HTTP Stubs ─────────────────────────────────────────────────────────────
class InternetAddress {
  static final loopbackIPv4 = InternetAddress._('127.0.0.1');
  final String address;
  InternetAddress._(this.address);
}

class ContentType {
  final String primaryType;
  final String subType;
  final String? charset;
  ContentType(this.primaryType, this.subType, {this.charset});
  static final html = ContentType('text', 'html', charset: 'utf-8');
  static final json = ContentType('application', 'json', charset: 'utf-8');
  static final binary = ContentType('application', 'octet-stream');
}

class HttpStatus {
  static const ok = 200;
  static const notFound = 404;
  static const internalServerError = 500;
}

class HttpHeaders {
  dynamic contentType;
  void add(String name, Object value) {}
  void set(String name, Object value) {}
}

class HttpResponse {
  int statusCode = 200;
  final HttpHeaders headers = HttpHeaders();
  void write(Object? obj) {}
  void add(List<int> data) {}
  Future<void> close() async {}
}

class HttpRequest {
  final String method = 'GET';
  final Uri uri = Uri();
  final HttpResponse response = HttpResponse();
}

class HttpServer {
  final int port = 0;
  Future<void> close({bool force = false}) async {}
  static Future<HttpServer> bind(dynamic host, int port, {int backlog = 0, bool v6Only = false, bool shared = false}) async => HttpServer();
  Stream<HttpRequest> asStream() => const Stream.empty();
  dynamic listen(void Function(HttpRequest)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) => null;
}

