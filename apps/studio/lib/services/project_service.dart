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

    // Write ZIP to downloads/documents directory
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

  /// Buat project baru dengan template.
  static Future<Project> createProject({
    required String name,
    required String parentPath,
    required ProjectTemplate template,
  }) async {
    final projectPath = '$parentPath${Platform.pathSeparator}$name';

    // Buat direktori project
    final dir = Directory(projectPath);
    if (await dir.exists()) {
      throw Exception('Folder "$projectPath" sudah ada.');
    }
    await dir.create(recursive: true);

    // Buat file sesuai template
    switch (template) {
      case ProjectTemplate.console:
        await File(
          '$projectPath/main.rpl',
        ).writeAsString(_consoleTemplate(name));
        break;
      case ProjectTemplate.website:
        await dir.create(recursive: true);
        await File(
          '$projectPath/server.rpl',
        ).writeAsString(_websiteTemplate(name));
        final tampilanDir = Directory('$projectPath/tampilan');
        await tampilanDir.create();
        await File(
          '$projectPath/tampilan/index.rpl.html',
        ).writeAsString(_websiteHtmlTemplate(name));
        break;
      case ProjectTemplate.restApi:
        await File(
          '$projectPath/server.rpl',
        ).writeAsString(_restApiTemplate(name));
        final kontrolerDir = Directory('$projectPath/kontroler');
        await kontrolerDir.create();
        await File(
          '$projectPath/kontroler/contoh.rpl',
        ).writeAsString(_restApiControllerTemplate());
        break;
      case ProjectTemplate.desktop:
        await File(
          '$projectPath/main.rpl',
        ).writeAsString(_consoleTemplate(name));
        break;
      case ProjectTemplate.library:
        await File(
          '$projectPath/$name.rpl',
        ).writeAsString(_libraryTemplate(name));
        break;
      case ProjectTemplate.cli:
        await File('$projectPath/main.rpl').writeAsString(_cliTemplate(name));
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

  // ======== Templates ========

  static String _consoleTemplate(String name) =>
      '''// Project: $name
// Template: Console

tampilkan("Halo dari $name!")
tampilkan("Dimulai pada \${waktu.sekarang()}")

buat nama = "Pemula"
tampilkan("Selamat belajar, \$nama!")
''';

  static String _websiteTemplate(String name) => '''// Project: $name
// Template: Website

db.hubungkan("sqlite://data.db")

web.get("/", fungsi(req)
    kembalikan web.render("tampilan/index.rpl.html")
selesai)

web.jalankan(3000)
''';

  static String _websiteHtmlTemplate(String name) =>
      '''<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$name</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; max-width: 600px; margin: 2rem auto; padding: 1rem; }
        h1 { color: #2563eb; }
    </style>
</head>
<body>
    <h1>Halo dari $name! 🚀</h1>
    <p>Selamat datang di project website RPL.</p>
</body>
</html>
''';

  static String _restApiTemplate(String name) =>
      '''// Project: $name
// Template: REST API

db.hubungkan("sqlite://data.db")

// Inisialisasi tabel (opsional)
db.kueri("CREATE TABLE IF NOT EXISTS contoh (id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT)")

buat kontroler = pakai "kontroler/contoh.rpl"

web.get("/api/halo", fungsi(req)
    kembalikan {
        "status": 200,
        "json": { "pesan": "Halo dari $name!" }
    }
selesai)

web.jalankan(3000)
''';

  static String _restApiControllerTemplate() =>
      '''buat ambil_semua = fungsi(req)
    buat hasil = db.kueri("SELECT * FROM contoh")
    kembalikan hasil
selesai

buat tambah = fungsi(req)
    buat data = req.tubuh
    db.kueri("INSERT INTO contoh (nama) VALUES ('" + data.nama + "')")
    kembalikan {
        "status": 201,
        "json": { "pesan": "Data berhasil ditambahkan!" }
    }
selesai
''';

  static String _libraryTemplate(String name) => '''// Project: $name
// Template: Library

// Fungsi-fungsi utilitas yang bisa dipakai ulang

fungsi sapa(nama)
    kembalikan "Halo, " + nama + "!"
selesai

fungsi tambah(a, b)
    kembalikan a + b
selesai

fungsi faktorial(n)
    jika n <= 1 maka
        kembalikan 1
    selesai
    kembalikan n * faktorial(n - 1)
selesai
''';

  static String _cliTemplate(String name) =>
      '''// Project: $name
// Template: CLI

tampilkan("=== $name CLI ===")

buat nama = masukkan("Masukkan nama kamu: ")
tampilkan("Halo, " + nama + "!")

buat pilihan = masukkan("Pilih menu (1-3): ")

jika pilihan == "1" maka
    tampilkan("Kamu memilih menu 1")
atau jika pilihan == "2" maka
    tampilkan("Kamu memilih menu 2")
atau jika pilihan == "3" maka
    tampilkan("Kamu memilih menu 3")
jika tidak maka
    tampilkan("Pilihan tidak valid")
selesai
''';
}
