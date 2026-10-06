import 'browser_launcher.dart';

BrowserLauncherBase getPlatformBrowserLauncher() => BrowserLauncherStub();

class BrowserLauncherStub implements BrowserLauncherBase {
  @override
  void openUrl(String url) {}
}
