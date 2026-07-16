/// Model for open editor tabs.
class EditorTab {
  final String filePath;
  final String fileName;
  bool isModified;
  String content;

  EditorTab({
    required this.filePath,
    required this.fileName,
    this.isModified = false,
    this.content = '',
  });

  String get title => isModified ? '• $fileName' : fileName;
}
