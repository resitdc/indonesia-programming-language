import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isLowEndMode = settings.isLowEndMode;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D30),
        title: const Text(
          'Pengaturan',
          style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: const Border(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFFFFFFFF),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              'Performa',
              style: TextStyle(
                color: Color(0xFF2568E7),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            color: const Color(0xFF2D2D30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              activeColor: const Color(0xFF2568E7),
              title: Container (
                margin: const EdgeInsets.only(bottom: 8), 
                child: const Text(
                  'Mode Ringan (Low-End Mode)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                )
              ),
              subtitle: const Text(
                'Direkomendasikan untuk perangkat berspesifikasi rendah. Fitur ini akan menghemat RAM secara drastis dengan cara:\n'
                '• Mematikan animasi & efek visual\n'
                '• Membatasi maksimal 2 tab Editor terbuka\n'
                '• Menunda pewarnaan sintaks, atau mematikannya untuk file lebih dari 800 baris\n'
                '• Membersihkan RAM Browser ( WebView ) otomatis saat tidak aktif\n'
                '• Membatasi pembacaan data Database & SQL Query maksimal 20 baris',
                style: TextStyle(color: Colors.white70, height: 1.1),
              ),
              value: isLowEndMode,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).toggleLowEndMode(value);
              },
            ),
          ),
          const SizedBox(height: 16.0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              'Editor',
              style: TextStyle(
                color: Color(0xFF2568E7),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            color: const Color(0xFF2D2D30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              activeColor: const Color(0xFF2568E7),
              title: Container (
                margin: const EdgeInsets.only(bottom: 8), 
                child: const Text(
                  'Auto Save',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                )
              ),
              subtitle: const Text(
                'Menyimpan file secara otomatis setiap kali Anda mengetik di editor.',
                style: TextStyle(color: Colors.white70, height: 1.1),
              ),
              value: settings.isAutoSave,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).toggleAutoSave(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
