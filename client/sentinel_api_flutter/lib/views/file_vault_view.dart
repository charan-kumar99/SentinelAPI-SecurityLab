import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../models/file_models.dart';
import '../services/api_service.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_card.dart';
import '../widgets/code_preview.dart';
import '../widgets/badge_chip.dart';

class FileVaultView extends StatefulWidget {
  const FileVaultView({super.key});

  @override
  State<FileVaultView> createState() => _FileVaultViewState();
}

class _FileVaultViewState extends State<FileVaultView> {
  bool _loading = false;
  List<FileMetadataDto> _files = [];
  String _uploadAnalysis = 'Upload a file or choose an exploit preset to test Magic Byte validation.';
  String _signedUrlOutput = 'Select a stored file below to generate a cryptographically signed expiring download URL.';
  int _expirationSeconds = 300;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    if (!ApiService.isLoggedIn) return;
    setState(() => _loading = true);
    final files = await ApiService.getMyFiles();
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  Future<void> _uploadCustomFile() async {
    if (!ApiService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please Login first in the Auth tab!')),
      );
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          _executeUpload(file.name, file.bytes!, 'application/octet-stream');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File picker error: $e')),
      );
    }
  }

  // Built-in presets for testing Magic Byte security checks
  void _uploadPreset(String presetType) {
    if (!ApiService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please Login first in the Auth tab!')),
      );
      return;
    }

    if (presetType == 'valid_pdf') {
      // Magic Bytes: %PDF-1.7 (0x25 0x50 0x44 0x46)
      final pdfBytes = utf8.encode('%PDF-1.7\n%Valid Secure Document\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF');
      _executeUpload('SecurityReport_2026.pdf', Uint8List.fromList(pdfBytes), 'application/pdf');
    } else if (presetType == 'valid_png') {
      // Magic Bytes: \x89PNG\r\n\x1a\n (0x89 0x50 0x4E 0x47)
      final pngHeader = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52];
      _executeUpload('dashboard_screenshot.png', Uint8List.fromList(pngHeader), 'image/png');
    } else if (presetType == 'polyglot_exe') {
      // Polyglot Attack: Windows PE / EXE disguised as .png (Magic bytes: MZ -> 0x4D 0x5A)
      final exeBytes = [0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00];
      _executeUpload('malicious_trojan.png', Uint8List.fromList(exeBytes), 'image/png');
    } else if (presetType == 'disguised_php') {
      // Disguised Web Shell: <?php echo "PWNED"; ?> disguised as .jpg
      final phpBytes = utf8.encode('<?php system(\$_GET["cmd"]); ?>');
      _executeUpload('avatar_photo.jpg', Uint8List.fromList(phpBytes), 'image/jpeg');
    }
  }

  Future<void> _executeUpload(String fileName, Uint8List bytes, String contentType) async {
    setState(() => _loading = true);

    // Format first 16 bytes in HEX for inspector
    final hexList = bytes.take(16).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

    final res = await ApiService.uploadFile(
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );

    setState(() {
      _loading = false;
      _uploadAnalysis = '--- BINARY INSPECTION STREAM ---\nTarget File: $fileName\nContent-Type Claimed: $contentType\nFile Size: ${bytes.length} bytes\nMagic Bytes (Hex): $hexList\n\n--- SERVER RESPONSE ---\n${const JsonEncoder.withIndent('  ').convert(res)}';
    });

    if (res['success'] == true) {
      _loadFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File passed magic byte validation, encrypted with AES-256, and saved!'),
            backgroundColor: CyberTheme.emeraldNeon,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload Blocked: ${res['error'] ?? "Magic Byte mismatch"}'),
            backgroundColor: CyberTheme.crimsonNeon,
          ),
        );
      }
    }
  }

  Future<void> _generateSignedUrl(FileMetadataDto file) async {
    setState(() => _loading = true);
    final res = await ApiService.generateSignedUrl(file.id, expirationSeconds: _expirationSeconds);
    setState(() {
      _loading = false;
      _signedUrlOutput = const JsonEncoder.withIndent('  ').convert(res);
    });
  }

  Future<void> _downloadFile(FileMetadataDto file) async {
    setState(() => _loading = true);
    final bytes = await ApiService.downloadFileBytes(file.id);
    setState(() => _loading = false);
    if (bytes != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded "${file.originalFileName}" (${bytes.length} bytes) decrypted via AES-256!'),
          backgroundColor: CyberTheme.emeraldNeon,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Upload & Exploit Presets
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    CyberCard(
                      title: 'Magic Byte Binary Sanitizer & Upload',
                      subtitle: 'Deep Header Inspection & Anti-Polyglot Defense Pipeline',
                      icon: Icons.shield_outlined,
                      accentColor: CyberTheme.primaryNeon,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select a file from your system or execute pre-configured test scenarios to verify magic byte binary signature validation:',
                            style: TextStyle(fontSize: 12.5, color: CyberTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CyberTheme.primaryNeon,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            ),
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('PICK & UPLOAD CUSTOM FILE', style: TextStyle(fontWeight: FontWeight.w900)),
                            onPressed: _loading ? null : _uploadCustomFile,
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          Text('Test Vectors & Polyglot Presets:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.picture_as_pdf, color: CyberTheme.emeraldNeon, size: 16),
                                label: const Text('Valid PDF (25 50 44 46)'),
                                backgroundColor: CyberTheme.emeraldNeon.withOpacity(0.12),
                                side: BorderSide(color: CyberTheme.emeraldNeon.withOpacity(0.4)),
                                onPressed: () => _uploadPreset('valid_pdf'),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.image, color: CyberTheme.emeraldNeon, size: 16),
                                label: const Text('Valid PNG (89 50 4E 47)'),
                                backgroundColor: CyberTheme.emeraldNeon.withOpacity(0.12),
                                side: BorderSide(color: CyberTheme.emeraldNeon.withOpacity(0.4)),
                                onPressed: () => _uploadPreset('valid_png'),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.dangerous, color: CyberTheme.crimsonNeon, size: 16),
                                label: const Text('Fake Polyglot EXE (4D 5A)'),
                                backgroundColor: CyberTheme.crimsonNeon.withOpacity(0.15),
                                side: BorderSide(color: CyberTheme.crimsonNeon.withOpacity(0.5)),
                                onPressed: () => _uploadPreset('polyglot_exe'),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.pest_control, color: CyberTheme.crimsonNeon, size: 16),
                                label: const Text('Disguised PHP WebShell'),
                                backgroundColor: CyberTheme.crimsonNeon.withOpacity(0.15),
                                side: BorderSide(color: CyberTheme.crimsonNeon.withOpacity(0.5)),
                                onPressed: () => _uploadPreset('disguised_php'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          CyberCodeBox(
                            title: 'BINARY INSPECTOR & SERVER REJECTION LOG',
                            content: _uploadAnalysis,
                            accentColor: CyberTheme.primaryNeon,
                            maxHeight: 220,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Right: Stored File Vault & Expiring Signed URLs
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    CyberCard(
                      title: 'Encrypted Vault & Signed Expiring URLs',
                      subtitle: 'AES-256-GCM at rest with HMAC-SHA256 Expiring Download Signatures',
                      icon: Icons.folder_special_rounded,
                      accentColor: CyberTheme.secondaryNeon,
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: CyberTheme.secondaryNeon),
                        tooltip: 'Refresh Vault Files',
                        onPressed: _loadFiles,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Expiring TTL: $_expirationSeconds sec', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Expanded(
                                child: Slider(
                                  value: _expirationSeconds.toDouble(),
                                  min: 30,
                                  max: 3600,
                                  divisions: 10,
                                  activeColor: CyberTheme.secondaryNeon,
                                  onChanged: (v) => setState(() => _expirationSeconds = v.toInt()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Vault File List
                          Container(
                            constraints: const BoxConstraints(maxHeight: 230),
                            decoration: BoxDecoration(
                              color: CyberTheme.surfaceInput,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: CyberTheme.borderSubtle),
                            ),
                            child: _files.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Text(
                                        'No encrypted files in vault. Upload or use test presets on the left!',
                                        style: TextStyle(color: CyberTheme.textMuted, fontSize: 12),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: _files.length,
                                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                                    itemBuilder: (ctx, i) {
                                      final f = _files[i];
                                      return ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.lock_outline, color: CyberTheme.secondaryNeon, size: 20),
                                        title: Text(
                                          f.originalFileName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                        ),
                                        subtitle: Text(
                                          '${f.fileSizeBytes} B • ${f.contentType} • SHA: ${f.sha256Hash.substring(0, 10)}...',
                                          style: const TextStyle(fontSize: 10.5, color: CyberTheme.textMuted),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.link_rounded, color: CyberTheme.primaryNeon, size: 18),
                                              tooltip: 'Generate Signed URL',
                                              onPressed: () => _generateSignedUrl(f),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.download_rounded, color: CyberTheme.emeraldNeon, size: 18),
                                              tooltip: 'Download (AES-256 Decrypt)',
                                              onPressed: () => _downloadFile(f),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 14),
                          CyberCodeBox(
                            title: 'SIGNED DOWNLOAD URL METADATA (HMAC-SHA256)',
                            content: _signedUrlOutput,
                            accentColor: CyberTheme.secondaryNeon,
                            maxHeight: 150,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
