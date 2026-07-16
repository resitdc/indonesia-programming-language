/// Model untuk project RPL Studio.
library;

enum ProjectTemplate { console, website, restApi, desktop, library, cli }

extension ProjectTemplateExtension on ProjectTemplate {
  String get displayName {
    switch (this) {
      case ProjectTemplate.console:
        return 'Console';
      case ProjectTemplate.website:
        return 'Website';
      case ProjectTemplate.restApi:
        return 'REST API';
      case ProjectTemplate.desktop:
        return 'Desktop';
      case ProjectTemplate.library:
        return 'Library';
      case ProjectTemplate.cli:
        return 'CLI';
    }
  }

  String get description {
    switch (this) {
      case ProjectTemplate.console:
        return 'Program sederhana yang berjalan di terminal';
      case ProjectTemplate.website:
        return 'Website dengan HTML, CSS, dan backend RPL';
      case ProjectTemplate.restApi:
        return 'Backend REST API dengan routing dan database';
      case ProjectTemplate.desktop:
        return 'Aplikasi desktop native';
      case ProjectTemplate.library:
        return 'Pustaka/modul yang bisa dipakai ulang';
      case ProjectTemplate.cli:
        return 'Command-line tool';
    }
  }

  String get icon {
    switch (this) {
      case ProjectTemplate.console:
        return 'terminal';
      case ProjectTemplate.website:
        return 'web';
      case ProjectTemplate.restApi:
        return 'api';
      case ProjectTemplate.desktop:
        return 'desktop_windows';
      case ProjectTemplate.library:
        return 'library_books';
      case ProjectTemplate.cli:
        return 'code';
    }
  }
}

class Project {
  final String name;
  final String path;
  final ProjectTemplate template;
  final DateTime createdAt;
  final DateTime lastOpened;

  Project({
    required this.name,
    required this.path,
    required this.template,
    required this.createdAt,
    required this.lastOpened,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'template': template.name,
    'createdAt': createdAt.toIso8601String(),
    'lastOpened': lastOpened.toIso8601String(),
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    name: json['name'] as String,
    path: json['path'] as String,
    template: ProjectTemplate.values.firstWhere(
      (t) => t.name == json['template'],
      orElse: () => ProjectTemplate.console,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastOpened: DateTime.parse(json['lastOpened'] as String),
  );

  Project copyWith({DateTime? lastOpened}) => Project(
    name: name,
    path: path,
    template: template,
    createdAt: createdAt,
    lastOpened: lastOpened ?? this.lastOpened,
  );
}
