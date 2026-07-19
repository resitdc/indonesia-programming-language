import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';

/// Service untuk manajemen project: create, open, recent list.
class ProjectService {
  static const _recentProjectsKey = 'recent_projects';
  static const _maxRecent = 10;

  /// Load daftar recent projects dari shared_preferences.
  static Future<List<Project>> getRecentProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getStringList(_recentProjectsKey) ?? [];
    final projects = json
        .map((s) => Project.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    // Sort by lastOpened descending
    projects.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    return projects;
  }

  /// Simpan project ke recent list.
  static Future<void> addToRecent(Project project) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getRecentProjects();

    // Remove existing entry with same path
    existing.removeWhere((p) => p.path == project.path);

    // Insert at beginning
    existing.insert(0, project);

    // Keep max _maxRecent
    if (existing.length > _maxRecent) {
      existing.removeRange(_maxRecent, existing.length);
    }

    final json = existing.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_recentProjectsKey, json);
  }

  /// Touch — update lastOpened time.
  static Future<void> touchProject(Project project) async {
    await addToRecent(project.copyWith(lastOpened: DateTime.now()));
  }

  /// Hapus project dari recent list.
  static Future<void> removeFromRecent(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getRecentProjects();
    existing.removeWhere((p) => p.path == path);
    final json = existing.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_recentProjectsKey, json);
  }

  /// Export project folder ke file ZIP.
  static Future<String> exportToZip(String projectPath) async {
    final projectDir = Directory(projectPath);
    if (!projectDir.existsSync()) {
      throw Exception('Folder project tidak ditemukan.');
    }

    final projectName = projectPath.split(Platform.pathSeparator).last;
    final archive = Archive();

    // Scan all files recursively
    for (var entity in projectDir.listSync(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.substring(projectPath.length + 1);
        final name = relativePath.split(Platform.pathSeparator).last;
        // Skip hidden files and build folders
        if (name.startsWith('.')) continue;
        if (relativePath.startsWith('build')) continue;

        try {
          final bytes = entity.readAsBytesSync();
          archive.addFile(ArchiveFile(
            relativePath.replaceAll(Platform.pathSeparator, '/'),
            bytes.length,
            bytes,
          ));
        } catch (_) {
          // Skip unreadable files
        }
      }
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final zipFileName = '${projectName}_${DateTime.now().millisecondsSinceEpoch}.zip';
    final zipPath = '${docsDir.path}${Platform.pathSeparator}$zipFileName';

    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      File(zipPath).writeAsBytesSync(zipData);
    } else {
      throw Exception('Gagal membuat file ZIP.');
    }

    return zipPath;
  }

  static Future<Project> createProject({
    required String name,
    required String parentPath,
    required ProjectTemplate template,
  }) async {
    final projectPath = '$parentPath${Platform.pathSeparator}$name';

    final dir = Directory(projectPath);
    if (await dir.exists()) {
      throw Exception('Folder "$projectPath" sudah ada.');
    }
    await dir.create(recursive: true);

    switch (template) {
      case ProjectTemplate.console:
        await File(
          '$projectPath/main.rpl',
        ).writeAsString(_consoleTemplate(name));
        break;
      default:
        await File(
          '$projectPath/main.rpl',
        ).writeAsString(_consoleTemplate(name));
        break;
    }

    final project = Project(
      name: name,
      path: projectPath,
      template: template,
      createdAt: DateTime.now(),
      lastOpened: DateTime.now(),
    );

    await addToRecent(project);
    return project;
  }

  //#region Templates
  static String _consoleTemplate(String name) => '''tampilkan "Halo Dunia"''';
  //#endregion
}
