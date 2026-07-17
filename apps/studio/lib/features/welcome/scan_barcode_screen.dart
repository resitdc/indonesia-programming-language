import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanBarcodeScreen extends StatefulWidget {
  const ScanBarcodeScreen({super.key});

  @override
  State<ScanBarcodeScreen> createState() => _ScanBarcodeScreenState();
}

class _ScanBarcodeScreenState extends State<ScanBarcodeScreen> {
  String? _scannedCode;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white70,
        elevation: 0,
        title: const Text(
          'Scan Barcode',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: isDesktop ? _buildDesktopFallback() : _buildMobileScanner(),
    );
  }

  /// Desktop: show manual code input since camera is not available
  Widget _buildDesktopFallback() {
    final codeController = TextEditingController();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.qr_code_2,
                size: 36,
                color: Color(0xFFDCDCAA),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Kamera tidak tersedia di desktop',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan kode project secara manual untuk mengunduh sample project dari guru Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
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
                  fillColor: Color(0xFF252526),
                ),
              ),
              child: TextField(
                controller: codeController,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'Masukkan kode project...',
                  hintStyle: TextStyle(color: Colors.white30),
                  prefixIcon: Icon(Icons.vpn_key_outlined, color: Colors.white30, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () {
                        final code = codeController.text.trim();
                        if (code.isNotEmpty) {
                          _handleScannedCode(code);
                        }
                      },
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download_outlined, size: 18),
                label: Text(_isProcessing ? 'Memproses...' : 'Download Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2568E7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            if (_scannedCode != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF332B00),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF665600)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFFDCDCAA)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kode: $_scannedCode\nServer belum tersedia. Fitur ini akan segera hadir!',
                        style: const TextStyle(color: Color(0xFFDCDCAA), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Mobile: show camera scanner
  Widget _buildMobileScanner() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(
                onDetect: (capture) {
                  if (_isProcessing) return;
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final code = barcodes.first.rawValue;
                    if (code != null && code.isNotEmpty) {
                      _handleScannedCode(code);
                    }
                  }
                },
              ),
              // Scan overlay frame
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF2568E7), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              // Corner accents
              Positioned(
                bottom: 100,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Arahkan kamera ke barcode project',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_scannedCode != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF252526),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF4EC9B0), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kode terdeteksi: $_scannedCode',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF332B00),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Color(0xFFDCDCAA)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Server belum tersedia. Fitur ini akan segera hadir!',
                          style: TextStyle(color: Color(0xFFDCDCAA), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _handleScannedCode(String code) {
    setState(() {
      _isProcessing = true;
      _scannedCode = code;
    });

    // TODO: Send code to server to get download URL
    // For now, just show the code and a placeholder message
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }
}
