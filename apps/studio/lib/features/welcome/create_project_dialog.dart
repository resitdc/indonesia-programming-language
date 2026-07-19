import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/project.dart';
import '../../services/project_service.dart';

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _nameController = TextEditingController();
  String _parentPath = '';
  ProjectTemplate _selectedTemplate = ProjectTemplate.console;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initDefaultPath();
  }

  Future<void> _initDefaultPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final rplDir = '${appDir.path}${Platform.pathSeparator}RPLProjects';
    final dir = Directory(rplDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    setState(() => _parentPath = rplDir);
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.getDirectoryPath();
    if (result != null) {
      setState(() => _parentPath = result);
    }
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama project tidak boleh kosong.');
      return;
    }
    if (_parentPath.isEmpty) {
      setState(() => _error = 'Pilih folder penyimpanan terlebih dahulu.');
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    try {
      final project = await ProjectService.createProject(
        name: name,
        parentPath: _parentPath,
        template: _selectedTemplate,
      );
      if (mounted) {
        Navigator.pop(context, project);
      }
    } catch (e) {
      setState(() {
        _creating = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF252526),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2568E7).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.create_new_folder_outlined,
                    color: Color(0xFF2568E7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Buat Project Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Project Name
            Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3C3C3C)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2568E7)),
                  ),
                  filled: true,
                  fillColor: Color(0xFF1E1E1E),
                ),
              ),
              child: TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Nama Project',
                  labelStyle: const TextStyle(color: Colors.white54),
                  hintText: 'contoh: aplikasi_toko',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                  prefixIcon: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: HugeIcon(icon: HugeIcons.strokeRoundedEdit02, color: Colors.white38, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Folder Path
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF3C3C3C)),
              ),
              child: Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedFolder01, size: 16, color: Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _parentPath.isEmpty ? 'Memilih folder...' : _parentPath,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _pickFolder,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2568E7),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Browse', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5A1D1D),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedAlert02, size: 14, color: Color(0xFFFF6B6B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _creating ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _creating ? null : _create,
                  icon: _creating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkSquare02, size: 16, color: Colors.white70),
                  label: Text(_creating ? 'Membuat...' : 'Buat Project'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2568E7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
