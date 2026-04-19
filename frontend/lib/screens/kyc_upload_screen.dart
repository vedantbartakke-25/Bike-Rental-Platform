// screens/kyc_upload_screen.dart — Driving License Upload (KYC)
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {
  Uint8List? _imageBytes;
  String?    _fileName;
  bool       _isUploading = false;
  String?    _error;
  String?    _successUrl;

  final ImagePicker _picker = ImagePicker();

  // ── Pick from gallery or camera ───────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fileName   = picked.name;
        _error      = null;
        _successUrl = null;
      });
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  // ── Upload to backend ─────────────────────────────────────────
  Future<void> _uploadLicense() async {
    if (_imageBytes == null || _fileName == null) {
      setState(() => _error = 'Please select an image first.');
      return;
    }
    setState(() { _isUploading = true; _error = null; });

    try {
      final result = await ApiService.uploadLicense(_imageBytes!, _fileName!);
      final url = result['license_image'] as String?;
      if (mounted) {
        setState(() {
          _successUrl  = url;
          _isUploading = false;
        });
        // Show success snackbar then pop with true (tell caller to proceed)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('License uploaded! You are now verified ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error       = e.toString().replaceAll('Exception: ', '');
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Driving License'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────
            const Icon(Icons.badge_outlined, size: 64, color: Color(0xFF1565C0)),
            const SizedBox(height: 12),
            const Text(
              'KYC Verification Required',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a clear photo of your driving license to continue with your booking. '
              'This is required only once.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // ── Image preview ────────────────────────────────────
            GestureDetector(
              onTap: () => _showSourceSheet(context),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _imageBytes != null
                        ? const Color(0xFF1565C0)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 52, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text('Tap to select image',
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Pick image button ────────────────────────────────
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_imageBytes == null ? 'Choose Image' : 'Change Image'),
              onPressed: () => _showSourceSheet(context),
            ),
            const SizedBox(height: 12),

            // ── Error message ────────────────────────────────────
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
              const SizedBox(height: 12),
            ],

            // ── Upload button ────────────────────────────────────
            ElevatedButton.icon(
              icon: _isUploading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                _isUploading ? 'Uploading...' : 'Upload License',
                style: const TextStyle(fontSize: 16),
              ),
              onPressed: _isUploading ? null : _uploadLicense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // ── Privacy note ─────────────────────────────────────
            Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your license is stored securely and only used for identity verification.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
