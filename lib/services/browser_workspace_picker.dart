import 'browser_workspace_selection.dart';
import 'browser_workspace_picker_stub.dart'
    if (dart.library.html) 'browser_workspace_picker_web.dart' as platform;

Future<BrowserWorkspaceSelection?> pickBrowserWorkspace({
  required bool folder,
}) {
  return platform.pickBrowserWorkspace(folder: folder);
}
