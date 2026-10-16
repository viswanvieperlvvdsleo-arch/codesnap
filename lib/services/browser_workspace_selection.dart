class BrowserWorkspaceSelection {
  final String projectName;
  final Map<String, String> files;
  final int skippedFiles;
  final int totalBytes;

  const BrowserWorkspaceSelection({
    required this.projectName,
    required this.files,
    required this.skippedFiles,
    required this.totalBytes,
  });
}
