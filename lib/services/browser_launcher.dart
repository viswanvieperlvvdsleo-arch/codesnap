import 'browser_launcher_stub.dart'
    if (dart.library.html) 'browser_launcher_web.dart';

abstract class BrowserLauncherBase {
  void openUrl(String url);
}

BrowserLauncherBase getBrowserLauncher() => getPlatformBrowserLauncher();

void openInBrowser(String url) {
  getBrowserLauncher().openUrl(url);
}
