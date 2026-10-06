// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'browser_launcher.dart';

BrowserLauncherBase getPlatformBrowserLauncher() => BrowserLauncherWeb();

class BrowserLauncherWeb implements BrowserLauncherBase {
  @override
  void openUrl(String url) {
    try {
      html.window.open(url, '_blank');
    } catch (_) {}
  }
}
